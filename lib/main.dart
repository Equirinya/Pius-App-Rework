import 'dart:async';

import 'package:PiusApp/background.dart';
import 'package:PiusApp/pages/news.dart';
import 'package:PiusApp/qr_import.dart';
import 'package:PiusApp/share_link.dart';
import 'package:app_links/app_links.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ionicons/ionicons.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'connection.dart';
import 'database.dart';
import 'promotion.dart';
import 'promotion_dialog.dart';
import 'welcome.dart';
import 'pages/settings.dart';
import 'pages/stundenplan.dart';
import 'pages/vertretungsplan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'dart:io' show Platform;

//TODO home screen widgets
//TODO app badge?

//TODO fix overlap in update stundenplan

//TODO google calendar

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final Isar isar = await Isar.open(
    isarSchemas,
    directory: (await getApplicationSupportDirectory()).path,
  );

  SharedPreferences prefs = await SharedPreferences.getInstance();

  // One-time migration for users upgrading from the single-profile Stundenplan.
  await migrateLegacyStundenplanIfNeeded(isar, prefs);

  // Räumt eine Vertretungsplan-URL auf, die durch den früher falschen Default
  // in den Erweiterten Einstellungen festgeschrieben wurde.
  await repairVertretungsplanUrlIfNeeded(prefs);

  if (kDebugMode) {
    timeDilation = 1.0;
  }

  if (Platform.isIOS || Platform.isAndroid) {
    // Initialise flutter_local_notifications. `ic_stat_icon_transparent` needs
    // to exist as a drawable resource in the Android head project.
    await initializeNotifications();

    // Register the Android headless entry-point exactly once, as early as
    // possible, so terminated-app fetches can find it.
    registerBackgroundHeadlessTask();

    // Deliberately not awaited so it doesn't delay the first frame.
    // Also a no-op (and stops any scheduled task) when the user has
    // background updates disabled.
    unawaited(configureBackgroundFetch());

    // Deliberately *no* permission request here. The system prompt belongs on
    // the screen that explains what the notifications are for - the onboarding
    // page and the Benachrichtigungen section in the settings - not in front of
    // a user who just opened the app. See requestNotificationPermission().
  }

  runApp(MyApp(
    isar: isar,
    prefs: prefs,
  ));
}

/// Lets the deep-link handler reach a Navigator without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// `Connectivity.checkConnectivity()` returns a *list* since connectivity_plus 6
/// (a device can be on WLAN and mobile data at the same time). Comparing that
/// list against a single `ConnectivityResult` is always false, which silently
/// disabled every "nur WLAN" guarded refresh. Always go through this helper.
Future<bool> isOnWifi() async {
  final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
  return results.contains(ConnectivityResult.wifi);
}

/// Bumped whenever Konfigurationen were changed from outside the widget tree
/// (currently: an import triggered by a `piusapp://` deep link). Screens that
/// list Konfigurationen but weren't the ones that started the import - most
/// importantly the onboarding carousel - listen to this to refresh.
final ValueNotifier<int> konfigurationenRevision = ValueNotifier<int>(0);

class MyApp extends StatefulWidget {
  MyApp({super.key, required this.isar, required this.prefs});

  final Isar isar;
  final SharedPreferences prefs;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<Uri>? _linkSubscription;

  /// Guards against a second link opening a second import page on top of the
  /// first (double-tapped link, or a link arriving while one is being shown).
  bool _handlingLink = false;

