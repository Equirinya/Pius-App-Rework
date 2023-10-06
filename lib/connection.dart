import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_launcher_icons/custom_exceptions.dart';
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
const String stundenplanUrl = baseUrl + "/stundenplaene/"; //TODO put into settings
const String vertretungsplanUrl = baseUrl + "/vertretungsplan/";
const String termineUrl = baseUrl + "/pius-kalender.ics";

class ColorChangedNotification extends Notification {}

Future<List<Appointment>> getPiusTermine() async {
  http.Response response = await http.get(Uri.parse(termineUrl));

  if (response.statusCode != 200) throw Exception("Unexpected response code ${response.statusCode}");
  final iCalendar = ICalendar.fromString(response.body);
  List<Appointment> termine = iCalendar.data
      .map((e) {
        if (e["type"] != "VEVENT") return null;
        DateTime startTime =  DateTime.parse((e["dtstart"] as IcsDateTime).dt);
        DateTime endTime = DateTime.parse((e["dtend"] as IcsDateTime).dt);
        bool isAllDay = (startTime.hour == 0 && startTime.minute == 0 && endTime.hour == 0 && endTime.hour == 0);
        return Appointment(
          startTime: startTime,
          endTime: isAllDay ? endTime.subtract(const Duration(seconds: 1)) : endTime,
          subject: e["summary"],
          isAllDay: isAllDay,
        );
      })
      .nonNulls
      .toList();
  return termine;
}

Future<void> updateTermine() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<Appointment> termine = await getPiusTermine();
  String termineString = jsonEncode(termine.map((e) => appointmentToMap(e)).toList());
  prefs.setString("piusTermine", termineString);
  return;
}

Map<String, dynamic> appointmentToMap(Appointment appointment) =>
    {"start": appointment.startTime.millisecondsSinceEpoch, "end": appointment.endTime.millisecondsSinceEpoch, "subject": appointment.subject, "isAllDay" : appointment.isAllDay};

Appointment appointmentFromMap(Map<String, dynamic> map) => Appointment(
    startTime: DateTime.fromMillisecondsSinceEpoch(map["start"]), endTime: DateTime.fromMillisecondsSinceEpoch(map["end"]), subject: map["subject"], isAllDay: map["isAllDay"]);

Future<(PdfDocument klassenplan, PdfDocument oberstufenplan)> getStundenplaene() async {
  DOM.Document document = parse(await getStundenplanWebsite());

  List<(String name, Uint8List data)> stundenplaene = List.empty(growable: true);
  for (DOM.Element element in document.body?.querySelectorAll("a") ?? []) {
    if (element.attributes["href"]?.isEmpty ?? true) throw Exception("No href in links");
    stundenplaene.add((element.text, (await getSecuredPage(stundenplanUrl + element.attributes["href"]!)).bodyBytes));
  }

  //TODO
  if (stundenplaene.length != 2) throw Exception("wrong amount of stundenplaene");

  try {
    Uint8List klassenplan = stundenplaene.firstWhere((element) => element.$1.toLowerCase().contains("klasse")).$2;
    Uint8List oberstufenplan = stundenplaene.firstWhere((element) => element.$1.toLowerCase().contains("oberstufe")).$2;

    return (PdfDocument(inputBytes: klassenplan), PdfDocument(inputBytes: oberstufenplan));
  } catch (e) {
    throw Exception("Entweder Klassen oder Oberstufenplan fehlen: $e");
  }
}

Future<(List<String> klassen, List<String> oberstufen)> getStufen(PdfDocument klassenplan, PdfDocument oberstufenplan) async {
  List<String> klassen = List.empty(growable: true);
  List<String> oberstufen = List.empty(growable: true);

  for (int i = 0; i < klassenplan.pages.count; i++) {
    final PdfPage page = klassenplan.pages[i];
    //Extracts the text line collection from the document
    final List<TextLine> lines = PdfTextExtractor(klassenplan).extractTextLines(startPageIndex: i, endPageIndex: i);

    String klasse = lines[6].text;
    if (klasse.length > 3 || int.tryParse(klasse[0]) == null) throw Exception("Klassenname in Klassenplan nicht gefunden");
    klassen.add(klasse);
  }
  for (int i = 0; i < oberstufenplan.pages.count; i++) {
    final PdfPage page = oberstufenplan.pages[i];
    //Extracts the text line collection from the document
    final List<TextLine> lines = PdfTextExtractor(oberstufenplan).extractTextLines(startPageIndex: i, endPageIndex: i);

    String oberstufe = lines[6].text;
    if (oberstufe.length > 3) throw Exception("Stufenname in Oberstufenplan nicht gefunden");
    oberstufen.add(oberstufe);
  }

  return (klassen.toSet().toList(), oberstufen.toSet().toList());
}

