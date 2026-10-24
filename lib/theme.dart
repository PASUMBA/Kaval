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
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kForest,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Image.asset(
        'assets/kerala_emblem.png',
        fit: BoxFit.contain,
        semanticLabel: 'Government of Kerala',
      ),
    );
  }
}

class StatusDot extends StatelessWidget {
  final Color color;
  final String label;
  const StatusDot({super.key, required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
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

/// Soft leaf vectors for backgrounds (login, drawer header). Pure paint, no assets.
class LeafBackdrop extends StatelessWidget {
  final Color color;
  final double opacity;
  const LeafBackdrop({
    super.key,
    this.color = Colors.white,
    this.opacity = 0.08,
  });
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _LeafPainter(color.withOpacity(opacity)),
      size: Size.infinite,
    ),
  );
}

class _LeafPainter extends CustomPainter {
  final Color c;
  _LeafPainter(this.c);

  Path _leaf(double len) {
    final p = Path();
    p.moveTo(0, 0);
    p.quadraticBezierTo(len * 0.55, -len * 0.42, len, 0);
    p.quadraticBezierTo(len * 0.55, len * 0.42, 0, 0);
    p.close();
    return p;
  }

  void _draw(
    Canvas canvas,
    Offset at,
    double len,
    double angle,
    Paint fill,
    Paint vein,
  ) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    canvas.drawPath(_leaf(len), fill);
    canvas.drawLine(Offset.zero, Offset(len, 0), vein);
    for (var i = 1; i <= 4; i++) {
      final x = len * i / 5;
      final h = len * 0.26 * (1 - (i - 2.5).abs() / 4);
      canvas.drawLine(Offset(x, 0), Offset(x + len * 0.08, -h), vein);
      canvas.drawLine(Offset(x, 0), Offset(x + len * 0.08, h), vein);
    }
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = c;
    final vein = Paint()
      ..color = c.withOpacity((c.opacity * 1.8).clamp(0.0, 1.0))
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final w = size.width, h = size.height;
    final spec = <List<double>>[
      // x frac, y frac, length frac of width, angle
      [-0.05, 0.08, 0.42, 0.55],
      [0.70, -0.02, 0.38, 2.4],
      [0.85, 0.30, 0.34, -1.1],
      [-0.08, 0.62, 0.40, -0.45],
      [0.62, 0.88, 0.46, 3.6],
      [0.20, 1.02, 0.30, -2.2],
    ];
    for (final sp in spec) {
      _draw(canvas, Offset(w * sp[0], h * sp[1]), w * sp[2], sp[3], fill, vein);
    }
  }

  @override
  bool shouldRepaint(covariant _LeafPainter old) => old.c != c;
}
