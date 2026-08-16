import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:PiusApp/pages/settings.dart';
import 'package:PiusApp/pages/stundenplan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:html/parser.dart';
import 'package:html/dom.dart' as DOM;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

const String baseUrl = "https://www.pius-gymnasium.de";
const String stundenplanUrl = baseUrl + "/stundenplaene";
const String vertretungsplanUrl = baseUrl + "/vertretungsplan/piusapp.php";
const String termineUrl = baseUrl + "/pius-kalender.ics";
const String newsUrl = baseUrl + "/wp-json/wp/v2/posts";
const String feiertagUrl = "https://get.api-feiertage.de/?states=nw";

class ColorChangedNotification extends Notification {}

/// Repariert eine Vertretungsplan-URL, die durch den falschen Default in den
/// "Erweiterten Einstellungen" festgeschrieben wurde.
///
/// Dort stand als Vorgabe ".../vertretungsplan" statt ".../vertretungsplan/
/// piusapp.php". Der Dialog schreibt beim Bestätigen immer, also reichte
/// einmal Öffnen + "Bestätigen", um die kaputte URL dauerhaft zu speichern -
/// danach kam nur noch normales HTML zurück und der Vertretungsplan blieb
/// leer, ohne Weg zurück in der UI. Betrifft nur genau diesen einen Wert;
/// eine bewusst selbst gesetzte andere URL bleibt unangetastet.
Future<void> repairVertretungsplanUrlIfNeeded(SharedPreferences prefs) async {
  const String kaputterDefault = baseUrl + "/vertretungsplan";
  if (prefs.getString("website_url_vertretungsplan") == kaputterDefault) {
    await prefs.remove("website_url_vertretungsplan");
  }
}

Future<List<Appointment>> getPiusTermine() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  http.Response response = await http.get(Uri.parse(prefs.getString("website_url_termine") ?? termineUrl));

  if (response.statusCode != 200) throw Exception("Unexpected response code ${response.statusCode}");
  final iCalendar = ICalendar.fromString(response.body);
  List<Appointment> termine = iCalendar.data
      .map((e) {
        if (e["type"] != "VEVENT") return null;
        DateTime startTime = DateTime.parse((e["dtstart"] as IcsDateTime).dt);
        DateTime endTime = DateTime.parse((e["dtend"] as IcsDateTime).dt);
        bool isAllDay = (startTime.hour == 0 && startTime.minute == 0 && endTime.hour == 0 && endTime.minute == 0);
        String subject = e["summary"];
        return Appointment(
          startTime: startTime,
          endTime: isAllDay ? endTime.subtract(const Duration(seconds: 1)) : endTime,
          subject: utf8.decode(subject.codeUnits),
          isAllDay: isAllDay,
        );
      })
      .nonNulls
      .toList();
  return termine;
}

Future<List<Appointment>> getFeiertagTermine() async {
  http.Response response = await http.get(Uri.parse(feiertagUrl));

  if (response.statusCode != 200) throw Exception("Unexpected response code ${response.statusCode}");
  List<Appointment> termine = List<Appointment>.from(jsonDecode(response.body)["feiertage"].map((e) {
    DateTime startTime = DateTime.parse(e["date"]);
    DateTime endTime = startTime.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
    return Appointment(
      startTime: startTime,
      endTime: endTime,
      subject: e["fname"],
      isAllDay: true,
    );
  }));
  return termine;
}

Future<void> updateTermine() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<Appointment> termine = await getPiusTermine();
  List<Appointment> feiertagTermine = await getFeiertagTermine();
  String termineString = jsonEncode(termine.map((e) => appointmentToMap(e)).toList());
  String feiertagTermineString = jsonEncode(feiertagTermine.map((e) => appointmentToMap(e)).toList());
  prefs.setString("piusTermine", termineString);
  prefs.setString("feiertagTermine", feiertagTermineString);
  return;
}

Map<String, dynamic> appointmentToMap(Appointment appointment) => {
      "start": appointment.startTime.millisecondsSinceEpoch,
      "end": appointment.endTime.millisecondsSinceEpoch,
      "subject": appointment.subject,
      "isAllDay": appointment.isAllDay
    };

Appointment appointmentFromMap(Map<String, dynamic> map) => Appointment(
    startTime: DateTime.fromMillisecondsSinceEpoch(map["start"]),
    endTime: DateTime.fromMillisecondsSinceEpoch(map["end"]),
    subject: map["subject"],
    isAllDay: map["isAllDay"]);

