import 'dart:math';
import 'package:PiusApp/background.dart';
import 'package:app_settings/app_settings.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ionicons/ionicons.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

import 'package:isar/isar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../connection.dart';
import 'vertretungsplan.dart';

//TODO rework from enum to Objects
enum SettingType {
  bool, //default value false, extra is null
  boolDefaultTrue, //extra is null
  boolWithCallback, //extra is (defaultValue, callback(bool))
  selection, //extra is (List<String> options, fallbackIndex)
  selectionWithCallback, //extra is (List<String> options, fallbackIndex, callback)
  customTap, //extra is VoidCallback
  custom, //extra is custom Widget
  flutterAbout, //extra is License String
  text, //extra is null
  string //extra is fallback
}

Random random = Random();

Map<String, Duration> durations = {
  "15 Minuten": const Duration(minutes: 15),
  "30 Minuten": const Duration(minutes: 30),
  "1 Stunde": const Duration(hours: 1),
  "2 Stunden": const Duration(hours: 2),
  "4 Stunden": const Duration(hours: 2),
  "6 Stunden": const Duration(hours: 6),
  "12 Stunden": const Duration(hours: 12),
  "1 Tag": const Duration(days: 1),
  "2 Tage": const Duration(days: 2),
  "1 Woche": const Duration(days: 7),
};

