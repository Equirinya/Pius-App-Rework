import 'dart:convert';
import 'dart:math';

import 'package:PiusApp/pages/settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:isar/isar.dart';
import '../connection.dart';
import '../database.dart';
import 'vertretungsplan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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

  @override
  void initState() {
    SharedPreferences.getInstance().then((value) {
      prefs = value;
      int? stundenplanView = prefs.getInt("stundenplanView");
      if(stundenplanView == null) prefs.setInt("stundenplanView", (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ? 2 : 1);
      view = prefs.getInt("stundenplanView") == 0
          ? CalendarView.day
          : prefs.getInt("stundenplanView") == 2
              ? CalendarView.week
              : CalendarView.workWeek;
      initialized = true;
      setState(() {});
    });
    widget.vertretungsLoading.addListener(() {
      if (!(widget.vertretungsLoading.value ?? false))
        vertretungLoading = widget.vertretungsLoading.value;
      setState(() {});
    });
    widget.calendarLoading.addListener(() {
      if (!(widget.calendarLoading.value ?? false))
        calendarLoading = widget.calendarLoading.value;
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) return const Center(child: CircularProgressIndicator());
    bool emptyCalendar = widget.isar.stundes.where().countSync() == 0;

    ButtonStyle selectedButtonStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.surfaceVariant),
    );

    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            title: Text(
              "${DateFormat("LLLL", "DE_de").format(controller.displayDate ?? DateTime.now())} ${controller.displayDate?.year.toString().substring(2) ?? ""}",
              overflow: TextOverflow.fade,
            ),
            surfaceTintColor: Colors.transparent,
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
                  initialDisplayDate: DateTime.now().copyWith(hour: 7, minute: 55, day: DateTime.now().day - DateTime.now().weekday + 1),
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
                  dataSource: _getCalendarDataSource(
                      isar: widget.isar,
                      prefs: prefs,
                      stufe: prefs.getString("stundenplanStufe") ?? "",
                      isOberstufe: prefs.getBool("stundenplanIsOberstufe") ?? false),
                ),
              ),
            ],
          ),
          floatingActionButton: emptyCalendar
              ? FloatingActionButton.extended(
                  onPressed: () => addStundenplan(context, widget.isar, prefs, () {
                    setState(() {});
                    widget.calendarLoading.value = false;
                  }),
                  tooltip: 'Klicke hier um eine Klasse oder Stufe auszuwählen um sie in deinem Stundenplan anzuzeigen',
                  label: const Text("Klasse/Stufe auswählen"),
                  icon: const Icon(Ionicons.options_outline),
                )
              : null
          // : FloatingActionButton(
          //     onPressed: addStundenplan,
          //     tooltip: 'Klicke hier um eine Klasse oder Stufe auszuwählen um sie in deinem Stundenplan anzuzeigen',
          //     child: const Icon(Ionicons.options_outline)),
          ),
    );
  }
}

void addStundenplan(BuildContext context, Isar isar, SharedPreferences prefs, VoidCallback refresh,
    [Function(List<Stunde> stunden, String stufe)? customKursSelection]) async {
  List<String> klassen = List.empty(growable: true);
  List<String> oberstufen = List.empty(growable: true);
  List<String> stufen = List.empty(growable: true);
  bool loading = false;
  PdfDocument? klassenplan;
  PdfDocument? oberstufenplan;

  showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text("Klasse/Stufe auswählen"),
            icon: const Icon(Ionicons.options_outline),
            content: StatefulBuilder(
              builder: (context, listSetState) {
                if (stufen.isEmpty) {
                  (() async {
                    try {
                      (klassenplan, oberstufenplan) = await getCurrentStundenplaene();

                      klassen = await compute(getStufen, klassenplan);
                      oberstufen = await compute(getStufen, oberstufenplan);
                      if (context.mounted) {
                        listSetState(() {
                          stufen.addAll(klassen);
                          stufen.addAll(oberstufen);
                        });
                      }
                    } catch (e) {
                      if (kDebugMode) {
                        print(e);
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Konnte Stundenpläne nicht abrufen: $e"),
                      ));
                    }
                  }).call();
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CupertinoActivityIndicator(),
                  );
                }
                if (loading || klassenplan == null || oberstufenplan == null) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CupertinoActivityIndicator(),
                  );
                }
                return SingleChildScrollView(
                    child: Column(
                  children: [
                    for (int i = 0; i < stufen.length; i++)
                      ListTile(
                        title: Text(stufen[i]),
                        onTap: () async {
                          if (i < klassen.length) {
                            listSetState(() {
                              loading = true;
                            });
                            setStundenplan(await compute(getStundenPlan, (klassen[i], klassenplan, false)), klassen[i], false, isar, prefs, refresh);
                            if (context.mounted) Navigator.pop(context);
                          } else {
                            listSetState(() {
                              loading = true;
                            });
                            List<Stunde> stunden = await compute(getStundenPlan, (oberstufen[i - klassen.length], oberstufenplan, true));
                            if (context.mounted) Navigator.pop(context);
                            if (customKursSelection != null) {
                              customKursSelection(stunden, oberstufen[i - klassen.length]);
                            } else {
                              showStundenplanSelection(stunden, oberstufen[i - klassen.length], () => context, isar, prefs, refresh);
                            }
                          }
                        },
                      ),
                  ],
                ));
              },
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Abbrechen"))],
          ));
}

