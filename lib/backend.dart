import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

/// Firebase Realtime Database (REST) used as the shared backend:
/// users/, reports/, events/<postId>/ and the camera relay posts/, snaps/.
const kRelayDb =
    'https://kaval-ab7b2-default-rtdb.asia-southeast1.firebasedatabase.app';

class Backend {
  static String hash(String pw) =>
      sha256.convert(utf8.encode('kaval:$pw')).toString();

  static String key(String s) =>
      s.trim().replaceAll(RegExp(r'[.#$\[\]/\s]'), '_');

  static Uri _u(String path) => Uri.parse('$kRelayDb/$path.json');

  static Future<dynamic> get(String path) async {
    final r = await http.get(_u(path)).timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) throw Exception('Server HTTP ${r.statusCode}');
    return jsonDecode(r.body);
  }

  static Future<void> put(String path, Object v) async {
    final r = await http
        .put(_u(path), body: jsonEncode(v))
        .timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) throw Exception('Server HTTP ${r.statusCode}');
  }

  static Future<void> post(String path, Object v) async {
    final r = await http
        .post(_u(path), body: jsonEncode(v))
        .timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) throw Exception('Server HTTP ${r.statusCode}');
  }

  /// Officer / resident sign-in. Throws with a short human message.
  static Future<Map<String, dynamic>> login(String id, String pw) async {
    final u = await get('users/${key(id)}');
    if (u is! Map) throw Exception('No account "$id"');
    if (u['hash'] != hash(pw)) throw Exception('Wrong password');
    return Map<String, dynamic>.from(u);
  }

  /// Resident self-registration keyed by phone; re-login if it exists.
  static Future<void> signupResident(
      String name, String phone, String pw, String post) async {
    final k = key(phone);
    final u = await get('users/$k');
    if (u is Map) {
      if (u['hash'] != hash(pw)) {
        throw Exception('This phone is already registered — wrong password');
      }
      await put('users/$k/post', post);
      return;
    }
    await put('users/$k', {
      'name': name,
      'phone': phone,
      'role': 'resident',
      'post': post,
      'hash': hash(pw),
      'created': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static Future<void> pushReport(SightingReport r) =>
      post('reports', r.toJson());

  static Future<List<SightingReport>> fetchReports() async {
    final v = await get('reports');
    if (v is! Map) return [];
    final list = v.entries
        .where((e) => e.value is Map)
        .map((e) => SightingReport.fromJson(
            e.key.toString(), Map<String, dynamic>.from(e.value as Map)))
        .toList();
    list.sort((a, b) => b.time.compareTo(a.time));
    return list;
  }

  /// Detection log pushed by each post: events/<postId>/<pushId>.
  static Future<Map<String, List<Map<String, dynamic>>>> fetchEvents() async {
    final v = await get('events');
    final out = <String, List<Map<String, dynamic>>>{};
    if (v is! Map) return out;
    v.forEach((post, evs) {
      if (evs is! Map) return;
      final l = evs.values
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      l.sort((a, b) =>
          (b['time'] ?? '').toString().compareTo((a['time'] ?? '').toString()));
      out[post.toString()] = l;
    });
    return out;
  }
}