Future<List<Stunde>> getStundenPlan(String stufe) async {
  var (PdfDocument klassenplan, PdfDocument oberstufenplan) = await getStundenplaene();
  var (klassen, oberstufen) = await getStufen(klassenplan, oberstufenplan);

  bool isKlasse = klassen.contains(stufe);
  if (!isKlasse && !oberstufen.contains(stufe)) throw Exception("Stufe nicht gefunden");

  List<Stunde> stunden = List.empty(growable: true);
  int stufenIndex = isKlasse ? klassen.indexOf(stufe) : oberstufen.indexOf(stufe);

  List<TextLine> lines = isKlasse
      ? PdfTextExtractor(klassenplan).extractTextLines(startPageIndex: stufenIndex, endPageIndex: stufenIndex)
      : PdfTextExtractor(oberstufenplan).extractTextLines(startPageIndex: stufenIndex * 2, endPageIndex: stufenIndex * 2);

  if (lines[6].text != stufe) throw Exception("Reihenfolge von Klassenplan durcheinandergekommen");

  int index = 6;
  if (!lines[3].text.startsWith("ab ")) throw Exception("kein Startdatum gefunden");
  final europeanDateFormatter = DateFormat('dd.MM.yyyy');
  DateTime gueltigAb = europeanDateFormatter.parse(lines[3].text.substring(3));
  // int i2= 0;
  // while(i2<lines.length){
  //   print(lines[i2].text);
  //   i2++;
  // }
  for (bool gerade in [false, true]) {
    if (gerade && !isKlasse) {
      lines = PdfTextExtractor(oberstufenplan).extractTextLines(startPageIndex: stufenIndex * 2 + 1, endPageIndex: stufenIndex * 2 + 1);
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
    // print(tageXAbstand);
    index++;
    List<double> stundenYAbstand = List.empty(growable: true);
    while (lines[index].text.length <= 2 && int.tryParse(lines[index].text) != null && index < lines.length - 1) {
      int stunde = int.parse(lines[index].text);
      if (stunde != stundenYAbstand.length + 1) throw Exception("Stundenreihenfolge durcheinandergekommen");
      stundenYAbstand.add(lines[index].bounds.centerRight.dy);
      index++;
    }

    // print(stundenYAbstand);
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
      // print("tag $tag");
      for (int stunde = 0; stunde < linesInDays[tag].length; stunde++) {
        // print(linesInDays[tag][stunde].text);
        if (stundenInBlock.isEmpty) {
          stundenInBlock.add(linesInDays[tag][stunde]);
        } else if (linesInDays[tag][stunde].bounds.centerRight.dy - stundenInBlock.last.bounds.centerRight.dy < linesInDays[tag][stunde].bounds.height) {
          // print("${linesInDays[tag][stunde].text}"
          //     " ${linesInDays[tag][stunde].bounds.centerRight.dy - stundenInBlock.last.bounds.centerRight.dy} < ${linesInDays[tag][stunde].bounds.height}");
          stundenInBlock.add(linesInDays[tag][stunde]);
        } else {
          double averageY = (stundenInBlock.first.bounds.centerRight.dy + stundenInBlock.last.bounds.centerRight.dy) / 2;
          int closestYMatch = findClosestMatchIndex(averageY, stundenWithAveragesYAbstand);
          List<int> stundenWhereBlockTakesPlace = closestYMatch % 2 == 0 ? [closestYMatch ~/ 2] : [closestYMatch ~/ 2, closestYMatch ~/ 2 + 1];

          // print("finished Block:");
          for (TextLine textLine in stundenInBlock) {
            // print(textLine.text);
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
  String tickertext = ticker.nextElementSibling?.text ?? "";
  ticker.remove();

  List<Vertretung> vertretungen = [];
  for (DOM.Element h2 in plan.body!.querySelectorAll("h2")) {
    final europeanDateFormatter = DateFormat('dd.MM.yyyy');
    DateTime datum = europeanDateFormatter.parse(h2.text.substring(h2.text.lastIndexOf(" ") + 1));
    // print(datum);
    DOM.Element? letzteAktualisierung = h2.nextElementSibling;
    if (letzteAktualisierung == null || letzteAktualisierung.localName != "p" || !letzteAktualisierung.text.startsWith("(Letzte Aktualisierung"))
      throw Exception("No last update found");
    DOM.Element? betroffen = letzteAktualisierung.nextElementSibling?.nextElementSibling;
    if (betroffen == null || betroffen.localName != "h3") throw Exception("No affected classes found");
    if (betroffen.text.contains("keine"))
      continue;
    else if (!betroffen.text.startsWith("betroffen:")) throw Exception("betroffen text doesnt start with betroffen:");
    DOM.Element? table = betroffen.nextElementSibling?.nextElementSibling;
    if (table == null || table.localName != "table") throw Exception("No table found");
    String stufe = "";
    for (DOM.Element tr in table.querySelectorAll("tr")) {
      List<DOM.Element> ths = tr.querySelectorAll("th");
      List<DOM.Element> tds = tr.querySelectorAll("td");
      if (ths.length == 1) {
        stufe = ths[0].text;
        // print(stufe);
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
        for (DOM.Element td in tds) if (td.className == "vertretung neu") hervorgehoben.add(tds.indexOf(td));

        List<int> stundenList = stunden.length == 1
            ? [int.parse(stunden) - 1]
            : [for (int i = int.parse(stunden.substring(0, 1)); i <= int.parse(stunden.substring(4, 5)); i++) i - 1];
        vertretungen.add(Vertretung()
          ..klasse = stufe
          ..stunden = stundenList
          ..art = art
          ..kurs = kurs
          ..raum = raum
          ..lehrkraft = lehrkraft
          ..bemerkung = bemerkung
          ..tag = datum
          ..hervorgehoben = hervorgehoben);
        // print("$stufe $stunden $art $kurs $raum $lehrkraft $bemerkung");
      }
      if (tds.length == 3) {
        if (tds[2].className != "eva auftrag") throw Exception("No eva found");
        String eva = tds[2].text;
        vertretungen.last.eva = vertretungen.last.eva == null ? eva : "${vertretungen.last.eva!}\n$eva";
      }
    }
  }

  prefs.setString("ticker", tickertext);
  List<Vertretung> alteVertretungen = isar.vertretungs.where().findAllSync();
  List<Vertretung> neueVertretungen = vertretungen
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
    await isar.vertretungs.putAll(vertretungen);
  });

  prefs.setInt("vertretungLastDownload", DateTime.now().millisecondsSinceEpoch);

  return neueVertretungen;
}

Future<String> getStundenplanWebsite() async => (await getSecuredPage(stundenplanUrl)).body;
Future<String> getVertretungsplanWebsite() async => (await getSecuredPage(vertretungsplanUrl)).body;
Future<bool> checkCredentials() async {
  await getVertretungsplanWebsite();
  return true;
}

Future<http.Response> getSecuredPage(String url) async {
  AndroidOptions getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );
  final FlutterSecureStorage securePrefs = FlutterSecureStorage(aOptions: getAndroidOptions());
  String? username = await securePrefs.read(key: "username");
  String? password = await securePrefs.read(key: "password");

  if (username == null || password == null) throw Exception("No username or password found");

  Map<String, String> authorizationHeaders = {
    "Authorization": "Basic " + base64Encode(utf8.encode("$username:$password")),
  };

  if (username.isEmpty || password.isEmpty) throw Exception("Username or Password is empty");

  http.Response response = await http.get(Uri.parse(url), headers: authorizationHeaders);

  if (response.statusCode == 401) throw const AuthorizationException("Ungültiger Nutzername oder Passwort");
  if (response.statusCode != 200) throw Exception("Unexpected response code ${response.statusCode}");
  return response;
}

class AuthorizationException implements Exception {
  final String msg;
  const AuthorizationException(this.msg);
  @override
  String toString() => msg;
}
