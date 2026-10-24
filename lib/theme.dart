import 'package:flutter/material.dart';

const kForest = Color(0xFF0B3D2E);
const kMoss = Color(0xFF2E7D4F);
const kOk = Color(0xFF2E7D32);
const kAlert = Color(0xFFD32F2F);
const kOffline = Color(0xFF8E8E8E);
const kAmber = Color(0xFFF9A825);

ThemeData kavalTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: kForest, primary: kForest),
  );
  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFFF4F6F3),
    appBarTheme: const AppBarTheme(
      backgroundColor: kForest,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F4F0),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kForest,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

class KavalLogo extends StatelessWidget {
  final double size;
  const KavalLogo({super.key, this.size = 48});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
      child: Image.asset('assets/kerala_emblem.png',
          fit: BoxFit.contain, semanticLabel: 'Government of Kerala'),
    );
  }
}

class StatusDot extends StatelessWidget {
  final Color color;
  final String label;
  const StatusDot({super.key, required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]);
  }
}

IconData detectionIcon(String type) {
  switch (type) {
    case 'elephant':
      return Icons.pets;
    case 'person':
      return Icons.directions_walk;
    case 'chainsaw':
      return Icons.carpenter;
    case 'gunshot':
      return Icons.flash_on;
    case 'vehicle':
      return Icons.local_shipping;
    case 'fire':
    case 'smoke':
      return Icons.local_fire_department;
    default:
      return Icons.visibility;
  }
}
