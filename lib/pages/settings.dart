import 'dart:math';
import 'dart:io' show Platform;
import 'package:PiusApp/background.dart';
import 'package:PiusApp/course_selection.dart';
import 'package:PiusApp/login_fields.dart';
import 'package:PiusApp/main.dart';
import 'package:PiusApp/pages/stundenplan.dart';
import 'package:PiusApp/promotion.dart';
import 'package:PiusApp/promotion_dialog.dart';
import 'package:PiusApp/qr_import.dart';
import 'package:PiusApp/share_link.dart';
import 'package:app_settings/app_settings.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ionicons/ionicons.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import 'package:isar_community/isar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
  "4 Stunden": const Duration(hours: 4),
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
    securePrefs = getSecurePrefs();
    SharedPreferences.getInstance().then((value) {
      prefs = value;
      initialized = true;
      setState(() {});
    });
    super.initState();
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
                (
                  "Dein Login",
                  "Klicke hier um deinen Login zu ändern",
                  Ionicons.log_in,
                  "-",
                  SettingType.customTap,
                  () async {
                    await newLogin(context, securePrefs);
                    widget.refresh();
                  }
                ),
              ]
            ),
            if(Platform.isAndroid || Platform.isIOS)(
              "Hintergrundaktualisierung",
              [
                (
                  "Vertretungsplan",
                  "Aktualisiere den Vertretungsplan im Hintergrund",
                  Ionicons.refresh_outline,
                  "background",
                  SettingType.boolWithCallback,
                  (
                    true,
                    (value) {
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
                  (
                    durations.keys.toList(),
                    2,
                    () {
                      configureBackgroundFetch();
                    }
                  ),
                ),
                (
                  "Vertretungsplan Update Wifi Only",
                  "Aktualisiere Vertretungsplan nur bei WLAN Verbindung.",
                  Ionicons.wifi_outline,
                  "vertretungUpdateWifi",
                  SettingType.boolWithCallback,
                  (
                    false,
                    (value) {
                      configureBackgroundFetch();
                    }
                  )
                ),
              ]
            ),
            if ((Platform.isAndroid || Platform.isIOS) && (prefs.getBool("background") ?? true))
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
                        // pref is already persisted by the SwitchListTile handler
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
              "Stundenplan Aktualisierung",
              [
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
            (
              "Termine Aktualisierung",
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
              ]
            ),
            (
              "News Aktualisierung",
              [
                (
                  "News Update bei App Start",
                  "Aktualisiere News bei App Start",
                  Ionicons.refresh_circle_outline,
                  "newsUpdateStart",
                  SettingType.boolDefaultTrue,
                  null,
                ),
                if(prefs.getBool("newsUpdateStart") ?? true)(
                  "News Update Wifi Only",
                  "Aktualisiere News nur bei WLAN Verbindung automatisch.",
                  Ionicons.wifi_outline,
                  "newsUpdateWifi",
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
            // Die Defaults kommen bewusst aus den Konstanten in connection.dart
            // statt aus abgetippten Literalen: der Vertretungsplan-Default hier
            // war ".../vertretungsplan" statt ".../vertretungsplan/piusapp.php".
            // Wer den Dialog nur geöffnet und "Bestätigen" getippt hat, schrieb
            // damit die falsche URL fest - danach lieferte die Seite normales
            // HTML, parseVertretungsplan warf "No ticker found" und der
            // Vertretungsplan blieb dauerhaft leer.
            (
              "Website URLs",
              [
                (
                  "Stundenplan Website",
                  "Die URL der Stundenpläne",
                  Ionicons.globe_outline,
                  "website_url_stundenplan",
                  SettingType.string,
                  stundenplanUrl
                ),
                (
                  "Vertretungsplan Website",
                  "Die URL des Vertretungsplans",
                  Ionicons.globe_outline,
                  "website_url_vertretungsplan",
                  SettingType.string,
                  vertretungsplanUrl
                ),
                (
                  "Pius Termine Website",
                  "Die URL des ICS Kalenders der Pius Termine",
                  Ionicons.globe_outline,
                  "website_url_termine",
                  SettingType.string,
                  termineUrl
                ),
                (
                  "Pius News-Archiv Website",
                  "Die URL des Pius News-Archivs",
                  Ionicons.globe_outline,
                  "website_news_termine",
                  SettingType.string,
                  newsUrl
                ),
              ]
            ),
            // Debug builds only: the Klasse/Stufe-Wechsel can otherwise only
            // be exercised during the Sommerferien, and only in the few days
            // between the new Stundenplan going online and the school year
            // starting. See simulatePromotionForTesting.
            if (kDebugMode)
              (
                "Schuljahreswechsel (nur Debug)",
                [
                  (
                    "Wechsel-Popup jetzt testen",
                    "Markiert alle Stundenpläne als wechselbereit und öffnet das Popup - mit der echten Empfehlung aus dem aktuell veröffentlichten Stundenplan.",
                    Icons.school_outlined,
                    "-",
                    SettingType.customTap,
                    _testSchuljahreswechsel,
                  ),
                  (
                    "Test zurücksetzen",
                    "Entfernt den simulierten Wechsel-Hinweis wieder. Ein bereits durchgeführter Wechsel wird dadurch nicht rückgängig gemacht.",
                    Icons.restart_alt,
                    "-",
                    SettingType.customTap,
                    _resetSchuljahreswechsel,
                  ),
                ]
              ),
          ]
        ),
        (
          "Über",
          "Kontakt, Datenschutz",
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
                  "Entwickler: Jacob Peters\n\nPius-Logo: Benedikt Seidl\n\nSyncfusion libraries licensed under the Syncfusion Community License"
                ),
                (
                  "Datenschutz",
                  "Datenschutzerklärung",
                  Ionicons.shield_checkmark_outline,
                  "-",
                  SettingType.customTap,
                  () => openExternalUrl(Uri.parse("https://raw.githubusercontent.com/Equirinya/Pius-App-Rework/master/privacy_policy.md"))
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
          KonfigurationenSection(isar: widget.isar, refresh: widget.refresh),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 16),
          for (final (index, (title, subtitle, icon, sections)) in getSettings().indexed) ...[
            if (title == "Erweiterte Einstellungen") _feedbackCard(context),
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
                                                // Geklammert: ein gespeicherter Index ausserhalb der Liste
                                                // (z.B. nach einer verkürzten Auswahl in einem Update)
                                                // hat hier sonst bei jedem Build einen RangeError geworfen
                                                // und die betroffene Einstellungsseite unbenutzbar gemacht.
                                                int savedIndex = (prefs.getInt(setting) ?? fallbackIndex).clamp(0, options.length - 1);
                                                //(type == SettingType.selectionWithConfirm) ? (extra as (List<String>, VoidCallback)).$1 : extra);
                                                return ListTile(
                                                    title: Text(title),
                                                    subtitle: Text(options[savedIndex]),
                                                    leading: Icon(icon),
                                                    onTap: () => showDialog(
                                                        context: context,
                                                        builder: (context) {
                                                          int index = savedIndex;
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
            ),
          ],
        ],
      ),
    );
  }

  /// Debug-only: puts every Konfiguration into the "new Stundenplan is
  /// online" state and opens the Wechsel-Popup straight away, so the whole
  /// flow can be walked through outside the Sommerferien. Everything except
  /// the calendar gate is real - the Stufen list, the recommendation and the
  /// plan that gets saved all come from the currently published PDFs.
  Future<void> _testSchuljahreswechsel() async {
    ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    NavigatorState navigator = Navigator.of(context);
    messenger.showSnackBar(const SnackBar(content: Text("Prüfe die veröffentlichten Stundenpläne…")));
    try {
      // The picker must not be served plans cached from an earlier,
      // non-simulated run in this same session.
      invalidateStundenplanCache();
      String summary = await simulatePromotionForTesting(widget.isar);
      List<Konfiguration> ready = widget.isar.konfigurations
          .where()
          .findAllSync()
          .where((k) => k.promotionPlanReady && k.promotionCheckedForYear > k.promotedForYear)
          .toList();
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      if (ready.isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text("Keine Stundenpläne zum Wechseln vorhanden.")));
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(summary)));
      await navigator.push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => PromotionPopup(isar: widget.isar, konfigurationen: ready, onChanged: widget.refresh),
      ));
      if (mounted) setState(() {});
    } catch (e) {
      if (kDebugMode) print("[Promotion-Test] $e");
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text("Test fehlgeschlagen: $e")));
    }
  }

  Future<void> _resetSchuljahreswechsel() async {
    ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await resetPromotionsForTesting(widget.isar);
    invalidateStundenplanCache();
    if (!mounted) return;
    setState(() {});
    messenger.showSnackBar(const SnackBar(content: Text("Wechsel-Hinweis zurückgesetzt.")));
  }

  Widget _feedbackCard(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Ionicons.mail_outline, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text("Feedback", style: Theme.of(context).textTheme.titleLarge)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Fehler oder Feedback? Melde dich gerne! Mein Abi ist schon was her, daher nutze ich die App selbst nicht mehr und umso wichtiger ist eure Rückmeldung.",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _sendFeedbackEmail,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  icon: const Icon(Ionicons.mail_outline),
                  label: const Text("E-Mail schreiben"),
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _sendFeedbackEmail() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final bool launched = await openExternalUrl(Uri(
      scheme: "mailto",
      path: "equirinya@gmail.com",
      query: "subject=${Uri.encodeComponent("Anmerkung PiusApp Version ${packageInfo.version}")}",
    ));
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Konnte keine E-Mail-App öffnen. Schreib gerne an equirinya@gmail.com.")),
      );
    }
  }
}