  @override
  void initState() {
    super.initState();
    // app_links only has implementations for the platforms whose share-link
    // scheme we actually register (see AndroidManifest.xml / Info.plist).
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      // uriLinkStream also replays the link the app was cold-started with,
      // so there is no separate getInitialLink() call to keep in sync.
      _linkSubscription = AppLinks().uriLinkStream.listen(
        _handleLink,
        onError: (Object e) {
          if (kDebugMode) print("Deep link error: $e");
        },
      );
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  /// Opens the import screen for an incoming `piusapp://1/...` share link.
  /// Anything else that happens to use our scheme is ignored.
  Future<void> _handleLink(Uri uri) async {
    final String link = uri.toString();
    if (!mounted || !isShareLink(link) || _handlingLink) return;

    final NavigatorState? navigator = navigatorKey.currentState;
    if (navigator == null) {
      // Cold start: the link arrives before the first frame, so there is no
      // Navigator yet. Retry once the tree is up.
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleLink(uri));
      return;
    }

    _handlingLink = true;
    try {
      final List<Konfiguration>? imported = await navigator.push<List<Konfiguration>>(
        MaterialPageRoute(builder: (context) => QrScanPage(isar: widget.isar, initialLink: link)),
      );
      if (imported != null && imported.isNotEmpty) konfigurationenRevision.value++;
    } finally {
      _handlingLink = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    int colorSchemeIndex = widget.prefs.getInt("colorSchemeIndex") ?? 1;
    int darkMode = widget.prefs.getInt("darkMode") ?? 0;

    return NotificationListener<ColorChangedNotification>(
      onNotification: (notification) {
        setState(() {});
        return true;
      },
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          ColorScheme lightColorScheme;
          ColorScheme darkColorScheme;
          VertretungsColors? vertretungsColors;

          //order of color schemes: pius, dynamic?, [user defined]

          bool dynamicSchemeExists = lightDynamic != null && darkDynamic != null;
          int maxColorSchemeIndex = widget.isar.colorPalettes.where().countSync() + (dynamicSchemeExists ? 1 : 0);

          if (colorSchemeIndex >= (dynamicSchemeExists ? 2 : 1) && colorSchemeIndex <= maxColorSchemeIndex) {
            ColorPalette palette = widget.isar.colorPalettes.where().findAllSync()[colorSchemeIndex - (dynamicSchemeExists ? 2 : 1)];
            lightColorScheme = palette.toColorScheme();
            darkColorScheme = palette.toColorScheme(true);
            vertretungsColors = palette.fromSeed ? null : palette.getExactColors();
          } else if (dynamicSchemeExists && colorSchemeIndex == 1) {
            // On Android S+ devices, use the provided dynamic color scheme.
            // (Recommended) Harmonize the dynamic color scheme' built-in semantic colors.
            lightColorScheme = lightDynamic.harmonized();
            darkColorScheme = darkDynamic.harmonized();
          } else {
            // Otherwise, use fallback schemes.
            Color primaryColor = Color.fromARGB(255, 87, 162, 211);
            Color secondaryColor = Color.fromARGB(255, 30, 111, 147);
            Color tertiaryColor = Color.fromARGB(255, 255, 204, 0);
            Color errorColor = Color.fromARGB(255, 255, 0, 0);
            lightColorScheme = SeedColorScheme.fromSeeds(
              primaryKey: primaryColor,
              secondaryKey: secondaryColor,
              tertiaryKey: tertiaryColor,
              errorKey: errorColor,
            );
            darkColorScheme = SeedColorScheme.fromSeeds(
              primaryKey: primaryColor,
              secondaryKey: secondaryColor,
              tertiaryKey: tertiaryColor,
              errorKey: errorColor,
              brightness: Brightness.dark,
            );
            vertretungsColors = VertretungsColors(
              mainColor: primaryColor,
              headerColor: secondaryColor,
              evaColor: tertiaryColor,
              replacementColor: errorColor,
            );
          }

          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            supportedLocales: const [
              Locale('de'),
            ],
            locale: const Locale("de"),
            localizationsDelegates: const [...GlobalMaterialLocalizations.delegates, SfGlobalLocalizations.delegate],
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: lightColorScheme,
              extensions: [if (vertretungsColors != null) vertretungsColors],
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: darkColorScheme,
              extensions: [if (vertretungsColors != null) vertretungsColors],
            ),
            // Geklammert: ein einmal ausserhalb des gültigen Bereichs
            // geschriebener Wert (z.B. weil die Auswahlliste später kürzer
            // wird) würde sonst bei jedem Build einen RangeError werfen - die
            // App käme nicht mehr hoch und wäre über die UI nicht zu retten.
            themeMode: ThemeMode.values[darkMode.clamp(0, ThemeMode.values.length - 1)],
            home: (widget.prefs.getBool("initialized") ?? false) ? OuterPage(isar: widget.isar, prefs: widget.prefs) : WelcomeCarousel(isar: widget.isar),
          );
        },
      ),
    );
  }
}

@immutable
class VertretungsColors extends ThemeExtension<VertretungsColors> {
  const VertretungsColors({
    required this.mainColor,
    required this.headerColor,
    required this.evaColor,
    required this.replacementColor,
  });

  final Color mainColor;
  final Color headerColor;
  final Color evaColor;
  final Color replacementColor;

  @override
  VertretungsColors copyWith({Color? mainColor, Color? headerColor, Color? evaColor, Color? replacementColor}) {
    return VertretungsColors(
      mainColor: mainColor ?? this.mainColor,
      headerColor: headerColor ?? this.headerColor,
      evaColor: evaColor ?? this.evaColor,
      replacementColor: replacementColor ?? this.replacementColor,
    );
  }

  @override
  VertretungsColors lerp(VertretungsColors? other, double t) {
    if (other is! VertretungsColors) {
      return this;
    }
    return VertretungsColors(
      mainColor: Color.lerp(mainColor, other.mainColor, t) ?? mainColor,
      headerColor: Color.lerp(headerColor, other.headerColor, t) ?? headerColor,
      evaColor: Color.lerp(evaColor, other.evaColor, t) ?? evaColor,
      replacementColor: Color.lerp(replacementColor, other.replacementColor, t) ?? replacementColor,
    );
  }

