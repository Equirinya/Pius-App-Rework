import 'dart:convert';
import 'dart:math';

import 'package:PiusApp/course_selection.dart';
import 'package:PiusApp/pages/settings.dart';
import 'package:PiusApp/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:isar_community/isar.dart';
import '../connection.dart';
import '../database.dart';
import 'vertretungsplan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'dart:io' show Platform;

//on load load stundenplan dateien if namen unterschiedlich
//on add nur bis nächste sommerferien

//TODO klausurenplan
//TODO show original classes on vertetung dialog

class StundenplanPage extends StatefulWidget {
  const StundenplanPage({super.key, required this.isar, required this.vertretungsLoading, required this.calendarLoading, required this.refreshStundenplan, required this.refreshVertretungsplan});

  final Isar isar;
  final ValueNotifier<bool?> vertretungsLoading;
  final ValueNotifier<bool?> calendarLoading;
  final VoidCallback refreshStundenplan;
  final VoidCallback refreshVertretungsplan;

  @override
  State<StundenplanPage> createState() => _StundenplanPageState();
}

class _StundenplanPageState extends State<StundenplanPage> {
  late SharedPreferences prefs;
  bool initialized = false;
  bool calendarInitialized = false;
  bool? calendarLoading = false;
  bool? vertretungLoading = false;
  CalendarController controller = CalendarController();
  late CalendarView view;
  int selectedKonfigurationIndex = 0;

  @override
  void initState() {
    SharedPreferences.getInstance().then((value) {
      if (!mounted) return;
      prefs = value;
      int? stundenplanView = prefs.getInt("stundenplanView");
      if(stundenplanView == null) prefs.setInt("stundenplanView", (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ? 2 : 1);
      view = prefs.getInt("stundenplanView") == 0
          ? CalendarView.day
          : prefs.getInt("stundenplanView") == 2
              ? CalendarView.week
              : CalendarView.workWeek;
      initialized = true;
      selectedKonfigurationIndex = prefs.getInt("stundenplanSelectedKonfigurationIndex") ?? 0;
      setState(() {});
    });
    // Benannte Methoden statt anonymer Closures: nur so lassen sie sich in
    // dispose() wieder abmelden. Die Notifier gehören dem Elternwidget und
    // leben länger als diese Seite - jeder Rebuild hängte vorher einen
    // weiteren, unentfernbaren Listener an, der nach dem dispose weiter
    // setState() aufrief.
    widget.vertretungsLoading.addListener(_onVertretungsLoadingChanged);
    widget.calendarLoading.addListener(_onCalendarLoadingChanged);
    super.initState();
  }

  void _onVertretungsLoadingChanged() {
    if (!mounted) return;
    if (!(widget.vertretungsLoading.value ?? false)) vertretungLoading = widget.vertretungsLoading.value;
    setState(() {});
  }

  void _onCalendarLoadingChanged() {
    if (!mounted) return;
    if (!(widget.calendarLoading.value ?? false)) calendarLoading = widget.calendarLoading.value;
    setState(() {});
  }

  @override
  void dispose() {
    widget.vertretungsLoading.removeListener(_onVertretungsLoadingChanged);
    widget.calendarLoading.removeListener(_onCalendarLoadingChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) return const Center(child: CircularProgressIndicator());

    List<Konfiguration> konfigurationen = widget.isar.konfigurations.where().findAllSync()..sort((a, b) => a.position.compareTo(b.position));
    if (selectedKonfigurationIndex >= konfigurationen.length) selectedKonfigurationIndex = max(0, konfigurationen.length - 1);
    Konfiguration? konfiguration = konfigurationen.isEmpty ? null : konfigurationen[selectedKonfigurationIndex];
    bool emptyCalendar = konfigurationen.isEmpty;

    ButtonStyle selectedButtonStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.surfaceVariant),
    );

