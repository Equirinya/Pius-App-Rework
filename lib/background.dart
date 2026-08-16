import 'dart:io';
import 'dart:math';
import 'dart:ui' show DartPluginRegistrant;
import 'package:PiusApp/connection.dart';
import 'package:PiusApp/database.dart';
import 'package:PiusApp/pages/settings.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-isolate guards. The headless engine is a fresh isolate, so these are
/// false there even if the main isolate already did the work.
bool _notificationsInitialized = false;
bool _dateFormattingInitialized = false;
bool _headlessTaskRegistered = false;

/// Initialises flutter_local_notifications for the *current* isolate.
///
/// Calling `show()` without a prior `initialize()` is unsupported and is the
/// classic reason notifications silently never appear from a headless task.
Future<void> initializeNotifications() async {
  if (_notificationsInitialized) return;
  if (!(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) return;

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_stat_icon_transparent');
  const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
    requestSoundPermission: false,
    requestBadgePermission: false,
    requestAlertPermission: false,
  );
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsDarwin, macOS: initializationSettingsDarwin);

  await FlutterLocalNotificationsPlugin().initialize(settings: initializationSettings);
  _notificationsInitialized = true;
}

/// `DateFormat(..., "de_DE")` throws a `LocaleDataException` unless the locale
/// data has been loaded. In the main isolate `GlobalMaterialLocalizations`
/// does this implicitly; in the headless isolate nothing does, so every
/// notification build used to blow up before it was ever shown.
Future<void> initializeGermanDateFormatting() async {
  if (_dateFormattingInitialized) return;
  await initializeDateFormatting('de_DE');
  _dateFormattingInitialized = true;
}

