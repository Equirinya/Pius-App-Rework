import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ionicons/ionicons.dart';

import 'package:isar/isar.dart';
import 'package:piusapp/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:piusapp/connection.dart';
import 'package:piusapp/pages/vertretungsplan.dart';

enum SettingType {
  bool,
  selection,
  customTap,
  custom,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SharedPreferences prefs;
  late FlutterSecureStorage securePrefs;
  bool initialized = false;

  @override
  void initState() {
    AndroidOptions getAndroidOptions() => const AndroidOptions(
          encryptedSharedPreferences: true,
        );
    securePrefs = FlutterSecureStorage(aOptions: getAndroidOptions());
    SharedPreferences.getInstance().then((value) {
      prefs = value;
      initialized = true;
      setState(() {});
    });
    super.initState();
  }

  void newLogin(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {

        TextEditingController usernameController = TextEditingController();
        TextEditingController passwordController = TextEditingController();

        int state = 0;
        String error = "";

        return StatefulBuilder(
          builder: (context, setState) {

            return AlertDialog(
              icon: const Icon(Icons.account_circle),
              title: const Text("Neuer Login"),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: "Benutzername",
                    ),
                  ),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: "Passwort",
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: 32,
                      child: IndexedStack(
                        index: state,
                          alignment: Alignment.center,
                          children: [
                        Text(error),
                        const CupertinoActivityIndicator(),
                        Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],),
                    ),
                  )
                ],
              ),
              actions: [
                TextButton(
                    style: TextButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primaryContainer),
                    onPressed: state == 0
                        ? () async {
                            if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
                              setState(() {
                                state = 0;
                                error = "Bitte fülle alle Felder aus.";
                              });
                              return;
                            }

                            setState(() {
                              state = 1;
                            });
                            await securePrefs.write(key: "username", value: usernameController.text);
                            await securePrefs.write(key: "password", value: passwordController.text);

                            try {
                              await checkCredentials();
                            } on AuthorizationException catch (e) {
                              setState(() {
                                state = 0;
                                error = e.msg;
                              });
                              return;
                            } catch (e) {
                              setState(() {
                                state = 0;
                                error = "Unerwarteter Fehler: ${e.toString()}";
                              });
                              return;
                            }
                            setState(() {
                              state = 2;
                            });
                            await Future.delayed(const Duration(seconds: 1));

                            Navigator.of(context).pop();
                          }
                        : null,
                    child: const Text("Einloggen")),
                TextButton(
                    onPressed: state == 0
                        ? () {
                            Navigator.of(context).pop();
                          }
                        : null,
                    child: const Text("Abbrechen"))
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) return const Center(child: CircularProgressIndicator());

    TextStyle? titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary);

    final List<(String, String?, IconData, List<(String?, List<(String, String?, IconData, String, SettingType, dynamic)>)>)> settings = [
      (
        "Dein Account",
        "Login, Klassen- und Kursauswahl",
        Ionicons.person,
        [
          (
            "Login",
            [
              ("Dein Login", "Klicke hier um deinen Login zu ändern", Ionicons.log_in, "-", SettingType.customTap, () => newLogin(context)),
            ]
          ),
        ]
      ),
      (
        "Anzeige",
        "Dunkles Farbschema, dynamische Farben, Abkürzungen",
        Ionicons.color_palette,
        [
          (
            "Farbauswahl",
            [
              ("Aktuelle Farben", "-", Ionicons.color_palette, "-", SettingType.custom, klassenVertretungsBlock([
                Vertretung()
                  ..klasse = "XX"
                  ..stunde = "1"
                  ..raum = "A123" ,
              ])),
            ]
          ),
        ]
      ),
      (
        "Benachrichtigungen",
        "Zeiten, Hintergrundaktualisierung, WLAN only",
        Ionicons.notifications,
        [
          (
            "Debugging",
            [
              (
                "Ask for Video Source",
                "Show selection pop-up with options for video source instead of deciding for best",
                Ionicons.wifi,
                "askForVideo",
                SettingType.bool,
                null
              ),
            ]
          ),
        ]
      ),
      (
        "Über",
        "Kontakt, Impressum, Datenschutz",
        Ionicons.information_circle,
        [
          (
            "Debugging",
            [
              (
                "Ask for Video Source",
                "Show selection pop-up with options for video source instead of deciding for best",
                Ionicons.wifi,
                "askForVideo",
                SettingType.bool,
                null
              ),
            ]
          ),
        ]
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Padding(padding: EdgeInsets.only(right: 32.0, top: 12), child: Text("Settings", overflow: TextOverflow.ellipsis)),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 128, top: 16),
        children: [
          for (final (title, subtitle, icon, sections) in settings)
            ListTile(
              leading: Icon(icon),
              title: Text(title, style: Theme.of(context).textTheme.titleLarge),
              subtitle: subtitle != null ? Text(subtitle) : null,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text(title),
                    // backgroundColor: Theme.of(context).colorScheme.background,
                    // leading: IconButton(
                    //   icon: const Icon(Ionicons.arrow_back),
                    //   onPressed: () => Navigator.of(context).pop(),
                    // ),
                  ),
                  body: ListView(
                    padding: const EdgeInsets.only(bottom: 128, top: 16),
                    children: [
                      for (final (title, settings) in sections)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (title != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Text(
                                  title,
                                  style: titleStyle,
                                ),
                              ),
                            for (final (title, subtitle, icon, setting, type, extra) in settings)
                              StatefulBuilder(
                                builder: (context, setState) {
                                  switch (type) {
                                    case SettingType.bool:
                                      return SwitchListTile(
                                        title: Text(title),
                                        subtitle: subtitle != null ? Text(subtitle) : null,
                                        secondary: Icon(icon),
                                        value: prefs.getBool(setting) ?? false,
                                        onChanged: (value) {
                                          prefs.setBool(setting, value);
                                          setState(() {});
                                        },
                                      );
                                    case SettingType.selection:
                                      return ListTile(
                                          title: Text(title),
                                          subtitle: Text(extra[prefs.getInt(setting) ?? 0]),
                                          leading: Icon(icon),
                                          onTap: () => showDialog(
                                              context: context,
                                              builder: (context) {
                                                int index = prefs.getInt(setting) ?? 0;
                                                return StatefulBuilder(
                                                    builder: (context, setState) => AlertDialog(
                                                          icon: Icon(icon),
                                                          title: Text(title),
                                                          content: Column(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Text(subtitle ?? ""),
                                                              const SizedBox(height: 16),
                                                              for (final option in extra)
                                                                RadioListTile(
                                                                  title: Text(option),
                                                                  value: option,
                                                                  groupValue: extra[index],
                                                                  onChanged: (value) {
                                                                    index = extra.indexOf(value);
                                                                    setState(() {});
                                                                  },
                                                                )
                                                            ],
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                                style: TextButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primaryContainer),
                                                                onPressed: () {
                                                                  Navigator.of(context).pop();
                                                                  prefs.setInt(setting, index);
                                                                },
                                                                child: Text("Bestätigen")),
                                                            TextButton(
                                                                onPressed: () {
                                                                  Navigator.of(context).pop();
                                                                },
                                                                child: Text("Abbrechen"))
                                                          ],
                                                        ));
                                              }).then((value) => setState(() {})));
                                    case SettingType.customTap:
                                      return ListTile(
                                        title: Text(title),
                                        subtitle: subtitle != null ? Text(subtitle) : null,
                                        leading: Icon(icon),
                                        onTap: () => extra(),
                                      );
                                    case SettingType.custom:
                                      return extra;
                                  }
                                },
                              )
                          ],
                        )
                    ],
                  ),
                );
              })),
            )
        ],
      ),
    );
  }
}
