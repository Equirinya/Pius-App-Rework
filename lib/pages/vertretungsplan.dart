import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:isar/isar.dart';

class VertretungsplanPage extends StatefulWidget {
  const VertretungsplanPage({super.key, required this.isar});

  final Isar isar;

  @override
  State<VertretungsplanPage> createState() => _VertretungsplanPageState();
}

class _VertretungsplanPageState extends State<VertretungsplanPage> {

  bool filter = false; //TODO load on startup last state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vertretungsplan"),//Appbar mit Tickertext und floating tag sobald der hochgescrollt wurde, sofie den filtern
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() {
          filter = !filter;
        }),
        tooltip: 'Filter',
        child: Icon(filter ? Ionicons.filter : Ionicons.filter_outline),
      ),
    );
  }
}
