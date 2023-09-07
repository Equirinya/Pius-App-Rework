import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import 'package:http/http.dart' as http;

import 'package:html/parser.dart';
import 'package:html/dom.dart' as DOM;

class StundenplanPage extends StatelessWidget {
  StundenplanPage({super.key, required this.isar});

  final Isar isar;

  void loadStundenplan() {
      http.get(Uri.parse("https://www.pius-gymnasium.de/stundenplaene/")).then((response) {
      print(response.body);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          ElevatedButton(
            onPressed: loadStundenplan,
            child: const Text("load"),
          ),
        ],
      ),
    );
  }
}
