/// Share-Links
/// ===========
///
/// Replaces the old "raw JSON in a QR code" transport. A share is now a real
/// URL, so the *same* string works as a QR code, as a tappable link in
/// WhatsApp, as a link on a website and as `adb shell am start -d ...`
/// during debugging.
///
/// Two shapes, one payload
/// -----------------------
/// ```
/// https://<host>/<path>#1/<data>   <- what we hand out ("Web-Link")
/// piusapp://1/<data>               <- what actually launches the app
/// ```
///
/// Messengers only turn *known* schemes into tappable links; `piusapp://`
/// arrives in WhatsApp as dead plain text. So the shared string is an https
/// URL pointing at a tiny static page (see `docs/s/index.html`), which reads
/// the fragment and forwards to the `piusapp://` form. That is also the only
/// approach that works on GitHub Pages: real Universal Links would need
/// `apple-app-site-association` served as `application/json`, which Pages
/// cannot do.
///
/// The payload lives in the URL **fragment** on purpose. Browsers never send
/// fragments to the server, so a link that carries a Pius-Login never exposes
/// it to the host - the redirect happens entirely in the visitor's browser.
///
/// [buildShareLink] emits the https form; [parseShareLink] reads both, so a
/// `piusapp://` link handed over directly (deep link, QR code, debugging)
/// keeps working.
///
/// Character set
/// -------------
/// The payload is drawn from `A-Z a-z 0-9 - _` only - the base64url alphabet,
/// all *unreserved* URL characters per RFC 3986. So the link survives every
/// hop unchanged: no percent-encoding, no `+`/`=` that chat apps or mail
/// clients might mangle, nothing that ends a URL early when it is
/// auto-linkified, and nothing that needs quoting in a shell. It is also pure
/// ASCII, which keeps the QR code in byte mode without any UTF-8 multibyte
/// blowup.
///
/// Payload
/// -------
/// The data segment is the raw-DEFLATEd form of
///
/// ```
/// u8      magic 0x50 ('P')            -- sanity check after inflating
/// u8      flags                       -- bit0: a Pius-Login is included
/// str     username                    -- only if bit0
/// str     password                    -- only if bit0
/// varint  konfigurationCount
/// repeat {
///   str     name                      -- empty = same as stufe
///   str     stufe
///   u8      flags                     -- bit0: isOberstufe
///   varint  kurseCount
///   repeat { str kurs }
/// }
/// ```
///
/// `varint` is an unsigned LEB128 (7 bits per byte, high bit = continue) and
/// `str` is `varint byteLength` followed by that many UTF-8 bytes.
///
/// The body is always DEFLATEd - there is no "stored" alternative, so both
/// ends only ever have one code path to get right. For a realistic
/// Oberstufen-Profil with ten Kursen plus a second Klassen-Profil and a
/// bundled login the payload lands at ~124 characters, versus ~305 for the
/// old JSON. Very short shares pay a handful of characters for DEFLATE's
/// overhead, which at that size is irrelevant to the QR code anyway.
///
/// Versioning
/// ----------
/// The version lives in the URL, not in the payload, so a future format can
/// be detected *before* trying to parse anything. Unknown versions throw
/// [ShareLinkException] with a "please update the app" message rather than
/// failing obscurely. There is deliberately no backwards compatibility with
/// the pre-1.0.21 plain-JSON codes.
///
/// Security
/// --------
/// This is an encoding, not encryption. A link that carries a login carries
/// the password in recoverable form - exactly as the old JSON did - so every
/// UI that produces one must keep warning about that, and every UI that
/// consumes one must let the user decline the credentials.
library;

import 'dart:convert';
import 'dart:io' show ZLibCodec, ZLibOption;
import 'dart:typed_data';

import 'database.dart';

/// URI scheme registered with the OS - the form that actually launches the
/// app. Users normally never see it; the web page redirects to it.
const String kShareLinkScheme = "piusapp";

/// Host serving the redirect page (`docs/s/index.html`, published via GitHub
/// Pages). Changing this only affects *newly created* links - [parseShareLink]
/// deliberately doesn't check the host, so links created before a move keep
/// working.
const String kShareLinkHost = "equirinya.github.io";

/// Path of the redirect page on [kShareLinkHost], with trailing slash.
const String kShareLinkPath = "/Pius-App-Rework/s/";

/// Payload format version this build writes.
const int kShareLinkVersion = 1;