    //if its saturday or sunday and school-week-view, show the next monday
    int dayShift = view == CalendarView.workWeek && DateTime.now().weekday >= 6 ? 8-DateTime.now().weekday : 0;
    DateTime initialDisplayDate = DateTime.now().copyWith(hour: 7, minute: 55, day: DateTime.now().day + dayShift);

    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            title: Text(
              "${DateFormat("LLLL", "de_DE").format(controller.displayDate ?? DateTime.now())} ${controller.displayDate?.year.toString().substring(2) ?? ""}",
              overflow: TextOverflow.fade,
            ),
            surfaceTintColor: Colors.transparent,
            bottom: konfigurationen.length > 1
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          for (final (index, k) in konfigurationen.indexed)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                              child: ChoiceChip(
                                label: Text(k.name),
                                selected: index == selectedKonfigurationIndex,
                                onSelected: (_) {
                                  setState(() {
                                    selectedKonfigurationIndex = index;
                                  });
                                  prefs.setInt("stundenplanSelectedKonfigurationIndex", index);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                : null,
            actions: [
              IconButton(
                onPressed: () => controller.displayDate = DateTime.now().copyWith(hour: 7, minute: 30),
                icon: const Icon(Icons.today_rounded),
              ),
              IconButton(
                  onPressed: () => setState(() {
                    controller.view = CalendarView.day;
                    view = CalendarView.day;
                      }),
                  icon: const Icon(Icons.calendar_view_day_rounded),
                  style: view == CalendarView.day ? selectedButtonStyle : null),
              IconButton(
                  onPressed: () => setState(() {
                    controller.view = CalendarView.workWeek;
                    view = CalendarView.workWeek;
                  }),
                  icon: const Icon(Icons.view_week_outlined),
                  style: view == CalendarView.workWeek ? selectedButtonStyle : null),
              IconButton(
                onPressed: () => setState(() {
                  controller.view = CalendarView.week;
                  view = CalendarView.week;
                }),
                icon: const Icon(Icons.calendar_view_week_rounded),
                style: view == CalendarView.week ? selectedButtonStyle : null,
              ),
              PopupMenuButton(
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      child: Text("Vertretungsplan aktualisieren"),
                      onTap: () => widget.refreshVertretungsplan(),
                    ),
                    PopupMenuItem(
                      child: Text("Stundenplan aktualisieren"),
                      onTap: () => widget.refreshStundenplan(),
                    ),
                  ];
                },
              )
            ],
          ),
          body: Column(
            children: [
              if (calendarLoading == null || vertretungLoading == null)
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.errorContainer,
                  alignment: Alignment.center,
                  child: Text("Konnte ${[
                    if (vertretungLoading == null) "Vertretungsplan",
                    if (calendarLoading == null) "Stundenplan"
                  ].join(" und ")} nicht aktualisieren"),
                ),
              if(widget.calendarLoading.value == true || widget.vertretungsLoading.value == true)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: SfCalendar(
                  controller: controller,
                  view: view,
                  firstDayOfWeek: 1,
                  showWeekNumber: true,
                  showTodayButton: true,
                  headerHeight: 0,
                  initialDisplayDate: initialDisplayDate,
                  timeSlotViewSettings: const TimeSlotViewSettings(
                    timeIntervalHeight: 80,
                    timeFormat: "HH",
                  ),
                  allowViewNavigation: true,
                  allowedViews: const [
                    CalendarView.day,
                    CalendarView.workWeek,
                    CalendarView.week,
                  ],
                  appointmentBuilder: (context, calendarAppointmentDetails) {
                    Appointment appointment = ((calendarAppointmentDetails.appointments.first) as Appointment);
                    bool isTermin = (appointment.notes != null && appointment.notes!.isNotEmpty && appointment.notes! == "termin");
                    bool isVertretung = (!isTermin && appointment.notes != null && appointment.notes!.isNotEmpty);
                    ColorScheme colorScheme = Theme.of(context).colorScheme;

                    Map<String, dynamic> vertretungsMap = isVertretung ? jsonDecode(appointment.notes ?? "{}") : {};
                    return GestureDetector(
                      onTap: isVertretung
                          ? () => showDialog(
                                builder: (context) {
                                  double width = MediaQuery.of(context).size.width;
                                  return Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal:  (Platform.isWindows || Platform.isMacOS) ?
                                      width > 700 ? (width - 700)/2 +32 : 32
                                          : 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: klassenVertretungsBlock([Vertretung.fromMap(vertretungsMap)], theme: Theme.of(context)),
                                      ),
                                    ),
                                  );
                                },
                                context: context,
                              )
                          : isTermin
                              ? () => showDialog(
                                    builder: (context) {
                                      DateFormat dateFormat = DateFormat("dd.MM.yy\nHH:mm");

                                      return Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: colorScheme.secondaryContainer,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            child: IntrinsicHeight(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        dateFormat.format(appointment.startTime),
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          color: colorScheme.onSecondaryContainer,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 4,
                                                      ),
                                                      Text(
                                                        dateFormat.format(appointment.endTime),
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          color: colorScheme.onSecondaryContainer,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                                    child: VerticalDivider(
                                                      width: 1,
                                                      color: colorScheme.onSecondaryContainer,
                                                    ),
                                                  ),
                                                  Flexible(
                                                    child: Text(
                                                      appointment.subject,
                                                      style: TextStyle(
                                                        color: colorScheme.onSecondaryContainer,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    context: context,
                                  )
                              : null,
                      child: Container(
                        decoration: BoxDecoration(
                            color: isTermin
                                ? colorScheme.secondaryContainer
                                : isVertretung
                                    ? colorScheme.errorContainer
                                    : colorScheme.primaryContainer,
                            borderRadius: const BorderRadius.all(Radius.circular(4))),
                        width: calendarAppointmentDetails.bounds.width,
                        height: calendarAppointmentDetails.bounds.height,
                        child: Column(
                          children: [
                            Expanded(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(1.0),
                                  child: Text(
                                    appointment.subject,
                                    overflow: isTermin && appointment.isAllDay ? TextOverflow.ellipsis : null,
                                    maxLines: isTermin && appointment.isAllDay ? 1 : null,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isTermin ? colorScheme.onSecondaryContainer : null,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            if (isVertretung && vertretungsMap["eva"] != null)
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Icon(
                                    Ionicons.information_circle_outline,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.onErrorContainer,
                                  ),
                                ),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                  //viewNavigationMode: ViewNavigationMode.snap,
                  onViewChanged: (details) {
                    int visibleDates = details.visibleDates.length;
                    int view = visibleDates == 1
                        ? 0
                        : visibleDates == 7
                            ? 2
                            : 1;
                    this.view = controller.view ?? CalendarView.workWeek;
                    prefs.setInt("stundenplanView", view);
                    if (calendarInitialized)
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (context.mounted) setState(() {});
                      });
                    else
                      calendarInitialized = true;
                  },
                  selectionDecoration: const BoxDecoration(
                    color: Colors.transparent,
                    border: null,
                  ),
                  dataSource: konfiguration == null
                      ? getCalendarDataSourceFromStunden(stunden: const [])
                      : getCalendarDataSourceForKonfiguration(isar: widget.isar, prefs: prefs, konfiguration: konfiguration),
                ),
              ),
            ],
          ),
          floatingActionButton: emptyCalendar
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (context) => CourseSelection(isar: widget.isar)));
                    setState(() {});
                    widget.calendarLoading.value = false;
                  },
                  tooltip: 'Klicke hier um eine Klasse oder Stufe auszuwählen um sie in deinem Stundenplan anzuzeigen',
                  label: const Text("Klasse/Stufe auswählen"),
                  icon: const Icon(Ionicons.options_outline),
                )
              : null,
          ),
    );
  }
}

