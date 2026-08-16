import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Benutzername- und Passwortfeld für beide Login-Stellen der App (Onboarding
/// in `welcome.dart` und "Dein Login" in den Einstellungen).
///
/// Vorher hatte jede Stelle ihre eigenen zwei `TextField`s, und beide fehlte
/// etwas Unterschiedliches:
///
/// * **Autofill** funktionierte nirgends. Ohne `AutofillGroup` +
///   `autofillHints` bieten iOS-Keychain, Google Passwortmanager und die
///   Desktop-Passwortmanager weder das Ausfüllen noch das Speichern an.
/// * **Sichtbarkeit des Passworts** war im Onboarding hart auf verdeckt ohne
///   Umschalter - und in den Einstellungen war das Passwort überhaupt nicht
///   verdeckt, stand also im Klartext auf dem Bildschirm.
///
/// Damit das Betriebssystem nach einem *erfolgreichen* Login das Speichern
/// anbietet, muss die aufrufende Stelle zusätzlich [finishLoginAutofill]
/// aufrufen - das kann dieses Widget nicht selbst wissen.
class LoginFields extends StatefulWidget {
  const LoginFields({
    super.key,
    required this.usernameController,
    required this.passwordController,
    this.enabled = true,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;

  /// Während ein Login-Versuch läuft, sollen die Felder nicht editierbar sein.
  final bool enabled;
  final bool autofocus;

  /// Enter-Taste im Passwortfeld - üblicherweise derselbe Callback wie der
  /// "Einloggen"-Button.
  final VoidCallback? onSubmitted;

  @override
  State<LoginFields> createState() => _LoginFieldsState();
}

class _LoginFieldsState extends State<LoginFields> {
  final FocusNode _passwordFocus = FocusNode();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.usernameController,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            autofillHints: const [AutofillHints.username],
            textInputAction: TextInputAction.next,
            // Der Pius-Benutzername ist keine Prosa - Autokorrektur und
            // Wortvorschläge machen ihn nur kaputt.
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: "Benutzername",
              prefixIcon: Icon(Icons.person_outline),
            ),
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.passwordController,
            focusNode: _passwordFocus,
            enabled: widget.enabled,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: "Passwort",
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                tooltip: _obscure ? "Passwort anzeigen" : "Passwort verbergen",
              ),
            ),
            onSubmitted: (_) => widget.onSubmitted?.call(),
          ),
        ],
      ),
    );
  }
}

/// Schliesst den Autofill-Kontext ab, damit das Betriebssystem das Speichern
/// der eingegebenen Zugangsdaten anbieten kann.
///
/// Nur nach einem *erfolgreichen* Login aufrufen - nach einem fehlgeschlagenen
/// Versuch würde man dem Passwortmanager falsche Daten zum Merken anbieten.
void finishLoginAutofill() => TextInput.finishAutofillContext();