Future<void> _onBackgroundFetch(String taskId) async {
  try {
    // Plugins are not auto-registered in a headless isolate on all platforms.
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    await initializeGermanDateFormatting();
    await initializeNotifications();

    final Isar isar = Isar.getInstance() ??
        await Isar.open(
          isarSchemas,
          directory: (await getApplicationSupportDirectory()).path,
        );

    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Guards against the headless isolate winning the race against the main
    // isolate right after an app update - e.g. a background fetch firing
    // before the user has reopened the app once. Cheap no-op once migrated.
    await migrateLegacyStundenplanIfNeeded(isar, prefs);

    // Respect the user's settings: don't fetch at all if background updates
    // are off, and don't post notifications if the user disabled them.
    if (!(prefs.getBool("background") ?? true)) return;
    final bool showNotifications = prefs.getBool("showNotifications") ?? true;

    List<Vertretung> alteVertretungen = await isar.vertretungs.where().findAll();
    List<Vertretung> neueVertretungen = List.empty(growable: true);

    String vertretungsplanWebsite = await getVertretungsplanWebsite();
    neueVertretungen = await parseVertretungsplan(vertretungsplanWebsite, isar);

    await prefs.setInt("lastBackgroundFetch", DateTime.now().millisecondsSinceEpoch);
    // A fetch got all the way through - drop any error recorded by an earlier
    // run so a stale message can't outlive the problem.
    await prefs.remove("lastBackgroundFetchError");
    await prefs.remove("lastBackgroundFetchErrorTime");

    if (!showNotifications) return;

    neueVertretungen.removeWhere((neu) => alteVertretungen.any((alt) {
          return listEquals(alt.stunden, neu.stunden) &&
              alt.klasse == neu.klasse &&
              alt.eva == neu.eva &&
              alt.raum == neu.raum &&
              alt.kurs == neu.kurs &&
              alt.bemerkung == neu.bemerkung &&
              alt.lehrkraft == neu.lehrkraft &&
              alt.tag == neu.tag &&
              listEquals(alt.hervorgehoben, neu.hervorgehoben) &&
              alt.art == neu.art;
        }));

    List<Konfiguration> konfigurationen = await isar.konfigurations.where().findAll();

    if (konfigurationen.isNotEmpty) {
      // For each Konfiguration derive the short "Fach Kursart" codes (e.g. "M GK")
      // from its own stored Stunden, the same way the Stundenplan view does, and
      // keep a Vertretung if it's relevant to at least one saved Konfiguration.
      List<(String stufe, bool isOberstufe, Set<String> kurse)> relevant = [];
      for (Konfiguration konfiguration in konfigurationen) {
        List<Stunde> stunden = await isar.stundes.filter().konfigurationIdEqualTo(konfiguration.id).findAll();
        // See kursKuerzel() in database.dart - derived from each line's own
        // token count rather than guessed from isOberstufe, so Sek-I-
        // Differenzierungsgruppen (e.g. "F7 2" vs "F7 3") aren't wrongly
        // merged into a single "F7" and matched against every group's Vertretung.
        Set<String> kurse = stunden.map((e) => kursKuerzel(e.name)).toSet();
        relevant.add((konfiguration.stufe, konfiguration.isOberstufe, kurse));
      }
      neueVertretungen.retainWhere((vertretung) => relevant.any((k) => vertretung.klasse == k.$1 && (!k.$2 || k.$3.contains(vertretung.kurs))));
    }

    // Must be awaited: `BackgroundFetch.finish` below lets the OS tear the
    // process down, which would cancel any still-pending notification posts.
    for (Vertretung vertretung in neueVertretungen) {
      String tag = DateFormat('E dd.MM.', "de_DE").format(vertretung.tag);
      String stunden =
          vertretung.stunden.length > 1 ? "${vertretung.stunden.first + 1}. - ${vertretung.stunden.last + 1}." : "${vertretung.stunden.first + 1}.";
      String lehrkraft = vertretung.lehrkraft.isNotEmpty && vertretung.lehrkraft != "---" ? " ${vertretung.lehrkraft}" : "";
      String bemerkung = vertretung.bemerkung != null && vertretung.bemerkung!.trim().isNotEmpty ? " \n(${vertretung.bemerkung})" : "";
      String eva = vertretung.eva != null && vertretung.eva!.trim().isNotEmpty ? " \nEVA: ${vertretung.eva}" : "";
      String vertretungsText = "$tag $stunden Stunde: ${vertretung.art} ${vertretung.klasse} ${vertretung.kurs} $lehrkraft$bemerkung$eva";
      await showNotification("Neue Vertretung", vertretungsText);
    }
  } catch (e, s) {
    // Catch *everything* (not just Exception). An escaping error used to skip
    // `finish()` entirely, which the OS treats as a timeout and punishes by
    // demoting the app's scheduling priority for all future fetches.
    if (kDebugMode) {
      print("[BackgroundFetch] error during fetch: $e");
      print(s);
    }
    // Persist the failure so it is diagnosable in release builds. Without this
    // the typical iOS case - the fetch runs while the device is locked, the
    // Keychain read returns null and getSecuredPage throws "No username or
    // password found" - leaves no trace whatsoever, and the user just reports
    // "keine Benachrichtigungen".
    try {
      final SharedPreferences errorPrefs = await SharedPreferences.getInstance();
      await errorPrefs.setString("lastBackgroundFetchError", e.toString());
      await errorPrefs.setInt("lastBackgroundFetchErrorTime", DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // Prefs unavailable in this isolate - nothing sensible left to do.
    }
  } finally {
    await BackgroundFetch.finish(taskId);
  }
}

Future<void> showNotification(String title, String body) async {
  await initializeNotifications();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
    'new',
    'Neue Vertretungen',
    channelDescription: 'Neue Vertretungen seit dem letzten Update',
    importance: Importance.high,
    priority: Priority.high,
    groupKey: "new",
    // setAsGroupSummary: true,
  );
  const DarwinNotificationDetails darwinPlatformChannelSpecifics = DarwinNotificationDetails(threadIdentifier: 'new');

  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidNotificationDetails, iOS: darwinPlatformChannelSpecifics, macOS: darwinPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    id: random.nextInt((pow(2, 31) - 1).toInt()),
    title: title,
    body: body,
    notificationDetails: notificationDetails,
  );

  const AndroidNotificationDetails androidNotificationGroupDetails = AndroidNotificationDetails(
    'new',
    'Neue Vertretungen',
    channelDescription: 'Neue Vertretungen seit dem letzten Update',
    importance: Importance.high,
    priority: Priority.high,
    groupKey: "new",
    setAsGroupSummary: true,
  );

  const NotificationDetails notificationGroupDetails =
  NotificationDetails(android: androidNotificationGroupDetails, iOS: darwinPlatformChannelSpecifics, macOS: darwinPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    id: 0,
    title: "Neue Vertretungen",
    body: "Es gibt neue Vertretungen",
    notificationDetails: notificationGroupDetails,
  );
}

/// Set once the silent catch-up request below has run, so opening the settings
/// repeatedly doesn't hit the platform channel again.
bool _notificationPermissionChecked = false;