  // Optional
  @override
  String toString() => 'VertretungsColors(mainColor: $mainColor, headerColor: $headerColor, evaColor: $evaColor, replacementColor: $replacementColor)';
}

class OuterPage extends StatefulWidget {
  const OuterPage({super.key, required this.isar, required this.prefs});

  final Isar isar;
  final SharedPreferences prefs;

  @override
  State<OuterPage> createState() => _OuterPageState();
}

class _OuterPageState extends State<OuterPage> {
  ValueNotifier<bool?> vertretungsLoadingNotifier = ValueNotifier(false);
  ValueNotifier<bool?> calendarLoadingNotifier = ValueNotifier(false);

  // Session-only memory of which Konfigurationen already got the fullscreen
  // promotion popup, so switching tabs / pull-to-refresh doesn't reopen it
  // on top of itself. Not persisted on purpose: if it's still unresolved
  // (user hasn't tapped "Jetzt wechseln" or "Später"), it should pop up
  // again next time the app is opened - the Klasse/Stufe-Wechsel window is
  // short and easy to miss otherwise. The Settings row remains the
  // permanent, calmer place to act on it in the meantime.
  final Set<int> _promotionPopupShown = {};

  @override
  void initState() {
    _selectedIndex = widget.prefs.getInt("selectedPage") ?? 0;
    asyncInit();
    super.initState();
  }

  void asyncInit() async {
    FlutterSecureStorage securePrefs = getSecurePrefs();

    String? username = await securePrefs.read(key: "username");
    String? password = await securePrefs.read(key: "password");
    if(username == null || password == null || username.isEmpty || password.isEmpty) {
      if(context.mounted) await newLogin(context, securePrefs); //TODO would be better to replace with shortened welcome screen
    }
    unawaited(loadVertretungsplanIfAllowed());
    loadCalendarContent();
    // Also check the *already cached* promotion state on every launch, not
    // just after a refresh actually ran. loadCalendarContent() only reaches
    // checkPromotions() when an update is due, so with the default update
    // intervals a Konfiguration that became ready yesterday would otherwise
    // never get its popup - the one thing this popup exists to prevent.
    _maybeShowPromotionPopup();
  }

  /// Single place that decides whether the Vertretungsplan may refresh right
  /// now. Both callers used to inline this check with *different* defaults for
  /// `vertretungUpdateWifi` (false on launch, true from Settings), so the same
  /// switch behaved differently depending on where the refresh came from.
  /// The default here matches the one the Settings switch itself uses: false.
  Future<void> loadVertretungsplanIfAllowed() async {
    if (!(widget.prefs.getBool("vertretungUpdateWifi") ?? false) || await isOnWifi()) {
      loadVertretungsplan();
    }
  }

  void loadVertretungsplan() async {
    vertretungsLoadingNotifier.value = true;
    try {
      String vertretungsplanWebsite = await getVertretungsplanWebsite();
      await parseVertretungsplan(vertretungsplanWebsite, widget.isar);
      vertretungsLoadingNotifier.value = false;
      // Catch Error too, not just Exception: parsing foreign HTML routinely
      // throws RangeError/TypeError/StateError, and an escaping Error left the
      // notifier stuck on `true` - a spinner that never stops.
    } catch (e, s) {
      vertretungsLoadingNotifier.value = null;
      if (kDebugMode) {
        print("Error while fetching Vertretungsplan:");
        print(e);
        print(s);
      }
    }
  }

  void loadCalendarContent({bool forceUpdateStundenPlan = false}) async {
    bool shouldUpdateTermine =
        DateTime.fromMillisecondsSinceEpoch(widget.prefs.getInt("lastTermineUpdate") ?? 0)
            .isBefore(DateTime.now().subtract(durations.values.elementAt(widget.prefs.getInt("termineUpdateDuration") ?? 8)));
    bool shouldUpdateStundenplan = DateTime.fromMillisecondsSinceEpoch(widget.prefs.getInt("lastStundenplanUpdate") ?? 0)
        .isBefore(DateTime.now().subtract(durations.values.elementAt(widget.prefs.getInt("stundenplanUpdateDuration") ?? 8)));
    if (shouldUpdateTermine || shouldUpdateStundenplan || forceUpdateStundenPlan) {
      calendarLoadingNotifier.value = true;
      bool failed = false;
      if (forceUpdateStundenPlan || (shouldUpdateTermine &&
          (!(widget.prefs.getBool("termineUpdateWifi") ?? true) || await isOnWifi()))) {
        try {
          await updateTermine();
          widget.prefs.setInt("lastTermineUpdate", DateTime.now().millisecondsSinceEpoch);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          failed = true;
        }
      }
      if (forceUpdateStundenPlan || (shouldUpdateStundenplan &&
          (!(widget.prefs.getBool("stundenplanUpdateWifi") ?? true) || await isOnWifi()))) {
        try {
          await refreshAllConfigurations(widget.isar);
          widget.prefs.setInt("lastStundenplanUpdate", DateTime.now().millisecondsSinceEpoch);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          failed = true;
        }
      }
      // Cheap no-op outside Sommerferien (just reads already-cached Termine).
      // During Sommerferien it checks whether next year's Stundenplan is up
      // yet and, if so, caches a Klasse/Stufe-Wechsel recommendation on the
      // affected Konfigurationen for Settings to surface.
      try {
        await checkPromotions(widget.isar, widget.prefs);
        _maybeShowPromotionPopup();
      } catch (e) {
        if (kDebugMode) print(e);
      }
      calendarLoadingNotifier.value = failed ? null : false;
    }
  }

