import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'backend.dart';
import 'models.dart';

/// Central state: watchers, polling, notifications, demo mode.
class KavalStore extends ChangeNotifier {
  final List<Watcher> watchers = [];
  final List<AppNotification> notifications = [];
  final List<SightingReport> reports = [];
  ForestRange? range;
  String officer = '';
  String officerName = '';
  /// 'officer' (default) or 'resident' (forest-edge villager mode).
  String role = 'officer';
  /// Resident mode: the watch post nearest to the user's home.
  String? homePostId;
  bool demoMode = true;
  String lastError = '';
  DateTime? lastPollOk;
  String cameraUrl = 'http://192.168.4.2:1880';
  Timer? _timer;
  final _rng = Random();
  int _tick = 0;

  /// Fired when a new critical notification arrives (UI plays sound).
  final StreamController<AppNotification> alerts =
      StreamController.broadcast();

  int get unread => notifications.where((n) => !n.read).length;

  List<Watcher> get rangeWatchers =>
      watchers.where((w) => range == null || w.range == range!.id).toList();

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      officer = p.getString('officer') ?? '';
      officerName = p.getString('officerName') ?? '';
      phone = p.getString('phone') ?? '';
      role = p.getString('role') ?? 'officer';
      homePostId = p.getString('homePost');
      demoMode = p.getBool('demo') ?? true;
      cameraUrl = p.getString('cameraUrl') ?? cameraUrl;
      final rid = p.getString('range');
      range = kRanges.where((r) => r.id == rid).firstOrNull;
    } catch (_) {}
    _seedWatchers();
    notifyListeners();
  }

  /// Officer sign-in against the backend. Returns an error text or null.
  Future<String?> login(String id, String pw) async {
    final Map<String, dynamic> u;
    try {
      u = await Backend.login(id, pw);
    } catch (e) {
      return _err(e);
    }
    if (u['role'] != 'officer') return 'Not an officer account';
    officer = id.trim();
    officerName = (u['name'] ?? '').toString();
    role = 'officer';
    notifyListeners();
    await _save((p) async {
      await p.setString('officer', officer);
      await p.setString('officerName', officerName);
      await p.setString('role', 'officer');
    });
    return null;
  }

  String _err(Object e) {
    final m = e.toString().replaceFirst('Exception: ', '');
    if (m.contains('SocketException') ||
        m.contains('Timeout') ||
        m.contains('ClientException')) {
      return 'No internet — could not reach the server';
    }
    return m;
  }

  Future<void> logout() async {
    officer = '';
    role = 'officer';
    homePostId = null;
    stopPolling();
    final p = await SharedPreferences.getInstance();
    await p.remove('officer');
    await p.remove('officerName');
    await p.remove('phone');
    await p.remove('role');
    await p.remove('homePost');
    notifyListeners();
  }

  String phone = '';

  /// Resident sign-in/sign-up (backend keyed by phone). Error text or null.
  Future<String?> loginResident(
      String name, String ph, String pw, String postId) async {
    try {
      await Backend.signupResident(name, ph, pw, postId);
    } catch (e) {
      return _err(e);
    }
    officer = name;
    phone = ph;
    role = 'resident';
    homePostId = postId;
    final w = watchers.where((w) => w.id == postId).firstOrNull;
    range = kRanges.where((r) => r.id == w?.range).firstOrNull;
    notifyListeners();
    await _save((p) async {
      await p.setString('officer', name);
      await p.setString('phone', ph);
      await p.setString('role', 'resident');
      await p.setString('homePost', postId);
      if (range != null) await p.setString('range', range!.id);
    });
    return null;
  }

  Watcher? get homePost =>
      watchers.where((w) => w.id == homePostId).firstOrNull;

  /// Active elephant/bear alert at the resident's post (within the alert hold).
  Detection? get homeWildlifeAlert {
    final w = homePost;
    if (w == null || w.status != WatcherStatus.alert) return null;
    final d = w.lastDetection;
    if (d == null) return null;
    if (d.type != 'elephant' && d.type != 'bear') return null;
    if (DateTime.now().difference(d.time).inMinutes > 10) return null;
    return d;
  }

  void reportSighting(String type, String note, {String photo = ''}) {
    final w = homePost;
    if (w == null) return;
    final r = SightingReport(
      reporter: officer,
      phone: phone,
      watcherId: w.id,
      type: type,
      note: note.trim(),
      time: DateTime.now(),
      photo: photo,
    );
    reports.insert(0, r);
    reportError = '';
    Backend.pushReport(r).catchError((e) {
      reportError = _err(e);
      notifyListeners();
    });
    _notify(w, 'Resident report: ${_cap(type)}',
        '${w.name} · by $officer${r.note.isEmpty ? '' : ' · ${r.note}'}',
        critical: type == 'elephant' || type == 'bear');
    notifyListeners();
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String reportError = '';
  bool _reportsLoaded = false;

  /// Officers: pull resident reports from the backend (every 4th poll).
  Future<void> _syncReports() async {
    try {
      final list = await Backend.fetchReports();
      final known = reports.map((r) => r.id).toSet();
      for (final r in list.reversed) {
        if (r.id.isEmpty || known.contains(r.id)) continue;
        reports.insert(0, r);
        if (_reportsLoaded) {
          final w = watchers.where((w) => w.id == r.watcherId).firstOrNull;
          if (w != null) {
            _notify(w, 'Resident report: ${_cap(r.type)}',
                '${w.name} · by ${r.reporter}${r.note.isEmpty ? '' : ' · ${r.note}'}',
                critical: r.type == 'elephant' || r.type == 'bear');
          }
        }
      }
      reports.sort((a, b) => b.time.compareTo(a.time));
      _reportsLoaded = true;
    } catch (_) {}
  }

  Future<void> selectRange(ForestRange r) async {
    range = r;
    (await SharedPreferences.getInstance()).setString('range', r.id);
    startPolling();
    notifyListeners();
  }

  Future<void> clearRange() async {
    range = null;
    stopPolling();
    (await SharedPreferences.getInstance()).remove('range');
    notifyListeners();
  }

  Future<void> setDemo(bool v) async {
    demoMode = v;
    _seedWatchers();
    notifyListeners();
    await _save((p) => p.setBool('demo', v));
  }

  Future<void> setCameraUrl(String url) async {
    cameraUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    _seedWatchers();
    notifyListeners();
    await _save((p) => p.setString('cameraUrl', cameraUrl));
  }

  Future<void> _save(Future<void> Function(SharedPreferences p) f) async {
    try {
      await f(await SharedPreferences.getInstance());
    } catch (_) {}
  }

  /// Watch posts. The first Kodanad post is the real reCamera; the rest are
  /// demo posts so the map always has a network to show.
  void _seedWatchers() {
    watchers.clear();
    watchers.addAll([
      Watcher(
        id: 'KDN-01',
        name: 'Vadakkumbhagam Post',
        range: 'kodanad',
        lat: 10.1715,
        lon: 76.6902,
        baseUrl: demoMode ? null : cameraUrl,
        status: demoMode ? WatcherStatus.ok : WatcherStatus.offline,
        lastSeen: demoMode ? null : DateTime.fromMillisecondsSinceEpoch(0),
        battery: 87,
      ),
      Watcher(
        id: 'KDN-02',
        name: 'Vettilappara Road Post',
        range: 'kodanad',
        lat: 10.1532,
        lon: 76.7034,
        battery: 64,
      ),
      Watcher(
        id: 'KDN-03',
        name: 'Vaveli Fringe Post',
        range: 'kodanad',
        lat: 10.1861,
        lon: 76.7118,
        battery: 9,
        issue: 'Low battery',
        status: WatcherStatus.alert,
      ),
      Watcher(
        id: 'KDN-04',
        name: 'Kuttampuzha Machan Post',
        range: 'kodanad',
        lat: 10.1388,
        lon: 76.7340,
        battery: 0,
        status: WatcherStatus.offline,
        lastSeen: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Watcher(
        id: 'MRY-01',
        name: 'Sandal Reserve Gate Post',
        range: 'marayoor',
        lat: 10.2765,
        lon: 77.1602,
        battery: 92,
      ),
      Watcher(
        id: 'MRY-02',
        name: 'Nachivayal Post',
        range: 'marayoor',
        lat: 10.2612,
        lon: 77.1811,
        battery: 71,
      ),
      Watcher(
        id: 'RNI-01',
        name: 'Olikkallu Post',
        range: 'ranni',
        lat: 9.3821,
        lon: 76.8012,
        battery: 80,
      ),
      Watcher(
        id: 'RNI-02',
        name: 'Kodamala Post',
        range: 'ranni',
        lat: 9.3604,
        lon: 76.7770,
        battery: 55,
      ),
      Watcher(
        id: 'WYD-01',
        name: 'Bathery Fringe Post',
        range: 'wayanad',
        lat: 11.6650,
        lon: 76.2601,
        battery: 77,
      ),
      Watcher(
        id: 'MNR-01',
        name: 'Munnar Town Fringe Post',
        range: 'munnar',
        lat: 10.0890,
        lon: 77.0601,
        battery: 83,
      ),
      Watcher(
        id: 'KDN-05',
        name: 'Kottappady Village Post',
        range: 'kodanad',
        lat: 10.199,
        lon: 76.678,
        battery: 58,
      ),
      Watcher(
        id: 'MRY-03',
        name: 'Kanthalloor Fringe Post',
        range: 'marayoor',
        lat: 10.231,
        lon: 77.2,
        battery: 44,
      ),
      Watcher(
        id: 'MRY-04',
        name: 'Chinnar Checkpost',
        range: 'marayoor',
        lat: 10.329,
        lon: 77.182,
        battery: 12,
        issue: 'Low battery',
        status: WatcherStatus.alert,
      ),
      Watcher(
        id: 'RNI-03',
        name: 'Vadasserikkara Post',
        range: 'ranni',
        lat: 9.436,
        lon: 76.808,
        battery: 0,
        status: WatcherStatus.offline,
        lastSeen: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      Watcher(
        id: 'RNI-04',
        name: 'Perunad Post',
        range: 'ranni',
        lat: 9.405,
        lon: 76.842,
        battery: 66,
      ),
      Watcher(
        id: 'WYD-02',
        name: 'Noolpuzha Post',
        range: 'wayanad',
        lat: 11.621,
        lon: 76.318,
        battery: 69,
      ),
      Watcher(
        id: 'WYD-03',
        name: 'Muthanga Checkpost',
        range: 'wayanad',
        lat: 11.653,
        lon: 76.37,
        battery: 35,
      ),
      Watcher(
        id: 'WYD-04',
        name: 'Naikatty Post',
        range: 'wayanad',
        lat: 11.7,
        lon: 76.34,
        battery: 0,
        status: WatcherStatus.offline,
        lastSeen: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      Watcher(
        id: 'MNR-02',
        name: 'Eravikulam Gate Post',
        range: 'munnar',
        lat: 10.148,
        lon: 77.048,
        battery: 90,
      ),
      Watcher(
        id: 'MNR-03',
        name: 'Chinnakanal Post',
        range: 'munnar',
        lat: 10.008,
        lon: 77.143,
        battery: 48,
      ),
      Watcher(
        id: 'MNR-04',
        name: 'Mattupetty Post',
        range: 'munnar',
        lat: 10.107,
        lon: 77.126,
        battery: 14,
        issue: 'Low battery',
        status: WatcherStatus.alert,
      ),
    ]);
  }

  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
    _poll();
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    _tick++;
    if (role == 'officer' && (_tick % 4 == 1)) _syncReports();
    for (final w in rangeWatchers) {
      if (w.isDemo) {
        _simulate(w);
      } else {
        await _pollReal(w);
      }
    }
    notifyListeners();
  }

  Future<void> _pollReal(Watcher w) async {
    final prevAlert = w.status == WatcherStatus.alert;
    final prevDet = w.lastDetection?.time;
    try {
      final r = await http
          .get(Uri.parse(w.isRelay
              ? '${w.baseUrl}/posts/${w.id}.json'
              : '${w.baseUrl}/api/watcher'))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final j = jsonDecode(r.body);
      if (j == null) throw Exception('No data on relay yet');
      if (w.isRelay && j is Map<String, dynamic>) {
        final pushed = DateTime.tryParse(j['pushed']?.toString() ?? '');
        if (pushed != null &&
            DateTime.now().difference(pushed).inSeconds > 40) {
          throw Exception(
              'Camera stopped pushing ${DateTime.now().difference(pushed).inSeconds}s ago');
        }
      }
      lastPollOk = DateTime.now();
      lastError = '';
      if (j is Map<String, dynamic>) {
        final wasOffline =
            w.status == WatcherStatus.offline && w.lastSeen.year > 2000;
        w.applyJson(j);
        if (wasOffline) {
          _notify(w, 'Post back online', '${w.name} reconnected',
              critical: false);
        }
        final d = w.lastDetection;
        if (d != null && d.time != prevDet && d.isThreat) {
          _notify(w, '${d.label} detected',
              '${w.name} · ${(d.confidence * 100).round()}% · ${d.source}',
              critical: true);
        } else if (!prevAlert && w.status == WatcherStatus.alert &&
            w.issue.isNotEmpty) {
          _notify(w, w.issue, w.name, critical: false);
        }
      }
    } catch (e) {
      lastError = e.toString();
      if (DateTime.now().difference(w.lastSeen).inSeconds > 25 &&
          w.status != WatcherStatus.offline &&
          w.lastSeen.year > 2000) {
        w.status = WatcherStatus.offline;
        _notify(w, 'Post offline', '${w.name} not responding',
            critical: false);
      }
    }
  }

  /// Demo traffic: an occasional detection on a random healthy post.
  void _simulate(Watcher w) {
    if (w.status == WatcherStatus.offline) return;
    if (_tick % 3 == 0 && w.battery > 0 && _rng.nextInt(50) == 0) {
      w.battery = max(0, w.battery - 1);
    }
    if (w.status == WatcherStatus.alert &&
        w.lastDetection != null &&
        DateTime.now().difference(w.lastDetection!.time).inSeconds > 25 &&
        w.issue.isEmpty) {
      w.status = WatcherStatus.ok;
      w.tracking = false;
      w.pan = 90;
      w.tilt = 90;
    }
    if (w.tracking) {
      w.pan = (w.pan + _rng.nextInt(9) - 4).clamp(0, 180);
      w.tilt = (w.tilt + _rng.nextInt(5) - 2).clamp(40, 140);
    }
    final chance = w.range == 'marayoor' ? 45 : 60;
    if (_rng.nextInt(chance) == 0 && w.status == WatcherStatus.ok) {
      final types = w.range == 'marayoor'
          ? ['chainsaw', 'person', 'vehicle', 'chainsaw']
          : ['elephant', 'elephant', 'person', 'wild boar', 'vehicle'];
      final t = types[_rng.nextInt(types.length)];
      fireDemoDetection(w, t);
    }
  }

  void fireDemoDetection(Watcher w, String type) {
    final d = Detection(
      type: type,
      confidence: 0.72 + _rng.nextDouble() * 0.26,
      time: DateTime.now(),
      source: (type == 'chainsaw' || type == 'gunshot') ? 'audio' : 'camera',
    );
    w.lastDetection = d;
    w.history.insert(0, d);
    if (w.history.length > 50) w.history.removeLast();
    if (d.isThreat) {
      w.status = WatcherStatus.alert;
      w.tracking = d.source == 'camera';
      _notify(w, '${d.label} detected',
          '${w.name} · ${(d.confidence * 100).round()}% · ${d.source}',
          critical: true);
    }
    notifyListeners();
  }

  void _notify(Watcher w, String title, String body,
      {required bool critical}) {
    final n = AppNotification(
      watcherId: w.id,
      watcherName: w.name,
      title: title,
      body: body,
      time: DateTime.now(),
      critical: critical,
    );
    notifications.insert(0, n);
    if (notifications.length > 100) notifications.removeLast();
    alerts.add(n);
  }

  void markAllRead() {
    for (final n in notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  void acknowledge(Watcher w) {
    w.status = WatcherStatus.ok;
    w.tracking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    alerts.close();
    super.dispose();
  }
}