Future<(PdfDocument klassenplan, PdfDocument oberstufenplan)> getCurrentStundenplaene() async {
  DOM.Document document = parse(await getStundenplanWebsite());

  List<(DateTime starting, DateTime updated, bool oberstufe, String url)> stundenplaene = await getStundenplanLinks(document);

  if (stundenplaene.length < 2) throw Exception("less than 2 stundenplaene found");

  try {
    List<(DateTime starting, DateTime updated, bool oberstufe, String url)> klassenplaene =
        (stundenplaene.where((element) => !element.$3).toList()..sort((a, b) => -a.$1.compareTo(b.$1)));
    if (klassenplaene.isEmpty) throw Exception("Keinen Klassenplan gefunden");
    String klassenplan;
    if (klassenplaene.length == 1)
      klassenplan = klassenplaene.first.$4;
    else
      // Absteigend nach "gültig ab" sortiert, also ist der erste Treffer der
      // aktuell gültige Plan. Sind ausnahmsweise *alle* Pläne erst in der
      // Zukunft gültig (kommt kurz vor Schuljahresbeginn vor, wenn der alte
      // Plan schon von der Seite genommen wurde), gibt es keinen Treffer -
      // dann den zuerst in Kraft tretenden nehmen statt mit StateError
      // abzustürzen.
      klassenplan = klassenplaene.firstWhere((element) => element.$1.isBefore(DateTime.now()), orElse: () => klassenplaene.last).$4;

    List<(DateTime starting, DateTime updated, bool oberstufe, String url)> oberstufenplaene =
        (stundenplaene.where((element) => element.$3).toList()..sort((a, b) => -a.$1.compareTo(b.$1)));
    if (oberstufenplaene.isEmpty) throw Exception("Keinen Oberstufenplan gefunden");
    String oberstufenplan;
    if (oberstufenplaene.length == 1)
      oberstufenplan = oberstufenplaene.first.$4;
    else
      // Siehe Klassenplan oben.
      oberstufenplan = oberstufenplaene.firstWhere((element) => element.$1.isBefore(DateTime.now()), orElse: () => oberstufenplaene.last).$4;

    return (PdfDocument(inputBytes: (await getSecuredPage(klassenplan)).bodyBytes), PdfDocument(inputBytes: (await getSecuredPage(oberstufenplan)).bodyBytes));
  } catch (e, s) {
    debugPrintStack(stackTrace: s);
    throw Exception("Fehler beim Laden der Klassen und Oberstufenpläne: $e");
  }
}

/// Downloads and writes the full Stunden list for [konfiguration] using an
/// already-fetched [plan] PDF (shared between all Konfigurationen of the
/// same Klassen-/Oberstufenplan so it's only ever downloaded once).
Future<void> populateKonfiguration(Isar isar, Konfiguration konfiguration, PdfDocument? plan) async {
  List<Stunde> stunden = await compute(getStundenPlan, (konfiguration.stufe, plan, konfiguration.isOberstufe));
  if (konfiguration.isOberstufe && konfiguration.kurse.isNotEmpty) {
    stunden.retainWhere((element) => konfiguration.kurse.contains(element.name));
  }
  for (Stunde stunde in stunden) {
    stunde.konfigurationId = konfiguration.id;
  }
  await isar.writeTxn(() async {
    await isar.stundes.filter().konfigurationIdEqualTo(konfiguration.id).deleteAll();
    await isar.stundes.putAll(stunden);
  });
}

/// Persists a (new or edited) [konfiguration] and immediately (re-)populates
/// its Stunden from [plan]. Returns the Konfiguration with its assigned id.
Future<Konfiguration> saveKonfiguration(Isar isar, Konfiguration konfiguration, PdfDocument? plan) async {
  await isar.writeTxn(() async {
    await isar.konfigurations.put(konfiguration);
  });
  await populateKonfiguration(isar, konfiguration, plan);
  return konfiguration;
}

/// Persists a (new or edited) [konfiguration] using a [stunden] list that has
/// already been parsed (e.g. by the Kurse-Auswahl step), instead of
/// re-parsing the Stundenplan PDF again. Callers that already have the
/// matching Stunden in hand should always prefer this over [saveKonfiguration]
/// - re-running the PDF parse a second time is the main reason saving used
/// to feel slow (or occasionally hang).
Future<Konfiguration> saveKonfigurationWithStunden(Isar isar, Konfiguration konfiguration, List<Stunde> stunden) async {
  for (Stunde stunde in stunden) {
    stunde.id = Isar.autoIncrement;
  }
  await isar.writeTxn(() async {
    await isar.konfigurations.put(konfiguration);
    for (Stunde stunde in stunden) {
      stunde.konfigurationId = konfiguration.id;
    }
    await isar.stundes.filter().konfigurationIdEqualTo(konfiguration.id).deleteAll();
    await isar.stundes.putAll(stunden);
  });
  return konfiguration;
}

Future<void> deleteKonfiguration(Isar isar, int id) async {
  await isar.writeTxn(() async {
    await isar.stundes.filter().konfigurationIdEqualTo(id).deleteAll();
    await isar.konfigurations.delete(id);
  });
}