void setStundenplan(List<Stunde> stunden, String stufe, bool isOberstufe, Isar isar, SharedPreferences prefs, VoidCallback refresh) async {
  await isar.writeTxn(() async {
    await isar.stundes.clear();
    await isar.stundes.putAll(stunden);
  });
  await prefs.setString("stundenplanStufe", stufe);
  await prefs.setBool("stundenplanIsOberstufe", isOberstufe);
  refresh();
  try {
    await Future.delayed(const Duration(seconds: 10));
    await updateStundenplan(isar);
  } catch (e) {
    if (kDebugMode) print(e);
  }
  refresh();
}

Future<bool> showStundenplanSelection(
    List<Stunde> stunden, String stufe, BuildContext Function() getContext, Isar isar, SharedPreferences prefs, VoidCallback refresh) async {
  DateTime initialDisplayDate = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1, hours: DateTime.now().hour, minutes: DateTime.now().minute));
  if (stunden.isNotEmpty && initialDisplayDate.isBefore(stunden.first.gueltigAb)) {
    DateTime firstTime = stunden.first.gueltigAb;
    initialDisplayDate =
        firstTime.add(const Duration(days: 7)).subtract(Duration(days: firstTime.weekday - 1, hours: firstTime.hour, minutes: firstTime.minute));
  }
  CalendarDataSource dataTableSource = _getCalendarDataSourceFromStunden(stunden: stunden, realTime: false);
  Map<Stunde, bool> activeStunden = {for (var item in stunden) item: false};
  var result = await Navigator.push(getContext(), MaterialPageRoute(builder: (context) {
    CalendarController calendarController = CalendarController();
    bool flyby = false;
    bool visitedFriday = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Wähle deine Kurse"),
          ),
          body: SfCalendar(
            initialDisplayDate: initialDisplayDate,
            view: CalendarView.day,
            controller: calendarController,
            onViewChanged: (viewChangedDetails) {
              if (viewChangedDetails.visibleDates.first.weekday == 5) {
                setState(() {
                  visitedFriday = true;
                });
              }
              if (flyby) return;
              if (viewChangedDetails.visibleDates.first.weekday == 6) {
                flyby = true;
                calendarController.forward!();
                calendarController.forward!();
                flyby = false;
              }
              if (viewChangedDetails.visibleDates.first.weekday == 7) {
                flyby = true;
                calendarController.backward!();
                calendarController.backward!();
                flyby = false;
              }
            },
            dataSource: dataTableSource,
            allowViewNavigation: false,
            showCurrentTimeIndicator: false,
            showTodayButton: false,
            showWeekNumber: true,
            appointmentBuilder: (context, calendarAppointmentDetails) {
              Appointment appointment = ((calendarAppointmentDetails.appointments.first) as Appointment);
              bool? active = activeStunden[stunden.firstWhere((element) => element.name == appointment.subject)];
              if (active == null) throw StateError("couldnt find active Stunde");
              return GestureDetector(
                onTap: () => setState(() {
                  List<Stunde> stundenToActivate = stunden
                      .where((element) => element.name.split(" ").getRange(0, 2).join(" ") == appointment.subject.split(" ").getRange(0, 2).join(" "))
                      .toList();
                  for (Stunde stunde in stundenToActivate) {
                    activeStunden[stunde] = !active;
                  }
                }),
                child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      color: active ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.all(Radius.circular(4))),
                  width: calendarAppointmentDetails.bounds.width,
                  height: calendarAppointmentDetails.bounds.height,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: Text(
                        appointment.subject,
                        style: const TextStyle(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            },
            timeSlotViewSettings: const TimeSlotViewSettings(
              timeFormat: "HH",
              startHour: 0,
              endHour: 12,
              timeIntervalHeight: 80,
            ),
            viewHeaderStyle: const ViewHeaderStyle(
              dateTextStyle: TextStyle(color: Colors.transparent, fontSize: 0),
            ),
            minDate: initialDisplayDate,
            maxDate: initialDisplayDate.add(const Duration(days: 12)).subtract(const Duration(minutes: 1)),
            selectionDecoration: const BoxDecoration(
              color: Colors.transparent,
              border: null,
            ),
          ),
          floatingActionButton: AnimatedScale(
            duration: const Duration(milliseconds: 300),
            scale: visitedFriday ? 1 : 0,
            child: FloatingActionButton.extended(
              heroTag: null,
              onPressed: () {
                setStundenplan((activeStunden..removeWhere((key, value) => !value)).keys.toList(), stufe, true, isar, prefs, refresh);
                Navigator.of(context).pop(true);
              },
              icon: const Icon(Ionicons.checkmark),
              label: const Text("Kursauswahl bestätigen"),
            ),
          ),
        );
      },
    );
  }));
  if (result is bool) return result;
  return false;
}

