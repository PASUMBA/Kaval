enum WatcherStatus { ok, alert, offline }

bool isRelayUrl(String? url) =>
    url != null && url.contains('firebasedatabase.app');

double _norm(double c) => c > 1 ? c / 100 : c;

class Detection {
  final String type; // elephant, person, chainsaw, gunshot, vehicle, fire
  final double confidence;
  final DateTime time;
  final String? snapshotUrl;
  final String source; // camera / audio

  Detection({
    required this.type,
    required this.confidence,
    required this.time,
    this.snapshotUrl,
    this.source = 'camera',
  });

  factory Detection.fromJson(Map<String, dynamic> j, String base) {
    final snap = j['snapshot'] as String?;
    return Detection(
      type: (j['type'] ?? 'unknown').toString(),
      confidence: _norm((j['confidence'] ?? 0).toDouble()),
      time: DateTime.tryParse(j['time']?.toString() ?? '') ?? DateTime.now(),
      snapshotUrl: snap == null
          ? null
          : (snap.startsWith('http') ? snap : '$base$snap'),
      source: (j['source'] ?? 'camera').toString(),
    );
  }

  bool get isThreat => const {
        'elephant', 'tiger', 'leopard', 'bear', 'person', 'chainsaw',
        'gunshot', 'fire', 'smoke', 'vehicle'
      }.contains(type);

  String get label {
    switch (type) {
      case 'elephant':
        return 'Elephant';
      case 'person':
        return 'Human intrusion';
      case 'chainsaw':
        return 'Chainsaw sound';
      case 'gunshot':
        return 'Gunshot sound';
      case 'vehicle':
        return 'Vehicle';
      case 'fire':
      case 'smoke':
        return 'Fire / smoke';
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }
}

class Watcher {
  final String id;
  final String name;
  final String range;
  final double lat;
  final double lon;
  final String? baseUrl; // http://192.168.4.2:1880 ; null => demo
  int battery;
  WatcherStatus status;
  int pan;
  int tilt;
  bool tracking;
  Detection? lastDetection;
  List<Detection> history;
  DateTime lastSeen;
  String issue; // '' when fine

  Watcher({
    required this.id,
    required this.name,
    required this.range,
    required this.lat,
    required this.lon,
    this.baseUrl,
    this.battery = 100,
    this.status = WatcherStatus.ok,
    this.pan = 90,
    this.tilt = 90,
    this.tracking = false,
    this.lastDetection,
    List<Detection>? history,
    DateTime? lastSeen,
    this.issue = '',
  })  : history = history ?? [],
        lastSeen = lastSeen ?? DateTime.now();

  bool get isDemo => baseUrl == null;

  /// Cloud relay (Firebase RTDB REST) instead of the camera's own Node-RED.
  bool get isRelay => isRelayUrl(baseUrl);

  void applyJson(Map<String, dynamic> j) {
    final base = baseUrl ?? '';
    battery = (j['battery'] ?? battery).toInt();
    pan = (j['pan'] ?? pan).toInt();
    tilt = (j['tilt'] ?? tilt).toInt();
    tracking = j['tracking'] == true;
    issue = (j['issue'] ?? '').toString();
    lastSeen = DateTime.now();
    final ld = j['last_detection'];
    if (ld is Map<String, dynamic> && ld['type'] != null) {
      final d = Detection.fromJson(ld, base);
      if (lastDetection == null ||
          d.time.isAfter(lastDetection!.time) ||
          d.type != lastDetection!.type) {
        lastDetection = d;
        history.insert(0, d);
        if (history.length > 50) history.removeLast();
      }
    }
    final hist = j['history'];
    if (hist is List && history.isEmpty) {
      history = hist
          .whereType<Map<String, dynamic>>()
          .map((e) => Detection.fromJson(e, base))
          .toList();
    }
    final alertActive = j['alert'] == true;
    status = (alertActive || issue.isNotEmpty || battery < 15)
        ? WatcherStatus.alert
        : WatcherStatus.ok;
  }
}

class AppNotification {
  final String watcherId;
  final String watcherName;
  final String title;
  final String body;
  final DateTime time;
  final bool critical;
  bool read;

  AppNotification({
    required this.watcherId,
    required this.watcherName,
    required this.title,
    required this.body,
    required this.time,
    this.critical = false,
    this.read = false,
  });
}

class ForestRange {
  final String id;
  final String name;
  final String division;
  final double lat;
  final double lon;
  const ForestRange(this.id, this.name, this.division, this.lat, this.lon);
}

const kRanges = [
  ForestRange('kodanad', 'Kodanad Range', 'Malayattoor Division', 10.17, 76.67),
  ForestRange('marayoor', 'Marayoor Sandal Division', 'Marayoor', 10.27, 77.16),
  ForestRange('ranni', 'Ranni Range', 'Ranni Division', 9.38, 76.78),
  ForestRange('wayanad', 'Sulthan Bathery Range', 'Wayanad WLS', 11.66, 76.26),
  ForestRange('munnar', 'Munnar Range', 'Munnar Division', 10.09, 77.06),
];

/// A sighting reported by a local resident from the Resident mode.
class SightingReport {
  final String reporter;
  final String watcherId;
  final String type;
  final String note;
  final DateTime time;
  SightingReport({
    required this.reporter,
    required this.watcherId,
    required this.type,
    required this.note,
    required this.time,
  });
}