/// `<version>/<data>` - what sits in the fragment of an https share link and
/// in the `piusapp://` authority + path. Anchored so a random URL that merely
/// happens to have a fragment isn't mistaken for a share.
final RegExp _payloadPattern = RegExp(r"^(\d+)/([A-Za-z0-9_-]+)$");

const int _magic = 0x50; // 'P'

/// `raw: true` drops the 2-byte zlib header and the 4-byte Adler-32 checksum -
/// both are pure overhead here, since a corrupted link fails the magic-byte
/// check anyway. (Not `const`: ZLibCodec validates its arguments in its body.)
final ZLibCodec _deflate = ZLibCodec(raw: true, level: ZLibOption.maxLevel);

/// Thrown when a string isn't a share link, or is one we can't read.
class ShareLinkException implements Exception {
  const ShareLinkException(this.message);

  /// German, user-facing - the import UIs show this verbatim.
  final String message;

  @override
  String toString() => message;
}

/// Result of decoding a share link: the Konfigurationen it contains, plus the
/// Pius-Login if the person sharing chose to include it too.
class SharePayload {
  const SharePayload({required this.konfigurationen, this.username, this.password});

  final List<Konfiguration> konfigurationen;
  final String? username;
  final String? password;

  bool get includesLogin => username != null && password != null && username!.isNotEmpty && password!.isNotEmpty;
}

/// Builds the shareable https link for one or more Konfigurationen - the form
/// that messengers turn into a tappable link.
///
/// When [username]/[password] are given, the Pius-Login is bundled in too so
/// the receiving device is immediately fully set up - callers MUST warn the
/// user before sharing, since anyone who gets the link can then log in as
/// them. The payload sits in the fragment, so it never reaches
/// [kShareLinkHost]'s server even when the link is opened in a browser.
String buildShareLink(List<Konfiguration> konfigurationen, {String? username, String? password}) {
  final _ByteWriter body = _ByteWriter();
  final bool hasLogin = username != null && password != null && username.isNotEmpty && password.isNotEmpty;

  body.byte(_magic);
  body.byte(hasLogin ? 0x01 : 0x00);
  if (hasLogin) {
    body.string(username);
    body.string(password);
  }

  body.varint(konfigurationen.length);
  for (final Konfiguration konfiguration in konfigurationen) {
    // The name is almost always just the Stufe ("7A"), so store it only when
    // it actually differs.
    body.string(konfiguration.name == konfiguration.stufe ? "" : konfiguration.name);
    body.string(konfiguration.stufe);
    body.byte(konfiguration.isOberstufe ? 0x01 : 0x00);
    body.varint(konfiguration.kurse.length);
    for (final String kurs in konfiguration.kurse) {
      body.string(kurs);
    }
  }

  final String data = base64Url.encode(_deflate.encode(body.takeBytes())).replaceAll("=", "");
  return "https://$kShareLinkHost$kShareLinkPath#$kShareLinkVersion/$data";
}

/// The `piusapp://` form of [link] - what the redirect page navigates to, and
/// what the OS hands back to [parseShareLink]. Exposed mainly so the format
/// has exactly one definition; the app itself always shares the https form.
String toAppSchemeLink(String link) {
  final ({int version, String data}) payload = _extractPayload(link);
  return "$kShareLinkScheme://${payload.version}/${payload.data}";
}

/// True if [text] looks like one of our links, in either form - cheap enough
/// to run on every scanned QR code before committing to a full decode.
///
/// Whether it is actually *readable* is [parseShareLink]'s business. Anything
/// using our private scheme counts, even if malformed: nothing else on the
/// device uses `piusapp://`, so it was meant for us and deserves a real error
/// message rather than being silently skipped.
bool isShareLink(String text) {
  final Uri? uri = Uri.tryParse(text.trim());
  if (uri == null) return false;
  if (uri.scheme.toLowerCase() == kShareLinkScheme) return true;
  return uri.scheme.toLowerCase() == "https" && _payloadPattern.hasMatch(uri.fragment);
}