_AppointmentDataSource _getCalendarDataSource({required Isar isar, required SharedPreferences prefs, required String stufe, required bool isOberstufe}) {
  List<Stunde> stunden = isar.stundes.where().findAllSync();
  Set<String> kurse = stunden.map((e) {
    List<String> split = e.name.split(" ");
    return isOberstufe ? "${split[0]} ${split[1]}" : split[0];
  }).toSet();
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
        if (stufe != null && stufe.toLowerCase() != prefs.getString("stundenplanStufe")?.toLowerCase()) return null;
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

  return _getCalendarDataSourceFromStunden(
      stunden: stunden..addAll(vertretungsStunden),
      vertretungen: vertretungen,
      isOberstufe: isOberstufe,
      schulfreieZeiten: schulfreieZeiten,
      termine: toShowTermine);
}

_AppointmentDataSource _getCalendarDataSourceFromStunden(
    {required List<Stunde> stunden,
    List<(DateTime, DateTime)> schulfreieZeiten = const <(DateTime, DateTime)>[],
    List<Appointment> termine = const <Appointment>[],
    List<Vertretung> vertretungen = const <Vertretung>[],
    bool isOberstufe = false,
    bool realTime = true}) {
  List<Appointment> appointments = <Appointment>[];

  List<(int stunde, int minute)> uhrzeiten = realTime ? stundenZeiten : [for (int i = 0; i < 11; i++) (i, 30)];

  DateTime alternativeEndDate = DateTime.now().add(Duration(days: DateTime.now().month <= 7 ? 0 : 365)).copyWith(month: 7, day: 31);
  Appointment? sommerferien = termine.where((element) => element.subject.contains("Sommerferien")).firstOrNull;
  if (sommerferien != null) alternativeEndDate = sommerferien.startTime;

  for (Stunde stunde in stunden) {
    final (int uStunde, int uMinute) = uhrzeiten[stunde.stunden.first];
    final (int eStunde, int eMinute) = uhrzeiten[stunde.stunden.last];

    DateTime firstTime = getNextDateTimeWithWeekdayAndHour(stunde.gueltigAb, stunde.tag, uStunde, uMinute);
    if ((weekNumber(firstTime) % 2 == 0) != stunde.geradeWoche) {
      firstTime = firstTime.add(const Duration(days: 7));
    }
    final DateTime endTime = firstTime.copyWith(hour: eStunde, minute: eMinute).add(Duration(minutes: realTime ? 45 : 60));
    final DateTime endDate = stunde.gueltigBis ?? alternativeEndDate;

    bool isVertretung = stunde.vertretung.value != null;
    List<DateTime> vertreteneTage = List.empty(growable: true);
    if (!isVertretung) {
      List<String> split = stunde.name.split(" ");
      Map<DateTime, List<int>> vertreteneStunden = {};
      for (Vertretung vertretung in vertretungen) {
        if (vertretung.tag.weekday == stunde.tag &&
            (vertretung.kurs.split("→").length >= 2 ? vertretung.kurs.split("→")[0].trim() : vertretung.kurs) ==
                (isOberstufe ? "${split[0]} ${split[1]}" : split[0])) {
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
            ?..addAll(schulfreieZeiten
                .where((e) => //only works if multi day freie tage are from 0:00 to 23:59
                    (firstTime.hour > e.$1.hour || (firstTime.hour == e.$1.hour && firstTime.minute >= e.$1.minute)) &&
                    (endTime.hour < e.$2.hour || (endTime.hour == e.$2.hour && endTime.minute <= e.$2.minute)))
                .map((e) => [for (DateTime i = e.$1; i.isBefore(e.$2); i = i.add(const Duration(days: 1))) i])
                .expand((element) => element)),
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
