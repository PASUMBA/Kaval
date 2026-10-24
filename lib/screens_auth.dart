import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models.dart';
import 'store.dart';
import 'theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _id = TextEditingController();
  final _pw = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _rpw = TextEditingController();
  String? _post;
  String? _err;
  bool _busy = false;
  bool _resident = false;

  Future<void> _loginResident() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty || _post == null) {
      setState(() => _err = 'Enter your name and pick the nearest post');
      return;
    }
    if (phone.length < 10 || _rpw.text.length < 4) {
      setState(() => _err = 'Enter a 10-digit phone and a password (4+ chars)');
      return;
    }
    setState(() {
      _busy = true;
      _err = null;
    });
    final err = await context
        .read<KavalStore>()
        .loginResident(name, phone, _rpw.text, _post!);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _err = err;
      });
    }
  }

  Future<void> _login() async {
    final id = _id.text.trim();
    if (id.isEmpty || _pw.text.isEmpty) {
      setState(() => _err = 'Enter officer ID and password');
      return;
    }
    setState(() {
      _busy = true;
      _err = null;
    });
    final err = await context.read<KavalStore>().login(id, _pw.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _err = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B3D2E), Color(0xFF071F18)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const KavalLogo(size: 84),
                  const SizedBox(height: 16),
                  Text('KAVAL',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          letterSpacing: 6,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('കാവൽ · AI Forest Watch Network',
                      style: TextStyle(color: Colors.white.withOpacity(0.75))),
                  const SizedBox(height: 6),
                  Text('Kerala Forest & Wildlife Department',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.55), fontSize: 12)),
                  const SizedBox(height: 36),
                  SegmentedButton<bool>(
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.08),
                      foregroundColor: Colors.white70,
                      selectedBackgroundColor: const Color(0xFF9BE7B4),
                      selectedForegroundColor: kForest,
                    ),
                    segments: const [
                      ButtonSegment(
                          value: false,
                          label: Text('Forest Officer'),
                          icon: Icon(Icons.shield_outlined)),
                      ButtonSegment(
                          value: true,
                          label: Text('Local Resident'),
                          icon: Icon(Icons.home_outlined)),
                    ],
                    selected: {_resident},
                    onSelectionChanged: (s) => setState(() {
                      _resident = s.first;
                      _err = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                  if (_resident) _residentCard(context) else Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextField(
                            controller: _id,
                            decoration: const InputDecoration(
                              labelText: 'Officer ID',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _pw,
                            obscureText: true,
                            onSubmitted: (_) => _login(),
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          if (_err != null) ...[
                            const SizedBox(height: 10),
                            Text(_err!,
                                style: const TextStyle(color: Colors.red)),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy ? null : _login,
                              child: _busy
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Text('Sign in'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                      _resident
                          ? 'For people living near the forest edge · വനാതിർത്തിയിലെ നാട്ടുകാർക്ക്'
                          : 'Officer IDs are issued by the Forest Department',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _residentCard(BuildContext context) {
    final ws = context.read<KavalStore>().watchers;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Your name · പേര്',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone · ഫോൺ',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _rpw,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password (new or existing)',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _post,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Nearest watch post · അടുത്ത പോസ്റ്റ്',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              items: [
                for (final w in ws)
                  DropdownMenuItem(
                    value: w.id,
                    child: Text('${w.name} (${w.id})',
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _post = v),
            ),
            if (_err != null) ...[
              const SizedBox(height: 10),
              Text(_err!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _loginResident,
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Get elephant alerts'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RangeSelectScreen extends StatelessWidget {
  const RangeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<KavalStore>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Forest Range'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: store.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Welcome, ${store.officer}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Choose the range you are monitoring',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          for (final r in kRanges) _RangeTile(range: r),
        ],
      ),
    );
  }
}

class _RangeTile extends StatelessWidget {
  final ForestRange range;
  const _RangeTile({required this.range});

  @override
  Widget build(BuildContext context) {
    final store = context.read<KavalStore>();
    final posts = store.watchers.where((w) => w.range == range.id).toList();
    final alerts =
        posts.where((w) => w.status == WatcherStatus.alert).length;
    final offline =
        posts.where((w) => w.status == WatcherStatus.offline).length;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: kForest.withOpacity(0.12),
          child: const Icon(Icons.forest, color: kForest),
        ),
        title: Text(range.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(range.division),
              const SizedBox(width: 10),
              StatusDot(color: kOk, label: '${posts.length} posts'),
              if (alerts > 0) ...[
                const SizedBox(width: 8),
                StatusDot(color: kAlert, label: '$alerts'),
              ],
              if (offline > 0) ...[
                const SizedBox(width: 8),
                StatusDot(color: kOffline, label: '$offline'),
              ],
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => store.selectRange(range),
      ),
    );
  }
}