const List<(int, int)> stundenZeiten = [
  (7, 55),
  (8, 40),
  (9, 45),
  (10, 35),
  (11, 25),
  (12, 40),
  (13, 25),
  (14, 30),
  (15, 15),
  (16, 00),
  (16, 45)
]; //TODO make editable

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key, required this.isar, required this.refresh}) : super(key: key);

  final Isar isar;
  final VoidCallback refresh;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SharedPreferences prefs;
  late FlutterSecureStorage securePrefs;
  bool initialized = false;

  @override
  void initState() {
    AndroidOptions getAndroidOptions() => const AndroidOptions(
          encryptedSharedPreferences: true,
        );
    securePrefs = FlutterSecureStorage(aOptions: getAndroidOptions());
    SharedPreferences.getInstance().then((value) {
      prefs = value;
      initialized = true;
      setState(() {});
    });
    super.initState();
  }

  void newLogin(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController usernameController = TextEditingController();
        TextEditingController passwordController = TextEditingController();

        int state = 0;
        String error = "";

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              icon: const Icon(Icons.account_circle),
              title: const Text("Neuer Login"),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
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
                        index: state,
                        alignment: Alignment.center,
                        children: [
                          Text(error),
                          const CupertinoActivityIndicator(),
                          Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              actions: [
                TextButton(
                    style: TextButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primaryContainer),
                    onPressed: state == 0
                        ? () async {
                            if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
                              setState(() {
                                state = 0;
                                error = "Bitte fülle alle Felder aus.";
                              });
                              return;
                            }

                            setState(() {
                              state = 1;
                            });
                            String lastUsername = await securePrefs.read(key: "username") ?? "";
                            String lastPassword = await securePrefs.read(key: "password") ?? "";
                            await securePrefs.write(key: "username", value: usernameController.text);
                            await securePrefs.write(key: "password", value: passwordController.text);

                            try {
                              await checkCredentials();
                            } on AuthorizationException catch (e) {
                              setState(() {
                                state = 0;
                                error = e.msg;
                              });
                              securePrefs.write(key: "username", value: lastUsername);
                              securePrefs.write(key: "password", value: lastPassword);
                              return;
                            } catch (e) {
                              setState(() {
                                state = 0;
                                error = "Unerwarteter Fehler: ${e.toString()}";
                              });
                              securePrefs.write(key: "username", value: lastUsername);
                              securePrefs.write(key: "password", value: lastPassword);
                              return;
                            }
                            setState(() {
                              state = 2;
                            });
                            await Future.delayed(const Duration(seconds: 1));
                            widget.refresh();

                            Navigator.of(context).pop();
                          }
                        : null,
                    child: const Text("Einloggen")),
                TextButton(
                    onPressed: state == 0
                        ? () {
                            Navigator.of(context).pop();
                          }
                        : null,
                    child: const Text("Abbrechen"))
              ],
            );
          },
        );
      },
    );
  }

  List<(String, String?, IconData, List<(String?, List<(String, String?, IconData, String, SettingType, dynamic)>)>)> getSettings() => [
        (
          "Verbindung und Aktualisierungen",
          "Login, Benachrichtigungen, Hintergrundaktualisierung",
          Ionicons.globe_outline,
          [
            (
              "Login", //TODO make new login settingstype
              [
                ("Dein Login", "Klicke hier um deinen Login zu ändern", Ionicons.log_in, "-", SettingType.customTap, () => newLogin(context)),
              ]
            ),
            (
              "Hintergrundaktualisierung",
              [
                (
                  "Vertretungsplan",
                  "Aktualisiere den Vertretungsplan im Hintergrund",
                  Ionicons.refresh_outline,
                  "background",
                  SettingType.boolWithCallback,
                  (true, (value) {
                      enableBackground(value);
                    }
                  )
                ),
                (
                  "Vertretungsplan Update Intervall",
                  "Der Vertretungsplan wird im Hintergrund nach diesem Intervall aktualisiert",
                  Ionicons.refresh_circle_outline,
                  "vertretungUpdateDuration",
                  SettingType.selectionWithCallback,
                  (durations.keys.toList(), 2, () {
                    configureBackgroundFetch();
                  }),
                ),
                (
                  "Vertretungsplan Update Wifi Only",
                  "Aktualisiere Vertretungsplan nur bei WLAN Verbindung.",
                  Ionicons.wifi_outline,
                  "vertretungUpdateWifi",
                SettingType.boolWithCallback,
                (false, (value) {
                  configureBackgroundFetch();
                }
                )
                ),
              ]
            ),
            if (prefs.getBool("background") ?? true)
              (
                "Benachrichtigungen",
                [
                  (
                    "Zeige Benachrichtigungen",
                    "Zeige Benachrichtigungen passend zu deinen Kursen",
                    Ionicons.notifications,
                    "showNotifications",
                    SettingType.boolWithCallback,
                    (
                      true,
                      (value) {
                        if (value) requestNotificationPermission();
                      }
                    )
                  ),
                  (
                    "Ändere Benachrichtigungseinstellungen",
                    "Ändere Ton, Vibration, etc.",
                    Ionicons.settings_outline,
                    "",
                    SettingType.customTap,
                    () => AppSettings.openAppSettings(type: AppSettingsType.notification),
                  )
                ]
              ),
            (
              "Stundenplan und Termine Aktualisierung",
              [
                (
                  "Pius-Termine Update Intervall",
                  "Die Pius Termine werden bei App Start aktualisiert wenn die letzte Aktualisierung länger als das Intervall her ist.",
                  Ionicons.refresh_circle_outline,
                  "termineUpdateDuration",
                  SettingType.selection,
                  (durations.keys.toList(), 8),
                ),
                (
                  "Termine Update Wifi Only",
                  "Aktualisiere Termine nur bei WLAN Verbindung.",
                  Ionicons.wifi_outline,
                  "termineUpdateWifi",
                  SettingType.boolDefaultTrue,
                  null,
                ),
                (
                  "Stundenplan Update Intervall",
                  "Der Stundenplan wird bei App Start aktualisiert wenn die letzte Aktualisierung länger als das Intervall her ist.",
                  Ionicons.refresh_circle_outline,
                  "stundenplanUpdateDuration",
                  SettingType.selection,
                  (durations.keys.toList(), 8),
                ),
                (
                  "Stundenplan Update Wifi Only",
                  "Aktualisiere Stundenplan nur bei WLAN Verbindung.",
                  Ionicons.wifi_outline,
                  "stundenplanUpdateWifi",
                  SettingType.boolDefaultTrue,
                  null,
                ),
              ]
            ),
          ]
        ),
        (
          "Anzeige",
          "Dunkles Farbschema, dynamische Farben, Abkürzungen",
          Ionicons.color_palette,
          [
            (
              "Farbauswahl",
              [
                (
                  "Aktuelle Farben",
                  "-",
                  Ionicons.color_palette,
                  "-",
                  SettingType.custom,
                  ColorPaletteSelectionTile(
                    isar: widget.isar,
                    prefs: prefs,
                  )
                ),
                (
                  "Dark Mode",
                  "System, Light oder Dark Mode?",
                  Ionicons.moon_outline,
                  "darkMode",
                  SettingType.selectionWithCallback,
                  (["System", "Light", "Dark"], 0, () => ColorChangedNotification().dispatch(context))
                ),
              ]
            ),
          ]
        ),
        (
          "Stundenplan",
          "Anpassungen der Stundenplan Ansicht",
          Ionicons.calendar_outline,
          [
            (
            "Klasse/Kurs",
            [
              (
              "Ändere Klasse/Kurs",
              "Ändere die Klasse/den Kurs des Stundenplans",
              Ionicons.calendar_outline,
              "",
              SettingType.customTap,
              () => print("TODO") //TODO
              ),
            ]
            ),
            (
              "Inhalt",
              [
                (
                  "Zeige Pius-Termine",
                  "Zeige die Termine des offiziellen Pius Kalendars im Stundenplan",
                  Ionicons.newspaper_outline,
                  "showTermine",
                  SettingType.boolDefaultTrue,
                  null
                ),
                (
                  "Zeige Feiertage",
                  "Zeige die offiziellen NRW Feiertage im Stundenplan",
                  Ionicons.briefcase_outline,
                  "showFeiertage",
                  SettingType.boolDefaultTrue,
                  null
                ),
              ]
            ),
            (
              "unterrichtsfreie Zeiten",
              [
                (
                  "Pius-Termine unterrichtsfrei",
                  "Lese unterrichtsfreie Tage und Stunden aus den Terminen des Pius Kalenders aus",
                  Ionicons.newspaper_outline,
                  "termineFrei",
                  SettingType.boolDefaultTrue,
                  null
                ),
                (
                  "Feiertage als unterrichtsfrei",
                  "Zeige keinen Unterricht an den offiziellen NRW Feiertagen",
                  Ionicons.briefcase_outline,
                  "feiertageFrei",
                  SettingType.boolDefaultTrue,
                  null
                ),
              ]
            ),
          ]
        ),
        (
          "Vertretungsplan",
          "Anpassungen der Vertretungsplan Ansicht",
          Ionicons.reorder_four,
          [
            (
              "Inhalt",
              [
                (
                  "Nutze Abkürzungen",
                  "Kürze die Überschriften innerhalb des Vertretungsplans ab",
                  Ionicons.sparkles_outline,
                  "abbreviations",
                  SettingType.boolDefaultTrue,
                  null
                ),
                (
                  "Sortiere Vertretungen nach Klasse",
                  "Wähle aus nach welchem System die Reihenfolge der Vertretungen auf dem Vertretungsplan entschieden wird.",
                  Ionicons.shuffle_outline,
                  "vertretungen_sort",
                  SettingType.selection,
                  (["betroffen-Feld der Website", "Reihenfolge der Website", "Alphabetisch"], 0)
                ),
              ]
            ),
          ]
        ),
        (
          "Erweiterte Einstellungen",
          "Diese Einstellungen sollten in den meisten Fällen nicht geändert werden müssen",
          Ionicons.code_working_outline,
          [
            (
              "Website URLs",
              [
                (
                  "Stundenplan Website",
                  "Die URL der Stundenpläne",
                  Ionicons.globe_outline,
                  "website_url_stundenplan",
                  SettingType.string,
                  "https://www.pius-gymnasium.de/stundenplaene"
                ),
                (
                  "Vertretungsplan Website",
                  "Die URL des Vertretungsplans",
                  Ionicons.globe_outline,
                  "website_url_vertretungsplan",
                  SettingType.string,
                  "https://www.pius-gymnasium.de/vertretungsplan"
                ),
                (
                  "Pius Termine Website",
                  "Die URL des ICS Kalenders der Pius Termine",
                  Ionicons.globe_outline,
                  "website_url_termine",
                  SettingType.string,
                  "https://www.pius-gymnasium.de/pius-kalender.ics"
                ),
              ]
            ),
          ]
        ),
        (
          "Über",
          "Kontakt, Impressum, Datenschutz",
          Ionicons.information_circle,
          [
            (
              "",
              [
                (
                  "Über",
                  "App Informationen und Lizenzen",
                  Ionicons.information_circle,
                  "ueber",
                  SettingType.flutterAbout,
                  "Entwickelt von: Jacob Peters\nPius-Logo: Benedikt Seidl"
                ),
              ]
            ),
          ]
        ),
      ];

  @override
  Widget build(BuildContext context) {
    if (!initialized) return const Center(child: CircularProgressIndicator());

    TextStyle? titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary);

    return Scaffold(
      appBar: AppBar(
        title: const Padding(padding: EdgeInsets.only(right: 32.0, top: 12), child: Text("Settings", overflow: TextOverflow.ellipsis)),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 128, top: 16),
        children: [
          for (final (index, (title, subtitle, icon, sections)) in getSettings().indexed)
            ListTile(
              leading: Icon(icon),
              title: Text(title, style: Theme.of(context).textTheme.titleLarge),
              subtitle: subtitle != null ? Text(subtitle) : null,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => StatefulBuilder(
                        builder: (context, setState) {
                          List<(String?, List<(String, String?, IconData, String, SettingType, dynamic)>)> sections = getSettings()[index].$4;
                          return Scaffold(
                            appBar: AppBar(
                              title: Text(title),
                            ),
                            body: ListView(
                              padding: const EdgeInsets.only(bottom: 128, top: 16),
                              children: [
                                for (final (title, settings) in sections)
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (title != null && title.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16),
                                          child: Text(
                                            title,
                                            style: titleStyle,
                                          ),
                                        ),
                                      for (final (title, subtitle, icon, setting, type, extra) in settings)
                                        Builder(
                                          builder: (context) {
                                            switch (type) {
                                              case SettingType.text:
                                                return ListTile(
                                                  title: Text(title),
                                                  subtitle: subtitle != null ? Text(subtitle) : null,
                                                  leading: Icon(icon),
                                                );
                                              case SettingType.string:
                                                return ListTile(
                                                    title: Text(title),
                                                    subtitle: Text(prefs.getString(setting) ?? extra),
                                                    leading: Icon(icon),
                                                    onTap: () => showDialog(
                                                        context: context,
                                                        builder: (context) {
                                                          TextEditingController controller = TextEditingController(text: prefs.getString(setting) ?? extra);
                                                          return StatefulBuilder(
                                                              builder: (context, setState) => AlertDialog(
                                                                    icon: Icon(icon),
                                                                    title: Text(title),
                                                                    content: TextField(
                                                                      controller: controller,
                                                                    ),
                                                                    actions: [
                                                                      TextButton(
                                                                          style: TextButton.styleFrom(
                                                                              backgroundColor: Theme.of(context).colorScheme.primaryContainer),
                                                                          onPressed: () {
                                                                            Navigator.of(context).pop();
                                                                            prefs.setString(setting, controller.text);
                                                                          },
                                                                          child: const Text("Bestätigen")),
                                                                      TextButton(
                                                                          onPressed: () {
                                                                            Navigator.of(context).pop();
                                                                          },
                                                                          child: const Text("Abbrechen"))
                                                                    ],
                                                                  ));
                                                        }).then((value) => setState(() {})));
                                              case SettingType.boolDefaultTrue:
                                              case SettingType.boolWithCallback:
                                              case SettingType.bool:
                                                bool fallback = type == SettingType.boolDefaultTrue || (type == SettingType.boolWithCallback && extra.$1);
                                                return SwitchListTile(
                                                  title: Text(title),
                                                  subtitle: subtitle != null ? Text(subtitle) : null,
                                                  secondary: Icon(icon),
                                                  value: prefs.getBool(setting) ?? fallback,
                                                  onChanged: (value) {
                                                    prefs.setBool(setting, value);
                                                    if (type == SettingType.boolWithCallback) extra.$2(value);
                                                    setState(() {});
                                                  },
                                                );
                                              case SettingType.selectionWithCallback:
                                              case SettingType.selection:
                                                List<String> options = List<String>.from(extra.$1);
                                                int fallbackIndex = extra.$2;
                                                //(type == SettingType.selectionWithConfirm) ? (extra as (List<String>, VoidCallback)).$1 : extra);
                                                return ListTile(
                                                    title: Text(title),
                                                    subtitle: Text(options[prefs.getInt(setting) ?? fallbackIndex]),
                                                    leading: Icon(icon),
                                                    onTap: () => showDialog(
                                                        context: context,
                                                        builder: (context) {
                                                          int index = prefs.getInt(setting) ?? fallbackIndex;
                                                          return StatefulBuilder(
                                                              builder: (context, setState) => AlertDialog(
                                                                    icon: Icon(icon),
                                                                    title: Text(title),
                                                                    content: SingleChildScrollView(
                                                                      child: Column(
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        children: [
                                                                          Text(subtitle ?? ""),
                                                                          const SizedBox(height: 16),
                                                                          for (final option in options)
                                                                            RadioListTile(
                                                                              title: Text(option),
                                                                              value: option,
                                                                              groupValue: options[index],
                                                                              onChanged: (value) {
                                                                                index = options.indexOf(value ?? options[0]);
                                                                                setState(() {});
                                                                              },
                                                                            )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    actions: [
                                                                      TextButton(
                                                                          style: TextButton.styleFrom(
                                                                              backgroundColor: Theme.of(context).colorScheme.primaryContainer),
                                                                          onPressed: () {
                                                                            Navigator.of(context).pop();
                                                                            prefs.setInt(setting, index);
                                                                            if (type == SettingType.selectionWithCallback) {
                                                                              extra.$3();
                                                                            }
                                                                          },
                                                                          child: const Text("Bestätigen")),
                                                                      TextButton(
                                                                          onPressed: () {
                                                                            Navigator.of(context).pop();
                                                                          },
                                                                          child: const Text("Abbrechen"))
                                                                    ],
                                                                  ));
                                                        }).then((value) => setState(() {})));
                                              case SettingType.customTap:
                                                return ListTile(
                                                  title: Text(title),
                                                  subtitle: subtitle != null ? Text(subtitle) : null,
                                                  leading: Icon(icon),
                                                  onTap: () => extra(),
                                                );
                                              case SettingType.custom:
                                                return extra;
                                              case SettingType.flutterAbout:
                                                return ListTile(
                                                  title: Text(title),
                                                  subtitle: subtitle != null ? Text(subtitle) : null,
                                                  leading: Icon(icon),
                                                  onTap: () async {
                                                    PackageInfo packageInfo = await PackageInfo.fromPlatform();
                                                    if (context.mounted) {
                                                      showAboutDialog(
                                                        context: context,
                                                        applicationIcon: Image.asset("assets/icon/icon_transparent.png", height: 64, width: 64),
                                                        applicationName: packageInfo.appName,
                                                        applicationVersion: packageInfo.version,
                                                        applicationLegalese: extra,
                                                      );
                                                    }
                                                  },
                                                );
                                            }
                                          },
                                        ),
                                      SizedBox(height: 32),
                                    ],
                                  )
                              ],
                            ),
                          );
                        },
                      ))),
            )
        ],
      ),
    );
  }
}

