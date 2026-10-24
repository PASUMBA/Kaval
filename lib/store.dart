import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Central state: watchers, polling, notifications, demo mode.
class KavalStore extends ChangeNotifier {
  final List<Watcher> watchers = [];
  final List<AppNotification> notifications = [];
  ForestRange? range;
  String officer = '';
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
      demoMode = p.getBool('demo') ?? true;
      cameraUrl = p.getString('cameraUrl') ?? cameraUrl;
      final rid = p.getString('range');
      range = kRanges.where((r) => r.id == rid).firstOrNull;
    } catch (_) {}
    _seedWatchers();
    notifyListeners();
  }

  Future<void> login(String name) async {
    officer = name;
    (await SharedPreferences.getInstance()).setString('officer', name);
    notifyListeners();
  }

  Future<void> logout() async {
    officer = '';
    (await SharedPreferences.getInstance()).remove('officer');
    notifyListeners();
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
    ]);
  }

  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
    _poll();
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    _tick++;
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
          .get(Uri.parse('${w.baseUrl}/api/watcher'))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final j = jsonDecode(r.body);
      lastPollOk = DateTime.now();
      lastError = '';
      if (j is Map<String, dynamic>) {
        final wasOffline = w.status == WatcherStatus.offline;
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
          w.status != WatcherStatus.offline) {
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
