import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as DOM;
import 'package:html/parser.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'connection.dart';
import 'database.dart';

/// Everything needed to automatically suggest a Klasse/Stufe-Wechsel once
/// the Sommerferien start, without ever guessing at a Stundenplan that isn't
/// actually online yet.
///
/// The tricky bit this whole file works around: the school usually only
/// publishes next year's Stundenpläne roughly two weeks before it starts, so
/// for most of the Sommerferien there is nothing to recommend yet - we can
/// only detect "Sommerferien has started" and have to keep checking
/// (piggy-backing on the app's normal periodic Stundenplan/Termine refresh)
/// until a plan dated for the new year actually shows up.

/// Returns the (start, end) of the Sommerferien if "now" falls inside one,
/// based on the already-cached Pius-Termine (so this needs no network call).
(DateTime start, DateTime end)? currentSommerferien(SharedPreferences prefs) {
  List<dynamic> raw = jsonDecode(prefs.getString("piusTermine") ?? "[]");
  List<Appointment> termine = raw.map((e) => appointmentFromMap(Map<String, dynamic>.from(e))).toList();
  List<Appointment> sommerferien = termine.where((e) => e.subject.toLowerCase().contains("sommerferien")).toList();
  DateTime now = DateTime.now();
  for (Appointment s in sommerferien) {
    if (!now.isBefore(s.startTime) && now.isBefore(s.endTime)) return (s.startTime, s.endTime);
  }
  return null;
}

/// Fetches the Stundenplan-Übersichtsseite and returns the *newest*
/// available Klassen- or Oberstufenplan by "gültig ab", together with that
/// date - regardless of whether it has taken effect yet. Unlike
/// [getCurrentStundenplaene] (which deliberately only ever resolves to the
/// plan that is valid *today*), this is what lets us see a next-year plan
/// that has already been published but doesn't start until after the
/// Sommerferien.
Future<(PdfDocument plan, DateTime gueltigAb)?> getNewestAvailablePlan({required bool isOberstufe}) async {
  DOM.Document document = parse(await getStundenplanWebsite());
  List<(DateTime starting, DateTime updated, bool oberstufe, String url)> links = await getStundenplanLinks(document);
  links = links.where((e) => e.$3 == isOberstufe).toList();
  if (links.isEmpty) return null;
  links.sort((a, b) => -a.$1.compareTo(b.$1));
  var newest = links.first;
  return (PdfDocument(inputBytes: (await getSecuredPage(newest.$4)).bodyBytes), newest.$1);
}

/// This school's actual Sek-I/Oberstufe structure: lettered Klassen 5-10,
/// then the unlettered Oberstufe EF -> Q1 -> Q2. Kept isolated here so it's
/// easy to adjust if that ever changes.
const List<String> _oberstufenReihenfolge = ["EF", "Q1", "Q2"];

/// Suggests the next Klasse/Stufe for [stufe], cross-checked against what
/// Stufen actually exist in the *newly published* plan(s) so we never
/// recommend something that doesn't exist. Returns null if nothing sensible
/// can be determined (e.g. already in the final Oberstufen-Jahrgang, or the
/// relevant new plan category isn't available/checked).
String? recommendNextStufe({
  required String stufe,
  required bool isOberstufe,
  required List<String> newKlassen,
  required List<String> newOberstufen,
}) {
  if (isOberstufe) {
    int i = _oberstufenReihenfolge.indexWhere((s) => s.toUpperCase() == stufe.trim().toUpperCase());
    if (i == -1 || i == _oberstufenReihenfolge.length - 1) return null; // unknown, or already the final Jahrgang
    String next = _oberstufenReihenfolge[i + 1];
    return newOberstufen.contains(next) ? next : null;
  }

  String? candidate = _naechsteKlasse(stufe);
  if (candidate == null) return null;
  if (newKlassen.contains(candidate)) return candidate; // still Sek I next year

  // No numeric successor among the Klassen -> assume the jump into die Oberstufe.
  if (newOberstufen.contains("EF")) return "EF";
  return null;
}

