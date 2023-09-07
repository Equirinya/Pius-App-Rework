import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ionicons/ionicons.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:piusapp/pages/settings.dart';
import 'package:piusapp/pages/stundenplan.dart';
import 'package:piusapp/pages/vertretungsplan.dart';

import 'database.dart';

import 'test.dart' as test;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final Isar isar = await Isar.open(
      [VertretungSchema],
      directory: (await getApplicationSupportDirectory()).path,
  );

  if (kDebugMode) {
  timeDilation = 1.0;
  }

  test.main();

  runApp(MyApp(isar: isar));
}

class MyApp extends StatelessWidget {
  MyApp({super.key, required this.isar});

  final Isar isar;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // On Android S+ devices, use the provided dynamic color scheme.
          // (Recommended) Harmonize the dynamic color scheme' built-in semantic colors.
          lightColorScheme = lightDynamic.harmonized();
          // (Optional) Customize the scheme as desired. For example, one might
          // want to use a brand color to override the dynamic [ColorScheme.secondary].
          // lightColorScheme = lightColorScheme.copyWith(secondary: _brandBlue);
          // (Optional) If applicable, harmonize custom colors.
          // lightCustomColors = lightCustomColors.harmonized(lightColorScheme);

          // Repeat for the dark color scheme.
          darkColorScheme = darkDynamic.harmonized();
          // darkColorScheme = darkColorScheme.copyWith(secondary: _brandBlue);
          // darkCustomColors = darkCustomColors.harmonized(darkColorScheme);
        } else {
          // Otherwise, use fallback schemes.
          lightColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.teal,
          );
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
            // extensions: [lightCustomColors],
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
            // extensions: [darkCustomColors],
          ),
          themeMode: ThemeMode.dark,
          home: OuterPage(isar: isar),
        );
      },
    );
  }
}

class OuterPage extends StatefulWidget {
  OuterPage({super.key, required this.isar});

  final Isar isar;

  @override
  State<OuterPage> createState() => _OuterPageState();
}

class _OuterPageState extends State<OuterPage> {


  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          StundenplanPage(isar: widget.isar),
          VertretungsplanPage(isar: widget.isar),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index){
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Ionicons.calendar),
            icon: Icon(Ionicons.calendar_outline),
            label: "Stundenplan",
          ),
          NavigationDestination(
            selectedIcon: Icon(Ionicons.reorder_four),
            icon: Icon(Ionicons.reorder_four),
            label: "Vertretungsplan",
          ),
          NavigationDestination(
            selectedIcon: Icon(Ionicons.settings),
            icon: Icon(Ionicons.settings_outline),
            label: "Einstellungen",
          ),
        ],
      ),
    );
  }
}
