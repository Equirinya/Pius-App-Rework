import 'dart:math';
import 'dart:io' show Platform;

import 'package:PiusApp/background.dart';
import 'package:PiusApp/connection.dart';
import 'package:PiusApp/course_selection.dart';
import 'package:PiusApp/login_fields.dart';
import 'package:PiusApp/main.dart';
import 'package:PiusApp/qr_import.dart';
import 'package:PiusApp/database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ionicons/ionicons.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class WelcomeCarousel extends StatefulWidget {
  const WelcomeCarousel({super.key, required this.isar});

  final Isar isar;

  @override
  State<WelcomeCarousel> createState() => _WelcomeCarouselState();
}

class _WelcomeCarouselState extends State<WelcomeCarousel> {
  late SharedPreferences prefs;
  late FlutterSecureStorage securePrefs;

  bool loggedIn = false;
  bool courseSelected = false;

  final PageController _pageController = PageController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  int loginState = 0;
  String loginError = "";

  List<Konfiguration> importedKonfigurationen = [];

  // Mirrors the old (pre-Konfigurationen) onboarding, which went straight
  // into picking a Klasse/Stufe instead of showing an empty list first -
  // fires once, the first time the Klasse/Kurse page is reached with no
  // Stundenplan created yet. Afterwards (created or backed out) the normal
  // list view takes over, so a second/third Konfiguration is still just a
  // tap on "Erstellen" away.
  bool _autoOpenedCourseSelection = false;

  @override
  void initState() {
    securePrefs = getSecurePrefs();
    SharedPreferences.getInstance().then((value) {
      prefs = value;
    });
    loadConfiguration();
    // A share link tapped while onboarding is open imports through a page
    // pushed by main.dart, i.e. outside this widget - so pick the result up
    // once it comes back instead of showing a stale, empty list.
    konfigurationenRevision.addListener(_onKonfigurationenChanged);
    super.initState();
  }

  void _onKonfigurationenChanged() {
    if (!mounted) return;
    setState(() => courseSelected = widget.isar.konfigurations.where().countSync() > 0);
  }