/// Opens the system share sheet for [text].
///
/// [anchorContext] must belong to the widget that triggered the share (usually
/// the button). On iPad the sheet is presented as a popover anchored to that
/// widget's rect; without it share_plus throws a PlatformException and the
/// sheet never appears.
Future<void> shareText(BuildContext anchorContext, String text) async {
  final RenderBox? box = anchorContext.findRenderObject() as RenderBox?;
  try {
    await SharePlus.instance.share(ShareParams(
      text: text,
      sharePositionOrigin: box != null && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null,
    ));
  } catch (e) {
    if (kDebugMode) print("Could not share: $e");
    if (anchorContext.mounted) {
      ScaffoldMessenger.of(anchorContext).showSnackBar(
        const SnackBar(content: Text("Teilen hat nicht geklappt.")),
      );
    }
  }
}

/// `launchUrl` throws a PlatformException when the platform has no app for the
/// URL - on iOS that is the normal case for `mailto:` when no Mail account is
/// set up. Every call site used to leave that unhandled.
Future<bool> openExternalUrl(Uri uri) async {
  try {
    return await launchUrl(uri);
  } catch (e) {
    if (kDebugMode) print("Could not launch $uri: $e");
    return false;
  }
}

Future<void> newLogin(BuildContext context, FlutterSecureStorage securePrefs) {
  // Ausserhalb des builders, damit sie genau einmal existieren und am Ende
  // disposed werden können - im builder erzeugte Controller werden nie
  // freigegeben.
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  return showDialog(
      context: context,
      builder: (context) {
        int state = 0;
        String error = "";

        return StatefulBuilder(
          builder: (context, setState) {
            // Der Anmeldevorgang lag vorher komplett inline im onPressed des
            // Buttons. Als benannte Closure ist er auch von der Enter-Taste im
            // Passwortfeld aus erreichbar.
            Future<void> anmelden() async {
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
              // Erst nach geprüften Zugangsdaten darf der Passwortmanager das
              // Speichern anbieten.
              finishLoginAutofill();
              await Future.delayed(const Duration(seconds: 1));

              if (context.mounted) Navigator.of(context).pop();
            }

            return AlertDialog(
              icon: const Icon(Icons.account_circle),
              title: const Text("Neuer Login"),
              // Scrollbar, damit der Dialog bei aufgeklappter Tastatur auf
              // kleinen Displays nicht überläuft.
              content: SingleChildScrollView(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoginFields(
                    usernameController: usernameController,
                    passwordController: passwordController,
                    enabled: state == 0,
                    autofocus: true,
                    onSubmitted: anmelden,
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
              )),
              actions: [
                TextButton(
                    style: TextButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primaryContainer),
                    onPressed: state == 0 ? anmelden : null,
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
      }).whenComplete(() {
    usernameController.dispose();
    passwordController.dispose();
  });
}

/// Modern list of the user's saved Klasse/Kurse-Konfigurationen, shown at
/// the very top of the Settings page. Supports adding (manually or via
/// QR-Code), renaming, deleting and sharing (single or multi-select) a
/// profile's own QR code.
class KonfigurationenSection extends StatefulWidget {
  const KonfigurationenSection({super.key, required this.isar, required this.refresh});

  final Isar isar;
  final VoidCallback refresh;

  @override
  State<KonfigurationenSection> createState() => _KonfigurationenSectionState();
}

class _KonfigurationenSectionState extends State<KonfigurationenSection> {
  bool selectionMode = false;
  Set<int> selectedIds = {};

  @override
  void initState() {
    super.initState();
    // Imports started by a `piusapp://` link tapped outside the app happen on
    // a page pushed by main.dart, so this list has to be told about them.
    konfigurationenRevision.addListener(_onKonfigurationenChanged);
  }

  void _onKonfigurationenChanged() {
    if (!mounted) return;
    widget.refresh();
    setState(() {});
  }

  @override
  void dispose() {
    konfigurationenRevision.removeListener(_onKonfigurationenChanged);
    super.dispose();
  }

  List<Konfiguration> _konfigurationen() =>
      widget.isar.konfigurations.where().findAllSync()..sort((a, b) => a.position.compareTo(b.position));

  void _openCreate() async {
    Konfiguration? result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => CourseSelection(isar: widget.isar)));
    if (result != null) widget.refresh();
    setState(() {});
  }

  void _openScan() async {
    List<Konfiguration> imported = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => QrScanPage(isar: widget.isar))) ?? [];
    if (imported.isNotEmpty) widget.refresh();
    setState(() {});
  }

  void _openEdit(Konfiguration konfiguration) async {
    Konfiguration? result =
        await Navigator.of(context).push(MaterialPageRoute(builder: (context) => CourseSelection(isar: widget.isar, editing: konfiguration)));
    if (result != null) widget.refresh();
    setState(() {});
  }

  void _openPromotion(Konfiguration konfiguration) async {
    Konfiguration? result = await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => CourseSelection(
              isar: widget.isar,
              editing: konfiguration,
              recommendedStufe: konfiguration.promotionRecommendedStufe,
              recommendedIsOberstufe: konfiguration.promotionRecommendedIsOberstufe,
              // The Wechsel targets next year's plan, not the one still valid
              // today - see CourseSelection.useNewestPlan.
              useNewestPlan: true,
            )));
    if (result != null) {
      // Whatever Stufe they ended up on (recommended or manually picked),
      // this Sommerferien-cycle is handled - stop reminding about it.
      await _markPromotionHandled(result.id);
      widget.refresh();
    }
    setState(() {});
  }

  void _dismissPromotion(Konfiguration konfiguration) async {
    await _markPromotionHandled(konfiguration.id);
    setState(() {});
  }

  /// Re-reads the Konfiguration inside the transaction rather than writing
  /// back the instance this row was built from - by the time "Wechseln"
  /// returns, that instance's Stufe/Kurse/name are stale and putting it back
  /// wholesale would undo the switch that was just made.
  Future<void> _markPromotionHandled(int id) async {
    await widget.isar.writeTxn(() async {
      Konfiguration? aktuell = await widget.isar.konfigurations.get(id);
      if (aktuell == null) return;
      await widget.isar.konfigurations.put(aktuell..promotedForYear = aktuell.promotionCheckedForYear);
    });
  }

  Widget _promotionRow(BuildContext context, Konfiguration konfiguration) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    String? empfehlung = konfiguration.promotionRecommendedStufe;
    bool planReady = konfiguration.promotionPlanReady;

    String message;
    if (!planReady) {
      message = "${konfiguration.name}: Sommerferien! Sobald die Stundenpläne fürs neue Schuljahr online sind, kannst du hier wechseln.";
    } else if (empfehlung != null) {
      message = "${konfiguration.name}: neues Schuljahr! Wechsel vermutlich von ${konfiguration.stufe} zu $empfehlung.";
    } else {
      message = "${konfiguration.name}: die Stundenpläne fürs neue Schuljahr sind online. Wähle deine neue Klasse/Stufe.";
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: planReady ? colorScheme.primaryContainer : colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(planReady ? Icons.celebration : Icons.beach_access,
              color: planReady ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: planReady ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant)),
          ),
          if (planReady) ...[
            TextButton(onPressed: () => _dismissPromotion(konfiguration), child: const Text("Ignorieren")),
            const SizedBox(width: 4),
            FilledButton(onPressed: () => _openPromotion(konfiguration), child: const Text("Wechseln")),
          ],
        ],
      ),
    );
  }

  void _rename(Konfiguration konfiguration) async {
    TextEditingController controller = TextEditingController(text: konfiguration.name);
    String? name = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              icon: const Icon(Icons.sell_outlined),
              title: const Text("Umbenennen"),
              content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: "Name")),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Abbrechen")),
                TextButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text("Speichern")),
              ],
            ));
    if (name != null && name.trim().isNotEmpty) {
      await widget.isar.writeTxn(() async {
        await widget.isar.konfigurations.put(konfiguration..name = name.trim());
      });
      setState(() {});
    }
  }

  void _delete(List<Konfiguration> konfigurationen) async {
    bool? confirmed = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              title: Text(konfigurationen.length == 1 ? "\"${konfigurationen.first.name}\" löschen?" : "${konfigurationen.length} Stundenpläne löschen?"),
              content: Text(konfigurationen.length == 1 ? "Dieser Stundenplan wird endgültig entfernt." : "Diese Stundenpläne werden endgültig entfernt."),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Abbrechen")),
                TextButton(
                    style: TextButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.errorContainer),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text("Löschen", style: TextStyle(color: Theme.of(context).colorScheme.error))),
              ],
            ));
    if (confirmed == true) {
      for (Konfiguration k in konfigurationen) {
        await deleteKonfiguration(widget.isar, k.id);
      }
      widget.refresh();
      setState(() {
        selectionMode = false;
        selectedIds.clear();
      });
    }
  }

  void _share(List<Konfiguration> konfigurationen) async {
    if (konfigurationen.isEmpty) return;
    FlutterSecureStorage securePrefs = getSecurePrefs();
    String? username = await securePrefs.read(key: "username");
    String? password = await securePrefs.read(key: "password");
    bool includeLogin = false;

    if (!mounted) return;
    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, setStateDialog) {
                // An https share link (see share_link.dart) - the same string
                // works as a QR code and as a tappable link in any messenger,
                // and the payload is far shorter than the JSON it replaced,
                // so the QR code stays comfortably scannable even with many
                // Kursen.
                String payload = buildShareLink(
                  konfigurationen,
                  username: includeLogin ? username : null,
                  password: includeLogin ? password : null,
                );
                return AlertDialog(
                  icon: Icon(Icons.qr_code_rounded, color: Theme.of(context).colorScheme.primary, size: 32),
                  title:
                      Text(konfigurationen.length == 1 ? "\"${konfigurationen.first.name}\" teilen" : "${konfigurationen.length} Stundenpläne teilen"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: PrettyQrView(
                            qrImage: QrImage(QrCode.fromData(data: payload, errorCorrectLevel: QrErrorCorrectLevel.M)),
                            decoration: PrettyQrDecoration(shape: PrettyQrSmoothSymbol(color: Theme.of(context).colorScheme.primary)),
                          ),
                        ),
                        if (username != null && password != null) ...[
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Zugangsdaten mit teilen"),
                            subtitle: const Text("Das andere Gerät kann sich dann direkt mit deinem Pius-Login anmelden."),
                            value: includeLogin,
                            onChanged: (value) => setStateDialog(() => includeLogin = value),
                          ),
                        ],
                        if (includeLogin)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.onErrorContainer),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Achtung: Dieser QR-Code bzw. Link enthält dein Pius-Passwort. Wer ihn scannt, sieht oder öffnet, kann sich als du anmelden. Teile ihn nur mit Personen, denen du vertraust.",
                                    style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        // Builder so the button has its own BuildContext: on
                        // iPad the share sheet is a popover and needs an anchor
                        // rect. Without sharePositionOrigin share_plus throws a
                        // PlatformException there and nothing opens.
                        // `Share.share` is also deprecated since share_plus 11.
                        Builder(
                          builder: (buttonContext) => OutlinedButton.icon(
                            onPressed: () => shareText(buttonContext, payload),
                            icon: const Icon(Icons.link),
                            label: const Text("Als Link teilen"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Fertig"))],
                );
              },
            ));
  }

  @override
  Widget build(BuildContext context) {
    List<Konfiguration> konfigurationen = _konfigurationen();
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    List<Konfiguration> selected = konfigurationen.where((k) => selectedIds.contains(k.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              Icon(Icons.class_outlined, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text("Klasse/Kurse", style: Theme.of(context).textTheme.titleLarge),
              ),
              if (selectionMode) ...[
                IconButton(
                  tooltip: "Teilen",
                  onPressed: selected.isEmpty ? null : () => _share(selected),
                  icon: const Icon(Icons.share),
                ),
                IconButton(
                  tooltip: "Löschen",
                  onPressed: selected.isEmpty ? null : () => _delete(selected),
                  icon: Icon(Icons.delete_outline, color: selected.isEmpty ? null : colorScheme.error),
                ),
                IconButton(
                  tooltip: "Fertig",
                  onPressed: () => setState(() {
                    selectionMode = false;
                    selectedIds.clear();
                  }),
                  icon: const Icon(Icons.close),
                ),
              ] else if (konfigurationen.isNotEmpty) ...[
                IconButton(tooltip: "QR-Code scannen", onPressed: _openScan, icon: const Icon(Icons.qr_code_scanner)),
                IconButton(
                  tooltip: "QR-Code für alle Stundenpläne zeigen",
                  onPressed: () => _share(konfigurationen),
                  icon: const Icon(Icons.qr_code_rounded),
                ),
              ],
            ],
          ),
        ),
        for (final konfiguration in konfigurationen)
          if (konfiguration.promotionCheckedForYear > konfiguration.promotedForYear) _promotionRow(context, konfiguration),
        if (konfigurationen.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: _openCreate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    Icon(Icons.add_circle_outline, size: 32, color: colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      "Klasse oder Kurse hinzufügen",
                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Wähle deine Klasse oder deine Kurse, um deinen Stundenplan zu sehen.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 72,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final konfiguration in konfigurationen)
                  _KonfigurationCard(
                    konfiguration: konfiguration,
                    selectionMode: selectionMode,
                    selected: selectedIds.contains(konfiguration.id),
                    onTap: () {
                      if (selectionMode) {
                        setState(() {
                          if (!selectedIds.remove(konfiguration.id)) selectedIds.add(konfiguration.id);
                        });
                      } else {
                        showModalBottomSheet(
                            context: context,
                            builder: (context) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.edit_outlined),
                                        title: const Text("Bearbeiten"),
                                        subtitle: const Text("Klasse/Stufe oder Kurse ändern"),
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          _openEdit(konfiguration);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.sell_outlined),
                                        title: const Text("Umbenennen"),
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          _rename(konfiguration);
                                        },
                                      ),
                                      ListTile(
                                        leading: Icon(Icons.delete_outline, color: colorScheme.error),
                                        title: Text("Löschen", style: TextStyle(color: colorScheme.error)),
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          _delete([konfiguration]);
                                        },
                                      ),
                                    ],
                                  ),
                                ));
                      }
                    },
                    onLongPress: () => setState(() {
                      selectionMode = true;
                      selectedIds.add(konfiguration.id);
                    }),
                  ),
                if (!selectionMode)
                  GestureDetector(
                    onTap: _openCreate,
                    child: Container(
                      width: 84,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: colorScheme.surfaceVariant.withOpacity(0.5),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.add, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _KonfigurationCard extends StatelessWidget {
  const _KonfigurationCard({
    required this.konfiguration,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final Konfiguration konfiguration;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? colorScheme.primaryContainer : colorScheme.surfaceVariant.withOpacity(0.5),
          border: selected ? Border.all(color: colorScheme.primary, width: 2) : null,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(konfiguration.isOberstufe ? Icons.school_outlined : Icons.people_outline,
                        size: 14, color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        konfiguration.stufe,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  konfiguration.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: selected ? colorScheme.onPrimaryContainer : null,
                  ),
                ),
              ],
            ),
            if (selectionMode)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  size: 18,
                  color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
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
    // Einmal pro Dialog statt in jedem StatefulBuilder-Rebuild: der Controller
    // wurde vorher bei jedem setState (also bei jedem Tippen im Farbwähler)
    // neu gebaut, wodurch der Cursor im Namensfeld ans Ende sprang - und
    // disposed wurde er nie.
    TextEditingController nameController = TextEditingController(text: name);
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
                      controller: nameController,
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
    ).whenComplete(nameController.dispose);
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

        // Muss exakt dieselbe Bedingung sein wie in main.dart (dort:
        // `lightDynamic != null && darkDynamic != null`). Vorher hing nur das
        // helle Schema an der Prüfung: auf einem Gerät, das nur ein helles
        // Dynamic-Scheme liefert, zeigte diese Liste ein "System"-Feld, das
        // main.dart ignoriert - und alle Paletten dahinter waren um eins
        // verschoben, sodass Bearbeiten/Löschen die falsche Palette traf.
        bool dynamicSchemeExists = lightDynamic != null && darkDynamic != null;
        int paletteOffset = dynamicSchemeExists ? 2 : 1;

        List<(ColorScheme, String, bool)> colorSchemes = [
          (piusColorScheme, "Pius", false),
          if (dynamicSchemeExists) (lightDynamic.harmonized(), "System", false),
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
                            onLongPress: index >= paletteOffset
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
                                              .put((await widget.isar.colorPalettes.where().findAll())[index - paletteOffset]
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
                                              .delete((await widget.isar.colorPalettes.where().findAll())[index - paletteOffset].id);
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
