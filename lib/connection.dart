import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_launcher_icons/custom_exceptions.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:html/parser.dart';
import 'package:html/dom.dart' as DOM;

const String baseUrl = "https://www.pius-gymnasium.de";
const String stundenplanUrl = baseUrl + "/stundenplaene/";
const String vertretungsplanUrl = baseUrl + "/vertretungsplan/";


Future<List<Uint8List>> getStundenplaene() async {
  DOM.Document document = parse(await getStundenplanWebsite());

  List<Uint8List> stundenplaene = List.empty(growable: true);
  document.body?.querySelectorAll("a").forEach((element) async {
    if (element.attributes["href"]?.isEmpty ?? true) throw Exception("No href in links");
    stundenplaene.add((await getSecuredPage(stundenplanUrl+element.attributes["href"]!)).bodyBytes);
  });

  return stundenplaene;
}

Future<String> getStundenplanWebsite() async => (await getSecuredPage(stundenplanUrl)).body;
Future<String> getVertretungsplanWebsite() async => (await getSecuredPage(vertretungsplanUrl)).body;
Future<bool> checkCredentials() async {
  await getVertretungsplanWebsite();
  return true;
}

Future<http.Response> getSecuredPage(String url) async {
  AndroidOptions getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );
  final FlutterSecureStorage securePrefs = FlutterSecureStorage(aOptions: getAndroidOptions());
  String? username = await securePrefs.read(key: "username");
  String? password = await securePrefs.read(key: "password");

  if (username == null || password == null) throw Exception("No username or password found");

  Map<String, String> authorizationHeaders = {
    "Authorization": "Basic " + base64Encode(utf8.encode("$username:$password")),
  };

  if (username.isEmpty || password.isEmpty) throw Exception("Username or Password is empty");

  http.Response response = await http.get(Uri.parse(url), headers: authorizationHeaders);

  if (response.statusCode == 401) throw const AuthorizationException("Ungültiger Nutzername oder Passwort");
  if (response.statusCode != 200) throw Exception("Unexpected response code ${response.statusCode}");
  return response;
}

class AuthorizationException implements Exception {
  final String msg;
  const AuthorizationException(this.msg);
  @override
  String toString() => msg;
}
