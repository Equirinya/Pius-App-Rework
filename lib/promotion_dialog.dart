import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';

import 'course_selection.dart';
import 'database.dart';

/// Fullscreen "your Stundenplan(e) for next year are online" popup. Pushed
/// once per app launch (see main.dart) whenever at least one Konfiguration
/// has a freshly-checked, ready-to-act-on promotion
/// (`promotionCheckedForYear > promotedForYear && promotionPlanReady`).
///
/// This is deliberately much harder to miss than the compact row in
/// Settings - the Klasse/Stufe-Wechsel window is short (the old Stundenplan
/// only keeps working for ~2 weeks after the new one goes live), so this
/// popup exists to make sure the user actually notices in time. The same
/// row still lives in Settings as a permanent, calmer fallback for anyone
/// who closes this popup with "Später".
class PromotionPopup extends StatefulWidget {
  const PromotionPopup({super.key, required this.isar, required this.konfigurationen, this.onChanged});

  final Isar isar;
  final List<Konfiguration> konfigurationen;

  /// Called after a Konfiguration was actually switched, so the pages
  /// underneath (which read Isar synchronously in build) can rebuild and show
  /// the new Stundenplan instead of the old one.
  final VoidCallback? onChanged;

  @override
  State<PromotionPopup> createState() => _PromotionPopupState();
}

class _PromotionPopupState extends State<PromotionPopup> {
  late List<Konfiguration> pending = List.of(widget.konfigurationen);

  /// Marks this Sommerferien-cycle as handled for [id].
  ///
  /// Re-reads the Konfiguration inside the transaction instead of writing back
  /// the snapshot this popup was constructed with: that snapshot was taken
  /// when the popup opened and is by now potentially stale (the Wechsel itself
  /// rewrites Stufe/Kurse/name, and Settings stays interactive underneath).
  /// Writing the whole stale object back would silently revert those fields.
  Future<void> _markAsHandled(int id) async {
    await widget.isar.writeTxn(() async {
      Konfiguration? aktuell = await widget.isar.konfigurations.get(id);
      if (aktuell == null) return; // deleted in the meantime - nothing to mark
      await widget.isar.konfigurations.put(aktuell..promotedForYear = aktuell.promotionCheckedForYear);
    });
  }

  /// Drops [id] from the list and closes the popup once nothing is left.
  void _erledigt(int id) {
    if (!mounted) return;
    setState(() => pending.removeWhere((k) => k.id == id));
    if (pending.isEmpty) _schliessen();
  }

  /// Pops this popup, but only if it's actually the route on top - after
  /// returning from CourseSelection an unrelated route could have been pushed,
  /// and popping then would dismiss that one instead.
  void _schliessen() {
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent ?? false) Navigator.of(context).pop();
  }

  Future<void> _wechseln(Konfiguration konfiguration) async {
    Konfiguration? result = await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => CourseSelection(
              isar: widget.isar,
              editing: konfiguration,
              recommendedStufe: konfiguration.promotionRecommendedStufe,
              recommendedIsOberstufe: konfiguration.promotionRecommendedIsOberstufe,
              // The Wechsel is about next year's plan, not the one still valid
              // today - see CourseSelection.useNewestPlan.
              useNewestPlan: true,
            )));
    // null = backed out without saving. Leave it pending so the reminder (and
    // the Settings row) stick around.
    if (result == null) return;
    // Whatever Stufe they ended up on (recommended or manually picked), this
    // Sommerferien-cycle is handled for this Konfiguration - stop reminding.
    await _markAsHandled(result.id);
    widget.onChanged?.call();
    _erledigt(result.id);
  }

  Future<void> _ignorieren(Konfiguration konfiguration) async {
    await _markAsHandled(konfiguration.id);
    _erledigt(konfiguration.id);
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _schliessen),
        title: const Text("Neues Schuljahr"),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Icon(Icons.celebration, size: 56, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            "Die Stundenpläne fürs neue Schuljahr sind online",
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            "Aktualisiere deine Klasse bzw. deine Kurse, solange der alte Stundenplan noch als Vergleich verfügbar ist.",
            style: TextStyle(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          for (Konfiguration konfiguration in pending) _card(context, konfiguration, colorScheme),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _schliessen,
              child: const Text("Alle für später merken"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, Konfiguration konfiguration, ColorScheme colorScheme) {
    String? empfehlung = konfiguration.promotionRecommendedStufe;
    String subtitle = empfehlung != null
        ? "Vermutlich von ${konfiguration.stufe} zu $empfehlung"
        : "Neue Kurse online - wähle deine neue Klasse/Stufe";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(konfiguration.isOberstufe ? Icons.school_outlined : Icons.people_outline, color: colorScheme.onPrimaryContainer, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(konfiguration.name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onPrimaryContainer)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: colorScheme.onPrimaryContainer)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => _ignorieren(konfiguration), child: const Text("Später")),
              const SizedBox(width: 4),
              FilledButton(onPressed: () => _wechseln(konfiguration), child: const Text("Jetzt wechseln")),
            ],
          ),
        ],
      ),
    );
  }
}
