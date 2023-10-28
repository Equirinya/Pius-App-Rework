import 'dart:convert';
import 'dart:math';

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

//on load load stundenplan dateien if namen unterschiedlich
//on add nur bis nächste sommerferien

//TODO klausurenplan
//TODO show original classes on vertetung dialog

class StundenplanPage extends StatefulWidget {
  const StundenplanPage({super.key, required this.isar, required this.vertretungsLoading, required this.calendarLoading});

  final Isar isar;
  final ValueNotifier<bool?> vertretungsLoading;
  final ValueNotifier<bool?> calendarLoading;

  @override
  State<StundenplanPage> createState() => _StundenplanPageState();
}

class _StundenplanPageState extends State<StundenplanPage> {
  void setStundenplan(List<Stunde> stunden, String stufe, bool isOberstufe) {
    widget.isar.writeTxnSync(() {
      widget.isar.stundes.clearSync(); //TODO nur alle löschen die nicht vor aktuellem zeitraum enden
      widget.isar.stundes.putAllSync(stunden);
    });
    prefs.setString("stundenplanStufe", stufe);
    prefs.setBool("stundenplanIsOberstufe", isOberstufe);
    setState(() {});
  }

  void showStundenplanSelection(List<Stunde> stunden, String stufe) {
    CalendarDataSource dataTableSource = _getCalendarDataSourceFromStunden(stunden: stunden, realTime: false);
    Map<Stunde, bool> activeStunden = {for (var item in stunden) item: false};
    Navigator.push(context, MaterialPageRoute(builder: (context) {
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
              initialDisplayDate: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
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
                    List<Stunde> stundenToActivate = stunden.where((element) => element.name == appointment.subject).toList();
                    for (Stunde stunde in stundenToActivate) {
                      activeStunden[stunde] = !active;
                    }
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                        border: active
                            ? null
                            : Border.all(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.all(Radius.circular(4))),
                    width: calendarAppointmentDetails.bounds.width,
                    height: calendarAppointmentDetails.bounds.height,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: Text(
                          appointment.subject,
                          style: TextStyle(),
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
              minDate: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1, hours: DateTime.now().hour, minutes: DateTime.now().minute)),
              maxDate: DateTime.now()
                  .add(Duration(days: min(5, max(0, 5 - DateTime.now().weekday)), hours: 23 - DateTime.now().hour, minutes: 59 - DateTime.now().minute))
                  .add(const Duration(days: 7)),
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
                  setStundenplan((activeStunden..removeWhere((key, value) => !value)).keys.toList(), stufe, true);
                  Navigator.of(context).pop();
                },
                icon: Icon(Ionicons.checkmark),
                label: Text("Kursauswahl bestätigen"),
              ),
            ),
          );
        },
      );
    }));
  }

  void addStundenplan() async {
    List<String> klassen = List.empty(growable: true);
    List<String> oberstufen = List.empty(growable: true);
    List<String> stufen = List.empty(growable: true);
    bool loading = false;
    if (!context.mounted) return;
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Klasse/Stufe auswählen"),
              icon: const Icon(Ionicons.options_outline),
              content: StatefulBuilder(
                builder: (context, setState) {
                  if (stufen.isEmpty) {
                    try {
                      getCurrentStundenplaene().then((value) async {
                        klassenplan = value.$1;
                        oberstufenplan = value.$2;
                        await getStufen(value.$1, value.$2).then((value) =>
                            setState(() {
                              klassen = value.$1;
                              oberstufen = value.$2;
                              stufen.addAll(klassen);
                              stufen.addAll(oberstufen);
                            }));
                      });
                    } catch (e) {
                      if (kDebugMode) {
                        print(e);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Konnte Stundenpläne nicht abrufen: $e"),
                        ));
                      }
                    }
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CupertinoActivityIndicator(),
                    );
                  }
                  if (loading) {
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
                              Navigator.pop(context);
                              setStundenplan(await getStundenPlan(klassen[i], klassenplan, oberstufenplan), klassen[i], false);
                            } else {
                              setState(() {
                                loading = true;
                              });
                              List<Stunde> stunden = await getStundenPlan(oberstufen[i - klassen.length], klassenplan, oberstufenplan);
                              if (context.mounted) Navigator.pop(context);
                              showStundenplanSelection(stunden, oberstufen[i - klassen.length]);
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

  late SharedPreferences prefs;
  bool initialized = false;
  bool? calendarLoading = false;
  bool? vertretungLoading = false;
  late PdfDocument klassenplan;
  late PdfDocument oberstufenplan;

  @override
  void initState() {
    SharedPreferences.getInstance().then((value) {
      prefs = value;
      initialized = true;
      setState(() {});
    });
    widget.vertretungsLoading.addListener(() {
      if (!(widget.vertretungsLoading.value ?? false))
        setState(() {
          vertretungLoading = widget.vertretungsLoading.value;
        });
    });
    widget.calendarLoading.addListener(() {
      if (!(widget.calendarLoading.value ?? false))
        setState(() {
          calendarLoading = widget.calendarLoading.value;
        });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) return const Center(child: CircularProgressIndicator());
    bool emptyCalendar = widget.isar.stundes.where().countSync() == 0;

    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            if (calendarLoading == null || vertretungLoading == null)
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.errorContainer,
                alignment: Alignment.center,
                child: Text(
                    "Konnte ${[if (vertretungLoading == null) "Vertretungsplan", if (calendarLoading == null) "Kalender"].join(" und ")} nicht aktualisieren"),
              ),
            Expanded(
              child: SfCalendar(
                view: prefs.getInt("stundenplanView") == 0
                    ? CalendarView.day
                    : prefs.getInt("stundenplanView") == 2
                        ? CalendarView.week
                        : CalendarView.workWeek,
                firstDayOfWeek: 1,
                showWeekNumber: true,
                showTodayButton: true,
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
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
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
                                                    SizedBox(
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
                  prefs.setInt("stundenplanView", view);
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
                onPressed: addStundenplan,
                tooltip: 'Klicke hier um eine Klasse oder Stufe auszuwählen um sie in deinem Stundenplan anzuzeigen',
                label: Text("Klasse/Stufe auswählen"),
                icon: const Icon(Ionicons.options_outline),
              )
            : FloatingActionButton(
                onPressed: addStundenplan,
                tooltip: 'Klicke hier um eine Klasse oder Stufe auszuwählen um sie in deinem Stundenplan anzuzeigen',
                child: const Icon(Ionicons.options_outline)),
      ),
    );
  }
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

  List<DateTime> schulfreieTage = piusTermine
      .where((element) => element.subject.toLowerCase().contains("unterrichtsfrei") || element.subject.toLowerCase().contains("ferien"))
      .map((e) {
        return [for (DateTime i = e.startTime; i.isBefore(e.endTime); i = i.add(const Duration(days: 1))) i];
      })
      .expand((element) => element)
      .toList();

  return _getCalendarDataSourceFromStunden(
      stunden: stunden..addAll(vertretungsStunden),
      vertretungen: vertretungen,
      isOberstufe: isOberstufe,
      schulfreieTage: schulfreieTage,
      termine: (prefs.getBool("showTermine") ?? true) ? piusTermine : List.empty());
}

