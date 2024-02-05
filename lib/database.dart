//dart run build_runner build
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'main.dart';


part 'database.g.dart';

@Collection()
class Vertretung {
  late Id id = Isar.autoIncrement;
  late String klasse;
  late List<int> stunden;
  late String art;
  late String kurs;
  late String raum;
  late String lehrkraft;
  late List<int> hervorgehoben;
  String? bemerkung;
  String? eva;
  late DateTime tag;

  String toJSON() {
    return jsonEncode({
      "klasse": klasse,
      "stunden": stunden.toString(),
      "art": art,
      "kurs": kurs,
      "raum": raum,
      "lehrkraft": lehrkraft,
      "hervorgehoben": hervorgehoben.toString(),
      "bemerkung": bemerkung,
      "eva": eva,
      "tag": tag.toIso8601String()
    });
  }

  Vertretung();

  Vertretung.fromMap(Map<String, dynamic> map) {
    klasse = map["klasse"];
    stunden = List<int>.from(jsonDecode(map["stunden"]));
    art = map["art"];
    kurs = map["kurs"];
    raum = map["raum"];
    lehrkraft = map["lehrkraft"];
    hervorgehoben = List<int>.from(jsonDecode(map["hervorgehoben"]));
    bemerkung = map["bemerkung"];
    eva = map["eva"];
    tag = DateTime.parse(map["tag"]);
  }
}

@Collection()
class Stunde {
  late Id id = Isar.autoIncrement;
  late String name;
  late int tag;
  late List<int> stunden;
  late bool geradeWoche;
  late DateTime gueltigAb;
  DateTime? gueltigBis;

  IsarLink<Vertretung> vertretung = IsarLink();
}

@Collection()
class News{
  late Id id;
  late String title;
  late String content;
  String? teaser;
  late DateTime created;
  String? imageUrl;
}

@Collection()
class ColorPalette {
  late Id id = Isar.autoIncrement;
  bool fromSeed = true;
  String? name;

  int? primaryR;
  int? primaryG;
  int? primaryB;

  int? secondaryR;
  int? secondaryG;
  int? secondaryB;

  int? tertiaryR;
  int? tertiaryG;
  int? tertiaryB;

  int? errorR;
  int? errorG;
  int? errorB;

  ColorScheme toColorScheme([bool darkMode = false]) {
    if (fromSeed) {
      return ColorScheme.fromSeed(
        seedColor: Color.fromARGB(255, primaryR!, primaryG!, primaryB!),
        brightness: darkMode ? Brightness.dark : Brightness.light,
      );
    } else {
      Color primaryColor = Color.fromARGB(255, primaryR!, primaryG!, primaryB!);
      Color secondaryColor = Color.fromARGB(255, secondaryR!, secondaryG!, secondaryB!);
      Color tertiaryColor = Color.fromARGB(255, tertiaryR!, tertiaryG!, tertiaryB!);
      Color errorColor = Color.fromARGB(255, errorR!, errorG!, errorB!);
      return ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        error: errorColor,
        brightness: darkMode ? Brightness.dark : Brightness.light,
      );
    }
  }

  VertretungsColors getExactColors() {
    Color primaryColor = Color.fromARGB(255, primaryR!, primaryG!, primaryB!);
    Color secondaryColor = Color.fromARGB(255, secondaryR!, secondaryG!, secondaryB!);
    Color tertiaryColor = Color.fromARGB(255, tertiaryR!, tertiaryG!, tertiaryB!);
    Color errorColor = Color.fromARGB(255, errorR!, errorG!, errorB!);
    return VertretungsColors(mainColor: primaryColor, headerColor: secondaryColor, evaColor: tertiaryColor, replacementColor: errorColor);
  }
}