/// Incrementally updates a single Konfiguration's Stunden, carrying over the
/// "gültig ab"/"gültig bis" stitching so past and future Stundenplan
/// versions keep showing correctly. Mirrors the old single-profile
/// updateStundenplan(), just scoped to one Konfiguration at a time.
Future<void> updateKonfiguration(Isar isar, Konfiguration konfiguration) async {
  String stufe = konfiguration.stufe;
  bool isOberstufe = konfiguration.isOberstufe;

  List<Stunde> existingStunden = isar.stundes.filter().konfigurationIdEqualTo(konfiguration.id).findAllSync();
  if (existingStunden.isEmpty) {
    var (klassenplan, oberstufenplan) = await getCurrentStundenplaene();
    await populateKonfiguration(isar, konfiguration, isOberstufe ? oberstufenplan : klassenplan);
    return;
  }

  DOM.Document document = parse(await getStundenplanWebsite());

  List<(DateTime starting, DateTime updated, bool oberstufe, String url)> stundenplaene = await getStundenplanLinks(document);
  stundenplaene = stundenplaene.where((element) => element.$3 == isOberstufe).toList();
  if (stundenplaene.isEmpty) throw Exception("No stundenplan found");
  stundenplaene.sort((a, b) => -a.$1.compareTo(b.$1));

  int lastUpdate = konfiguration.lastUpdateMillis;

  List<DateTime> existingGueltigAb = existingStunden.map((e) => e.gueltigAb).toSet().toList();
  DateTime newestExisting = existingGueltigAb.reduce((value, element) => value.isBefore(element) ? element : value);
  List<DateTime> neueGueltigAb = stundenplaene.map((e) => e.$1).toList();

  List<DateTime> toDelete = existingGueltigAb.where((element) => !neueGueltigAb.contains(element)).toList();
  List<(DateTime starting, DateTime updated, bool oberstufe, String url)> toAdd = stundenplaene
      .where((element) => !existingGueltigAb.contains(element.$1) && (element.$1.millisecondsSinceEpoch >= newestExisting.millisecondsSinceEpoch))
      .toList();

  List<(DateTime starting, DateTime updated, bool oberstufe, String url)> stayedSame =
      stundenplaene.where((element) => existingGueltigAb.contains(element.$1)).toList();
  stayedSame.retainWhere((element) => element.$2.millisecondsSinceEpoch > lastUpdate);
  if (stayedSame.isNotEmpty) {
    //wenn ein Stundenplan gleiches "gültig ab" aber anderes "stand ab" hat, dann werden dieser und alle neueren neu eingefügt
    DateTime newestStayedSame = stayedSame.map((e) => e.$1).reduce((value, element) => value.isBefore(element) ? element : value);
    stayedSame = stundenplaene
        .where((element) => existingGueltigAb.contains(element.$1) && element.$1.millisecondsSinceEpoch >= newestStayedSame.millisecondsSinceEpoch)
        .toList();
  }

  toDelete.addAll(stayedSame.map((e) => e.$1));
  toAdd.addAll(stayedSame);

  toAdd.sort((a, b) => a.$1.compareTo(b.$1));

  for (DateTime gueltigAb in toDelete) {
    await isar.writeTxn(() async {
      await isar.stundes.filter().konfigurationIdEqualTo(konfiguration.id).gueltigAbEqualTo(gueltigAb).deleteAll();
    });
  }
  existingGueltigAb = isar.stundes.filter().konfigurationIdEqualTo(konfiguration.id).findAllSync().map((e) => e.gueltigAb).toSet().toList();
  for (var (DateTime gueltigAb, DateTime updated, bool oberstufe, String url) in toAdd) {
    if (existingGueltigAb.isNotEmpty) {
      List<Stunde> toUpdateStunden = isar.stundes
          .filter()
          .konfigurationIdEqualTo(konfiguration.id)
          .gueltigAbEqualTo(existingGueltigAb.reduce((value, element) => value.isBefore(element) ? element : value))
          .findAllSync();

      await isar.writeTxn(() async {
        await isar.stundes.putAll(toUpdateStunden.map((e) => e..gueltigBis = gueltigAb).toList());
      });
      existingGueltigAb = isar.stundes.filter().konfigurationIdEqualTo(konfiguration.id).findAllSync().map((e) => e.gueltigAb).toSet().toList();
    }

    List<Stunde> stunden = await compute(getStundenPlan, (stufe, PdfDocument(inputBytes: (await getSecuredPage(url)).bodyBytes), isOberstufe));

    if (isOberstufe && konfiguration.kurse.isNotEmpty) stunden.retainWhere((element) => konfiguration.kurse.contains(element.name));
    for (Stunde stunde in stunden) {
      stunde.konfigurationId = konfiguration.id;
    }
    await isar.writeTxn(() async {
      await isar.stundes.putAll(stunden);
    });
  }

  konfiguration.lastUpdateMillis = stundenplaene.map((e) => e.$2.millisecondsSinceEpoch).reduce(max);
  await isar.writeTxn(() async {
    await isar.konfigurations.put(konfiguration);
  });
}

/// Refreshes every saved Konfiguration. Downloads each Klassen-/Oberstufenplan
/// only once regardless of how many Konfigurationen use it.
Future<void> refreshAllConfigurations(Isar isar) async {
  List<Konfiguration> konfigurationen = isar.konfigurations.where().findAllSync();
  if (konfigurationen.isEmpty) return;
  for (Konfiguration konfiguration in konfigurationen) {
    try {
      await updateKonfiguration(isar, konfiguration);
    } catch (e) {
      if (kDebugMode) print("Fehler beim Aktualisieren von Konfiguration '${konfiguration.name}': $e");
    }
  }
}