_AppointmentDataSource getCalendarDataSourceForKonfiguration(
    {required Isar isar, required SharedPreferences prefs, required Konfiguration konfiguration}) {
  String stufe = konfiguration.stufe;
  bool isOberstufe = konfiguration.isOberstufe;
  List<Stunde> stunden = isar.stundes.filter().konfigurationIdEqualTo(konfiguration.id).findAllSync();
  // Derived from the actual token count of each line (see kursKuerzel() in
  // database.dart), not from `isOberstufe` - Sek-I-Differenzierungskurse
  // (e.g. "F7 2 BSK 113" for a Klasse) also have a two-word Fach-Kürzel, so
  // guessing "one word unless Oberstufe" used to merge distinct
  // Differenzierungsgruppen (e.g. "F7 2" and "F7 3") into a single "F7".
  Set<String> kurse = stunden.map((e) => kursKuerzel(e.name)).toSet();
  List<Vertretung> vertretungen =
      isar.vertretungs.filter().klasseEqualTo(stufe).findAllSync().where((element) => !isOberstufe || kurse.contains(element.kurs)).toList();
  List<Stunde> vertretungsStunden = vertretungen
      .map((e) => Stunde()
        ..name =
            "${e.kurs.split("→").length >= 2 ? e.kurs.split("→")[1].trim() : e.kurs} ${e.lehrkraft} ${e.raum.split("→").length >= 2 ? e.raum.split("→")[1].trim() : e.raum}"
        ..tag = e.tag.weekday
        ..stunden = e.stunden
        ..geradeWoche = weekNumber(e.tag) % 2 == 0
        ..gueltigAb = e.tag
        ..gueltigBis = e.tag
        ..vertretung.value = e)
      .toList();

  List<Appointment> piusTermine = List<dynamic>.from(jsonDecode(prefs.getString("piusTermine") ?? "[]"))
      .map((e) => appointmentFromMap(Map<String, dynamic>.from(e))..notes = "termin")
      .toList();

  List<Appointment> feiertagTermine = List<dynamic>.from(jsonDecode(prefs.getString("feiertagTermine") ?? "[]"))
      .map((e) => appointmentFromMap(Map<String, dynamic>.from(e))..notes = "termin")
      .toList();

  piusTermine.removeWhere((element) =>
      feiertagTermine.any((feiertag) => feiertag.subject == element.subject && feiertag.startTime == element.startTime && feiertag.endTime == element.endTime));

  List<(DateTime, DateTime)> schulfreieZeiten = List.empty(growable: true);

  if (prefs.getBool("termineFrei") ?? true) {
    schulfreieZeiten.addAll(piusTermine.map((e) {
      List<int?> selectionIndices = ["für die jgst.", "für die jahrgangsstufe", "für die klasse"]
          .map((s) => e.subject.toLowerCase().contains(s) ? e.subject.toLowerCase().indexOf(s) + s.length : null)
          .toList();
      for (int sI in selectionIndices.nonNulls) {
        String substring = e.subject.substring(sI);
        String? stufe = substring.trim().split(" ").firstOrNull;
        //sort out alle nicht betroffenen stufen
        if (stufe != null && stufe.toLowerCase() != konfiguration.stufe.toLowerCase()) return null;
      }

      if (e.subject.toLowerCase().contains("ferien")) return (e.startTime, e.endTime);
      if (e.subject.toLowerCase().contains("unterrichtsfrei")) return (e.startTime, e.endTime);

      List<int?> endIndices = ["unterricht schließt um", "unterrichtsende um"]
          .map((s) => e.subject.toLowerCase().contains(s) ? e.subject.toLowerCase().indexOf(s) + s.length + 1 : null)
          .toList();
      for (int eI in endIndices.nonNulls) {
        String uhrzeit = e.subject.substring(eI, eI + 5).trim();
        int hour = int.tryParse(uhrzeit.split(":").first) ?? 0;
        int minute = int.tryParse(uhrzeit.split(":").last) ?? 0;
        return (e.startTime.copyWith(hour: hour, minute: minute), e.endTime.copyWith(hour: 23));
      }

      final keinUnterrichtRegex = RegExp(r'findet(?:.*?)? kein Unterricht statt');
      if (keinUnterrichtRegex.hasMatch(e.subject)) {
        return (e.startTime, e.endTime);
      }

      final stdKeinUnterrichtRegex = RegExp(r'(\d+)\.?\s?(?:\/?-?\\?\s?(\d+)\s*)?\. ?Std.? kein Unterricht');
      final match = stdKeinUnterrichtRegex.firstMatch(e.subject);
      try {
        if (match != null) {
          final start = int.parse(match.group(1) ?? "");
          final end = match.group(2) != null ? int.parse(match.group(2) ?? "") : start;
          (int, int) startZeit = stundenZeiten[start - 1];
          (int, int) endZeit = stundenZeiten[end - 1];
          return (
            e.startTime.copyWith(hour: startZeit.$1, minute: startZeit.$2),
            e.startTime.copyWith(hour: endZeit.$1, minute: endZeit.$2).add(const Duration(minutes: 45))
          );
        }
      } catch (e) {
        //if error then Std couldnt be matched apparently
        if (kDebugMode) {
          print(e);
        }
      }

      //TODO Fettdonnerstag: Unterricht sowie Klassenarbeiten und Klausuren bis 11:20 Uhr (5-Q1) bzw. 12:30 Uhr (Q2)

      return null;
    }).nonNulls);

  }

  if (prefs.getBool("feiertageFrei") ?? true) schulfreieZeiten.addAll(feiertagTermine.map((e) => (e.startTime, e.endTime)));

  List<Appointment> toShowTermine = List.empty(growable: true);
  if (prefs.getBool("showTermine") ?? true) toShowTermine.addAll(piusTermine);
  if (prefs.getBool("showFeiertage") ?? true) toShowTermine.addAll(feiertagTermine);

  return getCalendarDataSourceFromStunden(
      stunden: stunden..addAll(vertretungsStunden),
      vertretungen: vertretungen,
      isOberstufe: isOberstufe,
      schulfreieZeiten: schulfreieZeiten,
      termine: toShowTermine);
}