_AppointmentDataSource _getCalendarDataSourceFromStunden(
    {required List<Stunde> stunden,
    List<DateTime> schulfreieTage = const <DateTime>[],
    List<Appointment> termine = const <Appointment>[],
    List<Vertretung> vertretungen = const <Vertretung>[],
    bool isOberstufe = false,
    bool realTime = true}) {
  List<Appointment> appointments = <Appointment>[];

  List<(int stunde, int minute)> uhrzeiten = realTime
      ? [(7, 55), (8, 40), (9, 45), (10, 35), (11, 25), (12, 40), (13, 25), (14, 30), (15, 15), (16, 00), (16, 45)]
      : [for (int i = 0; i < 11; i++) (i, 30)]; //TODO settings

  DateTime alternativeEndDate = DateTime.now().add(Duration(days: DateTime.now().month <= 7 ? 0 : 365)).copyWith(month: 7, day: 31);
  Appointment? sommerferien = termine.where((element) => element.subject.contains("Sommerferien")).firstOrNull;
  if (sommerferien != null) alternativeEndDate = sommerferien.startTime;

  for (Stunde stunde in stunden) {
    final (int uStunde, int uMinute) = uhrzeiten[stunde.stunden.first];
    final (int eStunde, int eMinute) = uhrzeiten[stunde.stunden.last];
    DateTime firstTime = getNextDateTimeWithWeekdayAndHour(stunde.gueltigAb, stunde.tag, uStunde, uMinute);
    // print(weekNumber(firstTime));
    if ((weekNumber(firstTime) % 2 == 0) != stunde.geradeWoche) {
      firstTime = firstTime.add(const Duration(days: 7));
    }
    final DateTime endTime = firstTime.copyWith(hour: eStunde, minute: eMinute).add(Duration(minutes: realTime ? 45 : 60));

    // print("$firstTime : $endTime");
    // print(firstTime.day);
    bool isVertretung = stunde.vertretung.value != null;
    List<DateTime> vertreteneTage = List.empty(growable: true);
    if (!isVertretung) {
      List<String> split = stunde.name.split(" ");
      for (Vertretung vertretung in vertretungen) {
        if (vertretung.tag.weekday == stunde.tag &&
            vertretung.stunden.contains(stunde.stunden.first) &&
            (vertretung.kurs.split("→").length >= 2 ? vertretung.kurs.split("→")[0].trim() : vertretung.kurs) ==
                (isOberstufe ? "${split[0]} ${split[1]}" : split[0])) {
          vertreteneTage.add(vertretung.tag);
        }
      }
    }

    appointments.add(Appointment(
        startTime: firstTime,
        endTime: endTime,
        subject: stunde.name,
        recurrenceExceptionDates: isVertretung ? null : vertreteneTage
          ?..addAll(schulfreieTage),
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
                    endDate: stunde.gueltigBis ?? alternativeEndDate),
                firstTime,
                endTime)));
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
    print(appointments![index].isAllDay);
    return appointments![index].isAllDay;
  }
}
