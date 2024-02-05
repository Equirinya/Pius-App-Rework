import 'package:PiusApp/background.dart';
import 'package:PiusApp/pages/news.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ionicons/ionicons.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'connection.dart';
import 'database.dart';
import 'welcome.dart';
import 'pages/settings.dart';
import 'pages/stundenplan.dart';
import 'pages/vertretungsplan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

//TODO home screen widgets
//TODO app badge?

//TODO fix overlap in update stundenplan
//TODO Increment klasse nach sommerferien

//TODO shrink calendar header and add buttons yourself than add extra refresh button

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final Isar isar = await Isar.open(
    [VertretungSchema, StundeSchema, ColorPaletteSchema, NewsSchema],
    directory: (await getApplicationSupportDirectory()).path,
  );

  SharedPreferences prefs = await SharedPreferences.getInstance();

  if (kDebugMode) {
    timeDilation = 1.0;
  }

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_stat_icon_transparent');
  const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
    requestSoundPermission: false,
    requestBadgePermission: false,
    requestAlertPermission: false,);
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsDarwin, macOS: initializationSettingsDarwin);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  configureBackgroundFetch();

  runApp(MyApp(
    isar: isar,
    prefs: prefs,
  ));
}

class MyApp extends StatefulWidget {
  MyApp({super.key, required this.isar, required this.prefs});

  final Isar isar;
  final SharedPreferences prefs;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    int colorSchemeIndex = widget.prefs.getInt("colorSchemeIndex") ?? 1;
    int darkMode = widget.prefs.getInt("darkMode") ?? 0;

    return NotificationListener<ColorChangedNotification>(
      onNotification: (notification) {
        setState(() {});
        return true;
      },
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          ColorScheme lightColorScheme;
          ColorScheme darkColorScheme;
          VertretungsColors? vertretungsColors;

          //order of color schemes: pius, dynamic?, [user defined]

          bool dynamicSchemeExists = lightDynamic != null && darkDynamic != null;
          int maxColorSchemeIndex = widget.isar.colorPalettes.where().countSync() + (dynamicSchemeExists ? 1 : 0);

          if (colorSchemeIndex >= (dynamicSchemeExists ? 2 : 1) && colorSchemeIndex <= maxColorSchemeIndex) {
            ColorPalette palette = widget.isar.colorPalettes.where().findAllSync()[colorSchemeIndex - (dynamicSchemeExists ? 2 : 1)];
            lightColorScheme = palette.toColorScheme();
            darkColorScheme = palette.toColorScheme(true);
            vertretungsColors = palette.fromSeed ? null : palette.getExactColors();
          } else if (dynamicSchemeExists && colorSchemeIndex == 1) {
            // On Android S+ devices, use the provided dynamic color scheme.
            // (Recommended) Harmonize the dynamic color scheme' built-in semantic colors.
            lightColorScheme = lightDynamic.harmonized();
            darkColorScheme = darkDynamic.harmonized();
          } else {
            // Otherwise, use fallback schemes.
            Color primaryColor = Color.fromARGB(255, 87, 162, 211);
            Color secondaryColor = Color.fromARGB(255, 30, 111, 147);
            Color tertiaryColor = Color.fromARGB(255, 255, 204, 0);
            Color errorColor = Color.fromARGB(255, 255, 0, 0);
            lightColorScheme = SeedColorScheme.fromSeeds(
              primaryKey: primaryColor,
              secondaryKey: secondaryColor,
              tertiaryKey: tertiaryColor,
              errorKey: errorColor,
            );
            darkColorScheme = SeedColorScheme.fromSeeds(
              primaryKey: primaryColor,
              secondaryKey: secondaryColor,
              tertiaryKey: tertiaryColor,
              errorKey: errorColor,
              brightness: Brightness.dark,
            );
            vertretungsColors = VertretungsColors(
              mainColor: primaryColor,
              headerColor: secondaryColor,
              evaColor: tertiaryColor,
              replacementColor: errorColor,
            );
          }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            supportedLocales: const [
              Locale('de'),
            ],
            locale: const Locale("de"),
            localizationsDelegates: const [...GlobalMaterialLocalizations.delegates, SfGlobalLocalizations.delegate],
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: lightColorScheme,
              extensions: [if (vertretungsColors != null) vertretungsColors],
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: darkColorScheme,
              extensions: [if (vertretungsColors != null) vertretungsColors],
            ),
            themeMode: ThemeMode.values[darkMode],
            home: (widget.prefs.getBool("initialized") ?? false) ? OuterPage(isar: widget.isar, prefs: widget.prefs) : WelcomeCarousel(isar: widget.isar),
          );
        },
      ),
    );
  }
}

@immutable
class VertretungsColors extends ThemeExtension<VertretungsColors> {
  const VertretungsColors({
    required this.mainColor,
    required this.headerColor,
    required this.evaColor,
    required this.replacementColor,
  });

  final Color mainColor;
  final Color headerColor;
  final Color evaColor;
  final Color replacementColor;

  @override
  VertretungsColors copyWith({Color? mainColor, Color? headerColor, Color? evaColor, Color? replacementColor}) {
    return VertretungsColors(
      mainColor: mainColor ?? this.mainColor,
      headerColor: headerColor ?? this.headerColor,
      evaColor: evaColor ?? this.evaColor,
      replacementColor: replacementColor ?? this.replacementColor,
    );
  }

