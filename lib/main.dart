import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ionicons/ionicons.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'connection.dart';
import 'database.dart';
import 'pages/settings.dart';
import 'pages/stundenplan.dart';
import 'pages/vertretungsplan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

//TODO über
//TODO carousel on first startup
//TODO syncfusion

//FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//         FlutterLocalNotificationsPlugin();
// flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
//     AndroidFlutterLocalNotificationsPlugin>().requestNotificationsPermission();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final Isar isar = await Isar.open(
    [VertretungSchema, StundeSchema, ColorPaletteSchema],
    directory: (await getApplicationSupportDirectory()).path,
  );

  SharedPreferences prefs = await SharedPreferences.getInstance();

  if (kDebugMode) {
    timeDilation = 1.0;
  }

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

          if (colorSchemeIndex > 1 && colorSchemeIndex <= widget.isar.colorPalettes.where().countSync() + 1) {
            ColorPalette palette = widget.isar.colorPalettes.where().findAllSync()[colorSchemeIndex - 2];
            lightColorScheme = palette.toColorScheme();
            darkColorScheme = palette.toColorScheme(true);
            vertretungsColors = palette.fromSeed ? null : palette.getExactColors();
          } else if (lightDynamic != null && darkDynamic != null && colorSchemeIndex == 1) {
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
              extensions: [if(vertretungsColors != null) vertretungsColors],
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: darkColorScheme,
              extensions: [if(vertretungsColors != null) vertretungsColors],
            ),
            themeMode: ThemeMode.values[darkMode],
            home: OuterPage(isar: widget.isar),
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
  OuterPage({super.key, required this.isar});

  final Isar isar;

  @override
  State<OuterPage> createState() => _OuterPageState();
}

class _OuterPageState extends State<OuterPage> {
  late SharedPreferences prefs;
  bool initialized = false;
  ValueNotifier<bool?> vertretungsLoadingNotifier = ValueNotifier(false);
  ValueNotifier<bool?> calendarLoadingNotifier = ValueNotifier(false);

  @override
  void initState() {
    SharedPreferences.getInstance().then((value) {
      prefs = value;
      initialized = true;
      setState(() {
        _selectedIndex = prefs.getInt("selectedPage") ?? 0;
      });
      Connectivity().checkConnectivity().then((value) {
        if(!(prefs.getBool("vertretungUpdateWifi") ?? true) || value == ConnectivityResult.wifi) {
          loadVertretungsplan();
        }
      });
      loadCalendarContent();
    });
    super.initState();
  }

  void loadVertretungsplan() async {
      vertretungsLoadingNotifier.value = true;
      try {
        String vertretungsplanWebsite = await getVertretungsplanWebsite();
        await parseVertretungsplan(vertretungsplanWebsite, widget.isar);
        vertretungsLoadingNotifier.value = false;
      }
      on Exception {
        vertretungsLoadingNotifier.value = null;
      }
  }

  void loadCalendarContent() async {
    bool shouldUpdateTermine = DateTime.fromMillisecondsSinceEpoch(prefs.getInt("lastTermineUpdate") ?? 0).isBefore(DateTime.now().subtract(durations.values.elementAt(prefs.getInt("termineUpdateDuration") ?? 8)));
    bool shouldUpdateStundenplan = DateTime.fromMillisecondsSinceEpoch(prefs.getInt("lastStundenplanUpdate") ?? 0).isBefore(DateTime.now().subtract(durations.values.elementAt(prefs.getInt("stundenplanUpdateDuration") ?? 8)));
    if(shouldUpdateTermine || shouldUpdateStundenplan){
      calendarLoadingNotifier.value = true;
      bool failed = false;
      if(shouldUpdateTermine && (!(prefs.getBool("termineUpdateWifi") ?? true) || await Connectivity().checkConnectivity() == ConnectivityResult.wifi)) {
        // print("Updating Termine");
        try{
          await updateTermine();
          prefs.setInt("lastTermineUpdate", DateTime.now().millisecondsSinceEpoch);
        }
        on Exception catch (e){
          if (kDebugMode) {
            print(e);
          }
          failed = true;
        }
      }
      if(shouldUpdateStundenplan && (!(prefs.getBool("stundenplanUpdateWifi") ?? true) || await Connectivity().checkConnectivity() == ConnectivityResult.wifi)) {
        // print("Updating Stundenplan");
        try{
          await updateStundenplan(widget.isar);
          prefs.setInt("lastStundenplanUpdate", DateTime.now().millisecondsSinceEpoch);
        }
        on Exception catch (e){
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
    if (!initialized) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          StundenplanPage(isar: widget.isar, vertretungsLoading: vertretungsLoadingNotifier, calendarLoading: calendarLoadingNotifier,),
          VertretungsplanPage(isar: widget.isar, loadingNotifier: vertretungsLoadingNotifier, refresh: loadVertretungsplan),
          SettingsPage(isar: widget.isar, refresh: (){
            Connectivity().checkConnectivity().then((value) {
              if(!(prefs.getBool("vertretungUpdateWifi") ?? true) || value == ConnectivityResult.wifi) {
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
            prefs.setInt("selectedPage", index);
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
            selectedIcon: Icon(Ionicons.settings),
            icon: Icon(Ionicons.settings_outline),
            label: "Einstellungen",
          ),
        ],
      ),
    );
  }
}