_AppointmentDataSource getCalendarDataSourceFromStunden(
    {required List<Stunde> stunden,
    List<(DateTime, DateTime)> schulfreieZeiten = const <(DateTime, DateTime)>[],
    List<Appointment> termine = const <Appointment>[],
    List<Vertretung> vertretungen = const <Vertretung>[],
    bool isOberstufe = false,
    bool realTime = true}) {

  List<Appointment> appointments = <Appointment>[];

  List<(int stunde, int minute)> uhrzeiten = realTime ? stundenZeiten : [for (int i = 0; i < 11; i++) (i, 30)];

  DateTime alternativeEndDate = DateTime.now().add(Duration(days: DateTime.now().month <= 7 ? 0 : 365)).copyWith(month: 7, day: 31);
  List<Appointment> sommerferien = termine.where((element) => element.subject.contains("Sommerferien")).toList();

  for (Stunde stunde in stunden) {
    // `stundenZeiten` kennt 11 Stunden. Eine Vertretung, die auf der Website
    // für eine spätere Stunde eingetragen ist (oder eine leere Stundenliste),
    // hat hier sonst einen RangeError geworfen - und damit den kompletten
    // Stundenplan statt nur dieses einen Eintrags unbrauchbar gemacht.
    if (stunde.stunden.isEmpty) continue;
    final (int uStunde, int uMinute) = uhrzeiten[stunde.stunden.first.clamp(0, uhrzeiten.length - 1)];
    final (int eStunde, int eMinute) = uhrzeiten[stunde.stunden.last.clamp(0, uhrzeiten.length - 1)];

    DateTime firstTime = getNextDateTimeWithWeekdayAndHour(stunde.gueltigAb, stunde.tag, uStunde, uMinute);
    if ((weekNumber(firstTime) % 2 == 0) != stunde.geradeWoche) {
      firstTime = firstTime.add(const Duration(days: 7));
    }
    final DateTime endTime = firstTime.copyWith(hour: eStunde, minute: eMinute).add(Duration(minutes: realTime ? 45 : 60));
    DateTime? nextSommerFerienStart = (sommerferien.where((element) => element.startTime.isAfter(stunde.gueltigAb)).toList()..sort((a, b) => a.startTime.compareTo(b.startTime))).firstOrNull?.startTime;
    final DateTime endDate = stunde.gueltigBis ?? (nextSommerFerienStart ?? alternativeEndDate);

    bool isVertretung = stunde.vertretung.value != null;
    List<DateTime> vertreteneTage = List.empty(growable: true);
    if (!isVertretung) {
      String kuerzel = kursKuerzel(stunde.name);
      Map<DateTime, List<int>> vertreteneStunden = {};
      for (Vertretung vertretung in vertretungen) {
        if (vertretung.tag.weekday == stunde.tag &&
            (vertretung.kurs.split("→").length >= 2 ? vertretung.kurs.split("→")[0].trim() : vertretung.kurs) == kuerzel) {
          if (vertreteneStunden[vertretung.tag] == null) vertreteneStunden[vertretung.tag] = List.empty(growable: true);
          vertreteneStunden[vertretung.tag]!.addAll(vertretung.stunden);
        }
      }
      for (DateTime tag in vertreteneStunden.keys) {
        List<int> stunden = vertreteneStunden[tag]!;
        if (stunde.stunden.every((element) => stunden.contains(element))) {
          vertreteneTage.add(tag);
        }
      }
    }

    //TODO wenn halbe stunde erwischt dann adde vertretenen tag und ein neues appointment für den tag

    if (firstTime.isBefore(endDate) || isVertretung) {
      appointments.add(Appointment(
          startTime: firstTime,
          endTime: endTime,
          subject: stunde.name,
          recurrenceExceptionDates: isVertretung ? null : vertreteneTage
            ?..addAll(schulfreieZeiten.map((e) {
              bool multiday = (e.$1.midnight().isBefore(e.$2.midnight()));
              bool dayTimeStartsAfter = (firstTime.hour > e.$1.hour || (firstTime.hour == e.$1.hour && firstTime.minute >= e.$1.minute));
              bool dayTimeEndsBefore = (endTime.hour < e.$2.hour || (endTime.hour == e.$2.hour && endTime.minute <= e.$2.minute));
              return [
              if(dayTimeStartsAfter && (multiday || dayTimeEndsBefore)) e.$1,
              if(dayTimeEndsBefore &&  (multiday || dayTimeStartsAfter)) e.$2,
              if(multiday) for (DateTime i = e.$1.add(const Duration(days: 1)); i.isBefore(e.$2.midnight()); i = i.add(const Duration(days: 1))) i
            ];
            }).expand((element) => element)),
          notes: stunde.vertretung.value?.toJSON(),
          recurrenceRule: stunde.vertretung.value != null
              ? null
              : SfCalendar.generateRRule(
                  RecurrenceProperties(
                      startDate: firstTime,
                      dayOfWeek: stunde.tag,
                      recurrenceType: RecurrenceType.weekly,
                      weekDays: [WeekDays.values[stunde.tag]],
                      interval: 2,
                      recurrenceRange: RecurrenceRange.endDate,
                      endDate: endDate),
                  firstTime,
                  endTime)));
    }
  }
  appointments.addAll(termine);

  return _AppointmentDataSource(appointments);
}

