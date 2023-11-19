import 'package:PiusApp/connection.dart';
import 'package:PiusApp/main.dart';
import 'package:PiusApp/pages/stundenplan.dart';
import 'package:PiusApp/database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ionicons/ionicons.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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

  late PdfDocument klassenplan;
  late PdfDocument oberstufenplan;
  List<String> klassen = List.empty(growable: true);
  List<String> oberstufen = List.empty(growable: true);
  List<String> stufen = List.empty(growable: true);
  bool stufenLoading = false;

  @override
  void initState() {
    AndroidOptions getAndroidOptions() => const AndroidOptions(
          encryptedSharedPreferences: true,
        );
    securePrefs = FlutterSecureStorage(aOptions: getAndroidOptions());
    SharedPreferences.getInstance().then((value) {
      prefs = value;
    });
    loadConfiguration();
    super.initState();
  }

  void loadConfiguration() async {
    String? username = await securePrefs.read(key: "username");
    String? password = await securePrefs.read(key: "password");

    if((username == null || password == null) && prefs.getBool("firstRunComplete") == true) { //test for old version
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
        if(kDebugMode) print("Error while logging in: $e");
      }
    }

    if (prefs.getString("stundenplanStufe")?.isNotEmpty ?? false) {
      setState(() {
        courseSelected = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              ColorFiltered(
                colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                child: Image.asset('assets/icon/icon_transparent.png'), //TODO fix hole in logo
              ),
            ],
          ),
          Text("Die Pius App", style: Theme.of(context).textTheme.displayLarge),
          Text("Willkommen zur neuen Pius App. Ab sofort Stunden- und Vertretungsplan in einem! Offline verfügbar und im Hintergrund aktualisiert. ",
              style: Theme.of(context).textTheme.bodyMedium),
          const Expanded(child: SizedBox()),
          FilledButton.tonal(
            onPressed: () {
              _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
            },
            child: Text("Mach die App dein eigen"), //TODO
          ),
        ],
      ),
      Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Icon(Icons.account_circle),
          Text("Login", style: Theme.of(context).textTheme.headlineMedium),
          Text("Bitte logge dich mit deinem Pius-Account ein. Die Daten werden verschlüsselt und nur auf deinem Gerät gespeichert.",
              style: Theme.of(context).textTheme.bodyMedium),
          TextField(
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: "Benutzername",
            ),
          ),
          TextField(
            controller: passwordController,
            decoration: const InputDecoration(
              labelText: "Passwort",
            ),
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
          const Expanded(child: SizedBox()),
          FilledButton.tonal(
            onPressed: loginState == 0
                ? () async {
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
                    await Future.delayed(const Duration(seconds: 1));
                    _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                  }
                : null,
            child: const Text("Einloggen"),
          ),
        ],
      ),
      if (loggedIn)
        Scaffold(
          body: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const Icon(Ionicons.options_outline),
              Text("Klasse/Stufe auswählen", style: Theme.of(context).textTheme.headlineMedium),
              const Expanded(child: SizedBox()),
              StatefulBuilder(
                builder: (context, setState) {
                  if (stufen.isEmpty) {
                    (() async {
                      try {
                        final (_klassenplan, _oberstufenplan) = await getCurrentStundenplaene();
                        klassenplan = _klassenplan;
                        oberstufenplan = _oberstufenplan;

                        klassen = await compute(getStufen, klassenplan);
                        oberstufen = await compute(getStufen, oberstufenplan);
                        if (context.mounted) {
                          setState(() {
                            stufen.addAll(klassen);
                            stufen.addAll(oberstufen);
                          });
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Konnte Stundenpläne nicht abrufen: $e"),
                        ));
                      }
                    }).call();
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CupertinoActivityIndicator(),
                    );
                  }
                  if (stufenLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CupertinoActivityIndicator(),
                    );
                  }
                  return SingleChildScrollView(
                      child: Column(
                    children: [
                      for (int i = 0; i < stufen.length; i++)
                        ListTile(
                          title: Text(stufen[i]),
                          onTap: () async {
                            if (i < klassen.length) {
                              setState(() {
                                stufenLoading = true;
                              });
                              setStundenplan(await compute(getStundenPlan, (klassen[i], klassenplan, false)), klassen[i], false, widget.isar, prefs, () {});
                              courseSelected = true;
                              _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                            } else {
                              setState(() {
                                stufenLoading = true;
                              });
                              List<Stunde> stunden = await compute(getStundenPlan, (oberstufen[i - klassen.length], oberstufenplan, true));
                              courseSelected =
                                  await showStundenplanSelection(stunden, oberstufen[i - klassen.length], () => context, widget.isar, prefs, () {});
                              if (courseSelected) _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                            }
                          },
                        ),
                    ],
                  ));
                },
              ),
              courseSelected
                  ? FilledButton.tonal(
                      onPressed: () {
                        _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                      },
                      child: const Text("Weiter"))
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
                                  _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
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
      if (loggedIn && courseSelected)
        Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            const Icon(Ionicons.notifications_outline),
            Text("Benachrichtigungen", style: Theme.of(context).textTheme.headlineMedium),
            Text("Möchtest du Benachrichtigungen zu neuen Vertretungen erhalten? Du kannst diese Einstellung später in den Einstellungen ändern.",
                style: Theme.of(context).textTheme.bodyMedium),
            const Expanded(child: SizedBox()),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    prefs.setBool("showNotifications", false);
                    prefs.setBool("initialized", true);
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => OuterPage(isar: widget.isar, prefs: prefs)));
                  },
                  child: const Text("Nein"),
                ),
                FilledButton.tonal(
                  onPressed: () {
                    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
                    flutterLocalNotificationsPlugin
                        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
                        ?.requestNotificationsPermission();
                    //TODO IOS permission?
                    prefs.setBool("showNotifications", true);
                    prefs.setBool("initialized", true);
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => OuterPage(isar: widget.isar, prefs: prefs)));
                  },
                  child: const Text("Ja"),
                ),
              ],
            ),
          ],
        ),
    ];

    //Align(
    //             alignment: Alignment.centerRight,
    //             child: Padding(
    //               padding: const EdgeInsets.all(8.0),
    //               child: Icon(
    //                 Ionicons.chevron_forward,
    //                 color: Theme.of(context).colorScheme.onSurfaceVariant,
    //               ),
    //             ),
    //           )

    return Material(
      child: SafeArea(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView(
              controller: _pageController,
              children: pages,
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
}
