import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const ValentineApp());

class ValentineApp extends StatelessWidget {
  const ValentineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const ValentineHome(),
    );
  }
}

class ValentineHome extends StatefulWidget {
  const ValentineHome({super.key});

  @override
  State<ValentineHome> createState() => _ValentineHomeState();
}

class _ValentineHomeState extends State<ValentineHome>
    with SingleTickerProviderStateMixin {
  final List<String> emojiOptions = const [
    'Sweet Heart',
    'Party Heart',
    'Lovestruck Heart',
  ];

  String selectedEmoji = 'Sweet Heart';
  final List<Offset> stamps = [];
  final List<Balloon> balloons = [];

  late AnimationController controller;

  bool pulsing = true;
  double pulseAmount = 0.12;

  final Random rng = Random();

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void dropBalloons() {
    setState(() {
      balloons.clear();
      for (int i = 0; i < 15; i++) {
        balloons.add(
          Balloon(
            x: rng.nextDouble(),
            y: 1.2 + rng.nextDouble(),
            speed: 0.01 + rng.nextDouble() * 0.02,
            wobble: rng.nextDouble() * 2 * pi,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cupid's Canvas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.celebration),
            onPressed: dropBalloons,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // Display Asset Images
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Image.asset('assets/images/love_icon.png', height: 60),
              Image.asset('assets/images/cupid_arrow.png', height: 60),
              Image.asset('assets/images/heart_confetti.png', height: 60),
            ],
          ),

          const SizedBox(height: 10),

          DropdownButton<String>(
            value: selectedEmoji,
            items: emojiOptions
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) =>
                setState(() => selectedEmoji = value ?? selectedEmoji),
          ),

          Slider(
            value: pulseAmount,
            min: 0,
            max: 0.3,
            onChanged: (v) => setState(() => pulseAmount = v),
          ),

          Expanded(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final t = controller.value;

                // Move balloons
                for (final b in balloons) {
                  b.y -= b.speed;
                  b.wobble += 0.05;
                }
                balloons.removeWhere((b) => b.y < -0.2);

                return GestureDetector(
                  onTapDown: (details) =>
                      stamps.add(details.localPosition),
                  onPanUpdate: (details) =>
                      stamps.add(details.localPosition),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: HeartPainter(
                      stamps: stamps,
                      balloons: balloons,
                      type: selectedEmoji,
                      time: t,
                      pulse: pulsing
                          ? (1 + sin(t * 2 * pi) * pulseAmount)
                          : 1,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------ Custom Painter ------------------ */

class HeartPainter extends CustomPainter {
  final List<Offset> stamps;
  final List<Balloon> balloons;
  final String type;
  final double time;
  final double pulse;

  HeartPainter({
    required this.stamps,
    required this.balloons,
    required this.type,
    required this.time,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    // Gradient Background
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFFFFE4EC),
          Color(0xFFFF6F91),
          Color(0xFFB0003A),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, bgPaint);

    // Draw stamped hearts
    for (final pos in stamps) {
      _drawHeart(canvas, pos, 40);
    }

    // Main pulsing heart
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(pulse);
    _drawHeart(canvas, Offset.zero, 100);
    canvas.restore();

    // Balloons
    for (final b in balloons) {
      _drawBalloon(canvas, size, b);
    }
  }

  void _drawHeart(Canvas canvas, Offset c, double size) {
    final path = Path()
      ..moveTo(c.dx, c.dy + size / 2)
      ..cubicTo(c.dx + size, c.dy - size / 3, c.dx + size / 2,
          c.dy - size, c.dx, c.dy - size / 4)
      ..cubicTo(c.dx - size / 2, c.dy - size,
          c.dx - size, c.dy - size / 3, c.dx, c.dy + size / 2)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        colors: type == "Party Heart"
            ? [Colors.pinkAccent, Colors.purple]
            : [Colors.redAccent, Colors.red],
      ).createShader(
          Rect.fromCircle(center: c, radius: size));

    canvas.drawPath(path, paint);

    // Sparkles
    final sparkle = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    canvas.drawLine(
        c + Offset(-size / 2, -size),
        c + Offset(-size / 2, -size - 10),
        sparkle);
  }

  void _drawBalloon(Canvas canvas, Size size, Balloon b) {
    final x = b.x * size.width + sin(b.wobble) * 10;
    final y = b.y * size.height;

    final rect = Rect.fromCenter(center: Offset(x, y), width: 30, height: 40);

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.yellow, Colors.orange],
      ).createShader(rect);

    canvas.drawOval(rect, paint);

    final stringPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    canvas.drawLine(
        Offset(x, y + 20), Offset(x, y + 60), stringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/* ------------------ Balloon Model ------------------ */

class Balloon {
  double x;
  double y;
  double speed;
  double wobble;

  Balloon({
    required this.x,
    required this.y,
    required this.speed,
    required this.wobble,
  });
}
