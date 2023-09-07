import 'dart:math';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class StundenplanPage extends StatelessWidget {
  StundenplanPage({super.key, required this.isar});

  final Isar isar;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SfCalendar(
          view: CalendarView.workWeek,
          minDate: DateTime.now().subtract(Duration(days: DateTime.now().weekday-1, hours: DateTime.now().hour, minutes: DateTime.now().minute)),
          maxDate: DateTime.now().add(const Duration(days: 7)).add(Duration(days: min(5, max(0, 5-DateTime.now().weekday)), hours: 24- DateTime.now().hour, minutes: 60- DateTime.now().minute)),
          timeSlotViewSettings: TimeSlotViewSettings(
            startHour: 7,
            timeInterval: Duration(minutes: 15),
            endHour: 17,
            timeFormat: "HH:mm",
            timeIntervalHeight: 20,
          ),
        ),
      ),
    );
  }
}
