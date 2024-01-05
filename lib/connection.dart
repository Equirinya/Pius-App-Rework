import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:PiusApp/pages/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:html/parser.dart';
import 'package:html/dom.dart' as DOM;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

const String baseUrl = "https://www.pius-gymnasium.de";
const String stundenplanUrl = baseUrl + "/stundenplaene";
const String vertretungsplanUrl = baseUrl + "/vertretungsplan";
const String termineUrl = baseUrl + "/pius-kalender.ics";
const String feiertagUrl = "https://get.api-feiertage.de/?states=nw";

class ColorChangedNotification extends Notification {}

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
        bool isAllDay = (startTime.hour == 0 && startTime.minute == 0 && endTime.hour == 0 && endTime.hour == 0);
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
    List<(DateTime starting, DateTime updated, bool oberstufe, String url)> klassenplaene = (stundenplaene.where((element) => !element.$3).toList()..sort((a, b) => -a.$1.compareTo(b.$1)));
    if(klassenplaene.isEmpty) throw Exception("Keinen Klassenplan gefunden");
    String klassenplan;
    if(klassenplaene.length == 1) klassenplan = klassenplaene.first.$4;
    else klassenplan = klassenplaene.firstWhere((element) => element.$1.isBefore(DateTime.now())).$4;

    List<(DateTime starting, DateTime updated, bool oberstufe, String url)> oberstufenplaene = (stundenplaene.where((element) => element.$3).toList()..sort((a, b) => -a.$1.compareTo(b.$1)));
    if(oberstufenplaene.isEmpty) throw Exception("Keinen Oberstufenplan gefunden");
    String oberstufenplan;
    if(oberstufenplaene.length == 1) oberstufenplan = oberstufenplaene.first.$4;
    else oberstufenplan = oberstufenplaene.firstWhere((element) => element.$1.isBefore(DateTime.now())).$4;

    return (PdfDocument(inputBytes: (await getSecuredPage(klassenplan)).bodyBytes), PdfDocument(inputBytes: (await getSecuredPage(oberstufenplan)).bodyBytes));
  } catch (e, s) {
    debugPrintStack(stackTrace: s);
    throw Exception("Fehler beim Laden der Klassen und Oberstufenpläne: $e");
  }
}

Future<void> updateStundenplan(Isar isar) async {
  DOM.Document document = parse(await getStundenplanWebsite());

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? stufe = prefs.getString("stundenplanStufe");
  bool? isOberstufe = prefs.getBool("stundenplanIsOberstufe");
  if (stufe == null || isOberstufe == null || stufe.isEmpty) throw Exception("No stufe found");

  List<(DateTime starting, DateTime updated, bool oberstufe, String url)> stundenplaene = await getStundenplanLinks(document);
  stundenplaene = stundenplaene.where((element) => element.$3 == isOberstufe).toList();
  if (stundenplaene.isEmpty) throw Exception("No stundenplan found");
  stundenplaene.sort((a, b) => -a.$1.compareTo(b.$1));

  int lastUpdate = prefs.getInt("stundenplanLastUpdate") ?? 0;

  List<String> kurse = isar.stundes.where().nameProperty().findAllSync().toSet().toList();
  List<DateTime> existingGueltigAb = isar.stundes.where().gueltigAbProperty().findAllSync().toSet().toList();
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
      await isar.stundes.filter().gueltigAbEqualTo(gueltigAb).deleteAll();
    });
  }
  existingGueltigAb = isar.stundes.where().gueltigAbProperty().findAllSync().toSet().toList();
  for (var (DateTime gueltigAb, DateTime updated, bool oberstufe, String url) in toAdd) {
    if (existingGueltigAb.isNotEmpty) {
      List<Stunde> toUpdateStunden =
          isar.stundes.filter().gueltigAbEqualTo(existingGueltigAb.reduce((value, element) => value.isBefore(element) ? element : value)).findAllSync();

      await isar.writeTxn(() async {
        await isar.stundes.putAll(toUpdateStunden.map((e) => e..gueltigBis = gueltigAb).toList());
      });
      existingGueltigAb = isar.stundes.where().gueltigAbProperty().findAllSync().toSet().toList();
    }

    List<Stunde> stunden = await compute(getStundenPlan, (stufe, PdfDocument(inputBytes: (await getSecuredPage(url)).bodyBytes), isOberstufe));

    if (isOberstufe) stunden.retainWhere((element) => kurse.contains(element.name));
    await isar.writeTxn(() async {
      await isar.stundes.putAll(stunden);
    });
  }

  prefs.setInt("stundenplanLastUpdate", stundenplaene.map((e) => e.$2.millisecondsSinceEpoch).reduce(max));
}