DateTime getNextDateTimeWithWeekdayAndHour(DateTime currentDateTime, int targetWeekday, int targetHour, int targetMinute) {
  // Calculate the days until the target weekday
  final daysUntilTarget = (targetWeekday - currentDateTime.weekday + 7) % 7;

  // Calculate the time until the target hour
  final hoursUntilTarget = (targetHour - currentDateTime.hour + 24) % 24;

  // Calculate the total minutes until the target time
  final minutesUntilTarget = daysUntilTarget * 24 * 60 + (hoursUntilTarget) * 60 - currentDateTime.minute + targetMinute;

  // Calculate the next DateTime
  final nextDateTime = currentDateTime.add(Duration(minutes: minutesUntilTarget));

  return nextDateTime;
}

// Calculates number of weeks for a given year as per https://en.wikipedia.org/wiki/ISO_week_date#Weeks_per_year
int numOfWeeks(int year) {
  DateTime dec28 = DateTime(year, 12, 28);
  int dayOfDec28 = int.parse(DateFormat("D").format(dec28));
  return ((dayOfDec28 - dec28.weekday + 10) / 7).floor();
}

// Calculates week number from a date as per https://en.wikipedia.org/wiki/ISO_week_date#Calculation
int weekNumber(DateTime date) {
  int dayOfYear = int.parse(DateFormat("D").format(date));
  int woy = ((dayOfYear - date.weekday + 10) / 7).floor();
  if (woy < 1) {
    woy = numOfWeeks(date.year - 1);
  } else if (woy > numOfWeeks(date.year)) {
    woy = 1;
  }
  return woy;
}

class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }

  @override
  bool isAllDay(int index) {
    return appointments![index].isAllDay;
  }
}