/// One-time migration for users upgrading from the single-profile version of
/// the app: turns the previously active Stundenplan (tracked via
/// SharedPreferences + unscoped Stunde rows) into a proper Konfiguration.
Future<void> migrateLegacyStundenplanIfNeeded(Isar isar, SharedPreferences prefs) async {
  // Only ever needed once: as soon as at least one Konfiguration exists
  // (whether from this migration, onboarding, or a QR import) there is
  // nothing left to migrate.
  if (isar.konfigurations.where().countSync() > 0) return;
  String? stufe = prefs.getString("stundenplanStufe");
  bool? isOberstufe = prefs.getBool("stundenplanIsOberstufe");
  // Nothing was ever selected on this install (fresh install) - nothing to carry over.
  if (stufe == null || stufe.isEmpty) return;

  List<Stunde> legacyStunden = isar.stundes.filter().konfigurationIdEqualTo(0).findAllSync();
  // Even if the lessons themselves haven't been (re-)downloaded yet, keep the
  // user's Klasse/Stufe pick so nothing is lost - the next background/manual
  // refresh will populate the Stunden for it automatically.
  List<String> kurse = (isOberstufe ?? false) ? legacyStunden.map((e) => e.name).toSet().toList() : [];

  Konfiguration konfiguration = Konfiguration()
    ..name = stufe
    ..stufe = stufe
    ..isOberstufe = isOberstufe ?? false
    ..kurse = kurse
    ..createdAt = DateTime.now()
    ..position = 0;

  await isar.writeTxn(() async {
    await isar.konfigurations.put(konfiguration);
    if (legacyStunden.isNotEmpty) {
      for (Stunde stunde in legacyStunden) {
        stunde.konfigurationId = konfiguration.id;
      }
      await isar.stundes.putAll(legacyStunden);
    }
  });
}


Future<List<(DateTime starting, DateTime updated, bool oberstufe, String url)>> getStundenplanLinks(DOM.Document document) async {
  List<(DateTime starting, DateTime updated, bool oberstufe, String url)> stundenplaene = List.empty(growable: true);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final europeanDateFormatter = DateFormat('dd.MM.yyyy');

  String stundenplanUrlMaybeOverriden = prefs.getString("website_url_stundenplan") ?? stundenplanUrl;
  if (!stundenplanUrlMaybeOverriden.endsWith("/")) stundenplanUrlMaybeOverriden += "/";

  for (DOM.Element element in document.body?.querySelectorAll("a") ?? []) {
    // Alles, was nicht wie ein Stundenplan-Eintrag aussieht (Navigation,
    // Footer, Anker, Zurück-Links, ...), wird übersprungen statt den ganzen
    // Parse abzubrechen. Vorher riss ein einziges fremdes <a> - oder ein
    // Eintrag ohne erkennbares Datum - die komplette Stundenplan- UND
    // Schuljahreswechsel-Erkennung mit runter. Kommt am Ende gar nichts
    // zusammen, wird weiter unten trotzdem geworfen.
    String? href = element.attributes["href"];
    if (href == null || href.isEmpty) continue;

    String name = element.text;
    DateTime? starting = _parseDatumNach(name, "ab", europeanDateFormatter);
    if (starting == null) continue;
    DateTime? updated = _parseDatumNach(name, "Stand", europeanDateFormatter);
    if (updated == null) continue;

    bool oberstufe = name.toLowerCase().contains("oberstufe") || name.toLowerCase().contains("q1");
    if (!oberstufe && !name.toLowerCase().contains("klasse")) continue;

    stundenplaene.add((starting, updated, oberstufe, Uri.parse(stundenplanUrlMaybeOverriden).resolve(href).toString()));
  }
  if (stundenplaene.isEmpty) throw Exception("Keine Stundenpläne auf der Seite gefunden");
  return stundenplaene;
}

/// Liest das Datum, das im Linktext direkt hinter [marker] steht, z.B. das
/// "2023-11-06" bzw. "03.11.2023" in
/// `Klassenpläne (SI) - ab 2023-11-06.pdf (Stand: 03.11.2023)`.
///
/// Akzeptiert bewusst beide Schreibweisen (ISO und deutsch), egal hinter
/// welchem Marker sie steht: die Seite benutzt heute je Marker eine andere,
/// und ein Wechsel soll nicht sofort alles lahmlegen. Gibt `null` zurück,
/// wenn der Marker fehlt oder dahinter kein Datum steht - der Aufrufer
/// überspringt den Link dann.
DateTime? _parseDatumNach(String name, String marker, DateFormat europeanDateFormatter) {
  int markerIndex = name.indexOf(marker);
  if (markerIndex == -1) return null;
  int start = markerIndex + marker.length;
  while (start < name.length && (name[start] == " " || name[start] == ":")) start++;
  if (start + 10 > name.length) return null;
  String datum = name.substring(start, start + 10);

  DateTime? iso = DateTime.tryParse(datum);
  if (iso != null) return iso;
  try {
    return europeanDateFormatter.parseStrict(datum);
  } catch (_) {
    return null;
  }
}

