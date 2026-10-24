import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'store.dart';
import 'theme.dart';

Color statusColor(WatcherStatus s) => switch (s) {
      WatcherStatus.ok => kOk,
      WatcherStatus.alert => kAlert,
      WatcherStatus.offline => kOffline,
    };

String statusText(WatcherStatus s) => switch (s) {
      WatcherStatus.ok => 'Normal',
      WatcherStatus.alert => 'Alert',
      WatcherStatus.offline => 'Offline',
    };

String ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return '${d.inSeconds}s ago';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return DateFormat('d MMM, HH:mm').format(t);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  final _player = AudioPlayer();
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    final store = context.read<KavalStore>();
    store.startPolling();
    _sub = store.alerts.stream.listen(_onAlert);
  }

  void _onAlert(AppNotification n) {
    if (!mounted) return;
    if (n.critical) {
      try {
        _player.play(AssetSource('alert.wav'));
      } catch (_) {}
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: n.critical ? kAlert : kForest,
        duration: const Duration(seconds: 4),
        content: Row(children: [
          Icon(n.critical ? Icons.warning_amber : Icons.info_outline,
              color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
              child: Text('${n.title} — ${n.watcherName}',
                  style: const TextStyle(color: Colors.white))),
        ]),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () {
            final store = context.read<KavalStore>();
            final w = store.watchers.where((w) => w.id == n.watcherId);
            if (w.isNotEmpty) openWatcher(context, w.first);
          },
        ),
      ));
  }

  @override
  void dispose() {
    _sub?.cancel();
    _player.dispose();
    context.read<KavalStore>().stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<KavalStore>();
    final pages = const [MapTab(), PostsTab(), NotificationsTab(), SettingsTab()];
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('KAVAL',
                style: TextStyle(letterSpacing: 3, fontSize: 16)),
            Text(store.range?.name ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          if (store.demoMode)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Chip(
                  label: Text('DEMO', style: TextStyle(fontSize: 10)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero),
            ),
          IconButton(
            tooltip: 'Change range',
            icon: const Icon(Icons.swap_horiz),
            onPressed: store.clearRange,
          ),
        ],
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          setState(() => _tab = i);
          if (i == 2) store.markAllRead();
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          const NavigationDestination(
              icon: Icon(Icons.videocam_outlined), label: 'Posts'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: store.unread > 0,
              label: Text('${store.unread}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            label: 'Alerts',
          ),
          const NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

void openWatcher(BuildContext context, Watcher w) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => WatcherDetailScreen(watcherId: w.id)),
  );
}

// ───────────────────────────── MAP ─────────────────────────────

class MapTab extends StatelessWidget {
  const MapTab({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<KavalStore>();
    final ws = store.rangeWatchers;
    final r = store.range!;
    final alerts = ws.where((w) => w.status == WatcherStatus.alert).length;
    final offline = ws.where((w) => w.status == WatcherStatus.offline).length;
    return Stack(children: [
      FlutterMap(
        options: MapOptions(
          initialCenter: ws.isEmpty
              ? LatLng(r.lat, r.lon)
              : LatLng(
                  ws.map((w) => w.lat).reduce((a, b) => a + b) / ws.length,
                  ws.map((w) => w.lon).reduce((a, b) => a + b) / ws.length),
          initialZoom: 12.3,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'in.pasulabs.kaval',
          ),
          MarkerLayer(
            markers: [
              for (final w in ws)
                Marker(
                  point: LatLng(w.lat, w.lon),
                  width: 120,
                  height: 72,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () => openWatcher(context, w),
                    child: _Pin(w: w),
                  ),
                ),
            ],
          ),
        ],
      ),
      Positioned(
        left: 12,
        right: 12,
        top: 12,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              _Stat(label: 'Posts', value: '${ws.length}', color: kForest),
              _Stat(label: 'Alerts', value: '$alerts', color: kAlert),
              _Stat(label: 'Offline', value: '$offline', color: kOffline),
              const Spacer(),
              const StatusDot(color: kOk, label: 'OK'),
              const SizedBox(width: 6),
              const StatusDot(color: kAlert, label: 'Issue'),
              const SizedBox(width: 6),
              const StatusDot(color: kOffline, label: 'Off'),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: const TextStyle(fontSize: 11)),
        ]),
      );
}

