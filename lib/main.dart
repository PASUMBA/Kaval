import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens_auth.dart';
import 'screens_home.dart';
import 'screens_resident.dart';
import 'store.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = KavalStore();
  runApp(
    ChangeNotifierProvider.value(value: store, child: const KavalApp()),
  );
  store.load();
}

class KavalApp extends StatelessWidget {
  const KavalApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kaval',
      debugShowCheckedModeBanner: false,
      theme: kavalTheme(),
      home: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();
  @override
  Widget build(BuildContext context) {
    final store = context.watch<KavalStore>();
    if (store.officer.isEmpty) return const LoginScreen();
    if (store.role == 'resident' && store.homePostId != null) {
      return const ResidentHomeScreen();
    }
    if (store.range == null) return const RangeSelectScreen();
    return const HomeScreen();
  }
}