Future<List<String>> getStufen(PdfDocument? plan) async {
  if (plan == null) return List.empty(growable: true);
  List<String> stufen = List.empty(growable: true);

  for (int i = 0; i < plan.pages.count; i++) {
    //Extracts the text line collection from the document
    final List<TextLine> lines = PdfTextExtractor(plan).extractTextLines(startPageIndex: i, endPageIndex: i);

    String stufe = lines[6].text;
    if (stufe.length > 3 && stufe != "TEST") throw Exception("Stufenname in Oberstufenplan nicht gefunden");
    stufen.add(stufe);
  }

  //check if known that plan is klassenplan:  if (klasse.length > 3 || int.tryParse(klasse[0]) == null) throw Exception("Klassenname in Klassenplan nicht gefunden");
  return (stufen.toSet().toList());
}

Future<List<Stunde>> getStundenPlan((String stufe, PdfDocument? plan, bool isOberstufe) value) async {
  if (value.$2 == null) return List.empty(growable: true);
  String stufe = value.$1;
  PdfDocument plan = value.$2!;
  bool isOberstufe = value.$3;

  var stufen = await getStufen(plan);

  // bool isKlasse = klassen.contains(stufe);
  // if (!isKlasse && !oberstufen.contains(stufe)) throw Exception("Stufe nicht gefunden");

  List<Stunde> stunden = List.empty(growable: true);
  int stufenIndex = stufen.indexOf(stufe);

  if (stufenIndex == -1) {
    throw Exception("Couldn't find stufe in stundenplan");
  }

  List<TextLine> lines = PdfTextExtractor(plan)
      .extractTextLines(startPageIndex: isOberstufe ? stufenIndex * 2 : stufenIndex, endPageIndex: isOberstufe ? stufenIndex * 2 : stufenIndex);

  if (lines[6].text != stufe) throw Exception("Reihenfolge von Stundenplan durcheinandergekmmen : ${lines[6].text} != $stufe");

  int index = 6;
  if (!lines[3].text.startsWith("ab ")) throw Exception("kein Startdatum gefunden");
  final europeanDateFormatter = DateFormat('dd.MM.yyyy');
  DateTime gueltigAb = europeanDateFormatter.parse(lines[3].text.substring(3));
  // }
  for (bool gerade in [false, true]) {
    if (gerade && isOberstufe) {
      lines = PdfTextExtractor(plan).extractTextLines(startPageIndex: stufenIndex * 2 + 1, endPageIndex: stufenIndex * 2 + 1);
      index = 6;
    }
    int startSearchDays = index;
    while (index < lines.length - 1 && !lines[index].text.startsWith("Mo Di")) {
      index++;
    }
    if (index - startSearchDays > 4) throw Exception("Tage nicht gefunden");
    TextLine tageline = lines[index];
    List<double> tageXAbstand = List.empty(growable: true);
    for (TextWord textWord in tageline.wordCollection) {
      double x = textWord.bounds.bottomCenter.dx;
      tageXAbstand.add(x);
    }
    index++;
    List<double> stundenYAbstand = List.empty(growable: true);
    while (index < lines.length - 1 && lines[index].text.length <= 2 && int.tryParse(lines[index].text) != null) {
      int stunde = int.parse(lines[index].text);
      if (stunde != stundenYAbstand.length + 1) throw Exception("Stundenreihenfolge durcheinandergekommen");
      stundenYAbstand.add(lines[index].bounds.centerRight.dy);
      index++;
    }

    List<double> stundenWithAveragesYAbstand = generateInBetweenAverages(stundenYAbstand);
    List<List<TextLine>> linesInDays = [for (int i = 0; i < tageXAbstand.length; i++) List.empty(growable: true)];
    while (index < lines.length - 1 && !lines[index].text.contains("Kalenderwoche")) {
      String text = lines[index].text;
      if (!(text.length == 1 && (text[0] == "A" || text[0] == "B"))) {
        int tag = findClosestMatchIndex(lines[index].bounds.bottomCenter.dx, tageXAbstand) + 1;
        linesInDays[tag - 1].add(lines[index]);
      }
      index++;
    }
    // --- Blockbildung ---------------------------------------------------
    // Untis stapelt alle parallel laufenden Kurse einer Zelle untereinander.
    // Ob ein Block eine Einzel- oder eine Doppelstunde ist, ergibt sich aus
    // der Mitte des *gesamten* Blocks - deshalb muss die Gruppierung stimmen.
    //
    // Frueher wurde dafuer getestet, ob der Abstand zweier Zeilen kleiner ist
    // als die Zeilenhoehe. Das hatte bei 9pt-Text nur ~0.4pt Reserve
    // (Zeilenabstand 8.64pt gegen Zeilenhoehe 9.00pt). Seit Untis den
    // Zeilenabstand auf 9.36pt vergroessert hat, ist der Test immer falsch:
    // jede Zeile wird zu einem eigenen "Block", und in Zellen mit >=5 Kursen
    // liegen die erste und die letzte Zeile weiter als eine Viertel-Zeilenhoehe
    // (61.19/4 = 15.3pt) von der Zellenmitte entfernt und rasten dadurch auf
    // der falschen Stunde ein.
    //
    // Die Schwelle wird deshalb jetzt aus dem Plan selbst abgeleitet: der
    // kleinste vorkommende Zeilenabstand IST der Abstand innerhalb einer Zelle.
    double rowSpacing = stundenYAbstand.length > 1
        ? (stundenYAbstand.last - stundenYAbstand.first) / (stundenYAbstand.length - 1)
        : 36.0;

    // Defensiv: die Reihenfolge aus der PDF-Extraktion ist nicht garantiert.
    for (List<TextLine> dayLines in linesInDays) {
      dayLines.sort((a, b) => a.bounds.centerRight.dy.compareTo(b.bounds.centerRight.dy));
    }

    List<double> gaps = List.empty(growable: true);
    for (List<TextLine> dayLines in linesInDays) {
      for (int i = 1; i < dayLines.length; i++) {
        double gap = dayLines[i].bounds.centerRight.dy - dayLines[i - 1].bounds.centerRight.dy;
        // Abstaende ab ~3/4 Stundenhoehe sind sicher Zellwechsel und
        // verfaelschen die Schaetzung des Zeilenabstands.
        if (gap > 0.5 && gap < rowSpacing * 0.75) gaps.add(gap);
      }
    }
    gaps.sort();
    // 10. Perzentil statt Minimum: robustes Minimum, unempfindlich gegen
    // einzelne Ausreisser aus der Textextraktion.
    double leading = gaps.isEmpty ? rowSpacing * 0.25 : gaps[(gaps.length * 0.1).floor()];
    // Im aktuellen Oberstufenplan liegen die Abstaende innerhalb einer Zelle bei
    // 9.3pt, der kleinste Abstand zwischen zwei Zellen bei 23.7pt - die Schwelle
    // liegt also mitten in einer sehr breiten Luecke. Die zusaetzliche Deckelung
    // auf 0.4 Stundenhoehen sichert die engeren Klassenplaene (36pt) ab.
    double blockThreshold = min(leading * 1.6, rowSpacing * 0.4);
    double maxBlockExtent = rowSpacing * 2 - leading; // hoechstens eine Doppelstunde

    void addBlock(List<TextLine> block, int tag) {
      if (block.isEmpty) return;
      double firstY = block.first.bounds.centerRight.dy;
      double lastY = block.last.bounds.centerRight.dy;
      int closestYMatch = findClosestMatchIndex((firstY + lastY) / 2, stundenWithAveragesYAbstand);
      List<int> stundenWhereBlockTakesPlace = closestYMatch % 2 == 0 ? [closestYMatch ~/ 2] : [closestYMatch ~/ 2, closestYMatch ~/ 2 + 1];

      // Sicherheitsnetz: ein Block, der hoeher ist als eine ganze Stundenzeile,
      // kann unmoeglich in eine einzelne Stunde passen.
      if (stundenWhereBlockTakesPlace.length == 1 && (lastY - firstY) > rowSpacing) {
        int k = stundenWhereBlockTakesPlace.first;
        bool nachUnten = (firstY + lastY) / 2 >= stundenYAbstand[k];
        if (nachUnten && k + 1 < stundenYAbstand.length)
          stundenWhereBlockTakesPlace = [k, k + 1];
        else if (!nachUnten && k > 0) stundenWhereBlockTakesPlace = [k - 1, k];
      }

      for (TextLine textLine in block) {
        // Strips the leading "*" PDF-Untis prints before
        // Differenzierungskurse (e.g. "*F7 2 BSK 113" -> "F7 2 BSK 113"),
        // and any stray junk character the PDF text extraction glues onto
        // it when that marker glyph doesn't have a proper Unicode mapping
        // in the embedded font (e.g. "*yF7 2" -> "F7 2"). See
        // stripKursMarker() in database.dart.
        stunden.add(Stunde()
          ..name = stripKursMarker(textLine.text)
          ..geradeWoche = gerade
          // eigene Liste pro Stunde - nicht eine geteilte Instanz
          ..stunden = List<int>.from(stundenWhereBlockTakesPlace)
          ..gueltigAb = gueltigAb
          ..tag = tag + 1);
      }
    }

    for (int tag = 0; tag < linesInDays.length; tag++) {
      List<TextLine> stundenInBlock = List.empty(growable: true);
      for (TextLine line in linesInDays[tag]) {
        if (stundenInBlock.isEmpty) {
          stundenInBlock = [line];
          continue;
        }
        double gap = line.bounds.centerRight.dy - stundenInBlock.last.bounds.centerRight.dy;
        double extent = line.bounds.centerRight.dy - stundenInBlock.first.bounds.centerRight.dy;
        if (gap <= blockThreshold && extent <= maxBlockExtent) {
          stundenInBlock.add(line);
        } else {
          addBlock(stundenInBlock, tag);
          stundenInBlock = [line];
        }
      }
      addBlock(stundenInBlock, tag);
    }
    index += 6;
  }

  return stunden;
}