class _Pin extends StatelessWidget {
  final Watcher w;
  const _Pin({required this.w});
  @override
  Widget build(BuildContext context) {
    final c = statusColor(w.status);
    final pulsing = w.status == WatcherStatus.alert;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _PulseRing(
        active: pulsing,
        color: c,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black38)],
          ),
          child: Icon(
            w.status == WatcherStatus.alert && w.lastDetection != null
                ? detectionIcon(w.lastDetection!.type)
                : Icons.videocam,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
      const SizedBox(height: 2),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(6)),
        child: Text(w.id,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
      ),
    ]);
  }
}

class _PulseRing extends StatefulWidget {
  final bool active;
  final Color color;
  final Widget child;
  const _PulseRing(
      {required this.active, required this.color, required this.child});
  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Stack(alignment: Alignment.center, children: [
        Container(
          width: 36 + 24 * _c.value,
          height: 36 + 24 * _c.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.45 * (1 - _c.value)),
          ),
        ),
        child!,
      ]),
      child: widget.child,
    );
  }
}

// ───────────────────────────── POSTS LIST ─────────────────────────────

class PostsTab extends StatelessWidget {
  const PostsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<KavalStore>();
    final ws = [...store.rangeWatchers]
      ..sort((a, b) => a.status == b.status
          ? a.id.compareTo(b.id)
          : (a.status == WatcherStatus.alert ? -1 : 1));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: ws.length,
      itemBuilder: (_, i) => WatcherCard(w: ws[i]),
    );
  }
}

class WatcherCard extends StatelessWidget {
  final Watcher w;
  const WatcherCard({super.key, required this.w});
  @override
  Widget build(BuildContext context) {
    final c = statusColor(w.status);
    final d = w.lastDetection;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => openWatcher(context, w),
        leading: CircleAvatar(
            backgroundColor: c, child: const Icon(Icons.videocam, color: Colors.white)),
        title: Text('${w.id} · ${w.name}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 2),
          Text(w.status == WatcherStatus.offline
              ? 'Offline · last seen ${ago(w.lastSeen)}'
              : w.issue.isNotEmpty
                  ? w.issue
                  : d == null
                      ? 'No detections yet'
                      : '${d.label} · ${ago(d.time)}'),
        ]),
        trailing: BatteryChip(level: w.battery),
      ),
    );
  }
}

class BatteryChip extends StatelessWidget {
  final int level;
  const BatteryChip({super.key, required this.level});
  @override
  Widget build(BuildContext context) {
    final c = level < 15 ? kAlert : (level < 40 ? kAmber : kOk);
    final icon = level < 15
        ? Icons.battery_alert
        : level < 40
            ? Icons.battery_3_bar
            : level < 80
                ? Icons.battery_5_bar
                : Icons.battery_full;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: c, size: 20),
      Text('$level%', style: TextStyle(color: c, fontWeight: FontWeight.w600)),
    ]);
  }
}

// ───────────────────────────── DETAIL ─────────────────────────────

class WatcherDetailScreen extends StatelessWidget {
  final String watcherId;
  const WatcherDetailScreen({super.key, required this.watcherId});

  @override
  Widget build(BuildContext context) {
    final store = context.read<KavalStore>();
    return ListenableBuilder(
        listenable: store, builder: (context, _) => _build(context, store));
  }