  /// Pushes the fullscreen "neues Schuljahr" popup (see promotion_dialog.dart)
  /// for any Konfigurationen that are ready (a new Stundenplan is online) and
  /// haven't already shown it this session. No-op the rest of the year, since
  /// [checkPromotions] only ever sets `promotionPlanReady` during Sommerferien.
  ///
  /// Deferred to the end of the frame: this is called both from [asyncInit]
  /// (which can run before the first build has finished) and from the async
  /// refresh, and both `ModalRoute.of` and `Navigator.push` need a fully
  /// built tree to work against.
  void _maybeShowPromotionPopup() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPromotionPopupIfReady());
  }

  void _showPromotionPopupIfReady() {
    if (!mounted) return;
    // Only ever open on top of the main scaffold. This can be reached while
    // the user is in the middle of something else (the login dialog on first
    // launch, an open CourseSelection, the popup itself) - pushing a
    // fullscreen dialog over that would hijack whatever they were doing.
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

    List<Konfiguration> ready = widget.isar.konfigurations.where().findAllSync().where((k) {
      return k.promotionPlanReady && k.promotionCheckedForYear > k.promotedForYear && !_promotionPopupShown.contains(k.id);
    }).toList();
    if (ready.isEmpty) return;

    _promotionPopupShown.addAll(ready.map((k) => k.id));
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => PromotionPopup(
        isar: widget.isar,
        konfigurationen: ready,
        // The pages in the IndexedStack below read Isar synchronously in
        // build(), so a switch only becomes visible once this rebuilds.
        onChanged: () {
          if (mounted) setState(() {});
        },
      ),
    ));
  }

  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          StundenplanPage(
            isar: widget.isar,
            vertretungsLoading: vertretungsLoadingNotifier,
            calendarLoading: calendarLoadingNotifier,
            refreshStundenplan: () => loadCalendarContent(forceUpdateStundenPlan: true),
            refreshVertretungsplan: loadVertretungsplan,
          ),
          VertretungsplanPage(isar: widget.isar, loadingNotifier: vertretungsLoadingNotifier, refresh: loadVertretungsplan),
          NewsPage(isar: widget.isar),
          SettingsPage(
              isar: widget.isar,
              refresh: () {
                unawaited(loadVertretungsplanIfAllowed());
                loadCalendarContent();
              }),
        ],
      ),
      bottomNavigationBar: Theme(
        data: theme.copyWith(
          navigationBarTheme: theme.navigationBarTheme.copyWith(
            labelTextStyle: WidgetStateTextStyle.resolveWith(
                  (Set<WidgetState> states) {
                    final TextStyle style = theme.textTheme.labelMedium!;
                    return style.apply(
                        color: states.contains(WidgetState.disabled)
                            ? theme.colorScheme.onSurfaceVariant.withOpacity(0.38)
                            : states.contains(WidgetState.selected)
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      overflow: TextOverflow.ellipsis,
                      fontSizeFactor: 0.95
                    );
              },
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
              widget.prefs.setInt("selectedPage", index);
            });
            // Catch-up permission request, hooked to the tab tap rather than
            // SettingsPage.initState: the pages live in an IndexedStack, so
            // initState already runs at app start - which is exactly where
            // this prompt does not belong.
            if (index == 3) unawaited(ensureNotificationPermissionAsked());
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
              selectedIcon: Icon(Ionicons.newspaper),
              icon: Icon(Ionicons.newspaper_outline),
              label: "News",
            ),
            NavigationDestination(
              selectedIcon: Icon(Ionicons.settings),
              icon: Icon(Ionicons.settings_outline),
              label: "Einstellungen",
            ),
          ],
        ),
      ),
    );
  }
}