int findClosestMatchIndex(double target, List<double> doubleList) {
  int index = 0;
  double minDifference = (target - doubleList[0]).abs();

  // Bewusst ueber den Index iterieren: indexOf() liefert bei doppelten Werten
  // in der Liste den falschen (naemlich den ersten) Treffer zurueck.
  for (int i = 1; i < doubleList.length; i++) {
    double difference = (target - doubleList[i]).abs();
    if (difference < minDifference) {
      minDifference = difference;
      index = i;
    }
  }

  return index;
}

List<double> generateInBetweenAverages(List<double> doubleList) {
  List<double> result = [];

  if (doubleList.isEmpty) {
    return result;
  }

  for (int i = 0; i < doubleList.length - 1; i++) {
    result.add(doubleList[i]);

    double average = (doubleList[i] + doubleList[i + 1]) / 2.0;
    result.add(average);
  }

  result.add(doubleList.last);

  return result;
}

Future<List<Vertretung>> parseVertretungsplan(String vertretungsplan, Isar isar) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  DOM.Document plan = parse(vertretungsplan);

  if (plan.body?.querySelector("h2")?.text == null || !plan.body!.querySelector("h2")!.text.startsWith("Ticker")) throw Exception("No ticker found");
  DOM.Element ticker = plan.body!.querySelector("h2")!;
  DOM.Element? tickerTextElement = ticker.nextElementSibling;
  if (tickerTextElement != null) tickerTextElement.innerHtml = tickerTextElement.innerHtml.replaceAll("<br>", "\n");
  String tickertext = tickerTextElement?.text ?? "";
  tickertext = tickertext.replaceAll("\n\n", "\n").trim();
  ticker.remove();

  List<List<Vertretung>> vertretungen = [];
  List<List<String>> betroffeneKlassenListen = List.empty(growable: true);
  for (DOM.Element h2 in plan.body!.querySelectorAll("h2")) {
    final europeanDateFormatter = DateFormat('dd.MM.yyyy');
    DateTime datum = europeanDateFormatter.parse(h2.text.substring(h2.text.lastIndexOf(" ") + 1));
    DOM.Element? letzteAktualisierung = h2.nextElementSibling;
    if (letzteAktualisierung == null || letzteAktualisierung.localName != "p" || !letzteAktualisierung.text.startsWith("(Letzte Aktualisierung"))
      throw Exception("No last update found");
    DOM.Element? betroffen = letzteAktualisierung.nextElementSibling?.nextElementSibling;
    if (betroffen == null || betroffen.localName != "h3") throw Exception("No affected classes found");
    if (betroffen.text.contains("keine"))
      continue;
    else if (!betroffen.text.startsWith("betroffen:")) throw Exception("betroffen text doesnt start with betroffen:");
    List<String> betroffeneKlassen = betroffen.text.substring(10).split(",").map((e) => e.trim()).toList();
    betroffeneKlassenListen.add(betroffeneKlassen);
    vertretungen.add(List.empty(growable: true));
    DOM.Element? table = betroffen.nextElementSibling?.nextElementSibling;
    if (table == null || table.localName != "table") throw Exception("No table found");
    String stufe = "";
    for (DOM.Element tr in table.querySelectorAll("tr")) {
      List<DOM.Element> ths = tr.querySelectorAll("th");
      List<DOM.Element> tds = tr.querySelectorAll("td");
      if (ths.length == 1) {
        stufe = ths[0].text;
        continue;
      }
      if (tds.length == 6) {
        String stunden = tds[0].text;
        String art = tds[1].text;
        String kurs = tds[2].text.replaceAll(RegExp(r"\s+"), " ");
        String raum = tds[3].text;
        String lehrkraft = tds[4].text;
        String bemerkung = tds[5].text;
        List<int> hervorgehoben = [];
        for (DOM.Element td in tds) {
          if (td.className == "vertretung neu") hervorgehoben.add(tds.indexOf(td));
        }

        List<int> stundenList;
        if (stunden.contains(" ") || stunden.contains("-")) {
          List<String> stundenSplit = stunden.split("-");
          if (stundenSplit.length != 2) throw Exception("Invalid stunden format");
          stundenList = [for (int i = int.parse(stundenSplit[0].trim()); i <= int.parse(stundenSplit[1].trim()); i++) i - 1];
        } else {
          stundenList = [int.parse(stunden) - 1];
        }
        vertretungen.last.add(Vertretung()
          ..klasse = stufe
          ..stunden = stundenList
          ..art = art
          ..kurs = kurs
          ..raum = raum
          ..lehrkraft = lehrkraft
          ..bemerkung = bemerkung
          ..tag = datum
          ..hervorgehoben = hervorgehoben);
      }
      if (tds.length == 3) {
        if (tds[2].className != "eva auftrag") throw Exception("No eva found");
        // Eine EVA-Zeile gehört immer zu der Vertretung direkt darüber. Steht
        // sie (durch doppeltes/kaputtes Markup) vor der ersten regulären
        // Zeile, gibt es nichts zum Anhängen - überspringen statt mit
        // "StateError: No element" den ganzen Vertretungsplan zu verlieren.
        if (vertretungen.last.isEmpty) continue;
        String eva = tds[2].text;
        vertretungen.last.last.eva = vertretungen.last.last.eva == null ? eva : "${vertretungen.last.last.eva!}\n$eva";
      }
    }
  }
  int sortMethod = prefs.getInt("vertretungen_sort") ?? 0;
  if (sortMethod != 1) {
    for (final (int index, List<Vertretung> vertretungList) in vertretungen.indexed) {
      if (sortMethod == 0) {
        vertretungList.sort(
          (a, b) {
            return betroffeneKlassenListen[index].indexOf(a.klasse).compareTo(betroffeneKlassenListen[index].indexOf(b.klasse));
          },
        );
      } else if (sortMethod == 2) {
        vertretungList.sort((a, b) {
          String klasseA = a.klasse;
          String klasseB = b.klasse;

          if (_startsWithDigit(klasseA) && _startsWithDigit(klasseB)) {
            // If both strings start with a digit, compare them as integers.
            int intA = int.parse(klasseA.split(RegExp(r'\D+')).first);
            int intB = int.parse(klasseB.split(RegExp(r'\D+')).first);
            return intA - intB;
          } else {
            // If at least one of the strings does not start with a digit, compare them lexicographically.
            return klasseA.compareTo(klasseB);
          }
        });
      }
    }
  }

  List<Vertretung> vertretungenFlattened = vertretungen.expand((element) => element).toList();

  // Die Website liefert Tage/Blöcke teilweise mehrfach aus (doppeltes Markup),
  // wodurch identische Einträge doppelt angezeigt würden -> hier deduplizieren.
  final Set<String> gesehen = {};
  vertretungenFlattened = vertretungenFlattened.where((v) => gesehen.add(_vertretungKey(v))).toList();

  prefs.setString("ticker", tickertext);
  // Vergleich über einen Inhalts-Key: `stunden` ist eine Liste und wurde vorher
  // per `==` (Referenzvergleich) geprüft, war also immer ungleich -> jede
  // Vertretung galt als neu.
  List<Vertretung> alteVertretungen = isar.vertretungs.where().findAllSync();
  final Set<String> alteKeys = alteVertretungen.map(_vertretungKey).toSet();
  List<Vertretung> neueVertretungen = vertretungenFlattened.where((vertretung) => !alteKeys.contains(_vertretungKey(vertretung))).toList();

  await isar.writeTxn(() async {
    await isar.vertretungs.clear();
    await isar.vertretungs.putAll(vertretungenFlattened);
  });

  prefs.setInt("vertretungLastDownload", DateTime.now().millisecondsSinceEpoch);

  return neueVertretungen;
}