  @override
  void dispose() {
    konfigurationenRevision.removeListener(_onKonfigurationenChanged);
    _pageController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void loadConfiguration() async {
    String? username = await securePrefs.read(key: "username");
    String? password = await securePrefs.read(key: "password");

    if ((username == null || password == null) && prefs.getBool("firstRunComplete") == true) {
      //test for old version
      //TODO read login.txt from old version
    }

    if (username != null && password != null) {
      usernameController.text = username;
      passwordController.text = password;
      try {
        await checkCredentials();
        setState(() {
          loggedIn = true;
        });
      } catch (e) {
        if (kDebugMode) print("Error while logging in: $e");
      }
    }

    if (widget.isar.konfigurations.where().countSync() > 0) {
      setState(() {
        courseSelected = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final List<Widget> pages = [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      constraints: BoxConstraints(maxHeight: size.height * 0.4, maxWidth: size.width * 0.4),
                      child: ClipRect(
                        child: Align(
                          widthFactor: 0.8,
                          heightFactor: 0.8,
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                            child: Image.asset('assets/icon/icon_transparent.png'), //TODO fix hole in logo
                          ),
                        ),
                      ),
                    ),
                    Text("Pius App", style: Theme.of(context).textTheme.displayLarge),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Willkommen zur neuen Pius App. Ab sofort Stunden- und Vertretungsplan in einem! Offline verfügbar und im Hintergrund aktualisiert. ",
                          style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () {
                    _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("Let's go!"),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 24),
                      child: Icon(
                        Icons.account_circle,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text("Login", style: Theme.of(context).textTheme.headlineLarge),
                    SizedBox(height: 8),
                    Text("Bitte logge dich mit deinem Pius-Account ein. Die Daten werden verschlüsselt und nur auf deinem Gerät gespeichert.",
                        style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    LoginFields(
                      usernameController: usernameController,
                      passwordController: passwordController,
                      enabled: loginState != 1,
                      onSubmitted: saveLogin,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: 32,
                        child: IndexedStack(
                          index: loginState,
                          alignment: Alignment.center,
                          children: [
                            Text(loginError),
                            const CupertinoActivityIndicator(),
                            Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FilledButton.tonal(
              onPressed: loginState == 0 || loginState == 2
                  ? saveLogin
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: const Text("Einloggen"),
              ),
            ),
            TextButton.icon(
              onPressed: loginState == 1 ? null : _loginViaQr,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text("Mit QR-Code einloggen"),
            ),
            SizedBox(height: max(MediaQuery.of(context).viewInsets.bottom, 16)),
          ],
        ),
      ),
      if (loggedIn)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Scaffold(
            body: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 32, bottom: 8),
                    child: Icon(Ionicons.options_outline, size: 48, color: Theme.of(context).colorScheme.primary),
                  ),
                  Text("Klasse/Kurse auswählen", style: Theme.of(context).textTheme.headlineMedium),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Erstelle einen Stundenplan für dich (oder mehrere, z.B. für Geschwister). Hast du die App schon auf einem anderen Gerät, kannst du sie per QR-Code übernehmen.",
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: StatefulBuilder(
                      builder: (context, listSetState) {
                        List<Konfiguration> konfigurationen = widget.isar.konfigurations.where().findAllSync();
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              for (final konfiguration in konfigurationen)
                                ListTile(
                                  leading: Icon(konfiguration.isOberstufe ? Icons.school_outlined : Icons.people_outline),
                                  title: Text(konfiguration.name),
                                  subtitle: Text("${konfiguration.isOberstufe ? "Oberstufe" : "Klasse"} ${konfiguration.stufe}"),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      await deleteKonfiguration(widget.isar, konfiguration.id);
                                      listSetState(() {});
                                      setState(() => courseSelected = widget.isar.konfigurations.where().countSync() > 0);
                                    },
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Ionicons.add),
                                        label: const Text("Erstellen"),
                                        onPressed: () async {
                                          Konfiguration? result = await Navigator.of(context)
                                              .push(MaterialPageRoute(builder: (context) => CourseSelection(isar: widget.isar)));
                                          if (result != null) {
                                            listSetState(() {});
                                            setState(() => courseSelected = true);
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.qr_code),
                                        label: const Text("QR-Code"),
                                        onPressed: () async {
                                          List<Konfiguration>? result = await Navigator.of(context)
                                              .push(MaterialPageRoute(builder: (context) => QrScanPage(isar: widget.isar, autoCommit: true)));
                                          if (result != null && result.isNotEmpty) {
                                            listSetState(() {});
                                            setState(() => courseSelected = true);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  courseSelected
                      ? FilledButton.tonal(
                          onPressed: _weiterVonKlasseSeite,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: const Text("Weiter"),
                          ))
                      : OutlinedButton(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              icon: const Icon(Ionicons.warning_outline),
                              title: const Text("Sicher?"),
                              content: const Text("Wenn du keine Klasse/Stufe auswählst, wirst du die App nur ohne Stundenplan Ansicht nutzen können."),
                              actions: [
                                TextButton(
                                    style: TextButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primaryContainer),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      setState(() {
                                        courseSelected = true;
                                      });
                                      _weiterVonKlasseSeite();
                                    },
                                    child: const Text("Verstanden, weiter")),
                                TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text("Zurück"))
                              ],
                            ),
                          ),
                          child: const Text("Überspringen"),
                        ),
                ],
              ),
            ),
          ),
        ),
      if (loggedIn && courseSelected && (Platform.isIOS || Platform.isAndroid) )
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 32, bottom: 16),
                  child: Icon(Ionicons.notifications_outline, size: 48, color: Theme.of(context).colorScheme.primary),
                ),
                Text("Benachrichtigungen", style: Theme.of(context).textTheme.headlineLarge),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Möchtest du Benachrichtigungen zu neuen Vertretungen erhalten? Du kannst diese Einstellung später in den Einstellungen ändern.",
                      style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                ),
                const Expanded(child: SizedBox()),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        prefs.setBool("showNotifications", false);
                        startApp(context);
                        configureBackgroundFetch();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: SizedBox(width: 48, child: Text("Nein", textAlign: TextAlign.center)),
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () async {
                        bool gotPermission = await requestNotificationPermission();
                        if(!gotPermission) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text("Konnte keine Benachrichtigungen aktivieren."),
                          ));
                          return;
                        }
                        prefs.setBool("showNotifications", true);
                        configureBackgroundFetch();
                        startApp(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: 48,
                          child: Text("Ja", textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16,
                )
              ],
            ),
          ),
        )
    ];

    return Material(
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: pages.length,
                effect: WormEffect(
                  activeDotColor: Theme.of(context).colorScheme.primary,
                  dotColor: Theme.of(context).colorScheme.primaryContainer,
                  dotHeight: 8,
                  dotWidth: 8,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  saveLogin() async {
              if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
                setState(() {
                  loginState = 0;
                  loginError = "Bitte fülle alle Felder aus.";
                });
                return;
              }

              setState(() {
                loginState = 1;
              });
              String lastUsername = await securePrefs.read(key: "username") ?? "";
              String lastPassword = await securePrefs.read(key: "password") ?? "";
              await securePrefs.write(key: "username", value: usernameController.text);
              await securePrefs.write(key: "password", value: passwordController.text);
              //print(passwordController.text);
              //print(await securePrefs.read(key: "password"));

              try {
                await checkCredentials();
              } on AuthorizationException catch (e) {
                setState(() {
                  loginState = 0;
                  loginError = e.msg;
                });
                securePrefs.write(key: "username", value: lastUsername);
                securePrefs.write(key: "password", value: lastPassword);
                return;
              } catch (e) {
                setState(() {
                  loginState = 0;
                  loginError = "Unerwarteter Fehler: ${e.toString()}";
                });
                securePrefs.write(key: "username", value: lastUsername);
                securePrefs.write(key: "password", value: lastPassword);
                return;
              }
              setState(() {
                loginState = 2;
                loggedIn = true;
              });
              // Erst jetzt - nach geprüften Zugangsdaten - darf der
              // Passwortmanager das Speichern anbieten.
              finishLoginAutofill();
              await Future.delayed(const Duration(seconds: 1));
              if (mounted) _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
            }

  /// Scans a "teilen" QR-Code (see settings.dart) right from the Login page,
  /// same as scanning one later in Settings can include Pius-Login
  /// credentials alongside Konfigurationen - so if someone shares theirs,
  /// this can skip typing a username/password entirely.
  Future<void> _loginViaQr() async {
    List<Konfiguration>? imported =
        await Navigator.of(context).push(MaterialPageRoute(builder: (context) => QrScanPage(isar: widget.isar, autoCommit: true)));
    if (imported == null || !mounted) return; // backed out without scanning/importing anything

    if (imported.isNotEmpty) setState(() => courseSelected = true);

    // QrScanPage already wrote any included credentials to secure storage -
    // just re-read them the same way loadConfiguration() does on startup.
    String? username = await securePrefs.read(key: "username");
    String? password = await securePrefs.read(key: "password");
    if (username != null && password != null && !loggedIn) {
      usernameController.text = username;
      passwordController.text = password;
      try {
        await checkCredentials();
        if (!mounted) return;
        setState(() => loggedIn = true);
      } catch (e) {
        if (kDebugMode) print("Error while logging in via QR: $e");
      }
    }

    // The scanned code didn't include a login (just Konfigurationen, say) -
    // stay put so the user can still log in manually.
    if (!loggedIn) return;
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  /// Verlässt die Klasse/Kurse-Seite - die letzte Seite, die es auf allen
  /// Plattformen gibt.
  ///
  /// Die Benachrichtigungs-Seite dahinter existiert nur auf iOS/Android. Auf
  /// Desktop war die Klasse/Kurse-Seite damit bereits die letzte, und
  /// `nextPage()` dort ein No-Op: wer eine Klasse ausgewählt hatte, kam über
  /// "Weiter" nie zu `startApp()`, "initialized" wurde nie gesetzt und die App
  /// startete wieder im Onboarding. Nur "Überspringen" führte hinaus - also
  /// ausgerechnet der Weg *ohne* Stundenplan.
  void _weiterVonKlasseSeite() {
    if (Platform.isIOS || Platform.isAndroid) {
      _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    } else {
      startApp(context);
    }
  }

  void _onPageChanged(int index) {
    // The Klasse/Kurse page is always index 2 once logged in (Willkommen ->
    // Login -> Klasse/Kurse). Only auto-opens once, and only if nothing has
    // been created yet - if the user swipes back and forward again, or
    // already has Konfigurationen (e.g. re-entering onboarding), it just
    // shows the normal list.
    if (loggedIn && index == 2 && !courseSelected && !_autoOpenedCourseSelection) {
      _autoOpenedCourseSelection = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoCreateFirstConfig());
    }
  }

  Future<void> _autoCreateFirstConfig() async {
    Konfiguration? result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => CourseSelection(isar: widget.isar)));
    if (!mounted) return;
    if (result != null) {
      setState(() => courseSelected = true);
    } else {
      // Backed out without creating one - just land on the normal list view
      // (still on the same onboarding page) instead of leaving it blank.
      setState(() {});
    }
  }

  void startApp(BuildContext context) {
    prefs.setBool("initialized", true);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => OuterPage(isar: widget.isar, prefs: prefs)));
  }
}
