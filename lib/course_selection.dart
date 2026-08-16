import 'package:PiusApp/pages/stundenplan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:isar_community/isar.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'connection.dart';
import 'database.dart';
import 'promotion.dart';

/// Small process-wide cache for the downloaded/parsed Klassen- und
/// Oberstufenpläne so that creating several Konfigurationen in a row (or
/// reopening this flow shortly after) doesn't re-download and re-parse the
/// PDFs every time. This is the main lever for keeping the flow feeling
/// instant.
///
/// There are two independently cached "vintages" of the same two plans,
/// because the normal create/edit flow and the Schuljahreswechsel-flow need
/// genuinely different documents:
///
/// * `newest: false` -> [getCurrentStundenplaene], the plan that is valid
///   *today*. Right for creating or editing a Konfiguration during the school
///   year: what you pick is what you immediately see in your Stundenplan.
/// * `newest: true`  -> [getNewestAvailablePlan], the newest *published* plan
///   even if it only takes effect after the Sommerferien. This is the entire
///   point of the Klasse/Stufe-Wechsel: during that window the currently
///   valid plan is still last year's, so picking e.g. "Q1" out of it would
///   offer last year's Q1 Kurse (different Kursangebot, different Lehrkräfte)
///   and save a Konfiguration built on the wrong document.
class _StundenplaeneCache {
  _StundenplaeneCache._(this.newest);

  static final Map<bool, _StundenplaeneCache> _instances = {};

  /// The shared cache for the requested plan vintage.
  static _StundenplaeneCache of({required bool newest}) => _instances.putIfAbsent(newest, () => _StundenplaeneCache._(newest));

  /// Drops every cached plan, so the next flow re-downloads from scratch.
  /// Used by the Schuljahreswechsel-Test, which must not be served PDFs that
  /// were cached before the simulated state was written.
  static void invalidateAll() => _instances.clear();

  final bool newest;

  PdfDocument? klassenplan;
  PdfDocument? oberstufenplan;
  List<String> klassen = [];
  List<String> oberstufen = [];
  DateTime? fetchedAt;
  Future<void>? _inflight;

  bool get isFresh => fetchedAt != null && DateTime.now().difference(fetchedAt!) < const Duration(minutes: 15);

  Future<void> ensureLoaded({bool forceRefresh = false}) {
    if (!forceRefresh && isFresh) return Future.value();
    return _inflight ??= _load().whenComplete(() => _inflight = null);
  }

  Future<void> _load() async {
    PdfDocument? kp;
    PdfDocument? op;
    if (newest) {
      // Fetched independently because either half may legitimately be missing:
      // the school doesn't necessarily publish the Klassen- and the
      // Oberstufenplan for the new year on the same day. getStufen/
      // getStundenPlan both treat a null plan as "no Stufen", so a missing
      // half simply shows up as an empty section in the picker.
      kp = (await getNewestAvailablePlan(isOberstufe: false).timeout(const Duration(seconds: 60)))?.$1;
      op = (await getNewestAvailablePlan(isOberstufe: true).timeout(const Duration(seconds: 60)))?.$1;
      if (kp == null && op == null) throw Exception("Keine veröffentlichten Stundenpläne gefunden");
    } else {
      // Downloading both Stundenplan-PDFs over a slow connection can genuinely
      // take a while - 25s was cutting it too close and turned "a bit slow"
      // into "always fails".
      (kp, op) = await getCurrentStundenplaene().timeout(const Duration(seconds: 60));
    }
    List<String> k = await compute(getStufen, kp).timeout(const Duration(seconds: 60));
    List<String> o = await compute(getStufen, op).timeout(const Duration(seconds: 60));
    klassenplan = kp;
    oberstufenplan = op;
    klassen = k;
    oberstufen = o;
    fetchedAt = DateTime.now();
  }
}

/// Throws away every cached Stundenplan-PDF, so the next [CourseSelection]
/// downloads fresh ones. Only needed by the Schuljahreswechsel-Test, which
/// would otherwise be served plans cached before the simulated state existed.
void invalidateStundenplanCache() => _StundenplaeneCache.invalidateAll();