String _vertretungKey(Vertretung v) => [
      v.tag.toIso8601String(),
      v.klasse,
      v.stunden.join("-"),
      v.art,
      v.kurs,
      v.raum,
      v.lehrkraft,
      v.bemerkung ?? "",
      v.eva ?? "",
    ].join("|");

bool _startsWithDigit(String s) {
  return RegExp(r'^\d').hasMatch(s);
}

Future<String> getStundenplanWebsite() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return (await getSecuredPage(prefs.getString("website_url_stundenplan") ?? stundenplanUrl)).body;
}

Future<String> getVertretungsplanWebsite() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return (await getSecuredPage(prefs.getString("website_url_vertretungsplan") ?? vertretungsplanUrl)).body;
}

Future<bool> checkCredentials() async {
  await getVertretungsplanWebsite();
  return true;
}

Future<http.Response> getSecuredPage(String url) async {
  FlutterSecureStorage securePrefs = getSecurePrefs();
  String? username = await securePrefs.read(key: "username");
  String? password = await securePrefs.read(key: "password");

  if (username == null || password == null) throw Exception("No username or password found");

  if (username == "test" && password == "test") {
    if (url == vertretungsplanUrl) url = "https://raw.githubusercontent.com/Equirinya/Pius-App-Rework/master/test_websites/vertretungsplan.html";
    if (url == stundenplanUrl) url = "https://raw.githubusercontent.com/Equirinya/Pius-App-Rework/master/test_websites/stundenplaene.html";
    return await http.get(Uri.parse(url));
  }

  Map<String, String> authorizationHeaders = {
    "Authorization": "Basic ${base64Encode(utf8.encode("$username:$password"))}",
  };

  if (username.isEmpty || password.isEmpty) throw Exception("Username or Password is empty");

  http.Response response = await http.get(Uri.parse(url), headers: authorizationHeaders);

  if (response.statusCode == 401) throw const AuthorizationException("Ungültiger Nutzername oder Passwort");
  if (response.statusCode != 200) throw Exception("Unexpected response code ${response.statusCode} while fetching $url");
  return response;
}

FlutterSecureStorage getSecurePrefs() {
  AndroidOptions getAndroidOptions() => const AndroidOptions();
  const iOptions = IOSOptions(accessibility: KeychainAccessibility.first_unlock);
  final FlutterSecureStorage securePrefs = FlutterSecureStorage(aOptions: getAndroidOptions(), iOptions: iOptions);
  return securePrefs;
}

class AuthorizationException implements Exception {
  final String msg;

  const AuthorizationException(this.msg);

  @override
  String toString() => msg;
}