  @override
  VertretungsColors lerp(VertretungsColors? other, double t) {
    if (other is! VertretungsColors) {
      return this;
    }
    return VertretungsColors(
      mainColor: Color.lerp(mainColor, other.mainColor, t) ?? mainColor,
      headerColor: Color.lerp(headerColor, other.headerColor, t) ?? headerColor,
      evaColor: Color.lerp(evaColor, other.evaColor, t) ?? evaColor,
      replacementColor: Color.lerp(replacementColor, other.replacementColor, t) ?? replacementColor,
    );
  }

  // Optional
  @override
  String toString() => 'VertretungsColors(mainColor: $mainColor, headerColor: $headerColor, evaColor: $evaColor, replacementColor: $replacementColor)';
}

class OuterPage extends StatefulWidget {
  const OuterPage({super.key, required this.isar, required this.prefs});

  final Isar isar;
  final SharedPreferences prefs;

  @override
  State<OuterPage> createState() => _OuterPageState();
}

class _OuterPageState extends State<OuterPage> {
  ValueNotifier<bool?> vertretungsLoadingNotifier = ValueNotifier(false);
  ValueNotifier<bool?> calendarLoadingNotifier = ValueNotifier(false);

  @override
  void initState() {
    _selectedIndex = widget.prefs.getInt("selectedPage") ?? 0;
    asyncInit();
    super.initState();
  }

  void asyncInit() async {
    FlutterSecureStorage securePrefs = getSecurePrefs();

    String? username = await securePrefs.read(key: "username");
    String? password = await securePrefs.read(key: "password");
    if(username == null || password == null || username.isEmpty || password.isEmpty) {
      if(context.mounted) await newLogin(context, securePrefs); //TODO would be better to replace with shortened welcome screen
    }
    Connectivity().checkConnectivity().then((value) {
      if (!(widget.prefs.getBool("vertretungUpdateWifi") ?? false) || value == ConnectivityResult.wifi) {
        loadVertretungsplan();
      }
    });
    loadCalendarContent();
  }

  void loadVertretungsplan() async {
    vertretungsLoadingNotifier.value = true;
    try {
      String vertretungsplanWebsite = await getVertretungsplanWebsite();
      await parseVertretungsplan(vertretungsplanWebsite, widget.isar);
      vertretungsLoadingNotifier.value = false;
    } on Exception catch (e, s)  {
      vertretungsLoadingNotifier.value = null;
      if (kDebugMode) {
        print("Error while fetching Vertretungsplan:");
        print(e);
        print(s);
      }
    }
  }

  void loadCalendarContent() async {
    bool shouldUpdateTermine = true ||
        DateTime.fromMillisecondsSinceEpoch(widget.prefs.getInt("lastTermineUpdate") ?? 0)
            .isBefore(DateTime.now().subtract(durations.values.elementAt(widget.prefs.getInt("termineUpdateDuration") ?? 8)));
    bool shouldUpdateStundenplan = DateTime.fromMillisecondsSinceEpoch(widget.prefs.getInt("lastStundenplanUpdate") ?? 0)
        .isBefore(DateTime.now().subtract(durations.values.elementAt(widget.prefs.getInt("stundenplanUpdateDuration") ?? 8)));
    if (shouldUpdateTermine || shouldUpdateStundenplan) {
      calendarLoadingNotifier.value = true;
      bool failed = false;
      if (shouldUpdateTermine &&
          (!(widget.prefs.getBool("termineUpdateWifi") ?? true) || await Connectivity().checkConnectivity() == ConnectivityResult.wifi)) {
        try {
          await updateTermine();
          widget.prefs.setInt("lastTermineUpdate", DateTime.now().millisecondsSinceEpoch);
        } on Exception catch (e) {
          if (kDebugMode) {
            print(e);
          }
          failed = true;
        }
      }
      if (shouldUpdateStundenplan &&
          (!(widget.prefs.getBool("stundenplanUpdateWifi") ?? true) || await Connectivity().checkConnectivity() == ConnectivityResult.wifi)) {
        try {
          await updateStundenplan(widget.isar);
          widget.prefs.setInt("lastStundenplanUpdate", DateTime.now().millisecondsSinceEpoch);
        } on Exception catch (e) {
          if (kDebugMode) {
            print(e);
          }
          failed = true;
        }
      }
      calendarLoadingNotifier.value = failed ? null : false;
    }
  }

  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          StundenplanPage(
            isar: widget.isar,
            vertretungsLoading: vertretungsLoadingNotifier,
            calendarLoading: calendarLoadingNotifier,
          ),
          VertretungsplanPage(isar: widget.isar, loadingNotifier: vertretungsLoadingNotifier, refresh: loadVertretungsplan),
          NewsPage(isar: widget.isar),
          SettingsPage(
              isar: widget.isar,
              refresh: () {
                Connectivity().checkConnectivity().then((value) {
                  if (!(widget.prefs.getBool("vertretungUpdateWifi") ?? true) || value == ConnectivityResult.wifi) {
                    loadVertretungsplan();
                  }
                });
                loadCalendarContent();
              }),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            widget.prefs.setInt("selectedPage", index);
          });
        },
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Ionicons.calendar),
            icon: Icon(Ionicons.calendar_outline),
            label: "Stundenplan",
          ),
          NavigationDestination(
            selectedIcon: Icon(Ionicons.reorder_four),
            icon: Icon(Ionicons.reorder_four),
            label: "Vertretungsplan",
          ),
          NavigationDestination(
            selectedIcon: Icon(Ionicons.newspaper),
            icon: Icon(Ionicons.newspaper_outline),
            label: "News",
          ),
          NavigationDestination(
            selectedIcon: Icon(Ionicons.settings),
            icon: Icon(Ionicons.settings_outline),
            label: "Einstellungen",
          ),
        ],
      ),
    );
  }
}