/// Modern, minimal-waiting create/edit flow for a single Konfiguration
/// (a named Klasse/Kurs profile). Three lightweight steps in one Scaffold:
/// 1. pick a Klasse/Stufe (instant search over an already-prefetched list)
/// 2. for Oberstufen-Stufen: tap your Kurse in a compact day view
/// 3. name it and save
class CourseSelection extends StatefulWidget {
  const CourseSelection({
    super.key,
    required this.isar,
    this.editing,
    this.recommendedStufe,
    this.recommendedIsOberstufe,
    this.useNewestPlan = false,
  });

  final Isar isar;

  /// If set, this Konfiguration is edited in place instead of a new one being created.
  final Konfiguration? editing;

  /// When set, the flow jumps straight past the Stufe-picker to this Stufe
  /// (still reachable via the back button for a manual pick instead). Used
  /// for the automatic Sommerferien-Wechsel recommendation.
  final String? recommendedStufe;
  final bool? recommendedIsOberstufe;

  /// Read the Klassen/Stufen, Kurse and Stunden from the newest *published*
  /// Stundenplan instead of the one valid today. Only the Schuljahreswechsel
  /// flow sets this: during the Wechsel-Fenster the currently valid plan is
  /// still last year's, so everything picked here has to come from next
  /// year's document instead. See [_StundenplaeneCache].
  final bool useNewestPlan;

  @override
  State<CourseSelection> createState() => _CourseSelectionState();
}

class _CourseSelectionState extends State<CourseSelection> {
  late final _StundenplaeneCache _plaene = _StundenplaeneCache.of(newest: widget.useNewestPlan);

  int step = 0;
  bool loadingStufen = true;
  bool loadingKurse = false;
  bool saving = false;
  String? error;
  String search = "";

  String? selectedStufe;
  bool isOberstufe = false;
  List<Stunde> stundenFuerStufe = [];
  Map<Stunde, bool> activeStunden = {};

  // Tracks which days of the Kurse-picker calendar the user has actually
  // swiped through, so "Weiter" can require seeing the whole ungerade Woche
  // plus at least the first day of the gerade Woche before it's enabled.
  DateTime? kalenderStart;
  DateTime? currentTag;
  Set<DateTime> visitedTage = {};

  // The date _KursCalendar should be freshly mounted at. Deliberately *not*
  // driven through CalendarController.forward()/displayDate: Syncfusion's
  // programmatic navigation left the newly shown page's appointments
  // unrendered (blank) until a manual swipe forced a fresh layout, for both
  // the weekend-skip and the "Nächster Tag" button. Changing this and
  // re-keying _KursCalendar instead fully remounts the calendar at the
  // target date, which is the same code path as the very first (correctly
  // rendered) mount - so it can't hit that stale-render bug.
  DateTime? _kalenderAnzeigeDatum;

  // Klassen (non-Oberstufe) have no Kurse-Auswahl step to piggy-back the
  // parse on, so as soon as a Klasse is picked in step 0 we kick the PDF
  // parse off in the background right away instead of waiting for
  // "Erstellen" - by the time the user has typed a name on step 2 it's
  // usually already done. Uses the exact same `getStundenPlan` call with the
  // exact same arguments as before, just started earlier; the output is
  // identical, only the timing changes. Keyed by Stufe so switching to a
  // different Klasse (e.g. via the back button) doesn't reuse a stale result.
  String? _precomputedKlassenStufe;
  Future<List<Stunde>>? _precomputedKlassenStunden;