/// Pulls `<version>/<data>` out of either link form, without interpreting it.
({int version, String data}) _extractPayload(String link) {
  final Uri? uri = Uri.tryParse(link.trim());
  if (uri == null) throw const ShareLinkException("Das ist kein Pius-App-Link.");

  final String raw;
  switch (uri.scheme.toLowerCase()) {
    case kShareLinkScheme:
      // piusapp://<version>/<data> - version in the authority, data in the path.
      raw = "${uri.host}/${uri.pathSegments.where((s) => s.isNotEmpty).join()}";
      break;
    case "https":
    case "http":
      // The host and path are deliberately not checked: they may move (new
      // domain, GitHub Pages -> custom domain) without invalidating links
      // people already have. The fragment is what identifies a share.
      raw = uri.fragment;
      break;
    default:
      throw const ShareLinkException("Das ist kein Pius-App-Link.");
  }

  final RegExpMatch? match = _payloadPattern.firstMatch(raw);
  if (match == null) {
    throw ShareLinkException(raw.isEmpty ? "Der Link ist unvollständig." : "Der Link ist beschädigt.");
  }
  return (version: int.parse(match.group(1)!), data: match.group(2)!);
}

/// Decodes a link produced by [buildShareLink] into unsaved [Konfiguration]
/// objects plus an optional bundled login.
///
/// Throws [ShareLinkException] for anything that isn't a readable share link.
SharePayload parseShareLink(String link) {
  final ({int version, String data}) payload = _extractPayload(link);

  if (payload.version > kShareLinkVersion) {
    throw const ShareLinkException("Dieser Link wurde mit einer neueren Version der App erstellt. Bitte aktualisiere die App.");
  }
  if (payload.version < kShareLinkVersion) {
    throw const ShareLinkException("Dieser Link stammt aus einer zu alten Version der App.");
  }

  final String data = payload.data;
  final Uint8List bytes;
  try {
    final Uint8List compressed = base64Url.decode(data.padRight(data.length + ((4 - data.length % 4) % 4), "="));
    bytes = Uint8List.fromList(_deflate.decode(compressed));
  } catch (_) {
    throw const ShareLinkException("Der Link ist beschädigt.");
  }

  try {
    return _readBody(bytes);
  } on ShareLinkException {
    rethrow;
  } catch (_) {
    throw const ShareLinkException("Der Link ist beschädigt.");
  }
}

SharePayload _readBody(Uint8List bytes) {
  final _ByteReader reader = _ByteReader(bytes);
  if (reader.byte() != _magic) throw const ShareLinkException("Der Link ist beschädigt.");

  final int flags = reader.byte();
  String? username;
  String? password;
  if (flags & 0x01 != 0) {
    username = reader.string();
    password = reader.string();
  }

  final int count = reader.varint();
  final List<Konfiguration> konfigurationen = [];
  for (int i = 0; i < count; i++) {
    final String name = reader.string();
    final String stufe = reader.string();
    final bool isOberstufe = reader.byte() & 0x01 != 0;
    final int kurseCount = reader.varint();
    konfigurationen.add(Konfiguration()
      ..name = name.isEmpty ? stufe : name
      ..stufe = stufe
      ..isOberstufe = isOberstufe
      ..kurse = [for (int k = 0; k < kurseCount; k++) reader.string()]
      ..createdAt = DateTime.now());
  }

  return SharePayload(konfigurationen: konfigurationen, username: username, password: password);
}

class _ByteWriter {
  final BytesBuilder _builder = BytesBuilder(copy: false);

  void byte(int value) => _builder.addByte(value);

  void varint(int value) {
    int remaining = value;
    do {
      int part = remaining & 0x7f;
      remaining >>= 7;
      _builder.addByte(remaining != 0 ? (part | 0x80) : part);
    } while (remaining != 0);
  }

  void string(String value) {
    final List<int> encoded = utf8.encode(value);
    varint(encoded.length);
    _builder.add(encoded);
  }

  Uint8List takeBytes() => _builder.takeBytes();
}

class _ByteReader {
  _ByteReader(this._bytes);

  final Uint8List _bytes;
  int _offset = 0;

  int byte() {
    if (_offset >= _bytes.length) throw const ShareLinkException("Der Link ist unvollständig.");
    return _bytes[_offset++];
  }

  int varint() {
    int result = 0;
    int shift = 0;
    while (true) {
      final int b = byte();
      result |= (b & 0x7f) << shift;
      if (b & 0x80 == 0) return result;
      shift += 7;
      if (shift > 35) throw const ShareLinkException("Der Link ist beschädigt.");
    }
  }

  String string() {
    final int length = varint();
    if (_offset + length > _bytes.length) throw const ShareLinkException("Der Link ist unvollständig.");
    final String value = utf8.decode(_bytes.sublist(_offset, _offset + length));
    _offset += length;
    return value;
  }
}
