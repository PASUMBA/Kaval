import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'screens_home.dart';
import 'store.dart';
import 'theme.dart';

/// Resident (forest-edge villager) mode: one post, one big status, bee-sound
/// deterrent and a one-tap sighting report.
class ResidentHomeScreen extends StatefulWidget {
  const ResidentHomeScreen({super.key});
  @override
  State<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends State<ResidentHomeScreen> {
  final _bee = AudioPlayer();
  final _ping = AudioPlayer();
  bool _beeOn = false;
  bool _beeAuto = false;
  DateTime? _lastAlertTime;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    final store = context.read<KavalStore>();
    store.startPolling();
    _bee.setReleaseMode(ReleaseMode.loop);
    _sub = store.alerts.stream.listen(_onNotification);
    store.addListener(_checkAlert);
  }

  void _onNotification(AppNotification n) {
    if (!mounted) return;
    final store = context.read<KavalStore>();
    if (n.watcherId != store.homePostId) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: n.critical ? kAlert : kForest,
          duration: const Duration(seconds: 5),
          content: Text(
            '${n.title} — ${n.watcherName}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
  }

  /// Elephant/bear at my post → bee sound starts by itself; stops when clear.
  void _checkAlert() {
    if (!mounted) return;
    final store = context.read<KavalStore>();
    final d = store.homeWildlifeAlert;
    if (d != null && d.time != _lastAlertTime) {
      _lastAlertTime = d.time;
      _startBee(auto: true);
      try {
        _ping.play(AssetSource('alert.wav'));
      } catch (_) {}
    } else if (d == null && _beeAuto && _beeOn) {
      _stopBee();
    }
  }

  Future<void> _startBee({bool auto = false}) async {
    _beeAuto = auto;
    if (!_beeOn) {
      try {
        await _bee.play(AssetSource('bee.wav'));
      } catch (_) {}
    }
    if (mounted) setState(() => _beeOn = true);
  }

  Future<void> _stopBee() async {
    _beeAuto = false;
    try {
      await _bee.stop();
    } catch (_) {}
    if (mounted) setState(() => _beeOn = false);
  }

  @override
  void dispose() {
    _sub?.cancel();
    context.read<KavalStore>().removeListener(_checkAlert);
    _bee.dispose();
    _ping.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<KavalStore>();
    final w = store.homePost;
    if (w == null) {
      return const Scaffold(body: Center(child: Text('Post not found')));
    }
    final alert = store.homeWildlifeAlert;
    final offline = w.status == WatcherStatus.offline;
    final c = alert != null ? kAlert : (offline ? kOffline : kOk);
    final threats = w.history.where((h) => h.isThreat).take(5).toList();
    final myReports = store.reports
        .where((r) => r.watcherId == w.id)
        .take(5)
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8),
          child: KavalLogo(size: 36),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KAVAL · നാട്ടുകാർ',
              style: TextStyle(letterSpacing: 2, fontSize: 16),
            ),
            Text(
              w.name,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (store.demoMode)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Chip(
                label: Text('DEMO', style: TextStyle(fontSize: 10)),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Settings')),
                  body: const SettingsTab(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // ── big status ──
          Card(
            color: c,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
              child: Column(
                children: [
                  Icon(
                    alert != null
                        ? detectionIcon(alert.type)
                        : offline
                        ? Icons.cloud_off
                        : Icons.verified_user_outlined,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    alert != null
                        ? (alert.type == 'bear'
                              ? 'BEAR NEARBY'
                              : 'ELEPHANT NEARBY')
                        : offline
                        ? (w.lastSeen.year < 2000
                              ? 'CONNECTING…'
                              : 'POST OFFLINE')
                        : 'ALL CLEAR',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert != null
                        ? (alert.type == 'bear'
                              ? 'കരടി സമീപത്ത്'
                              : 'ആന സമീപത്ത്')
                        : offline
                        ? 'ക്യാമറ ഓഫ്‌ലൈൻ'
                        : 'സുരക്ഷിതം',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    alert != null
                        ? '${w.name} · ${ago(alert.time)}\nStay indoors. Keep away from the forest edge.'
                        : offline
                        ? (w.lastSeen.year < 2000
                              ? 'Connecting…'
                              : 'Last seen ${ago(w.lastSeen)}')
                        : 'No elephant near ${w.name}\nLast check ${ago(w.lastSeen)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── bee deterrent ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.hive_outlined,
                        color: _beeOn ? kAmber : kForest,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Bee sound deterrent · തേനീച്ച ശബ്ദം',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (_beeOn)
                        const Chip(
                          label: Text(
                            'PLAYING',
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                          backgroundColor: kAmber,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Elephants avoid the sound of bees. Starts automatically when '
                    'an elephant is detected at your post; you can also play it any time.',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _beeOn ? kAlert : kAmber,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _beeOn ? _stopBee : () => _startBee(),
                      icon: Icon(_beeOn ? Icons.stop : Icons.volume_up),
                      label: Text(
                        _beeOn ? 'Stop sound' : 'Play bee sound',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── report ──
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: () => _report(context, store),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text(
                'Report a sighting · കണ്ടത് അറിയിക്കുക',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          if (w.isDemo && store.demoMode) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => store.fireDemoDetection(w, 'elephant'),
              icon: const Icon(Icons.science_outlined),
              label: const Text('Demo: simulate elephant at my post'),
            ),
          ],
          const SizedBox(height: 18),

          // ── recent ──
          Text(
            'Recent at ${w.name}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          if (threats.isEmpty && myReports.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nothing yet'),
              ),
            ),
          for (final r in myReports)
            Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                leading: const Icon(
                  Icons.record_voice_over_outlined,
                  color: kForest,
                ),
                title: Text('You reported: ${_cap(r.type)}'),
                subtitle: Text(
                  '${DateFormat('d MMM HH:mm').format(r.time)}${r.note.isEmpty ? '' : ' · ${r.note}'}',
                ),
              ),
            ),
          for (final h in threats)
            Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                leading: Icon(detectionIcon(h.type), color: kAlert),
                title: Text(h.label),
                subtitle: Text(
                  '${DateFormat('d MMM HH:mm').format(h.time)} · camera post',
                ),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(store.officer),
              subtitle: Text('Resident · ${w.name}'),
              trailing: TextButton(
                onPressed: () async {
                  await _stopBee();
                  store.logout();
                },
                child: const Text('Sign out'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Future<void> _report(BuildContext context, KavalStore store) async {
    String type = 'elephant';
    final note = TextEditingController();
    Uint8List? photo;
    Future<void> pick(
      ImageSource src,
      void Function(void Function()) setSheet,
    ) async {
      try {
        final x = await ImagePicker().pickImage(
          source: src,
          maxWidth: 1024,
          imageQuality: 60,
        );
        if (x == null) return;
        final b = await x.readAsBytes();
        setSheet(() => photo = b);
      } catch (_) {}
    }

    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What did you see?',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Sent to the Forest Department for ${store.homePost?.name ?? ''}',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in const [
                    ('elephant', 'Elephant · ആന', Icons.pets),
                    ('wild boar', 'Wild boar · പന്നി', Icons.pets),
                    ('bear', 'Bear · കരടി', Icons.pets),
                    ('person', 'Suspicious person', Icons.directions_walk),
                    ('fire', 'Fire / smoke', Icons.local_fire_department),
                    ('other', 'Other', Icons.help_outline),
                  ])
                    ChoiceChip(
                      avatar: Icon(
                        t.$3,
                        size: 16,
                        color: type == t.$1 ? Colors.white : kForest,
                      ),
                      label: Text(t.$2),
                      selected: type == t.$1,
                      selectedColor: kForest,
                      labelStyle: TextStyle(
                        color: type == t.$1 ? Colors.white : Colors.black87,
                      ),
                      onSelected: (_) => setSheet(() => type = t.$1),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: note,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Where / how many? (optional)',
                  hintText: 'e.g. 2 elephants near the paddy field',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (photo != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          photo!,
                          width: 72,
                          height: 54,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => pick(ImageSource.camera, setSheet),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(photo == null ? 'Take photo' : 'Retake'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => pick(ImageSource.gallery, setSheet),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                  if (photo != null)
                    IconButton(
                      tooltip: 'Remove photo',
                      onPressed: () => setSheet(() => photo = null),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.send),
                  label: const Text(
                    'Send report',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (sent == true) {
      store.reportSighting(
        type,
        note.text,
        photo: photo == null ? '' : base64Encode(photo!),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: kOk,
          content: Text('Report sent to the Forest Department. Thank you!'),
        ),
      );
    }
  }
}