  Widget _build(BuildContext context, KavalStore store) {
    final w = store.watchers.firstWhere((w) => w.id == watcherId);
    final c = statusColor(w.status);
    final d = w.lastDetection;
    return Scaffold(
      appBar: AppBar(title: Text(w.id)),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Card(
          color: c,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(
                  w.status == WatcherStatus.alert && d != null
                      ? detectionIcon(d.type)
                      : w.status == WatcherStatus.offline
                          ? Icons.cloud_off
                          : Icons.verified,
                  color: Colors.white,
                  size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      Text(
                        w.status == WatcherStatus.alert
                            ? (w.issue.isNotEmpty
                                ? w.issue
                                : '${d?.label ?? 'Alert'} · ${d == null ? '' : ago(d.time)}')
                            : w.status == WatcherStatus.offline
                                ? 'Offline · last seen ${ago(w.lastSeen)}'
                                : 'All normal · watching',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ]),
              ),
              if (w.status == WatcherStatus.alert)
                TextButton(
                  onPressed: () => store.acknowledge(w),
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.white, foregroundColor: c),
                  child: const Text('ACK'),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              _kv('Battery', '', trailing: BatteryChip(level: w.battery)),
              _kv('Range', store.range?.name ?? w.range),
              _kv('Location',
                  '${w.lat.toStringAsFixed(4)}, ${w.lon.toStringAsFixed(4)}'),
              _kv('Gimbal', 'pan ${w.pan}° · tilt ${w.tilt}°',
                  trailing: w.tracking
                      ? const Chip(
                          label: Text('TRACKING',
                              style: TextStyle(fontSize: 10, color: Colors.white)),
                          backgroundColor: kAlert,
                          visualDensity: VisualDensity.compact)
                      : null),
              _kv('Link',
                  w.isDemo ? 'Demo post' : '${w.baseUrl} · Wi-Fi'),
              _kv('Last heartbeat', ago(w.lastSeen)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Text('Recent detection',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        if (d == null)
          const Card(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nothing detected yet')))
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: d.snapshotUrl != null
                    ? _Snapshot(
                        key: ValueKey(
                            '${d.snapshotUrl}?t=${d.time.millisecondsSinceEpoch ~/ 60000}'),
                        url:
                            '${d.snapshotUrl}?t=${d.time.millisecondsSinceEpoch ~/ 60000}',
                        placeholder: _snapPlaceholder(d),
                      )
                    : _snapPlaceholder(d),
              ),
              ListTile(
                leading: Icon(detectionIcon(d.type), color: kAlert),
                title: Text(d.label),
                subtitle: Text(
                    '${(d.confidence * 100).round()}% confidence · ${d.source} · ${DateFormat('d MMM HH:mm:ss').format(d.time)}'),
              ),
            ]),
          ),
        const SizedBox(height: 12),
        Text('History (${w.history.length})',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        for (final h in w.history.take(20))
          ListTile(
            dense: true,
            leading: Icon(detectionIcon(h.type),
                color: h.isThreat ? kAlert : kOffline),
            title: Text(h.label),
            subtitle: Text(
                '${DateFormat('d MMM HH:mm:ss').format(h.time)} · ${(h.confidence * 100).round()}% · ${h.source}'),
          ),
        if (w.isDemo && w.status != WatcherStatus.offline) ...[
          const SizedBox(height: 16),
          Text('Demo triggers', style: Theme.of(context).textTheme.labelLarge),
          Wrap(spacing: 8, children: [
            for (final t in ['elephant', 'person', 'chainsaw', 'gunshot', 'fire'])
              ActionChip(
                avatar: Icon(detectionIcon(t), size: 16),
                label: Text(t),
                onPressed: () => store.fireDemoDetection(w, t),
              ),
          ]),
        ],
      ]),
    );
  }

  Widget _snapPlaceholder(Detection d) => Container(
        color: const Color(0xFF1F2A24),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(detectionIcon(d.type), color: Colors.white54, size: 48),
            const SizedBox(height: 6),
            const Text('snapshot', style: TextStyle(color: Colors.white38)),
          ]),
        ),
      );

  Widget _kv(String k, String v, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(
              width: 110,
              child: Text(k, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w500))),
          if (trailing != null) trailing,
        ]),
      );
}

