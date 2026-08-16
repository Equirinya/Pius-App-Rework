import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar_community/isar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'connection.dart';
import 'database.dart';
import 'share_link.dart';

/// Takes over Konfigurationen (and optionally a Pius-Login) that someone
/// shared from the "teilen" flow in Settings, lets the user pick which of
/// them to keep, and saves the selected ones.
///
/// The transport is a share link (see share_link.dart) in either of its two
/// forms. It reaches this page either by being scanned as a QR code (https
/// form), or - when the link was tapped somewhere else on the device and the
/// redirect page forwarded it - by being handed in through [initialLink] as
/// a `piusapp://` link by the deep-link handler in main.dart.
///
/// Pops with the list of newly imported Konfigurationen (empty list if the
/// user backed out).
class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key, required this.isar, this.autoCommit = false, this.initialLink});

  final Isar isar;

  /// Skips the picker/review screen and immediately imports everything the
  /// link contains - every Konfiguration, plus the login if one is included -
  /// instead of waiting for a confirmation tap. Used during onboarding, where
  /// scanning a code someone already handed you should just work in one step.
  final bool autoCommit;

  /// A `piusapp://` link that was already obtained elsewhere (deep link).
  /// When set, the camera is never opened; the page goes straight to the
  /// picker (or, with [autoCommit], straight to importing).
  final String? initialLink;

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> with WidgetsBindingObserver {
  MobileScannerController? controller;
  SharePayload? scanned;
  Set<int> selected = {};
  bool applyLogin = true;
  bool importing = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final String? link = widget.initialLink;
    if (link != null) {
      // Came in via deep link - nothing to scan.
      WidgetsBinding.instance.addPostFrameCallback((_) => _accept(link, fromScanner: false));
    } else {
      controller = MobileScannerController();
      // The MobileScanner widget only registers its own lifecycle observer
      // when it creates the controller itself (see _MobileScannerState.
      // _initializeController: `if (widget.controller == null)`). Because we
      // pass one in, the camera is never stopped on background and never
      // restarted on resume - on iOS the system tears the capture session
      // down anyway, so the user comes back to a frozen preview.
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final MobileScannerController? scanner = controller;
    // Nothing to resume once a code was accepted, and starting without
    // permission just produces an error.
    if (scanner == null || scanned != null || !scanner.value.hasCameraPermission) return;

    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_safeStart());
      case AppLifecycleState.inactive:
        unawaited(scanner.stop());
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        break;
    }
  }

  /// `start()` throws a MobileScannerException (camera busy, permission
  /// revoked, controller not attached yet). Unawaited that became an
  /// unhandled async error instead of something the user can see.
  Future<void> _safeStart() async {
    try {
      await controller?.start();
    } catch (e) {
      if (kDebugMode) print("Could not start scanner: $e");
      if (mounted) setState(() => error = "Kamera konnte nicht gestartet werden.");
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (scanned != null || capture.barcodes.isEmpty) return;
    final String? raw = capture.barcodes.first.rawValue;
    if (raw == null) return;
    // Cameras happily pick up unrelated codes (WLAN, Werbeplakate, ...);
    // those should not produce an error, just keep scanning.
    if (!isShareLink(raw)) return;
    _accept(raw, fromScanner: true);
  }

  /// Decodes [link] and moves on to the picker / import.
  void _accept(String link, {required bool fromScanner}) {
    final SharePayload result;
    try {
      result = parseShareLink(link);
    } on ShareLinkException catch (e) {
      if (!mounted) return;
      setState(() => error = e.message);
      return;
    } catch (e) {
      if (kDebugMode) print("Unreadable share link: $e");
      if (!mounted) return;
      setState(() => error = "Der Link ist beschädigt.");
      return;
    }

    if (result.konfigurationen.isEmpty && !result.includesLogin) {
      if (!mounted) return;
      setState(() => error = "Der Link enthält keine Stundenpläne.");
      return;
    }

    setState(() {
      error = null;
      scanned = result;
      selected = {for (int i = 0; i < result.konfigurationen.length; i++) i};
    });
    if (fromScanner) unawaited(controller?.stop());
    if (widget.autoCommit) _import();
  }

  Future<void> _import() async {
    SharePayload? payload = scanned;
    if (payload == null) return;
    if (selected.isEmpty && !(payload.includesLogin && applyLogin)) return;
    setState(() {
      importing = true;
      error = null;
    });
    try {
      if (payload.includesLogin && applyLogin) {
        FlutterSecureStorage securePrefs = getSecurePrefs();
        await securePrefs.write(key: "username", value: payload.username);
        await securePrefs.write(key: "password", value: payload.password);
      }

      var (klassenplan, oberstufenplan) = await getCurrentStundenplaene();
      List<Konfiguration> imported = [];
      int basePosition = widget.isar.konfigurations.where().countSync();
      for (final (index, konfiguration) in payload.konfigurationen.indexed) {
        if (!selected.contains(index)) continue;
        konfiguration.position = basePosition + imported.length;
        await saveKonfiguration(widget.isar, konfiguration, konfiguration.isOberstufe ? oberstufenplan : klassenplan);
        imported.add(konfiguration);
      }
      if (mounted) Navigator.of(context).pop(imported);
    } catch (e) {
      if (kDebugMode) print(e);
      if (!mounted) return;
      setState(() {
        importing = false;
        error = "Konnte Stundenpläne nicht importieren: $e";
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.initialLink != null ? "Stundenpläne übernehmen" : "QR-Code scannen")),
      body: scanned == null
          ? (controller == null ? _buildLinkPendingState(context) : _buildScannerState(context))
          : widget.autoCommit
              ? _buildAutoCommitState(context)
              : _buildPickerState(context),
    );
  }

  Widget _buildScannerState(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(controller: controller!, onDetect: _onDetect),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Richte die Kamera auf den QR-Code, den dir jemand in den Einstellungen unter \"Klasse/Kurse\" zeigen kann.",
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.orangeAccent), textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Deep link that turned out to be unreadable - there is no camera to fall
  /// back to here, so just explain and let the user leave.
  Widget _buildLinkPendingState(BuildContext context) {
    if (error == null) return const Center(child: CircularProgressIndicator());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_off, size: 40, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.of(context).pop(<Konfiguration>[]), child: const Text("Schließen")),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            scanned!.konfigurationen.length == 1 ? "1 Stundenplan gefunden" : "${scanned!.konfigurationen.length} Stundenpläne gefunden",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text("Wähle aus, welche du übernehmen möchtest."),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                for (final (index, konfiguration) in scanned!.konfigurationen.indexed)
                  CheckboxListTile(
                    value: selected.contains(index),
                    onChanged: (value) => setState(() {
                      if (value == true) {
                        selected.add(index);
                      } else {
                        selected.remove(index);
                      }
                    }),
                    title: Text(konfiguration.name),
                    subtitle: Text(
                      "${konfiguration.isOberstufe ? "Oberstufe" : "Klasse"} ${konfiguration.stufe}"
                      "${konfiguration.kurse.isNotEmpty ? " · ${konfiguration.kurse.length} Kurse" : ""}",
                    ),
                  ),
                if (scanned!.includesLogin)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: applyLogin,
                      onChanged: (value) => setState(() => applyLogin = value ?? false),
                      title: Text(
                        "Enthaltenen Pius-Login übernehmen",
                        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                      ),
                      subtitle: Text(
                        "Dieser Link enthält Zugangsdaten. Nur übernehmen, wenn du dem Absender vertraust.",
                        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center),
            ),
          FilledButton.icon(
            onPressed: (importing || (selected.isEmpty && !(scanned!.includesLogin && applyLogin))) ? null : _import,
            icon: importing
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_outlined),
            label: Text(selected.isEmpty ? "Übernehmen" : "${selected.length} übernehmen"),
          ),
          if (widget.initialLink == null)
            TextButton(
              onPressed: importing
                  ? null
                  : () {
                      setState(() {
                        scanned = null;
                        selected = {};
                        error = null;
                      });
                      unawaited(_safeStart());
                    },
              child: const Text("Erneut scannen"),
            ),
        ],
      ),
    );
  }

  Widget _buildAutoCommitState(BuildContext context) {
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _import,
                icon: const Icon(Icons.refresh),
                label: const Text("Erneut versuchen"),
              ),
            ],
          ),
        ),
      );
    }
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Übernehme Stundenpläne…"),
        ],
      ),
    );
  }
}