class ColorPaletteSelectionTile extends StatefulWidget {
  const ColorPaletteSelectionTile({super.key, required this.isar, required this.prefs});

  final Isar isar;
  final SharedPreferences prefs;

  @override
  State<ColorPaletteSelectionTile> createState() => _ColorPaletteSelectionTileState();
}

class _ColorPaletteSelectionTileState extends State<ColorPaletteSelectionTile> {
  void showEditColorDialog(
      bool fromSeed, String name, Color primary, Color secondary, Color tertiary, Color error, Function(bool, String, Color, Color, Color, Color) onConfirm,
      [VoidCallback? onDelete]) {
    int editingIndex = 0;
    List<Color> colors = fromSeed
        ? <ColorScheme>[
            ColorScheme.fromSeed(
              seedColor: primary,
            )
          ].map((e) => [primary, e.secondary, e.tertiary, e.error]).expand((element) => element).toList()
        : [primary, secondary, tertiary, error];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            ColorScheme colorScheme = fromSeed
                ? ColorScheme.fromSeed(
                    seedColor: primary,
                    brightness: Theme.of(context).colorScheme.brightness,
                  )
                : SeedColorScheme.fromSeeds(
                    primaryKey: colors[0],
                    secondaryKey: colors[1],
                    tertiaryKey: colors[2],
                    errorKey: colors[3],
                    brightness: Theme.of(context).colorScheme.brightness,
                  );
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: colorScheme,
              ),
              child: AlertDialog(
                title: const Text("Farben bearbeiten"),
                content: SingleChildScrollView(
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 128,
                      width: 128,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 128,
                              width: 128,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: GridView.count(
                                crossAxisCount: 2,
                                children: [
                                  for (final (index, color) in (fromSeed
                                          ? <ColorScheme>[
                                              ColorScheme.fromSeed(
                                                seedColor: colors[0],
                                              )
                                            ].map((e) => [e.primary, e.secondary, e.tertiary, e.error]).expand((element) => element).toList()
                                          : colors)
                                      .indexed)
                                    GestureDetector(
                                        onTap: () {
                                          editingIndex = index;
                                          setState(() {});
                                        },
                                        child: Container(color: color)),
                                ],
                              ),
                            ),
                          ),
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            alignment: [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight][editingIndex],
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              height: fromSeed ? 128 : 64,
                              width: fromSeed ? 128 : 64,
                              decoration: BoxDecoration(
                                borderRadius: fromSeed
                                    ? BorderRadius.circular(8)
                                    : BorderRadius.only(
                                        topLeft: editingIndex == 0 ? const Radius.circular(8) : const Radius.circular(0),
                                        topRight: editingIndex == 1 ? const Radius.circular(8) : const Radius.circular(0),
                                        bottomLeft: editingIndex == 2 ? const Radius.circular(8) : const Radius.circular(0),
                                        bottomRight: editingIndex == 3 ? const Radius.circular(8) : const Radius.circular(0),
                                      ),
                                border: Border.all(color: Theme.of(context).colorScheme.inverseSurface, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextField(
                      controller: TextEditingController(text: name),
                      decoration: const InputDecoration(
                        labelText: "Name",
                      ),
                      onChanged: (value) => name = value,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Text("Anhand einer einzelnen Farbe generieren")),
                        Switch(
                          value: fromSeed,
                          onChanged: (value) => setState(() {
                            fromSeed = value;
                            if (fromSeed) {
                              colors = <ColorScheme>[
                                ColorScheme.fromSeed(
                                  seedColor: colors[0],
                                )
                              ].map((e) => [colors[0], e.secondary, e.tertiary, e.error]).expand((element) => element).toList();
                            }
                          }),
                        ),
                      ],
                    ),
                    ColorPicker(
                      color: fromSeed ? colors[0] : colors[editingIndex],
                      onColorChanged: (value) {
                        setState(() {
                          if (fromSeed) {
                            colors[0] = value;
                            ColorScheme scheme = SeedColorScheme.fromSeeds(primaryKey: value);
                            colors = [colors[0], scheme.secondary, scheme.tertiary, scheme.error];
                          } else {
                            colors[editingIndex] = value;
                          }
                        });
                      },
                      pickersEnabled: const {
                        ColorPickerType.primary: true,
                        ColorPickerType.accent: false,
                      },
                      enableShadesSelection: !fromSeed,
                    )
                  ],
                )),
                actions: [
                  TextButton(
                      style: TextButton.styleFrom(backgroundColor: colorScheme.primaryContainer),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onConfirm(fromSeed, name, colors[0], colors[1], colors[2], colors[3]);
                      },
                      child: const Text("Bestätigen")),
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Abbrechen")),
                  if (onDelete != null)
                    TextButton(
                        style: TextButton.styleFrom(backgroundColor: colorScheme.errorContainer),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onDelete();
                        },
                        child: Text("Löschen", style: TextStyle(color: colorScheme.error))),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        Color primaryColor = const Color.fromARGB(255, 87, 162, 211);
        Color secondaryColor = const Color.fromARGB(255, 30, 111, 147);
        Color tertiaryColor = const Color.fromARGB(255, 255, 204, 0);
        Color errorColor = const Color.fromARGB(255, 255, 0, 0);
        ColorScheme piusColorScheme =
            ColorScheme.fromSeed(seedColor: primaryColor, primary: primaryColor, secondary: secondaryColor, tertiary: tertiaryColor, error: errorColor);

        List<(ColorScheme, String, bool)> colorSchemes = [
          (piusColorScheme, "Pius", false),
          if (lightDynamic != null) (lightDynamic.harmonized(), "System", false),
          ...widget.isar.colorPalettes
              .where()
              .findAllSync()
              .map((e) => (e.toColorScheme(), (e.name == null || e.name!.isEmpty) ? "Unbenannt" : e.name!, e.fromSeed)),
        ];

        int selectedColorScheme = widget.prefs.getInt("colorSchemeIndex") ?? (colorSchemes.length > 1 ? 1 : 0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: klassenVertretungsBlock(
                  [
                    Vertretung()
                      ..klasse = "ZZ"
                      ..stunden = [1, 2]
                      ..art = "EVA"
                      ..kurs = "Kurs"
                      ..raum = "A123"
                      ..lehrkraft = "Lehrkraft"
                      ..eva = "EVA"
                      ..hervorgehoben = [4],
                  ],
                  theme: Theme.of(context),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var (index, (ColorScheme colorScheme, String name, bool fromSeed)) in colorSchemes.indexed)
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              await widget.prefs.setInt("colorSchemeIndex", index);
                              if (context.mounted) ColorChangedNotification().dispatch(context);
                              setState(() {});
                            },
                            onLongPress: index >= (lightDynamic != null ? 2 : 1)
                                ? () async {
                                    showEditColorDialog(
                                      fromSeed,
                                      name,
                                      colorScheme.primary,
                                      colorScheme.secondary,
                                      colorScheme.tertiary,
                                      colorScheme.error,
                                      (fromSeed, name, primary, secondary, tertiary, error) async {
                                        await widget.isar.writeTxn(() async {
                                          await widget.isar.colorPalettes
                                              .put((await widget.isar.colorPalettes.where().findAll())[index - (lightDynamic != null ? 2 : 1)]
                                                ..fromSeed = fromSeed
                                                ..name = name
                                                ..primaryR = primary.red
                                                ..primaryG = primary.green
                                                ..primaryB = primary.blue
                                                ..secondaryR = secondary.red
                                                ..secondaryG = secondary.green
                                                ..secondaryB = secondary.blue
                                                ..tertiaryR = tertiary.red
                                                ..tertiaryG = tertiary.green
                                                ..tertiaryB = tertiary.blue
                                                ..errorR = error.red
                                                ..errorG = error.green
                                                ..errorB = error.blue);
                                        });
                                        await widget.prefs.setInt("colorSchemeIndex", index);
                                        if (context.mounted) ColorChangedNotification().dispatch(context);
                                        setState(() {});
                                      },
                                      () async {
                                        await widget.isar.writeTxn(() async {
                                          await widget.isar.colorPalettes
                                              .delete((await widget.isar.colorPalettes.where().findAll())[index - (lightDynamic != null ? 2 : 1)].id);
                                        });
                                        await widget.prefs.setInt("colorSchemeIndex", 0);
                                        if (context.mounted) ColorChangedNotification().dispatch(context);
                                        setState(() {});
                                      },
                                    );
                                  }
                                : null,
                            child: AnimatedContainer(
                                height: 64,
                                width: 64,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: colorScheme.primaryContainer,
                                ),
                                padding: EdgeInsets.all(selectedColorScheme == index ? 2 : 0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: GridView.count(
                                    crossAxisCount: 2,
                                    children: [
                                      Container(color: colorScheme.primary),
                                      Container(color: colorScheme.secondary),
                                      Container(color: colorScheme.tertiary),
                                      Container(color: colorScheme.error),
                                    ],
                                  ),
                                )),
                          ),
                          Text(name, style: TextStyle(color: index == selectedColorScheme ? Theme.of(context).colorScheme.primary : null)),
                        ],
                      ),
                    GestureDetector(
                      onTap: () async {
                        showEditColorDialog(
                          true,
                          "",
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                          Theme.of(context).colorScheme.tertiary,
                          Theme.of(context).colorScheme.error,
                          (fromSeed, name, primary, secondary, tertiary, error) async {
                            await widget.isar.writeTxn(() async {
                              await widget.isar.colorPalettes.put(ColorPalette()
                                ..fromSeed = fromSeed
                                ..name = name
                                ..primaryR = primary.red
                                ..primaryG = primary.green
                                ..primaryB = primary.blue
                                ..secondaryR = secondary.red
                                ..secondaryG = secondary.green
                                ..secondaryB = secondary.blue
                                ..tertiaryR = tertiary.red
                                ..tertiaryG = tertiary.green
                                ..tertiaryB = tertiary.blue
                                ..errorR = error.red
                                ..errorG = error.green
                                ..errorB = error.blue);
                            });
                            await widget.prefs.setInt("colorSchemeIndex", colorSchemes.length);
                            if (context.mounted) ColorChangedNotification().dispatch(context);
                            setState(() {});
                          },
                        );
                      },
                      child: Container(
                          height: 64,
                          width: 64,
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Theme.of(context).colorScheme.surfaceVariant,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Ionicons.add)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