/// Silently makes sure the notification permission was asked for at least once,
/// for users whose settings say notifications are on but who never saw a
/// prompt - anyone who arrived here through an app update, since
/// `showNotifications` defaults to true and only the onboarding page and the
/// settings switch ever trigger a request.
///
/// Call this when the user opens the screen that *shows* the notification
/// settings, never on app start: the prompt needs the surrounding context to
/// make sense. Safe to call when permission was already granted or denied -
/// both platforms then answer from the stored decision without showing a
/// second prompt.
Future<void> ensureNotificationPermissionAsked() async {
  if (_notificationPermissionChecked) return;
  if (!(Platform.isAndroid || Platform.isIOS)) return;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (!(prefs.getBool("background") ?? true)) return;
  if (!(prefs.getBool("showNotifications") ?? true)) return;

  _notificationPermissionChecked = true;
  await requestNotificationPermission();
}

Future<bool> requestNotificationPermission() async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool? result;
  if (Platform.isAndroid) {
    result =
        await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  } else if (Platform.isIOS) {
    result = await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  } else if (Platform.isMacOS) {
    result = await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }
  return result ?? false;
}

/// Registers the Android headless entry-point. Must happen exactly once, as
/// early as possible — not on every settings change.
void registerBackgroundHeadlessTask() {
  if (_headlessTaskRegistered || !Platform.isAndroid) return;
  _headlessTaskRegistered = true;
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

// Platform messages are asynchronous, so we initialize in an async method.
Future<void> configureBackgroundFetch() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Nothing to schedule if the user turned background updates off.
  if (!(prefs.getBool("background") ?? true)) {
    await BackgroundFetch.stop();
    return;
  }

  // `durations` is keyed by String, so the old `durations[someInt]` lookup
  // always returned null and the interval was silently pinned to 60 minutes
  // no matter what the user picked. Index into the values instead.
  int durationIndex = prefs.getInt("vertretungUpdateDuration") ?? 2;
  if (durationIndex < 0 || durationIndex >= durations.length) durationIndex = 2;
  // Android/iOS both floor the period at 15 minutes.
  int intervalMinutes = max(15, durations.values.elementAt(durationIndex).inMinutes);

  // Configure BackgroundFetch. Calling this again cancels the existing task
  // and reschedules it with the new config.
  int status = await BackgroundFetch.configure(
    BackgroundFetchConfig(
        minimumFetchInterval: intervalMinutes,
        stopOnTerminate: false,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        startOnBoot: true,
        requiredNetworkType: (prefs.getBool("vertretungUpdateWifi") ?? false) ? NetworkType.UNMETERED : NetworkType.ANY),
    _onBackgroundFetch,
    _onBackgroundFetchTimeout,
  );
  if (kDebugMode) {
    print('[BackgroundFetch] configure status: $status');
  }
}

/// This event fires shortly before your task is about to timeout.  You must finish any outstanding work and call BackgroundFetch.finish(taskId).
void _onBackgroundFetchTimeout(String taskId) {
  if (kDebugMode) {
    print("[BackgroundFetch] TIMEOUT: $taskId");
  }
  BackgroundFetch.finish(taskId);
}

// [Android-only] This "Headless Task" is run when the Android app is terminated with `enableHeadless: true`
// Be sure to annotate your callback function to avoid issues in release mode on Flutter >= 3.3.0
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    // This task has exceeded its allowed running-time.
    // You must stop what you're doing and immediately .finish(taskId)
    if (kDebugMode) {
      print("[BackgroundFetch] Headless task timed-out: $taskId");
    }
    await BackgroundFetch.finish(taskId);
    return;
  }
  await _onBackgroundFetch(taskId);
}

Future<void> enableBackground(bool enable) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // The callers write the pref, but ordering isn't guaranteed — make sure
  // configureBackgroundFetch() below sees the intended value.
  await prefs.setBool("background", enable);

  if (enable) {
    await configureBackgroundFetch();
    try {
      await BackgroundFetch.start();
    } catch (e) {
      if (kDebugMode) {
        print('[BackgroundFetch] start FAILURE: $e');
      }
    }
    if (prefs.getBool("showNotifications") ?? true) {
      await requestNotificationPermission();
    }
  } else {
    try {
      int status = await BackgroundFetch.stop();
      if (kDebugMode) {
        print('[BackgroundFetch] stop success: $status');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[BackgroundFetch] stop FAILURE: $e');
      }
    }
  }
}
