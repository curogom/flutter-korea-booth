import 'dart:math';

import 'package:flutter/material.dart';

const navy = Color(0xff08225e);
const blue = Color(0xff0878f9);
const muted = Color(0xff48638b);
const paleBlue = Color(0xfff0f7ff);
const lineBlue = Color(0xffd9e7f7);

enum DemoEmotion { neutral, happy, sad }

class DemoMascot extends StatefulWidget {
  const DemoMascot({
    super.key,
    this.emotion = DemoEmotion.neutral,
    this.width = 250,
  });
  final DemoEmotion emotion;
  final double width;
  @override
  State<DemoMascot> createState() => _DemoMascotState();
}

class _DemoMascotState extends State<DemoMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _float.stop();
    } else {
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = min(widget.width, constraints.maxWidth);
      return SizedBox(
        width: width,
        height: width * 42 / 41,
        child: AnimatedBuilder(
          animation: _float,
          builder: (context, child) => Transform.translate(
            offset: Offset(
              0,
              MediaQuery.disableAnimationsOf(context)
                  ? 0
                  : -6 * sin(_float.value * pi),
            ),
            child: child,
          ),
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 230),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: .94, end: 1).animate(animation),
                child: child,
              ),
            ),
            child: Icon(
              widget.emotion == DemoEmotion.happy
                  ? Icons.sentiment_very_satisfied_rounded
                  : widget.emotion == DemoEmotion.sad
                  ? Icons.sentiment_neutral_rounded
                  : Icons.emoji_objects_rounded,
              key: ValueKey(widget.emotion),
              size: width * .8,
              color: blue,
              semanticLabel: 'Demo quiz ${widget.emotion.name}',
            ),
          ),
        ),
      );
    },
  );
}

class BoothBackground extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width + 25, -5),
      110,
      Paint()..color = const Color(0xffa9d0ff),
    );
    canvas.drawCircle(
      Offset(-85, size.height + 35),
      135,
      Paint()..color = const Color(0xffd9ebff),
    );
    canvas.drawCircle(
      Offset(size.width * .79, 135),
      5,
      Paint()..color = const Color(0xff32c3e8),
    );
    canvas.drawCircle(
      Offset(size.width * .54, size.height - 50),
      9,
      Paint()..color = const Color(0xffbadbff),
    );
  }

  @override
  bool shouldRepaint(covariant BoothBackground oldDelegate) => false;
}

class Celebration extends StatefulWidget {
  const Celebration({super.key});
  @override
  State<Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<Celebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _Confetti(_controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Confetti extends CustomPainter {
  _Confetti(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(77);
    const colors = [blue, Color(0xff44c5ed), Color(0xff9dceff), navy];
    for (var i = 0; i < 45; i++) {
      final dx = (random.nextDouble() - .5) * size.width * .85;
      final dy = -180 + random.nextDouble() * 500;
      canvas.save();
      canvas.translate(
        size.width * .5 + dx * progress,
        size.height * .3 + dy * progress + 100 * progress * progress,
      );
      canvas.rotate(progress * (i % 2 == 0 ? 7 : -6));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, -6, 7, 13),
          const Radius.circular(2),
        ),
        Paint()
          ..color = colors[i % colors.length].withValues(alpha: 1 - progress),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _Confetti oldDelegate) =>
      oldDelegate.progress != progress;
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 20),
    iconAlignment: IconAlignment.end,
    label: Text(label),
    style: FilledButton.styleFrom(
      backgroundColor: blue,
      foregroundColor: Colors.white,
      minimumSize: const Size(150, 56),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(
        fontFamily: 'NotoSansKR',
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