Future<List<(DateTime starting, DateTime updated, bool oberstufe, String url)>> getStundenplanLinks(DOM.Document document) async {
  List<(DateTime starting, DateTime updated, bool oberstufe, String url)> stundenplaene = List.empty(growable: true);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final europeanDateFormatter = DateFormat('dd.MM.yyyy');

  for (DOM.Element element in document.body?.querySelectorAll("a") ?? []) {
    if (element.attributes["href"]?.isEmpty ?? true) throw Exception("No href in links");
    String stundenplanUrlMaybeOverriden = prefs.getString("website_url_stundenplan") ?? stundenplanUrl;
    if (!stundenplanUrlMaybeOverriden.endsWith("/")) stundenplanUrlMaybeOverriden += "/";

    String name = element.text;
    int parseStart = name.indexOf("ab") + 2;
    while (parseStart < name.length && [" ", ":"].contains(name[parseStart])) parseStart++;
    DateTime starting = DateTime.parse(name.substring(parseStart, parseStart + 10));

    parseStart = name.indexOf("Stand") + 5;
    while (parseStart < name.length && [" ", ":"].contains(name[parseStart])) parseStart++;
    DateTime updated = europeanDateFormatter.parse(name.substring(parseStart, parseStart + 10));

    bool oberstufe = name.toLowerCase().contains("oberstufe");
    if (!oberstufe && !name.toLowerCase().contains("klasse"))
      throw Exception("Stundenplan welcher weder als Klasse noch Oberstufe identifizierbar ist gefunden");
    stundenplaene.add((starting, updated, oberstufe, Uri.parse(stundenplanUrlMaybeOverriden).resolve(element.attributes["href"]!).toString()));
  }
  return stundenplaene;
}