/// The numeric successor of a Sek-I-Klasse, e.g. "9A" -> "10A". Null if
/// [stufe] isn't a Klassenname at all.
String? _naechsteKlasse(String stufe) {
  Match? m = RegExp(r'^(\d+)([A-Za-z]*)$').firstMatch(stufe.trim());
  if (m == null) return null;
  return "${int.parse(m.group(1)!) + 1}${m.group(2) ?? ""}";
}

/// Runs during the normal periodic refresh (see main.dart). No-op outside
/// Sommerferien, and cheap (just cached Termine, no network) the rest of the
/// year. During Sommerferien it checks - at most once per refresh cycle -
/// whether a new-year Stundenplan is already online, and if so, computes and
/// caches a recommendation on each affected Konfiguration for Settings to show.
Future<void> checkPromotions(Isar isar, SharedPreferences prefs) async {
  var sommerferien = currentSommerferien(prefs);
  if (sommerferien == null) return;
  int year = sommerferien.$2.year;

  List<Konfiguration> konfigurationen = isar.konfigurations.where().findAllSync()
    ..removeWhere((k) => k.promotedForYear >= year);
  if (konfigurationen.isEmpty) return;

  bool needKlassen = konfigurationen.any((k) => !k.isOberstufe);

  bool klasseReady = false;
  bool oberstufeReady = false;
  List<String> newKlassen = [];
  List<String> newOberstufen = [];

  try {
    if (needKlassen) {
      var result = await getNewestAvailablePlan(isOberstufe: false);
      if (result != null && !result.$2.isBefore(sommerferien.$1)) {
        klasseReady = true;
        newKlassen = await compute(getStufen, result.$1);
      }
    }

    // The Oberstufenplan is needed for existing Oberstufen-Konfigurationen -
    // and also for a Sek-I-Konfiguration whose numeric successor no longer
    // exists in the new Klassenplan, i.e. exactly the Klasse-10 -> EF jump.
    // Deciding that *after* newKlassen is known mirrors recommendNextStufe
    // one-to-one; the old `konfigurationen.any((k) => k.isOberstufe)` meant a
    // student without any Oberstufen-Konfiguration never had newOberstufen
    // populated, so the 10 -> EF Wechsel was silently never recommended.
    bool needOberstufe = konfigurationen.any((k) => k.isOberstufe) ||
        (klasseReady &&
            konfigurationen.any((k) {
              if (k.isOberstufe) return false;
              String? naechste = _naechsteKlasse(k.stufe);
              return naechste != null && !newKlassen.contains(naechste);
            }));

    if (needOberstufe) {
      var result = await getNewestAvailablePlan(isOberstufe: true);
      if (result != null && !result.$2.isBefore(sommerferien.$1)) {
        oberstufeReady = true;
        newOberstufen = await compute(getStufen, result.$1);
      }
    }
  } catch (e) {
    // Typically: nothing published yet, or a transient network error. Either
    // way just try again on the next periodic refresh - don't overwrite any
    // previously cached (possibly already-ready) state with a failure.
    if (kDebugMode) print("[Promotion] Konnte neue Stundenpläne noch nicht prüfen: $e");
    return;
  }

  for (Konfiguration konfiguration in konfigurationen) {
    bool ready = konfiguration.isOberstufe ? oberstufeReady : klasseReady;
    konfiguration.promotionCheckedForYear = year;
    konfiguration.promotionPlanReady = ready;
    konfiguration.promotionRecommendedStufe = null;
    konfiguration.promotionRecommendedIsOberstufe = false;
    if (ready) {
      String? empfehlung = recommendNextStufe(
        stufe: konfiguration.stufe,
        isOberstufe: konfiguration.isOberstufe,
        newKlassen: newKlassen,
        newOberstufen: newOberstufen,
      );
      if (empfehlung != null) {
        konfiguration.promotionRecommendedStufe = empfehlung;
        konfiguration.promotionRecommendedIsOberstufe = newOberstufen.contains(empfehlung);
      }
    }
  }

  await isar.writeTxn(() async {
    await isar.konfigurations.putAll(konfigurationen);
  });
}

