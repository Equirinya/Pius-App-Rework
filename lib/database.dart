//dart run build_runner build
import 'package:isar/isar.dart';

part 'database.g.dart';

@Collection()
class Vertretung {
  late Id id = Isar.autoIncrement;
  late String klasse;
  late String stunde;
  late String art;
  late String kurs;
  late String raum;
  late String lehrkraft;
  late String bemerkung;
  late DateTime tag;
}