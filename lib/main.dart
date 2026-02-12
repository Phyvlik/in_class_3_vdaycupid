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
  final List<String> emojiOptions = const ['Sweet Heart', 'Party Heart'];
  String selectedEmoji = 'Sweet Heart';

  // stamps (draw as you drag)
  final List<Stamp> stamps = [];

  // balloons
  final List<Balloon> balloons = [];

  // animation ticker (sparkles + pulse + balloons)
  late final AnimationController ticker;

  bool pulsing = true;
  double pulseAmount = 0.12;
  double stampSize = 115;

  final rng = Random();

  @override
  void initState() {
    super.initState();
    ticker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  void addStamp(Offset pos) {
    setState(() {
      stamps.add(
        Stamp(
          pos: pos,
          type: selectedEmoji,
          size: stampSize,
          seed: rng.nextInt(1 << 31),
          bornT: ticker.value,
        ),
      );
    });
  }

  void dropBalloons() {
    setState(() {
      balloons.clear();
      for (int i = 0; i < 16; i++) {
        balloons.add(
          Balloon(
            x01: rng.nextDouble(),
            y01: 1.25 + rng.nextDouble() * 0.7,
            speed: 0.10 + rng.nextDouble() * 0.25,
            wobble: rng.nextDouble() * 2 * pi,
            seed: rng.nextInt(1 << 31),
          ),
        );
      }
    });
  }

  void clearAll() {
    setState(() {
      stamps.clear();
      balloons.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cupid's Canvas"),
        actions: [
          IconButton(
            tooltip: "Balloon Celebration",
            icon: const Icon(Icons.celebration),
            onPressed: dropBalloons,
          ),
          IconButton(
            tooltip: "Clear",
            icon: const Icon(Icons.delete_outline),
            onPressed: clearAll,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // Assets (Step 3: Display the Love)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _TopAssetTile(path: 'assets/images/love_icon.png'),
                _TopAssetTile(path: 'assets/images/cupid_arrow.png'),
                _TopAssetTile(path: 'assets/images/heart_confetti.png'),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<String>(
                  value: selectedEmoji,
                  items: emojiOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selectedEmoji = v ?? selectedEmoji),
                ),
                FilledButton.icon(
                  onPressed: () => setState(() => pulsing = !pulsing),
                  icon: Icon(pulsing ? Icons.pause : Icons.play_arrow),
                  label: Text(pulsing ? "Pause Pulse" : "Pulse"),
                ),
                SizedBox(
                  width: 220,
                  child: Row(
                    children: [
                      const Text("Pulse"),
                      Expanded(
                        child: Slider(
                          value: pulseAmount,
                          min: 0.0,
                          max: 0.28,
                          onChanged: (v) => setState(() => pulseAmount = v),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 230,
                  child: Row(
                    children: [
                      const Text("Stamp"),
                      Expanded(
                        child: Slider(
                          value: stampSize,
                          min: 70,
                          max: 170,
                          onChanged: (v) => setState(() => stampSize = v),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Canvas + main emoji
          Expanded(
            child: AnimatedBuilder(
              animation: ticker,
              builder: (context, _) {
                final t = ticker.value;

                // update balloons
                if (balloons.isNotEmpty) {
                  for (final b in balloons) {
                    b.y01 -= b.speed * 0.018;
                    b.wobble += 0.07;
                  }
                  balloons.removeWhere((b) => b.y01 < -0.4);
                }

                final mainScale =
                    pulsing ? (1.0 + sin(t * 2 * pi) * pulseAmount) : 1.0;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasSize =
                        Size(constraints.maxWidth, constraints.maxHeight);

                    return GestureDetector(
                      onTapDown: (d) => addStamp(d.localPosition),
                      onPanStart: (d) => addStamp(d.localPosition),
                      onPanUpdate: (d) => addStamp(d.localPosition),
                      child: CustomPaint(
                        size: canvasSize,
                        painter: ScenePainter(
                          stamps: stamps,
                          balloons: balloons,
                          time: t,
                        ),
                        child: Center(
                          child: Transform.scale(
                            scale: mainScale,
                            child: CustomPaint(
                              size: const Size(300, 300),
                              painter: HeartEmojiPainter(
                                type: selectedEmoji,
                                time: t,
                                seed: 999,
                                showOrbitSparkles: true,
                                showGlowTrail: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ Top asset tiles ------------------------------ */

class _TopAssetTile extends StatelessWidget {
  const _TopAssetTile({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 92,
        height: 62,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.35)),
        ),
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.white.withOpacity(0.12),
            alignment: Alignment.center,
            child: const Text(
              "Missing\nasset",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

/* ------------------------------ Scene Painter ------------------------------ */

class ScenePainter extends CustomPainter {
  ScenePainter({
    required this.stamps,
    required this.balloons,
    required this.time,
  });

  final List<Stamp> stamps;
  final List<Balloon> balloons;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size, time);

    // stamps
    for (final s in stamps) {
      final aura = _aura(time, s.bornT);

      canvas.save();
      canvas.translate(s.pos.dx - s.size / 2, s.pos.dy - s.size / 2);

      HeartEmojiPainter(
        type: s.type,
        time: time,
        seed: s.seed,
        stampAura: aura,
        showOrbitSparkles: false,
        showGlowTrail: true,
      ).paint(canvas, Size(s.size, s.size));

      canvas.restore();
    }

    // balloons
    for (final b in balloons) {
      _paintBalloon(canvas, size, b, time);
    }
  }

  void _paintBackground(Canvas canvas, Size size, double t) {
    // soft pink->red radial gradient (requirement)
    final cx = 0.5 + 0.08 * sin(t * 2 * pi);
    final cy = 0.45 + 0.08 * cos(t * 2 * pi);

    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(cx * 2 - 1, cy * 2 - 1),
        radius: 1.25,
        colors: const [
          Color(0xFFFFE4EC),
          Color(0xFFFF6F91),
          Color(0xFFB0003A),
          Color(0xFF160018),
        ],
        stops: const [0.0, 0.48, 0.80, 1.0],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);
  }

  double _aura(double t, double bornT) {
    double dt = t - bornT;
    if (dt < 0) dt += 1.0;
    return (1.0 - dt).clamp(0.18, 1.0);
  }

  void _paintBalloon(Canvas canvas, Size size, Balloon b, double t) {
    final rng = Random(b.seed);

    final w = 40 + rng.nextDouble() * 18;
    final h = 56 + rng.nextDouble() * 26;

    final x = b.x01 * size.width + sin(b.wobble) * 16;
    final y = b.y01 * size.height;

    final rect = Rect.fromCenter(center: Offset(x, y), width: w, height: h);

    final c1 = Color.lerp(
      const Color(0xFFFFC1E3),
      const Color(0xFF8BE9FD),
      rng.nextDouble(),
    )!;
    final c2 = Color.lerp(
      const Color(0xFFFFF59D),
      const Color(0xFFFF8A80),
      rng.nextDouble(),
    )!;

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c1, c2],
      ).createShader(rect);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(0.55);

    canvas.drawOval(rect, fill);
    canvas.drawOval(rect, outline);

    // knot
    final knot = Path()
      ..moveTo(x, y + h / 2)
      ..lineTo(x - 6, y + h / 2 + 10)
      ..lineTo(x + 6, y + h / 2 + 10)
      ..close();
    canvas.drawPath(knot, outline);

    // string (FIXED: no Path.start())
    final sp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = Colors.white.withOpacity(0.6);

    final stringPath = Path()
      ..moveTo(x, y + h / 2 + 10)
      ..cubicTo(
        x + sin(t * 2 * pi + b.wobble) * 12,
        y + h / 2 + 40,
        x - sin(t * 2 * pi + b.wobble) * 10,
        y + h / 2 + 85,
        x + sin(t * 2 * pi + b.wobble) * 8,
        y + h / 2 + 130,
      );

    canvas.drawPath(stringPath, sp);
  }

  @override
  bool shouldRepaint(covariant ScenePainter old) =>
      old.time != time || old.stamps != stamps || old.balloons != balloons;
}

/* ------------------------------ Heart Emoji Painter ------------------------------ */

class HeartEmojiPainter extends CustomPainter {
  HeartEmojiPainter({
    required this.type,
    required this.time,
    required this.seed,
    required this.showOrbitSparkles,
    required this.showGlowTrail,
    this.stampAura = 1.0,
  });

  final String type;
  final double time;
  final int seed;

  final bool showOrbitSparkles;
  final bool showGlowTrail;

  final double stampAura;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final s = min(size.width, size.height);
    final scale = s / 300.0;
    final center = Offset(size.width / 2, size.height / 2);

    // Love trail (glow outline) behind heart (requirement)
    if (showGlowTrail) {
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12 * scale
        ..color = Colors.white.withOpacity(0.14 * stampAura);
      canvas.drawPath(_heartPath(center, scale * 1.02), glow);
    }

    // Heart linear gradient fill (requirement)
    final heartRect =
        Rect.fromCenter(center: center, width: 250 * scale, height: 250 * scale);

    final heartPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: type == 'Party Heart'
            ? const [Color(0xFFFFC1DC), Color(0xFFF06292), Color(0xFFAD1457)]
            : const [Color(0xFFFF5A8A), Color(0xFFE91E63), Color(0xFFB0003A)],
      ).createShader(heartRect);

    canvas.drawPath(_heartPath(center, scale), heartPaint);

    // Face + party details
    if (type == 'Party Heart') {
      _drawCuteFace(canvas, center, scale, wink: true);
      _drawPartyHat(canvas, center, scale, time);
      _drawConfetti(canvas, size, scale, rng);
    } else {
      _drawCuteFace(canvas, center, scale, wink: false);
    }

    // Animated sparkles (requirement)
    _drawSparkles(canvas, size, scale, time);

    // Extra orbit sparkles on the main emoji
    if (showOrbitSparkles) {
      _drawOrbitDots(canvas, size, scale, time);
    }
  }

  Path _heartPath(Offset c, double scale) {
    return Path()
      ..moveTo(c.dx, c.dy + 60 * scale)
      ..cubicTo(
        c.dx + 110 * scale,
        c.dy - 10 * scale,
        c.dx + 60 * scale,
        c.dy - 120 * scale,
        c.dx,
        c.dy - 40 * scale,
      )
      ..cubicTo(
        c.dx - 60 * scale,
        c.dy - 120 * scale,
        c.dx - 110 * scale,
        c.dy - 10 * scale,
        c.dx,
        c.dy + 60 * scale,
      )
      ..close();
  }

  void _drawCuteFace(Canvas canvas, Offset c, double scale,
      {required bool wink}) {
    final eyeWhite = Paint()..color = Colors.white.withOpacity(0.92);
    final pupil = Paint()..color = Colors.black.withOpacity(0.75);

    if (!wink) {
      canvas.drawCircle(
          c + Offset(-40 * scale, -12 * scale), 12 * scale, eyeWhite);
      canvas.drawCircle(
          c + Offset(40 * scale, -12 * scale), 12 * scale, eyeWhite);
      canvas.drawCircle(c + Offset(-40 * scale, -10 * scale), 5 * scale, pupil);
      canvas.drawCircle(c + Offset(40 * scale, -10 * scale), 5 * scale, pupil);
    } else {
      final winkPaint = Paint()
        ..color = Colors.black.withOpacity(0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5 * scale
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(c + Offset(-52 * scale, -16 * scale),
          c + Offset(-25 * scale, -6 * scale), winkPaint);
      canvas.drawLine(c + Offset(-52 * scale, -6 * scale),
          c + Offset(-25 * scale, -16 * scale), winkPaint);

      canvas.drawCircle(
          c + Offset(42 * scale, -12 * scale), 12 * scale, eyeWhite);
      canvas.drawCircle(c + Offset(42 * scale, -10 * scale), 5 * scale, pupil);
    }

    // Smile
    final mouth = Paint()
      ..color = Colors.black.withOpacity(0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * scale
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCenter(
      center: c + Offset(0, 28 * scale),
      width: 88 * scale,
      height: 62 * scale,
    );
    canvas.drawArc(rect, 0.15, pi - 0.30, false, mouth);
  }

  void _drawPartyHat(Canvas canvas, Offset c, double scale, double t) {
    final wobble = sin(t * 2 * pi) * 0.07;

    canvas.save();
    canvas.translate(c.dx, c.dy - 112 * scale);
    canvas.rotate(wobble);

    final hatRect = Rect.fromLTWH(
        -65 * scale, -25 * scale, 130 * scale, 155 * scale);
    final hatPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFFFFF59D),
          Color(0xFFFFD54F),
          Color(0xFFFF8F00)
        ],
      ).createShader(hatRect);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..color = Colors.white.withOpacity(0.55);

    final hat = Path()
      ..moveTo(0, -10 * scale)
      ..lineTo(-58 * scale, 90 * scale)
      ..lineTo(58 * scale, 90 * scale)
      ..close();

    canvas.drawPath(hat, hatPaint);
    canvas.drawPath(hat, outline);

    final pom = Paint()..color = Colors.white.withOpacity(0.92);
    canvas.drawCircle(Offset(0, -10 * scale), 12 * scale, pom);

    canvas.restore();
  }

  void _drawConfetti(Canvas canvas, Size size, double scale, Random rng) {
    // Confetti using triangles/circles/lines
    final center = Offset(size.width / 2, size.height / 2);
    const count = 26;

    for (int i = 0; i < count; i++) {
      final a = (i / count) * 2 * pi;
      final r = 140 * scale + rng.nextDouble() * 35 * scale;
      final p = center + Offset(cos(a), sin(a)) * r;

      final color = _confettiColor(i).withOpacity(0.95);

      if (i % 3 == 0) {
        final paint = Paint()..color = color;
        final tri = Path()
          ..moveTo(p.dx, p.dy - 8 * scale)
          ..lineTo(p.dx - 8 * scale, p.dy + 8 * scale)
          ..lineTo(p.dx + 8 * scale, p.dy + 8 * scale)
          ..close();
        canvas.drawPath(tri, paint);
      } else if (i % 3 == 1) {
        final paint = Paint()..color = color;
        canvas.drawCircle(p, 6 * scale, paint);
      } else {
        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2 * scale
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(p + Offset(-8 * scale, -4 * scale),
            p + Offset(8 * scale, 4 * scale), paint);
      }
    }
  }

  Color _confettiColor(int i) {
    const palette = [
      Color(0xFF8BE9FD),
      Color(0xFFFFF59D),
      Color(0xFFFF8A80),
      Color(0xFFB39DDB),
      Color(0xFFA7FFEB),
    ];
    return palette[i % palette.length];
  }

  void _drawSparkles(Canvas canvas, Size size, double scale, double t) {
    final sparkle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * scale
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.78 * stampAura);

    final dot = Paint()..color = Colors.white.withOpacity(0.65 * stampAura);

    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 8; i++) {
      final a = (i / 8) * 2 * pi + t * 2 * pi;
      final r = 150 * scale + 10 * scale * sin(t * 2 * pi + i);
      final p = center + Offset(cos(a), sin(a)) * r;

      final len = (9 + 7 * sin(t * 2 * pi + i)) * scale;
      canvas.drawLine(p + Offset(-len, 0), p + Offset(len, 0), sparkle);
      canvas.drawLine(p + Offset(0, -len), p + Offset(0, len), sparkle);

      canvas.drawCircle(p + Offset(14 * scale, -10 * scale), 2.2 * scale, dot);
    }
  }

  void _drawOrbitDots(Canvas canvas, Size size, double scale, double t) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringPaint = Paint()..color = Colors.white.withOpacity(0.14);
    for (int i = 0; i < 36; i++) {
      final a = (i / 36) * 2 * pi + t * 2 * pi;
      final r = 170 * scale + 6 * scale * sin((t * 2 * pi) + i);
      final p = center + Offset(cos(a), sin(a)) * r;
      final rr = (i % 3 == 0 ? 2.7 : 1.7) * scale;
      canvas.drawCircle(p, rr, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant HeartEmojiPainter old) =>
      old.type != type ||
      old.time != time ||
      old.seed != seed ||
      old.showOrbitSparkles != showOrbitSparkles ||
      old.showGlowTrail != showGlowTrail ||
      old.stampAura != stampAura;
}

/* ------------------------------ Models ------------------------------ */

class Stamp {
  Stamp({
    required this.pos,
    required this.type,
    required this.size,
    required this.seed,
    required this.bornT,
  });

  final Offset pos;
  final String type;
  final double size;
  final int seed;
  final double bornT;
}

class Balloon {
  Balloon({
    required this.x01,
    required this.y01,
    required this.speed,
    required this.wobble,
    required this.seed,
  });

  final double x01;
  double y01;
  final double speed;
  double wobble;
  final int seed;
}