/// Debug-only: forces every Konfiguration into the "a new Stundenplan is
/// online, you can switch now" state so the whole Schuljahreswechsel flow can
/// be exercised outside the Sommerferien.
///
/// Deliberately *not* faked end-to-end: the Stufen and the recommendation are
/// computed from the plans that are actually published right now, using the
/// same [getNewestAvailablePlan] + [recommendNextStufe] the real
/// [checkPromotions] uses. Only the two conditions that can't be arranged on
/// demand are bypassed - that it's currently Sommerferien, and that the newest
/// plan is dated after it started. So a test run exercises the real
/// recommendation logic, the real PDFs and the real switch, and the only
/// untested part is the calendar gate.
///
/// Note that the simulated year is deliberately one *ahead* of any real one,
/// so tapping "Später" during a test would also suppress that future year's
/// real prompt on this install - run [resetPromotionsForTesting] afterwards.
///
/// Returns a short human-readable summary of what it set up, for the SnackBar.
Future<String> simulatePromotionForTesting(Isar isar) async {
  List<Konfiguration> konfigurationen = isar.konfigurations.where().findAllSync();
  if (konfigurationen.isEmpty) return "Keine Stundenpläne vorhanden.";

  // Pretend the upcoming (or current) Sommerferien is the one being handled,
  // so promotionCheckedForYear lands one ahead of promotedForYear for every
  // Konfiguration - including ones already promoted this calendar year.
  int year = konfigurationen.map((k) => k.promotedForYear).fold(DateTime.now().year, (a, b) => a > b ? a : b) + 1;

  var klassenResult = await getNewestAvailablePlan(isOberstufe: false);
  var oberstufenResult = await getNewestAvailablePlan(isOberstufe: true);
  List<String> newKlassen = klassenResult == null ? [] : await compute(getStufen, klassenResult.$1);
  List<String> newOberstufen = oberstufenResult == null ? [] : await compute(getStufen, oberstufenResult.$1);

  List<String> summary = [];
  for (Konfiguration konfiguration in konfigurationen) {
    konfiguration.promotionCheckedForYear = year;
    konfiguration.promotionPlanReady = true;
    String? empfehlung = recommendNextStufe(
      stufe: konfiguration.stufe,
      isOberstufe: konfiguration.isOberstufe,
      newKlassen: newKlassen,
      newOberstufen: newOberstufen,
    );
    konfiguration.promotionRecommendedStufe = empfehlung;
    konfiguration.promotionRecommendedIsOberstufe = empfehlung != null && newOberstufen.contains(empfehlung);
    summary.add("${konfiguration.name}: ${konfiguration.stufe} -> ${empfehlung ?? "keine Empfehlung"}");
  }

  await isar.writeTxn(() async {
    await isar.konfigurations.putAll(konfigurationen);
  });
  return summary.join(", ");
}

/// Debug-only counterpart to [simulatePromotionForTesting]: clears the
/// simulated state again so the app stops offering the Wechsel. Note that
/// actually going through with a test Wechsel really does rewrite that
/// Konfiguration's Stufe and Kurse - this only removes the prompt, it can't
/// undo the switch itself.
Future<void> resetPromotionsForTesting(Isar isar) async {
  List<Konfiguration> konfigurationen = isar.konfigurations.where().findAllSync();
  for (Konfiguration konfiguration in konfigurationen) {
    konfiguration.promotionCheckedForYear = 0;
    konfiguration.promotedForYear = 0;
    konfiguration.promotionPlanReady = false;
    konfiguration.promotionRecommendedStufe = null;
    konfiguration.promotionRecommendedIsOberstufe = false;
  }
  await isar.writeTxn(() async {
    await isar.konfigurations.putAll(konfigurationen);
  });
}
