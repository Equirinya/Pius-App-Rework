import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';



enum SettingType {
  bool,
  selection,
  customTap,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SharedPreferences prefs;
  bool initialized = false;

  @override
  void initState() {
    SharedPreferences.getInstance().then((value) {
      prefs = value;
      initialized = true;
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) return const Center(child: CircularProgressIndicator());


    TextStyle? titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary);

    final List<(String, String?, IconData, List<(String?, List<(String, String?, IconData, String, SettingType, dynamic)>)>)> settings = [
      (
        "Downloads",
        "Download over wifi, Ask before Delete, etc...",
        Ionicons.download,
        [
          (
            "Connection",
            [
              ("Download over mobile Data", "Videos, PDFs etc?", Ionicons.wifi, "downloadOverMobileData", SettingType.selection, ["no download over mobile data", "not videos", "download everything"]),
              ("Test", "Vidtetc?", Ionicons.wifi, "testBool", SettingType.bool,null),
            ]
          ),
        ]
      ),
      (
      "Developer Options",
      "Debugging, Logging, etc...",
      Ionicons.code_outline,
      [
        (
        "Debugging",
        [
          ("Ask for Video Source", "Show selection pop-up with options for video source instead of deciding for best", Ionicons.wifi, "askForVideo", SettingType.bool,null),
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
                                                return StatefulBuilder(builder: (context, setState) => AlertDialog(
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