Future<List<String>> getStufen(PdfDocument? plan) async {
  if(plan == null) return List.empty(growable: true);
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
  if(value.$2 == null) return List.empty(growable: true);
  String stufe = value.$1;
  PdfDocument plan = value.$2!;
  bool isOberstufe = value.$3;

  var stufen = await getStufen(plan);

  // bool isKlasse = klassen.contains(stufe);
  // if (!isKlasse && !oberstufen.contains(stufe)) throw Exception("Stufe nicht gefunden");

  List<Stunde> stunden = List.empty(growable: true);
  int stufenIndex = stufen.indexOf(stufe);

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
    while (!lines[index].text.startsWith("Mo Di") && index < lines.length - 1) {
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
    while (lines[index].text.length <= 2 && int.tryParse(lines[index].text) != null && index < lines.length - 1) {
      int stunde = int.parse(lines[index].text);
      if (stunde != stundenYAbstand.length + 1) throw Exception("Stundenreihenfolge durcheinandergekommen");
      stundenYAbstand.add(lines[index].bounds.centerRight.dy);
      index++;
    }

    List<double> stundenWithAveragesYAbstand = generateInBetweenAverages(stundenYAbstand);
    List<List<TextLine>> linesInDays = [for (int i = 0; i < tageXAbstand.length; i++) List.empty(growable: true)];
    while (!lines[index].text.contains("Kalenderwoche") && index < lines.length - 1) {
      String text = lines[index].text;
      if (!(text.length == 1 && (text[0] == "A" || text[0] == "B"))) {
        int tag = findClosestMatchIndex(lines[index].bounds.bottomCenter.dx, tageXAbstand) + 1;
        linesInDays[tag - 1].add(lines[index]);
      }
      index++;
    }
    List<TextLine> stundenInBlock = List.empty(growable: true);
    for (int tag = 0; tag < linesInDays.length; tag++) {
      for (int stunde = 0; stunde < linesInDays[tag].length; stunde++) {
        if (stundenInBlock.isEmpty) {
          stundenInBlock.add(linesInDays[tag][stunde]);
        } else if (linesInDays[tag][stunde].bounds.centerRight.dy - stundenInBlock.last.bounds.centerRight.dy < linesInDays[tag][stunde].bounds.height) {
          stundenInBlock.add(linesInDays[tag][stunde]);
        } else {
          double averageY = (stundenInBlock.first.bounds.centerRight.dy + stundenInBlock.last.bounds.centerRight.dy) / 2;
          int closestYMatch = findClosestMatchIndex(averageY, stundenWithAveragesYAbstand);
          List<int> stundenWhereBlockTakesPlace = closestYMatch % 2 == 0 ? [closestYMatch ~/ 2] : [closestYMatch ~/ 2, closestYMatch ~/ 2 + 1];

          for (TextLine textLine in stundenInBlock) {
            String text = textLine.text;
            stunden.add(Stunde()
              ..name = text
              ..geradeWoche = gerade
              ..stunden = stundenWhereBlockTakesPlace
              ..gueltigAb = gueltigAb
              ..tag = tag + 1);
          }

          //reset
          stundenInBlock = [linesInDays[tag][stunde]];
        }
        if (stunde == linesInDays[tag].length - 1) {
          double averageY = (stundenInBlock.first.bounds.centerRight.dy + stundenInBlock.last.bounds.centerRight.dy) / 2;
          int closestYMatch = findClosestMatchIndex(averageY, stundenWithAveragesYAbstand);
          List<int> stundenWhereBlockTakesPlace = closestYMatch % 2 == 0 ? [closestYMatch ~/ 2] : [closestYMatch ~/ 2, closestYMatch ~/ 2 + 1];

          for (TextLine textLine in stundenInBlock) {
            String text = textLine.text;
            stunden.add(Stunde()
              ..name = text
              ..geradeWoche = gerade
              ..stunden = stundenWhereBlockTakesPlace
              ..gueltigAb = gueltigAb
              ..tag = tag + 1);
          }

          stundenInBlock = List.empty(growable: true);
        }
      }
    }
    index += 6;
  }

  return stunden;
}

int findClosestMatchIndex(double target, List<double> doubleList) {
  int index = 0;
  double minDifference = (target - doubleList[index]).abs();

  for (double value in doubleList) {
    double difference = (target - value).abs();
    if (difference < minDifference) {
      minDifference = difference;
      index = doubleList.indexOf(value);
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
          if(stundenSplit.length != 2) throw Exception("Invalid stunden format");
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

  prefs.setString("ticker", tickertext);
  List<Vertretung> alteVertretungen = isar.vertretungs.where().findAllSync();
  List<Vertretung> neueVertretungen = vertretungenFlattened
      .where((vertretung) => !alteVertretungen.any((element) =>
          element.stunden == vertretung.stunden &&
          element.art == vertretung.art &&
          element.kurs == vertretung.kurs &&
          element.raum == vertretung.raum &&
          element.lehrkraft == vertretung.lehrkraft &&
          element.bemerkung == vertretung.bemerkung &&
          element.eva == vertretung.eva &&
          element.tag == vertretung.tag &&
          element.klasse == vertretung.klasse))
      .toList();

  await isar.writeTxn(() async {
    await isar.vertretungs.clear();
    await isar.vertretungs.putAll(vertretungenFlattened);
  });

  prefs.setInt("vertretungLastDownload", DateTime.now().millisecondsSinceEpoch);

  return neueVertretungen;
}

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

  if(username == "test" && password == "test") {
    if(url == vertretungsplanUrl) url = "https://raw.githubusercontent.com/Equirinya/Pius-App-Rework/master/test_websites/vertretungsplan.html";
    if(url == stundenplanUrl) url =  "https://raw.githubusercontent.com/Equirinya/Pius-App-Rework/master/test_websites/stundenplaene.html";
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

  AndroidOptions getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );
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