// ───────────────────────────── NOTIFICATIONS ─────────────────────────────

class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<KavalStore>();
    final ns = store.notifications;
    if (ns.isEmpty) {
      return const Center(child: Text('No alerts yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: ns.length,
      itemBuilder: (_, i) {
        final n = ns[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: n.critical ? kAlert : kForest,
              child: Icon(n.critical ? Icons.warning_amber : Icons.info_outline,
                  color: Colors.white),
            ),
            title: Text(n.title,
                style: TextStyle(
                    fontWeight: n.read ? FontWeight.w500 : FontWeight.w700)),
            subtitle: Text('${n.body}\n${ago(n.time)}'),
            isThreeLine: true,
            onTap: () {
              final w = store.watchers.where((w) => w.id == n.watcherId);
              if (w.isNotEmpty) openWatcher(context, w.first);
            },
          ),
        );
      },
    );
  }
}

// ───────────────────────────── SETTINGS ─────────────────────────────

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});
  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late final TextEditingController _url;
  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: context.read<KavalStore>().cameraUrl);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<KavalStore>();
    return ListView(padding: const EdgeInsets.all(14), children: [
      Card(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Mode', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Demo'), icon: Icon(Icons.science_outlined)),
                  ButtonSegment(value: false, label: Text('Live camera'), icon: Icon(Icons.videocam_outlined)),
                ],
                selected: {store.demoMode},
                onSelectionChanged: (s) => store.setDemo(s.first),
              ),
              const SizedBox(height: 8),
              Text(
                store.demoMode
                    ? 'Simulated posts. Choose Live camera to connect KDN-01 to the reCamera.'
                    : store.lastError.isNotEmpty
                        ? 'KDN-01 → ${store.cameraUrl}\nError: ${store.lastError}'
                        : store.lastPollOk == null
                            ? 'KDN-01 → ${store.cameraUrl}\nConnecting…'
                            : 'KDN-01 → ${store.cameraUrl}\nConnected · last reply ${ago(store.lastPollOk!)}',
                style: TextStyle(
                    fontSize: 12,
                    color: (!store.demoMode && store.lastError.isNotEmpty) ? kAlert : Colors.black54),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(
                controller: _url,
                decoration: const InputDecoration(
                  labelText: 'Watcher (reCamera Node-RED) URL',
                  hintText: 'http://192.168.4.2:1880',
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    store.setCameraUrl(_url.text);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saved')));
                  },
                  child: const Text('Save'),
                ),
              ),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Card(
        child: ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(store.officer),
          subtitle: const Text('Signed in'),
          trailing: TextButton(onPressed: store.logout, child: const Text('Sign out')),
        ),
      ),
      const SizedBox(height: 12),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Kaval (കാവൽ) — AI forest watch posts. Each post sees (YOLO on reCamera), '
            'hears (chainsaw / gunshot), tracks with a gimbal and reports here over Wi-Fi.\n'
            'PASU Labs · Devin Hacks Kochi',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ),
    ]);
  }
}

/// Fetches the snapshot once per URL; parent rebuilds (every poll) must not
/// re-request the image from the camera.
class _Snapshot extends StatefulWidget {
  const _Snapshot({super.key, required this.url, required this.placeholder});
  final String url;
  final Widget placeholder;
  @override
  State<_Snapshot> createState() => _SnapshotState();
}

class _SnapshotState extends State<_Snapshot> {
  late final Widget _img = Image.network(
    widget.url,
    fit: BoxFit.cover,
    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
    errorBuilder: (_, __, ___) => widget.placeholder,
  );
  @override
  Widget build(BuildContext context) => _img;
}
