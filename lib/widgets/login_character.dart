import 'dart:math';
import 'package:flutter/material.dart';

class LoginCharacter extends StatefulWidget {
  final double size;
  final bool isEmailFocused;
  final bool isPasswordFocused;
  final bool isShowingPassword;
  final double emailTextProgress;

  const LoginCharacter({
    super.key,
    this.size = 160,
    this.isEmailFocused = false,
    this.isPasswordFocused = false,
    this.isShowingPassword = false,
    this.emailTextProgress = 0.0,
  });

  @override
  State<LoginCharacter> createState() => _LoginCharacterState();
}

class _LoginCharacterState extends State<LoginCharacter>
    with TickerProviderStateMixin {
  late AnimationController _handController;
  late AnimationController _peekController;
  late AnimationController _headTiltController;
  late AnimationController _eyeTrackController;
  late AnimationController _entranceController;

  late Animation<double> _handAnim;
  late Animation<double> _peekAnim;
  late Animation<double> _headTiltAnim;
  late Animation<double> _entranceAnim;

  double _currentEyeTarget = 0.0;
  double _animatedEyeTarget = 0.0;

  @override
  void initState() {
    super.initState();

    _handController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _handAnim = CurvedAnimation(
      parent: _handController,
      curve: Curves.easeInOutBack,
    );

    _peekController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _peekAnim = CurvedAnimation(
      parent: _peekController,
      curve: Curves.easeInOut,
    );

    _headTiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _headTiltAnim = CurvedAnimation(
      parent: _headTiltController,
      curve: Curves.easeInOut,
    );

    _eyeTrackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addListener(() {
        setState(() {
          _animatedEyeTarget = _animatedEyeTarget +
              (_currentEyeTarget - _animatedEyeTarget) *
                  _eyeTrackController.value;
        });
      });

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entranceAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.elasticOut,
    );
    _entranceController.forward();
  }

  @override
  void didUpdateWidget(LoginCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Head tilt when email focused
    if (widget.isEmailFocused && !oldWidget.isEmailFocused) {
      _headTiltController.forward();
    } else if (!widget.isEmailFocused && oldWidget.isEmailFocused) {
      _headTiltController.reverse();
    }

    // Hands covering eyes
    if (widget.isPasswordFocused && !oldWidget.isPasswordFocused) {
      _handController.forward();
      _peekController.reverse();
      _headTiltController.reverse();
    } else if (!widget.isPasswordFocused && oldWidget.isPasswordFocused) {
      _handController.reverse();
      _peekController.reverse();
    }

    // Peek through fingers
    if (widget.isPasswordFocused) {
      if (widget.isShowingPassword && !oldWidget.isShowingPassword) {
        _peekController.forward();
      } else if (!widget.isShowingPassword && oldWidget.isShowingPassword) {
        _peekController.reverse();
      }
    }

    // Smooth eye tracking
    if (widget.emailTextProgress != oldWidget.emailTextProgress) {
      _currentEyeTarget = widget.emailTextProgress;
      _eyeTrackController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _handController.dispose();
    _peekController.dispose();
    _headTiltController.dispose();
    _eyeTrackController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _handAnim,
        _peekAnim,
        _headTiltAnim,
        _entranceAnim,
      ]),
      builder: (context, child) {
        final scale = 0.3 + (_entranceAnim.value * 0.7);
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _CharacterPainter(
                handProgress: _handAnim.value,
                peekProgress: _peekAnim.value,
                headTilt: _headTiltAnim.value,
                eyeTarget: _animatedEyeTarget,
                isPasswordMode: widget.isPasswordFocused,
                isEmailMode: widget.isEmailFocused,
                brightness: Theme.of(context).brightness,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CharacterPainter extends CustomPainter {
  final double handProgress;
  final double peekProgress;
  final double headTilt;
  final double eyeTarget;
  final bool isPasswordMode;
  final bool isEmailMode;
  final Brightness brightness;

  _CharacterPainter({
    required this.handProgress,
    required this.peekProgress,
    required this.headTilt,
    required this.eyeTarget,
    required this.isPasswordMode,
    required this.isEmailMode,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final isDark = brightness == Brightness.dark;

    // Colors
    final bgCircle = isDark ? const Color(0xFF1E293B) : const Color(0xFFE8EDF5);
    final bgBorder = isDark ? const Color(0xFF475569) : const Color(0xFFB0BEC5);
    final skin = isDark ? const Color(0xFFD4A574) : const Color(0xFFF0D0A0);
    final skinDark = isDark ? const Color(0xFFB8844A) : const Color(0xFFD4B07A);
    final hair = isDark ? const Color(0xFF1A1A2E) : const Color(0xFF3D2B1F);
    final eyeWhite = Colors.white;
    final iris = const Color(0xFF5B7553);
    final pupil = const Color(0xFF1A1A1A);
    final brow = isDark ? const Color(0xFF2A2A2A) : const Color(0xFF4A3728);
    final lip = const Color(0xFFCC6B6B);
    final shirt = isDark ? const Color(0xFF3B82F6) : const Color(0xFF5B6ABF);

    // Background circle
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = bgCircle);
    canvas.drawCircle(
      Offset(cx, cy),
      r - 1,
      Paint()
        ..color = bgBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r - 1)),
    );

    // Head tilt: slight downward shift when looking at email
    final tiltY = headTilt * r * 0.06;
    final faceCy = cy + r * 0.02 + tiltY;
    final faceRx = r * 0.58; // face width radius
    final faceRy = r * 0.66; // face height radius

    // --- Body/Shoulders ---
    final bodyTop = faceCy + faceRy * 0.75;
    final bodyPath = Path();
    bodyPath.moveTo(cx - r, cy + r);
    bodyPath.quadraticBezierTo(cx - r * 0.55, bodyTop, cx - r * 0.15, bodyTop);
    bodyPath.lineTo(cx + r * 0.15, bodyTop);
    bodyPath.quadraticBezierTo(cx + r * 0.55, bodyTop, cx + r, cy + r);
    bodyPath.close();
    canvas.drawPath(bodyPath, Paint()..color = shirt);

    // Collar V
    final collarP = Paint()
      ..color = isDark ? Colors.white12 : shirt.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - r * 0.12, bodyTop),
      Offset(cx, bodyTop + r * 0.15),
      collarP,
    );
    canvas.drawLine(
      Offset(cx + r * 0.12, bodyTop),
      Offset(cx, bodyTop + r * 0.15),
      collarP,
    );

    // --- Neck ---
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, bodyTop - r * 0.02),
        width: faceRx * 0.5,
        height: r * 0.12,
      ),
      Paint()..color = skin,
    );

    // --- Face ---
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, faceCy),
        width: faceRx * 2,
        height: faceRy * 2,
      ),
      Paint()..color = skin,
    );

    // Jaw shadow
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, faceCy),
        width: faceRx * 2,
        height: faceRy * 2,
      ),
      0.2, pi * 0.6,
      false,
      Paint()
        ..color = skinDark.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // --- Hair ---
    _drawHair(canvas, cx, faceCy, faceRx, faceRy, r, hair, isDark);

    // --- Eyes region ---
    final eyeY = faceCy - faceRy * 0.12 + tiltY * 0.3;
    final eyeSpacing = faceRx * 0.45;
    final eyeW = faceRx * 0.36;
    final eyeH = faceRy * 0.22;

    // Eye look direction (smooth)
    final lookX = (eyeTarget - 0.5) * eyeW * 0.55;
    final lookY = headTilt * eyeH * 0.25; // look down when tilted

    // --- Eyebrows ---
    final browLift = isPasswordMode ? handProgress * 4.0 : 0.0;
    final browW = faceRx * 0.22;
    for (final side in [-1.0, 1.0]) {
      final browCx = cx + eyeSpacing * side;
      final browPath = Path();
      browPath.moveTo(browCx - browW, eyeY - eyeH * 0.9 - browLift);
      browPath.quadraticBezierTo(
        browCx,
        eyeY - eyeH * 1.4 - browLift,
        browCx + browW,
        eyeY - eyeH * 0.95 - browLift,
      );
      canvas.drawPath(
        browPath,
        Paint()
          ..color = brow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round,
      );
    }

    // --- Eyes ---
    for (final side in [-1.0, 1.0]) {
      final eCx = cx + eyeSpacing * side;

      // Eye white (almond shape)
      final almondPath = Path();
      almondPath.moveTo(eCx - eyeW * 0.55, eyeY);
      almondPath.quadraticBezierTo(eCx, eyeY - eyeH * 0.6, eCx + eyeW * 0.55, eyeY);
      almondPath.quadraticBezierTo(eCx, eyeY + eyeH * 0.5, eCx - eyeW * 0.55, eyeY);
      almondPath.close();

      canvas.drawPath(almondPath, Paint()..color = eyeWhite);
      canvas.drawPath(
        almondPath,
        Paint()
          ..color = brow.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Iris
      final irisR = eyeH * 0.38;
      canvas.drawCircle(
        Offset(eCx + lookX, eyeY + lookY),
        irisR,
        Paint()..color = iris,
      );

      // Pupil
      canvas.drawCircle(
        Offset(eCx + lookX, eyeY + lookY),
        irisR * 0.5,
        Paint()..color = pupil,
      );

      // Eye highlight
      canvas.drawCircle(
        Offset(eCx + lookX - irisR * 0.28, eyeY + lookY - irisR * 0.28),
        irisR * 0.22,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );

      // Upper lid line
      final lidPath = Path();
      lidPath.moveTo(eCx - eyeW * 0.55, eyeY);
      lidPath.quadraticBezierTo(eCx, eyeY - eyeH * 0.6, eCx + eyeW * 0.55, eyeY);
      canvas.drawPath(
        lidPath,
        Paint()
          ..color = skinDark.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // --- Nose ---
    final noseY = faceCy + faceRy * 0.1 + tiltY * 0.3;
    final nosePath = Path();
    nosePath.moveTo(cx, eyeY + eyeH * 0.7);
    nosePath.quadraticBezierTo(
      cx - faceRx * 0.06, noseY + faceRy * 0.05,
      cx, noseY + faceRy * 0.1,
    );
    nosePath.quadraticBezierTo(
      cx + faceRx * 0.06, noseY + faceRy * 0.05,
      cx + faceRx * 0.01, noseY - faceRy * 0.01,
    );
    canvas.drawPath(
      nosePath,
      Paint()
        ..color = skinDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );

    // --- Mouth ---
    final mouthY = faceCy + faceRy * 0.38 + tiltY * 0.2;
    if (isPasswordMode && handProgress > 0.4) {
      // Worried "o" mouth
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, mouthY),
          width: faceRx * 0.12,
          height: faceRy * 0.1,
        ),
        Paint()..color = lip,
      );
    } else {
      // Gentle smile
      final smilePath = Path();
      smilePath.moveTo(cx - faceRx * 0.2, mouthY);
      smilePath.quadraticBezierTo(
        cx, mouthY + faceRy * 0.12,
        cx + faceRx * 0.2, mouthY,
      );
      canvas.drawPath(
        smilePath,
        Paint()
          ..color = lip
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // === HANDS ===
    if (handProgress > 0.01) {
      _drawHands(canvas, cx, faceCy, faceRx, faceRy, eyeY, eyeSpacing,
          eyeW, eyeH, r, skin, skinDark, eyeWhite, pupil, isDark);
    }

    canvas.restore();
  }

  void _drawHair(Canvas canvas, double cx, double faceCy, double faceRx,
      double faceRy, double r, Color hairColor, bool isDark) {
    final paint = Paint()..color = hairColor;

    final hairTop = faceCy - faceRy - r * 0.02;

    // Main hair shape
    final path = Path();
    path.moveTo(cx - faceRx * 1.15, faceCy - faceRy * 0.4);
    path.quadraticBezierTo(
      cx - faceRx * 1.2, hairTop - r * 0.05,
      cx - faceRx * 0.3, hairTop - r * 0.12,
    );
    path.quadraticBezierTo(
      cx, hairTop - r * 0.18,
      cx + faceRx * 0.3, hairTop - r * 0.12,
    );
    path.quadraticBezierTo(
      cx + faceRx * 1.2, hairTop - r * 0.05,
      cx + faceRx * 1.15, faceCy - faceRy * 0.4,
    );
    // Close through scalp area
    path.quadraticBezierTo(
      cx + faceRx * 0.9, faceCy - faceRy * 0.75,
      cx, faceCy - faceRy * 0.85,
    );
    path.quadraticBezierTo(
      cx - faceRx * 0.9, faceCy - faceRy * 0.75,
      cx - faceRx * 1.15, faceCy - faceRy * 0.4,
    );
    path.close();
    canvas.drawPath(path, paint);

    // Side hair (temples)
    for (final side in [-1.0, 1.0]) {
      final sidePath = Path();
      sidePath.moveTo(cx + faceRx * 1.0 * side, faceCy - faceRy * 0.55);
      sidePath.quadraticBezierTo(
        cx + faceRx * 1.15 * side, faceCy - faceRy * 0.2,
        cx + faceRx * 1.05 * side, faceCy - faceRy * 0.05,
      );
      sidePath.quadraticBezierTo(
        cx + faceRx * 1.1 * side, faceCy - faceRy * 0.35,
        cx + faceRx * 0.85 * side, faceCy - faceRy * 0.6,
      );
      sidePath.close();
      canvas.drawPath(sidePath, paint);
    }

    // Hair shine
    final shinePath = Path();
    shinePath.moveTo(cx + faceRx * 0.15, hairTop - r * 0.08);
    shinePath.quadraticBezierTo(
      cx + faceRx * 0.4, faceCy - faceRy * 0.75,
      cx + faceRx * 0.6, faceCy - faceRy * 0.6,
    );
    canvas.drawPath(
      shinePath,
      Paint()
        ..color = (isDark ? Colors.white12 : Colors.white30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawHands(
    Canvas canvas,
    double cx,
    double faceCy,
    double faceRx,
    double faceRy,
    double eyeY,
    double eyeSpacing,
    double eyeW,
    double eyeH,
    double r,
    Color skin,
    Color skinDark,
    Color eyeWhite,
    Color pupil,
    bool isDark,
  ) {
    final progress = handProgress;
    final peek = peekProgress;

    // Hand dimensions - larger and clearer
    final fingerLen = faceRy * 0.32;
    final fingerW = faceRx * 0.13;
    final palmH = faceRy * 0.22;
    final palmW = fingerW * 5.5;

    // Animation: hands come up from bottom to cover eyes
    final startY = faceCy + faceRy * 0.9;
    final endY = eyeY + eyeH * 0.1;
    final handY = startY + (endY - startY) * progress;

    final handPaint = Paint()..color = skin;
    final shadowPaint = Paint()..color = skinDark.withValues(alpha: 0.4);
    final knucklePaint = Paint()
      ..color = skinDark.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw both hands
    for (final side in [-1.0, 1.0]) {
      final handCx = cx + faceRx * 0.28 * side;

      // Palm (behind fingers)
      final palmRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(handCx, handY + fingerLen * 0.45),
          width: palmW,
          height: palmH,
        ),
        Radius.circular(palmH * 0.35),
      );
      canvas.drawRRect(palmRect, shadowPaint);
      canvas.drawRRect(palmRect, handPaint);

      // 4 Fingers
      for (int i = 0; i < 4; i++) {
        final baseX = handCx + (i - 1.5) * fingerW * 1.15;

        // Peek gap: between finger 1 and 2 (0-indexed)
        double gap = 0;
        if (peek > 0 && progress > 0.7) {
          if (i <= 1) {
            gap = -peek * fingerW * 0.7;
          } else {
            gap = peek * fingerW * 0.7;
          }
        }

        final fx = baseX + gap;

        // Finger length varies
        final lenMod = (i == 1 || i == 2) ? 1.0 : 0.82;
        final fl = fingerLen * lenMod;

        // Finger shape
        final fingerRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(fx, handY - fl * 0.38),
            width: fingerW * 0.9,
            height: fl,
          ),
          Radius.circular(fingerW * 0.42),
        );

        // Shadow
        canvas.drawRRect(
          fingerRect.shift(const Offset(1, 1)),
          shadowPaint,
        );
        // Finger
        canvas.drawRRect(fingerRect, handPaint);

        // Knuckle lines
        canvas.drawLine(
          Offset(fx - fingerW * 0.28, handY - fl * 0.08),
          Offset(fx + fingerW * 0.28, handY - fl * 0.08),
          knucklePaint,
        );
        canvas.drawLine(
          Offset(fx - fingerW * 0.22, handY + fl * 0.08),
          Offset(fx + fingerW * 0.22, handY + fl * 0.08),
          knucklePaint,
        );
      }

      // Thumb (on outer side)
      final thumbX = handCx + (palmW * 0.42) * side;
      canvas.save();
      canvas.translate(thumbX, handY + fingerLen * 0.12);
      canvas.rotate(side > 0 ? -0.35 : 0.35);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: fingerW * 0.85,
            height: fingerLen * 0.55,
          ),
          Radius.circular(fingerW * 0.4),
        ),
        handPaint,
      );
      canvas.restore();
    }

    // === PEEK: Eye visible through finger gap ===
    if (peek > 0.15 && progress > 0.7) {
      final peekAlpha = ((peek - 0.15) / 0.85).clamp(0.0, 1.0);

      for (final side in [-1.0, 1.0]) {
        final eCx = cx + eyeSpacing * side;
        final gapW = peek * fingerW * 1.2;
        final visibleW = gapW.clamp(0.0, eyeW * 0.6);
        final visibleH = eyeH * 0.55 * peekAlpha;

        if (visibleW > 3) {
          // Eye white peeking through gap
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(eCx, eyeY),
              width: visibleW,
              height: visibleH,
            ),
            Paint()..color = eyeWhite.withValues(alpha: peekAlpha),
          );

          // Pupil
          final pr = min(visibleW, visibleH) * 0.38;
          if (pr > 1.5) {
            canvas.drawCircle(
              Offset(eCx, eyeY),
              pr,
              Paint()..color = pupil.withValues(alpha: peekAlpha),
            );
            // Highlight
            canvas.drawCircle(
              Offset(eCx - pr * 0.3, eyeY - pr * 0.3),
              pr * 0.28,
              Paint()..color = Colors.white.withValues(alpha: peekAlpha * 0.9),
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_CharacterPainter oldDelegate) {
    return handProgress != oldDelegate.handProgress ||
        peekProgress != oldDelegate.peekProgress ||
        headTilt != oldDelegate.headTilt ||
        eyeTarget != oldDelegate.eyeTarget ||
        isPasswordMode != oldDelegate.isPasswordMode ||
        isEmailMode != oldDelegate.isEmailMode ||
        brightness != oldDelegate.brightness;
  }
}