  late TextEditingController nameController;
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.editing?.name ?? "");
    searchController = TextEditingController();
    if (widget.editing != null) {
      selectedStufe = widget.editing!.stufe;
      isOberstufe = widget.editing!.isOberstufe;
    }
    _load();
  }

  @override
  void dispose() {
    nameController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _load() async {
    setState(() {
      loadingStufen = true;
      error = null;
    });
    try {
      await _plaene.ensureLoaded();
      if (!mounted) return;
      setState(() => loadingStufen = false);
      if (widget.recommendedStufe != null) {
        // Land straight on the recommended Stufe's next step; "andere Stufe"
        // is still one tap away via the back button.
        _selectStufe(widget.recommendedStufe!, widget.recommendedIsOberstufe ?? false);
      } else if (selectedStufe != null && isOberstufe) {
        _loadKurseForSelectedStufe();
      }
    } catch (e) {
      // Printed for debugging only - showing the raw exception text to the
      // user (timeouts, PDF parsing internals, ...) isn't helpful to them.
      if (kDebugMode) print("[CourseSelection] Konnte Stundenpläne nicht abrufen: $e");
      if (!mounted) return;
      setState(() {
        loadingStufen = false;
        error = "Konnte Stundenpläne nicht abrufen. Prüfe deine Internetverbindung und versuche es erneut.";
      });
    }
  }

  void _loadKurseForSelectedStufe() async {
    setState(() {
      loadingKurse = true;
      error = null;
    });
    try {
      List<Stunde> stunden = await compute(getStundenPlan, (selectedStufe!, _plaene.oberstufenplan, true))
          .timeout(const Duration(seconds: 60));

      // Try to carry over the previous selection so editing/promoting mostly
      // just needs a review instead of a full reselect. Match by exact lesson
      // name first (same Stufe, nothing changed), and fall back to matching
      // just "Fach Kursart" (e.g. "M GK") when the Stufe itself changed, as it
      // does on every Oberstufen-Wechsel (EF -> Q1 -> Q2), since the room/
      // teacher after the "Fach Kursart" prefix is expected to differ there.
      Set<String> oldNames = widget.editing?.kurse.toSet() ?? <String>{};
      Set<String> oldPrefixes = oldNames.map(kursKuerzel).toSet();

      DateTime start = DateTime.now()
          .subtract(Duration(days: DateTime.now().weekday - 1, hours: DateTime.now().hour, minutes: DateTime.now().minute));
      if (stunden.isNotEmpty && start.isBefore(stunden.first.gueltigAb)) {
        DateTime firstTime = stunden.first.gueltigAb;
        start = firstTime.add(const Duration(days: 7)).subtract(Duration(days: firstTime.weekday - 1, hours: firstTime.hour, minutes: firstTime.minute));
      }
      start = DateTime(start.year, start.month, start.day);

      if (!mounted) return;
      setState(() {
        stundenFuerStufe = stunden;
        activeStunden = {
          for (var s in stunden) s: oldNames.contains(s.name) || oldPrefixes.contains(kursKuerzel(s.name)),
        };
        kalenderStart = start;
        _kalenderAnzeigeDatum = start;
        currentTag = start;
        visitedTage = {start};
        loadingKurse = false;
      });
    } catch (e) {
      if (kDebugMode) print("[CourseSelection] Konnte Kurse nicht laden: $e");
      if (!mounted) return;
      setState(() {
        loadingKurse = false;
        error = "Konnte Kurse nicht laden. Prüfe deine Internetverbindung und versuche es erneut.";
      });
    }
  }

  void _onVisibleTagChanged(DateTime date) {
    DateTime tag = DateTime(date.year, date.month, date.day);
    setState(() {
      currentTag = tag;
      visitedTage.add(tag);
    });
  }

  /// The five weekdays of whichever of the two shown weeks is the "ungerade" one.
  List<DateTime> get _ungeradeWochentage {
    if (kalenderStart == null) return const [];
    bool week1Gerade = weekNumber(kalenderStart!) % 2 == 0;
    DateTime ungeradeMontag = week1Gerade ? kalenderStart!.add(const Duration(days: 7)) : kalenderStart!;
    return [for (int i = 0; i < 5; i++) ungeradeMontag.add(Duration(days: i))];
  }

  DateTime? get _geradeMontag {
    if (kalenderStart == null) return null;
    bool week1Gerade = weekNumber(kalenderStart!) % 2 == 0;
    return week1Gerade ? kalenderStart! : kalenderStart!.add(const Duration(days: 7));
  }

  bool get _ungeradeWocheGesehen => _ungeradeWochentage.isNotEmpty && _ungeradeWochentage.every((d) => visitedTage.contains(d));

  // Deliberately does NOT fall back to "true" when kalenderStart is still
  // null - that used to let "Weiter" through while the Kurse list had failed
  // or hadn't finished loading yet, silently saving a Konfiguration with no
  // courses at all.
  bool get _kurseWeiterFreigegeben =>
      error == null &&
      kalenderStart != null &&
      stundenFuerStufe.isNotEmpty &&
      _ungeradeWocheGesehen &&
      _geradeMontag != null &&
      visitedTage.contains(_geradeMontag);

  // "Nächster Tag" normally; on the last weekday (Freitag) of whichever week
  // is currently shown it becomes "Gerade Woche"/"Ungerade Woche" - naming
  // the week the button is about to jump into - since that's what a tap
  // there actually does (the weekend-skip in _KursCalendarState.onViewChanged
  // means one forward() from Freitag already lands on the following Montag).
  String get _naechsterTagLabel {
    DateTime? tag = currentTag;
    if (tag == null || tag.weekday != DateTime.friday) return "Nächster Tag";
    bool geradeWoche = weekNumber(tag) % 2 == 0;
    return geradeWoche ? "Ungerade Woche" : "Gerade Woche";
  }

  void _goToNaechsterTag() {
    DateTime? tag = currentTag;
    if (tag == null) return;
    _springeZu(_naechsterWochentag(tag));
  }

  /// [tag] plus one day, skipping straight over Samstag/Sonntag.
  DateTime _naechsterWochentag(DateTime tag) {
    DateTime next = tag.add(const Duration(days: 1));
    if (next.weekday == DateTime.saturday) return next.add(const Duration(days: 2));
    if (next.weekday == DateTime.sunday) return next.add(const Duration(days: 1));
    return next;
  }

  /// Remounts _KursCalendar at [datum] (see _kalenderAnzeigeDatum) instead of
  /// driving the existing instance via its controller.
  void _springeZu(DateTime datum) => setState(() => _kalenderAnzeigeDatum = datum);

  void _selectStufe(String stufe, bool oberstufe) {
    setState(() {
      selectedStufe = stufe;
      isOberstufe = oberstufe;
      if (nameController.text.trim().isEmpty) nameController.text = stufe;
    });
    if (oberstufe) {
      setState(() => step = 1);
      _loadKurseForSelectedStufe();
    } else {
      setState(() => step = 2);
      // Fire-and-forget: same compute() call _save() would otherwise only
      // start once "Erstellen" is tapped, just moved earlier so it overlaps
      // with the user typing a name instead of blocking them at the end.
      _precomputedKlassenStufe = stufe;
      Future<List<Stunde>> vorab = compute(getStundenPlan, (stufe, _plaene.klassenplan, false));
      // Attach a listener immediately so that a failing precompute (e.g. the
      // recommended Klasse doesn't exist in this plan after all) doesn't blow
      // up as an unhandled async error in the seconds before _save() awaits
      // it. The error is still delivered to whoever awaits `vorab`, so the
      // error handling in _save() is unchanged.
      vorab.then((_) {}, onError: (_) {});
      _precomputedKlassenStunden = vorab;
    }
  }

  Future<void> _save() async {
    if (selectedStufe == null) return;

    List<Stunde> ausgewaehlt = activeStunden.entries.where((e) => e.value).map((e) => e.key).toList();
    // Belt-and-braces: never persist an Oberstufe-Konfiguration with no
    // courses at all, even if some future change reintroduces a way to reach
    // this step without a completed Kurse-Auswahl.
    if (isOberstufe && ausgewaehlt.isEmpty) {
      setState(() => error = "Bitte wähle mindestens einen Kurs aus, bevor du speicherst.");
      return;
    }
    // With useNewestPlan the two halves are fetched separately and either may
    // be missing (the school publishes them on different days). Without this
    // guard getStundenPlan would quietly return an empty list for a null plan
    // and we'd save a Konfiguration with no Stunden at all.
    if (!isOberstufe && _plaene.klassenplan == null) {
      setState(() => error = "Für diese Klasse ist noch kein Stundenplan verfügbar. Versuche es später erneut.");
      return;
    }

    setState(() {
      saving = true;
      error = null;
    });
    Konfiguration konfiguration = widget.editing ??
        (Konfiguration()
          ..createdAt = DateTime.now()
          ..position = widget.isar.konfigurations.where().countSync());
    konfiguration
      ..name = nameController.text.trim().isEmpty ? selectedStufe! : nameController.text.trim()
      ..stufe = selectedStufe!
      ..isOberstufe = isOberstufe
      ..kurse = isOberstufe ? (ausgewaehlt.map((s) => s.name).toSet().toList()) : <String>[];

    try {
      if (isOberstufe) {
        // The Kurse-Auswahl step already parsed and holds the exact Stunden
        // for this Stufe - reuse them instead of parsing the PDF a second
        // time, which used to be what made saving feel slow (or hang).
        await saveKonfigurationWithStunden(widget.isar, konfiguration, ausgewaehlt).timeout(const Duration(seconds: 60));
      } else {
        // Reuse the parse kicked off in the background back in _selectStufe
        // if it's for the same Klasse (the common case - it was usually
        // already finished by the time the user got here). Only falls back
        // to parsing now if that precompute is missing or stale, e.g. when
        // editing jumps straight past step 0. Either way this is the exact
        // same getStundenPlan() call _save() always made, so the result is
        // identical - only *when* the parse happens changed.
        List<Stunde> stunden = await (_precomputedKlassenStufe == selectedStufe && _precomputedKlassenStunden != null
                ? _precomputedKlassenStunden!
                : compute(getStundenPlan, (selectedStufe!, _plaene.klassenplan, false)))
            .timeout(const Duration(seconds: 60));
        await saveKonfigurationWithStunden(widget.isar, konfiguration, stunden).timeout(const Duration(seconds: 60));
      }
      if (mounted) Navigator.of(context).pop(konfiguration);
    } catch (e) {
      if (kDebugMode) print("[CourseSelection] Konnte Konfiguration nicht speichern: $e");
      if (!mounted) return;
      setState(() {
        saving = false;
        error = "Konnte Stundenplan nicht speichern. Prüfe deine Internetverbindung und versuche es erneut.";
      });
    }
  }

  /// Back navigation for the AppBar arrow: one wizard step back, and only
  /// leave the flow entirely from the first step.
  ///
  /// Step 2 for a Klasse used to pop the whole page instead, which made
  /// "andere Klasse/Stufe wählen" unreachable in the Schuljahreswechsel flow:
  /// there [widget.recommendedStufe] skips step 0 and drops a Klasse straight
  /// onto step 2, so the picker the docs promise is "still one tap away via
  /// the back button" had in fact never been shown and couldn't be reached.
  void _goBack() {
    if (step == 0) return Navigator.of(context).pop();
    setState(() => step = (step == 2 && isOberstufe) ? 1 : 0);
  }

  @override
  Widget build(BuildContext context) {
    List<String> titles = ["Klasse/Stufe wählen", "Kurse wählen", "Benennen & speichern"];

    // While a save is in flight, block both the custom back arrow and the
    // OS/gesture back button - leaving mid-save used to be how a Konfiguration
    // could end up looking "saved" while actually incomplete.
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(titles[step]),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: saving ? null : _goBack,
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: switch (step) {
            0 => _buildStufeStep(context),
            1 => _buildKurseStep(context),
            _ => _buildNameStep(context),
          },
        ),
      ),
    );
  }

  Widget _buildStufeStep(BuildContext context) {
    List<String> klassen = _plaene.klassen;
    List<String> oberstufen = _plaene.oberstufen;

    bool matches(String s) => search.isEmpty || s.toLowerCase().contains(search.toLowerCase());
    List<String> filteredKlassen = klassen.where(matches).toList();
    List<String> filteredOberstufen = oberstufen.where(matches).toList();

    if (error != null) return _buildStufeError(context);

    return Column(
      key: const ValueKey("stufe"),
      children: [
        // The Stufen listed here are the ones from *next* year's plan, which
        // can differ from what the app currently shows in the Stundenplan -
        // say so rather than letting it look like a glitch.
        if (widget.useNewestPlan)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Icon(Icons.event_available, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Auswahl aus dem Stundenplan fürs neue Schuljahr",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: searchController,
            onChanged: (value) => setState(() => search = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: "Klasse oder Kurs-Stufe suchen…",
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: loadingStufen
              ? _StufenSkeletonList()
              : ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    if (filteredKlassen.isNotEmpty) _sectionHeader(context, "Klassen"),
                    for (final klasse in filteredKlassen)
                      _StufeTile(
                        title: klasse,
                        icon: Icons.people_outline,
                        selected: selectedStufe == klasse && !isOberstufe,
                        onTap: () => _selectStufe(klasse, false),
                      ),
                    if (filteredOberstufen.isNotEmpty) _sectionHeader(context, "Oberstufe"),
                    for (final stufe in filteredOberstufen)
                      _StufeTile(
                        title: stufe,
                        icon: Icons.school_outlined,
                        selected: selectedStufe == stufe && isOberstufe,
                        onTap: () => _selectStufe(stufe, true),
                      ),
                    if (!loadingStufen && filteredKlassen.isEmpty && filteredOberstufen.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text("Keine Treffer für \"$search\"", textAlign: TextAlign.center),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStufeError(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Center(
      key: const ValueKey("stufe-error"),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.errorContainer),
              child: Icon(Icons.cloud_off_outlined, size: 40, color: colorScheme.onErrorContainer),
            ),
            const SizedBox(height: 20),
            Text("Das hat nicht geklappt", style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(error!, textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text("Erneut versuchen"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );

  Widget _buildKurseStep(BuildContext context) {
    DateTime? tag = currentTag ?? kalenderStart;
    bool geradeWoche = tag != null && weekNumber(tag) % 2 == 0;
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      key: const ValueKey("kurse"),
      children: [
        if (tag != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE', "de_DE").format(tag),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: geradeWoche ? colorScheme.tertiaryContainer : colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    geradeWoche ? "Gerade Woche" : "Ungerade Woche",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: geradeWoche ? colorScheme.onTertiaryContainer : colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              if (kalenderStart != null && _kalenderAnzeigeDatum != null)
                _KursCalendar(
                  key: ValueKey("$selectedStufe|$_kalenderAnzeigeDatum"),
                  stunden: stundenFuerStufe,
                  activeStunden: activeStunden,
                  initialDisplayDate: _kalenderAnzeigeDatum!,
                  // The two-week window (min/maxDate) has to stay anchored to
                  // the original start regardless of which day we're
                  // currently remounted at, otherwise every jump would shift
                  // the whole window along with it.
                  fensterStart: kalenderStart!,
                  onVisibleDateChanged: _onVisibleTagChanged,
                  onWeekendReached: _springeZu,
                  onToggle: (stunde, active) => setState(() {
                    // Group by Fach+Kursart+Lehrkraft (kursGruppe), not just
                    // Fach+Kursart (kursKuerzel) - two parallel Kurse of the
                    // same Fach taught by different Lehrkräfte (e.g.
                    // "GE G1 HDS 307" vs "GE G1 PAF 307") are different
                    // Kurse a student picks one of, not the same Kurs.
                    String gruppe = kursGruppe(stunde.name);
                    List<Stunde> toToggle = stundenFuerStufe.where((element) => kursGruppe(element.name) == gruppe).toList();
                    for (Stunde s in toToggle) {
                      activeStunden[s] = active;
                    }
                  }),
                ),
              if (loadingKurse) const Center(child: CircularProgressIndicator()),
              if (error != null && !loadingKurse)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        const SizedBox(height: 8),
                        ElevatedButton(onPressed: _loadKurseForSelectedStufe, child: const Text("Erneut versuchen")),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: [
              // Fixed width so this button's position never shifts once
              // "Speichern" appears next to it - the user can keep tapping
              // in the same spot to move through the days.
              SizedBox(
                width: 180,
                child: FilledButton.icon(
                  onPressed: (loadingKurse || kalenderStart == null) ? null : _goToNaechsterTag,
                  icon: const Icon(Ionicons.arrow_forward),
                  label: Text(_naechsterTagLabel),
                ),
              ),
              if (_kurseWeiterFreigegeben) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => setState(() => step = 2),
                    icon: const Icon(Ionicons.checkmark),
                    label: const Text("Speichern"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNameStep(BuildContext context) {
    // Count distinct Kurse (e.g. "M GK Meier"), not the individual Stunde
    // rows - the same Kurs usually has several timeslots a week, which isn't
    // what someone means by "3 Kurse". Grouped by kursGruppe (Fach+Kursart+
    // Lehrkraft), not just Fach+Kursart, since two parallel Kurse of the same
    // Fach taught by different Lehrkräfte are separate Kurse.
    int kursCount = activeStunden.entries.where((e) => e.value).map((e) => kursGruppe(e.key.name)).toSet().length;
    return SingleChildScrollView(
      key: const ValueKey("name"),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.account_circle_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            isOberstufe ? "$selectedStufe · $kursCount Kurse" : "Klasse $selectedStufe",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: "Name dieses Stundenplans",
              hintText: "z.B. Mia, Tom, …",
              prefixIcon: Icon(Icons.sell_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          FilledButton.icon(
            onPressed: saving ? null : _save,
            icon: saving
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: Text(widget.editing != null ? "Speichern" : "Erstellen"),
          ),
        ],
      ),
    );
  }
}

class _StufeTile extends StatelessWidget {
  const _StufeTile({required this.title, required this.icon, required this.selected, required this.onTap});

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected ? colorScheme.primaryContainer : colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: TextStyle(color: selected ? colorScheme.onPrimaryContainer : null))),
                if (selected) Icon(Icons.check_circle, color: colorScheme.onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StufenSkeletonList extends StatefulWidget {
  @override
  State<_StufenSkeletonList> createState() => _StufenSkeletonListState();
}

class _StufenSkeletonListState extends State<_StufenSkeletonList> {
  @override
  Widget build(BuildContext context) {
    Color base = Theme.of(context).colorScheme.surfaceVariant;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      itemCount: 8,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.4, end: 1),
          duration: Duration(milliseconds: 700 + (index % 3) * 150),
          curve: Curves.easeInOut,
          onEnd: () {},
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Container(
              height: 52,
              decoration: BoxDecoration(color: base.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tap-to-toggle day calendar used to pick Oberstufen-Kurse. One day at a
/// time (like the original picker), swiping past Friday/before Monday skips
/// straight over the weekend.
class _KursCalendar extends StatefulWidget {
  const _KursCalendar({
    super.key,
    required this.stunden,
    required this.activeStunden,
    required this.initialDisplayDate,
    required this.fensterStart,
    required this.onVisibleDateChanged,
    required this.onWeekendReached,
    required this.onToggle,
  });

  final List<Stunde> stunden;
  final Map<Stunde, bool> activeStunden;
  final DateTime initialDisplayDate;
  // Fixed anchor for the two-week min/maxDate window, independent of
  // whichever day this particular instance happens to mount at (see
  // _CourseSelectionState._kalenderAnzeigeDatum).
  final DateTime fensterStart;
  final void Function(DateTime date) onVisibleDateChanged;
  // Called (with the target weekday to jump to) instead of driving the
  // calendar's own controller - see _kalenderAnzeigeDatum for why.
  final void Function(DateTime target) onWeekendReached;
  final void Function(Stunde stunde, bool active) onToggle;

  @override
  State<_KursCalendar> createState() => _KursCalendarState();
}

class _KursCalendarState extends State<_KursCalendar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onVisibleDateChanged(widget.initialDisplayDate));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stunden.isEmpty) return const SizedBox.shrink();
    CalendarDataSource dataSource = getCalendarDataSourceFromStunden(stunden: widget.stunden, realTime: false);

    return SfCalendar(
      initialDisplayDate: widget.initialDisplayDate,
      view: CalendarView.day,
      onViewChanged: (details) {
        // Syncfusion fires the *first* onViewChanged synchronously from
        // inside the calendar's own initState/layout, before the widget tree
        // is done building - calling setState (via onVisibleDateChanged) on
        // an ancestor right then throws "setState() called during build" and
        // can corrupt the element tree. Deferring to the next frame is
        // Syncfusion's own recommended workaround and doesn't change what
        // gets reported, just when.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onVisibleDateChanged(details.visibleDates.first);
        });
        DateTime shown = details.visibleDates.first;
        if (shown.weekday != DateTime.saturday && shown.weekday != DateTime.sunday) return;
        // Report the weekend hit upward instead of driving this calendar's
        // own controller (forward()/backward()/displayDate all left the
        // newly shown page's appointments unrendered - blank - until a
        // manual swipe forced a fresh layout). The parent responds by
        // remounting a brand new _KursCalendar at the target date, which is
        // the same code path as this widget's very first (correctly
        // rendered) mount, so it can't hit that stale-render bug.
        DateTime target =
            shown.weekday == DateTime.saturday ? shown.add(const Duration(days: 2)) : shown.subtract(const Duration(days: 2));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onWeekendReached(target);
        });
      },
      dataSource: dataSource,
      allowViewNavigation: false,
      showCurrentTimeIndicator: false,
      todayHighlightColor: Colors.transparent,
      showTodayButton: false,
      showWeekNumber: true,
      // Hides Syncfusion's own built-in "August 2026 Woche 33" header bar -
      // the custom weekday/gerade-ungerade header above the calendar already
      // covers that, so this would just be a redundant second row.
      headerHeight: 0,
      // Hides the calendar's own day-name/date row (and the all-day-events
      // strip that ships with it) - same reasoning, it's redundant with the
      // custom header, and there are no all-day appointments to show anyway.
      viewHeaderHeight: 0,
      appointmentBuilder: (context, calendarAppointmentDetails) {
        Appointment appointment = calendarAppointmentDetails.appointments.first as Appointment;
        Stunde stunde = widget.stunden.firstWhere((element) => element.name == appointment.subject);
        bool active = widget.activeStunden[stunde] ?? false;
        ColorScheme colorScheme = Theme.of(context).colorScheme;
        return GestureDetector(
          onTap: () => widget.onToggle(stunde, !active),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.primaryContainer),
              color: active ? colorScheme.primaryContainer : colorScheme.surface,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
            width: calendarAppointmentDetails.bounds.width,
            height: calendarAppointmentDetails.bounds.height,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Text(appointment.subject, textAlign: TextAlign.center),
              ),
            ),
          ),
        );
      },
      timeSlotViewSettings: const TimeSlotViewSettings(timeFormat: "HH", startHour: 0, endHour: 12, timeIntervalHeight: 80),
      viewHeaderStyle: const ViewHeaderStyle(dateTextStyle: TextStyle(color: Colors.transparent, fontSize: 0)),
      minDate: widget.fensterStart,
      maxDate: widget.fensterStart.add(const Duration(days: 12)).subtract(const Duration(minutes: 1)),
      selectionDecoration: const BoxDecoration(color: Colors.transparent, border: null),
    );
  }
}
