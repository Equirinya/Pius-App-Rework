import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:isar/isar.dart';
import '../connection.dart';
import '../database.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VertretungsplanPage extends StatefulWidget {
  const VertretungsplanPage({super.key, required this.isar, required this.loadingNotifier, required this.refresh});

  final Isar isar;
  final ValueNotifier<bool?> loadingNotifier;
  final VoidCallback refresh;

  @override
  State<VertretungsplanPage> createState() => _VertretungsplanPageState();
}

class _VertretungsplanPageState extends State<VertretungsplanPage> {
  bool filter = false;
  late SharedPreferences prefs;
  bool initialized = false;
  bool? loading = false;

  @override
  void initState() {
    SharedPreferences.getInstance().then((value) {
      prefs = value;
      initialized = true;
      setState(() {
        filter = prefs.getBool("filterOn") ?? false;
      });
    });
    loading = widget.loadingNotifier.value;
    widget.loadingNotifier.addListener(() {
      setState(() {
        loading = widget.loadingNotifier.value;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) return const Center(child: CircularProgressIndicator());

    int? stand = prefs.getInt("vertretungLastDownload");
    Set<DateTime> tage = widget.isar.vertretungs.where().tagProperty().findAllSync().toSet();
    List<String> filters = prefs.getStringList("filter") ?? [];
    List<String> klassenFilter = filters.map((e) {
      List<String> split = e.split(" ");
      if (split.length == 1)
        return e;
      else
        return split[0];
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Vertretungsplan ${stand != null ? "(${DateFormat('dd.MM.yy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(stand))})" : ""}"),
        actions: [
          IconButton(
            onPressed: widget.refresh,
            icon: const Icon(Ionicons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (filter)
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: -4,
                  children: [
                    for (String filter in filters)
                      InputChip(
                        label: Text(filter),
                        onDeleted: () {
                          filters.remove(filter);
                          prefs.setStringList("filter", filters);
                          setState(() {});
                        },
                      ),
                    ActionChip(
                        label: Text("Hinzufügen"),
                        onPressed: () async {
                          String? filter = await showDialog(
                              context: context,
                              builder: (context) {
                                TextEditingController controller = TextEditingController();
                                return AlertDialog(
                                  title: const Text("Filter hinzufügen"),
                                  content: TextField(
                                    controller: controller,
                                    onChanged: (value) {
                                      controller.text = value.toUpperCase();
                                    },
                                    decoration: InputDecoration(hintText: "Filter"),
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text("Abbrechen")),
                                    TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, controller.text);
                                        },
                                        child: const Text("Hinzufügen")),
                                  ],
                                );
                              });
                          if (filter != null && filter.isNotEmpty) {
                            filters.add(filter);
                            prefs.setStringList("filter", filters);
                            setState(() {});
                          }
                        }),
                  ],
                ),
              ),
            ),
          if (filter)
            const Divider(
              height: 1,
            ),
          if (loading ?? false) LinearProgressIndicator(minHeight: 2),
          if(loading == null) Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.errorContainer,
            alignment: Alignment.center,
            child: Text("Konnte Vertretungsplan nicht aktualisieren"),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 72),
              children: [
                Text("Tickertext:\n${prefs.getString("ticker") ?? ""}"),
                for (DateTime tag in tage) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                        "${[
                          "Montag",
                          "Dienstag",
                          "Mittwoch",
                          "Donnerstag",
                          "Freitag",
                          "Samstag",
                          "Sonntag"
                        ][tag.weekday - 1]}, der ${DateFormat('dd.MM.yyyy').format(tag)}",
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
                  Text("betroffen: ${widget.isar.vertretungs.filter().tagEqualTo(tag).klasseProperty().findAllSync().toSet().join(", ")}"),
                  for (String klasse in filter
                      ? widget.isar.vertretungs.filter().tagEqualTo(tag).klasseProperty().findAllSync().toSet().intersection(klassenFilter.toSet())
                      : widget.isar.vertretungs.filter().tagEqualTo(tag).klasseProperty().findAllSync().toSet())
                    if (widget.isar.vertretungs
                        .filter()
                        .tagEqualTo(tag)
                        .klasseEqualTo(klasse)
                        .findAllSync()
                        .where((element) => !filter || filters.any((filter) => filter == "${element.klasse} ${element.kurs}" || filter == element.klasse))
                        .toList()
                        .isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: klassenVertretungsBlock(
                            widget.isar.vertretungs
                                .filter()
                                .tagEqualTo(tag)
                                .klasseEqualTo(klasse)
                                .findAllSync()
                                .where(
                                    (element) => !filter || filters.any((filter) => filter == "${element.klasse} ${element.kurs}" || filter == element.klasse))
                                .toList()..sort((a, b) => a.stunden.first.compareTo(b.stunden.first)),
                            theme: Theme.of(context),
                            shorten: prefs.getBool("abbreviations") ?? true,
                          ),
                        ),
                      ),
                ]
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => setState(() {
          filter = !filter;
          prefs.setBool("filterOn", filter);
        }),
        tooltip: 'Filter',
        child: Icon(filter ? Ionicons.filter : Ionicons.filter_outline),
      ),
    );
  }
}

