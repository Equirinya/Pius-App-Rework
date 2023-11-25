import 'dart:io';
import 'dart:math';
import 'package:PiusApp/connection.dart';
import 'package:PiusApp/database.dart';
import 'package:PiusApp/pages/settings.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _onBackgroundFetch(String taskId) async {

  final Isar isar = Isar.getInstance() ??
      await Isar.open(
        [VertretungSchema, StundeSchema, ColorPaletteSchema],
        directory: (await getApplicationSupportDirectory()).path,
      );

  SharedPreferences prefs = await SharedPreferences.getInstance();

  List<Vertretung> alteVertretungen = await isar.vertretungs.where().findAll();
  List<Vertretung> neueVertretungen = List.empty(growable: true);
  try {
    String vertretungsplanWebsite = await getVertretungsplanWebsite();
    neueVertretungen = await parseVertretungsplan(vertretungsplanWebsite, isar);
  } on Exception {
    if (kDebugMode) {
      print("Error while fetching Vertretungsplan");
    }
    return;
  }

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

  String? stufe = prefs.getString("stundenplanStufe");
  bool isOberstufe = prefs.getBool("stundenplanIsOberstufe") ?? false;

  if (stufe != null && stufe.isNotEmpty) {
    List<Stunde> stunden = await isar.stundes.where().findAll();
    Set<String> kurse = stunden.map((e) {
      List<String> split = e.name.split(" ");
      return isOberstufe ? "${split[0]} ${split[1]}" : split[0];
    }).toSet();
    neueVertretungen.retainWhere((element) => element.klasse == stufe && (!isOberstufe || kurse.contains(element.kurs)));
  }

  if (neueVertretungen.isNotEmpty) {
    for (Vertretung vertretung in neueVertretungen) {
      String tag = DateFormat('E dd.MM.', "de_DE").format(vertretung.tag);
      String stunden =
          vertretung.stunden.length > 1 ? "${vertretung.stunden.first + 1}. - ${vertretung.stunden.last + 1}." : "${vertretung.stunden.first + 1}.";
      String lehrkraft = vertretung.lehrkraft.isNotEmpty && vertretung.lehrkraft != "---" ? " ${vertretung.lehrkraft}" : "";
      String bemerkung = vertretung.bemerkung != null && vertretung.bemerkung!.trim().isNotEmpty ? " \n(${vertretung.bemerkung})" : "";
      String eva = vertretung.eva != null && vertretung.eva!.trim().isNotEmpty ? " \nEVA: ${vertretung.eva}" : "";
      String vertretungsText = "$tag $stunden Stunde: ${vertretung.art} ${vertretung.klasse} ${vertretung.kurs} $lehrkraft$bemerkung$eva";
      showNotification("Neue Vertretung", vertretungsText);
    }
  }

  BackgroundFetch.finish(taskId);
}

void showNotification(String title, String body) async {
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

  await flutterLocalNotificationsPlugin.show(random.nextInt((pow(2, 31) - 1).toInt()), title, body, notificationDetails);

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

  await flutterLocalNotificationsPlugin.show(0, "Neue Vertretungen", "Es gibt neue Vertretungen", notificationGroupDetails);
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

// Platform messages are asynchronous, so we initialize in an async method.
Future<void> configureBackgroundFetch() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // Configure BackgroundFetch.
  int status = await BackgroundFetch.configure(
    BackgroundFetchConfig(
        minimumFetchInterval: durations[prefs.getInt("vertretungUpdateDuration") ?? 2]?.inMinutes ?? 60,
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
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
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
    BackgroundFetch.finish(taskId);
    return;
  }
  _onBackgroundFetch(taskId);
}

void enableBackground(bool enable) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  //start stop
  if (enable) {
    configureBackgroundFetch();
    BackgroundFetch.start().then((int status) {
    }).catchError((e) {
      if (kDebugMode) {
        print('[BackgroundFetch] start FAILURE: $e');
      }
    });
    if (prefs.getBool("showNotifications") ?? true) {
      requestNotificationPermission();
    }
  } else {
    BackgroundFetch.stop().then((int status) {
      if (kDebugMode) {
        print('[BackgroundFetch] stop success: $status');
      }
    });
  }
}
