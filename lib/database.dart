//dart run build_runner build
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'main.dart';


part 'database.g.dart';

/// The single source of truth for the Isar schema list.
///
/// This MUST be identical everywhere `Isar.open` is called. The background
/// fetch headless task runs in a second FlutterEngine inside the *same*
/// process, so opening the default instance with a different set of schemas
/// than the main isolate used will fail.
final List<CollectionSchema<dynamic>> isarSchemas = [
  VertretungSchema,
  StundeSchema,
  ColorPaletteSchema,
  NewsSchema,
  KonfigurationSchema,
];

/// A single saved "Klasse/Kurse" profile (e.g. "Tom" -> Klasse 5A, or
/// "Max" -> Q1 with a specific set of Kurse). The user can have any number
/// of these; each gets its own live Stundenplan view.
@Collection()
class Konfiguration {
  late Id id = Isar.autoIncrement;

  /// Display name the user picked for this profile, e.g. "Tom".
  late String name;

  /// The Klasse (e.g. "5A") or Oberstufen-Stufe (e.g. "Q1") this profile is based on.
  late String stufe;

  late bool isOberstufe;

  /// Selected Kurs-Kürzel for Oberstufe profiles. Empty for Klassen (the whole Klasse applies).
  List<String> kurse = [];

  late DateTime createdAt;

  /// Manual sort order in the settings list.
  int position = 0;

  /// millisecondsSinceEpoch of the last successful incremental Stundenplan update for this profile.
  int lastUpdateMillis = 0;

  /// The school-year (the calendar year school resumes, i.e. the end of the
  /// relevant Sommerferien) this Konfiguration was last confirmed/updated or
  /// explicitly dismissed for. Used to stop nagging once handled.
  int promotedForYear = 0;

  /// The school-year the fields below were last computed for. See promotion.dart.
  int promotionCheckedForYear = 0;

  /// Whether a Stundenplan for [promotionCheckedForYear] was found online the
  /// last time this was checked.
  bool promotionPlanReady = false;

  /// Suggested next Klasse/Stufe (e.g. "7A", "Q1"), null if none could be
  /// determined (e.g. already in the final Oberstufen-Jahrgang).
  String? promotionRecommendedStufe;
  bool promotionRecommendedIsOberstufe = false;

  // Sharing a Konfiguration between devices no longer goes through JSON -
  // see lib/share_link.dart for the compact `piusapp://` link format that
  // replaced it.
}

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

/// Strips a leading marker glyph from a raw Stundenplan line, e.g. the "*"
/// PDF-Untis prints in front of Differenzierungskurse (courses split into
/// language/level groups within one Klasse, e.g. "*F7 2 BSK 113"). Also
/// covers the case where `PdfTextExtractor` can't map that marker glyph to a
/// proper Unicode character (the source PDF embeds it as a small subset font
/// without a usable ToUnicode map) and instead emits a stray lowercase
/// letter glued onto the "*", e.g. "*yF7 2" - the real Fach-Kürzel always
/// starts at the first uppercase letter, so anything before that between a
/// leading "*" and it is junk from the marker glyph, never part of a real
/// Fach name.
String stripKursMarker(String name) => name.replaceFirst(RegExp(r'^\*[a-zäöüß]*(?=[A-ZÄÖÜ])'), '');

/// Splits a Stundenplan line like "M GK Meier 205" (Oberstufen-Kurs) or
/// "F7 2 BSK 113" (Sek-I-Differenzierungsgruppe) into its Fach-Kürzel - the
/// part that actually identifies the course, e.g. "M GK" or "F7 2" - versus
/// guessing purely from whether the Konfiguration is Oberstufe or not: a
/// line is always "<Fach-Kürzel> <Lehrkraft> <Raum>", and the Fach-Kürzel
/// itself is one word normally (e.g. "L7", "D", "GE") but two words whenever
/// there's an extra Kursart/Gruppen-Kennung in front of the teacher (e.g.
/// "GK"/"LK" in der Oberstufe, or the Gruppennummer "2"/"3" for
/// Differenzierungskurse) - which shows up simply as one extra
/// space-separated token, regardless of Stufe.
String kursKuerzel(String name) {
  List<String> tokens = stripKursMarker(name).split(" ");
  int fachTokens = tokens.length >= 4 ? 2 : 1;
  return tokens.take(fachTokens).join(" ");
}

/// Identifies one actual Kurs a student can pick, as opposed to [kursKuerzel]
/// which only identifies the Fach/Kursart shared by *all* parallel groups of
/// it. A line is always "<Fach-Kürzel> <Lehrkraft> <Raum>", and it's the
/// Lehrkraft that distinguishes separate parallel Kurse of the same
/// Fach-Kürzel (e.g. "GE G1 HDS 307" and "GE G1 PAF 307" are two different
/// Kurse taught by different Lehrkräfte, not one Kurs meeting in two rooms) -
/// only the trailing Raum varies between a single Kurs's own weekly
/// timeslots (e.g. "GE G1 HDS 307" and "GE G1 HDS 306"), so dropping just
/// that last token is what actually identifies "the same Kurs".
String kursGruppe(String name) {
  List<String> tokens = stripKursMarker(name).split(" ");
  if (tokens.length <= 1) return tokens.join(" ");
  return tokens.sublist(0, tokens.length - 1).join(" ");
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

  /// Which Konfiguration (saved profile) this lesson belongs to. 0 = unassigned/legacy.
  @Index()
  int konfigurationId = 0;

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