Widget klassenVertretungsBlock(List<Vertretung> vertretungsBlock,
    {List<double> columnWidths = const [45, 72, 52, 60, 40], required ThemeData theme, bool shorten = true, double fontSize = 12}) {
  List<String> headers =
      shorten ? ["Stunde", "Art", "Kurs", "Raum", "akt.", "Bemerkung"] : ["Stunde(n)", "Art", "Fach / Kurs", "Raum", "Lehrkraft aktuell", "Bemerkung"];

  VertretungsColors? vertretungsColors = theme.extension<VertretungsColors>();
  Color darkColor = vertretungsColors?.headerColor ?? theme.colorScheme.secondaryContainer;
  Color lightColor = vertretungsColors?.mainColor ?? theme.colorScheme.primaryContainer;
  Color errorColor = vertretungsColors?.replacementColor ?? theme.colorScheme.errorContainer;
  Color evaColor = vertretungsColors?.evaColor ?? theme.colorScheme.tertiaryContainer;
  Color backgroundColor = theme.colorScheme.background;
  List<Color> textColors = [theme.colorScheme.surface, theme.colorScheme.inverseSurface]..sort((a, b) => a.computeLuminance().compareTo(b.computeLuminance()));
  Color lightTextColor = textColors.last;
  Color darkTextColor = textColors.first;

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: double.infinity,
        color: darkColor,
        child: Padding(
          padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
          child: Text(
            vertretungsBlock.first.klasse,
            style: TextStyle(
              fontSize: 16,
              color: vertretungsColors != null
                  ? darkColor.computeLuminance() > 0.5
                  ? darkTextColor
                  : lightTextColor
                  : null,
            ),
          ),
        ),
      ),
      Divider(
        color: backgroundColor,
        height: 0,
      ),
      Table(
        columnWidths: <int, TableColumnWidth>{for (int i = 0; i < columnWidths.length; i++) i: FixedColumnWidth(columnWidths[i])},
        children: [
          TableRow(
            decoration: BoxDecoration(color: darkColor),
            children: [
              for (String header in headers)
                TableCell(
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      header,
                      style: TextStyle(fontSize: fontSize,
                        color: vertretungsColors != null
                        ? darkColor.computeLuminance() > 0.5
                            ? darkTextColor
                            : lightTextColor
                        : null,),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      for (Vertretung vertretung in vertretungsBlock) ...[
        Table(
            border: TableBorder(verticalInside: BorderSide(color: backgroundColor, width: 1), top: BorderSide(color: backgroundColor, width: 1)),
            columnWidths: <int, TableColumnWidth>{
              for (int i = 0; i < columnWidths.length; i++) i: FixedColumnWidth(columnWidths[i])
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: lightColor),
                children: [
                  for (final (int i, String text) in [
                    vertretung.stunden.length > 1
                        ? "${vertretung.stunden.first + 1} - ${vertretung.stunden.last + 1}"
                        : (vertretung.stunden.first + 1).toString(),
                    vertretung.art,
                    vertretung.kurs,
                    vertretung.raum,
                    vertretung.lehrkraft,
                    vertretung.bemerkung ?? "",
                  ].indexed)
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.top,
                      child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          color: vertretung.hervorgehoben.contains(i) ? errorColor : lightColor,
                          child: Text(
                            text,
                            style: TextStyle(fontSize: fontSize,
                              color: vertretungsColors != null
                                  ? (vertretung.hervorgehoben.contains(i) ? errorColor : lightColor).computeLuminance() > 0.5
                                  ? darkTextColor
                                  : lightTextColor
                                  : null,),
                            textAlign: TextAlign.center,
                          )),
                    )
                ],
              ),
            ]),
        if (vertretung.eva != null && vertretung.eva!.isNotEmpty) ...[
          Divider(
            color: backgroundColor,
            height: 0,
          ),
          Container(
            width: double.infinity,
            color: evaColor,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text("⤷ Eva: ${vertretung.eva ?? ""}", style: TextStyle(fontSize: fontSize,
                color: vertretungsColors != null
                    ? evaColor.computeLuminance() > 0.5
                        ? darkTextColor
                        : lightTextColor
                    : null,)),
            ),
          ),
        ]
      ],
    ],
  );
}
