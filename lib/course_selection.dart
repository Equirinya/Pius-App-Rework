import 'package:PiusApp/pages/stundenplan.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'connection.dart';
import 'database.dart';

class CourseSelection extends StatefulWidget {
  const CourseSelection({super.key, required this.isar, required this.refresh});

  final Isar isar;
  final VoidCallback refresh;

  @override
  State<CourseSelection> createState() => _CourseSelectionState();
}

class _CourseSelectionState extends State<CourseSelection> with SingleTickerProviderStateMixin {
  late TabController tabController;
  int? selectedTab;
  late SharedPreferences prefs;
  bool initialized = false;
  bool downloaded = false;
  String? error;

  PdfDocument? klassenplan;
  PdfDocument? oberstufenplan;
  List<String> klassen = List.empty(growable: true);
  List<String> oberstufen = List.empty(growable: true);
  List<String> stufenLoading = List.empty(growable: true);
  Map<String, List<Stunde>> stufenStunden = {};

  String? selectedStufe;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    asyncInit();
  }

  void asyncInit() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      initialized = true;
    });
    try {
      var currentStundenplaene = await getCurrentStundenplaene();
      klassenplan = currentStundenplaene.$1;
      oberstufenplan = currentStundenplaene.$2;

      klassen = await compute(getStufen, klassenplan);
      oberstufen = await compute(getStufen, oberstufenplan);
      if (context.mounted) {
        setState(() {
          error = null;
          downloaded = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      error = "Konnte Stundenpläne nicht abrufen: $e";
    }
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
    DateTime initialDisplayDate =
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1, hours: DateTime.now().hour, minutes: DateTime.now().minute));
    if (stunden.isNotEmpty && initialDisplayDate.isBefore(stunden.first.gueltigAb)) {
      DateTime firstTime = stunden.first.gueltigAb;
      initialDisplayDate =
          firstTime.add(const Duration(days: 7)).subtract(Duration(days: firstTime.weekday - 1, hours: firstTime.hour, minutes: firstTime.minute));
    }
    CalendarDataSource dataTableSource = getCalendarDataSourceFromStunden(stunden: stunden, realTime: false);
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

  Future<void> computeStundenFuerStufe(String stufe, bool oberstufe) async {
    if (stufenStunden.containsKey(stufe)) return;
    stufenStunden[stufe] = await compute(getStundenPlan, (stufe, oberstufe ? oberstufenplan : klassenplan, oberstufe));
  }

  void stufeSelected(String stufe, bool oberstufe) async {
    if(!stufenStunden.containsKey(stufe) && !stufenLoading.contains(stufe)) {
      setState(() {
        stufenLoading.add(stufe);
      });
      await computeStundenFuerStufe(stufe, false);
      setState(() {
        stufenLoading.remove(stufe);
      });
    }
    setStundenplan(stufenStunden[klassen[i]]!, klassen[i], false, widget.isar, prefs, widget.refresh);
    if (context.mounted) Navigator.pop(context);
  }


  //TODO
  // flow:
  // 1. select tab
  // 2. select stufe

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error!),
          ElevatedButton(
              onPressed: () {
                asyncInit();
              },
              child: const Text("Erneut versuchen"))
        ],
      ));
    }

    if (!initialized) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if(selectedTab == null) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Ionicons.options_outline),
            Text("Klasse/Stufe auswählen", style: Theme
                .of(context)
                .textTheme
                .headlineSmall),
            Text("Wenn du die App bereits auf einem anderen Gerät installiert hast, kannst du deine Kurse auch mit einem QR-Code scannen oder aus einer Liste importieren."),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedTab = 0;
                  });
                },
                child: const Text("Manuell auswählen"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedTab = 1;
                  });
                },
                child: const Text("QR-Code scannen"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedTab = 2;
                  });
                },
                child: const Text("Aus Liste importieren"),
              ),
            ),
          ],
        ),
      );
    }

    List<Widget> stufenSelection = downloaded ? [ListTile(
      title: Text(stufen[i]),
      onTap: () async {
        if (i < klassen.length) {

        } else {
          setState(() {
            stufenLoading.add(i);
          });

          await computeStundenFuerStufe(oberstufen[i - klassen.length], true);
          List<Stunde> stunden = stufenStunden[oberstufen[i - klassen.length]]!;
          if (customKursSelection != null) {
            customKursSelection(stunden, oberstufen[i - klassen.length]);
          } else {
            showStundenplanSelection(stunden, oberstufen[i - klassen.length], () => context, isar, prefs, refresh);
          }
        }
      },
    ),] : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Klasse/Kurse auswählen"),
        bottom: TabBar(
          controller: tabController,
          tabs: [
            Tab(icon: Icon(Icons.rule), text: "Manuell auswählen"),
            Tab(icon: Icon(Icons.qr_code_scanner), text: "QR-Code scannen"),
            Tab(icon: Icon(Icons.list), text: "Liste importieren"),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          downloaded ? Placeholder() : const Center(child: CupertinoActivityIndicator()),
          downloaded ? Center(child: Text("QR-Code Scanning not suppoerted yet"),) : const Center(child: CupertinoActivityIndicator()),
          downloaded ? Placeholder() : const Center(child: CupertinoActivityIndicator()),
        ],
      ),
    );
  }
}
