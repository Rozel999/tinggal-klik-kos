import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/app_user.dart';
import '../../providers/auth_provider.dart';

class SplashIntroScreen extends StatefulWidget {
  const SplashIntroScreen({super.key});

  @override
  State<SplashIntroScreen> createState() => _SplashIntroScreenState();
}

class _SplashIntroScreenState extends State<SplashIntroScreen>
    with TickerProviderStateMixin {
  static const _mint = Color(0xFF7EE2B8);
  static const _ink = Color(0xFF0F1412);
  late final AnimationController _intro = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..forward();
  late final AnimationController _glow = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat(reverse: true);
  late final AnimationController _ring = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1900))
    ..repeat();
  late final AnimationController _progress = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2800))
    ..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2900), _continue);
  }

  void _continue() {
    if (!mounted) return;
    final user = context.read<AuthProvider>().user;
    context.go(user == null ? '/onboarding' : user.role.route);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    _glow.dispose();
    _ring.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final logoSize = (width * .27).clamp(92.0, 112.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
                decoration: BoxDecoration(
                    gradient: RadialGradient(
                        center: Alignment(0, -.42),
                        radius: 1.1,
                        colors: [Color(0xFF1E3A34), _ink],
                        stops: [0, .76]))),
            Positioned(
              top: height * .17,
              left: (width - logoSize * 2.7) / 2,
              child: AnimatedBuilder(
                animation: _glow,
                builder: (context, child) => Opacity(
                  opacity: .28 + _glow.value * .34,
                  child: Transform.scale(
                      scale: .82 + _glow.value * .32, child: child),
                ),
                child: Container(
                    width: logoSize * 2.7,
                    height: logoSize * 2.7,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          Color(0x997EE2B8),
                          Color(0x007EE2B8),
                        ]))),
              ),
            ),
            Positioned(
              top: height * .29,
              left: (width - logoSize * 1.35) / 2,
              child: AnimatedBuilder(
                animation: _ring,
                builder: (context, _) {
                  final scale = .65 + _ring.value * .9;
                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: (1 - _ring.value) * .55,
                      child: Container(
                        width: logoSize * 1.35,
                        height: logoSize * 1.35,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _mint, width: 1.5),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: height * .305,
              left: (width - logoSize) / 2,
              child: ScaleTransition(
                scale:
                    CurvedAnimation(parent: _intro, curve: Curves.elasticOut),
                child: Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    color: _mint,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x557EE2B8),
                          blurRadius: 36,
                          offset: Offset(0, 12)),
                    ],
                  ),
                  child: Stack(alignment: Alignment.center, children: [
                    const Icon(Icons.home_rounded, color: _ink, size: 58),
                    Positioned(
                      right: 17,
                      top: 17,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                            color: _mint, shape: BoxShape.circle),
                        child: const Icon(Icons.location_on_rounded,
                            color: _ink, size: 23),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            Positioned(
              top: height * .49,
              left: 16,
              right: 16,
              child: FadeTransition(
                opacity: CurvedAnimation(
                    parent: _intro,
                    curve: const Interval(.35, 1, curve: Curves.easeOut)),
                child: Column(children: [
                  const Text('Tinggal Klik Kos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color(0xFFF2F5F3),
                          fontSize: 32,
                          letterSpacing: -.8,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('Kos nyaman di Kota Padang',
                      style: TextStyle(
                          color: Color(0xFF9AA7A1),
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 120,
                    child: AnimatedBuilder(
                        animation: _progress,
                        builder: (context, _) => ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _progress.value,
                                minHeight: 4,
                                backgroundColor: const Color(0xFF26322D),
                                color: _mint,
                              ),
                            )),
                  ),
                ]),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: height * .22,
              child: _PadangSkyline(animation: _intro),
            ),
          ],
        );
      }),
    );
  }
}

class _PadangSkyline extends StatelessWidget {
  const _PadangSkyline({required this.animation});
  final Animation<double> animation;

  static const _buildings = <(double, double, Color)>[
    (64, 108, Color(0xFF1B332D)),
    (52, 148, Color(0xFF223F37)),
    (70, 94, Color(0xFF1B332D)),
    (60, 128, Color(0xFF29483F)),
    (52, 85, Color(0xFF1B332D)),
    (70, 142, Color(0xFF223F37)),
    (56, 103, Color(0xFF29483F)),
    (66, 126, Color(0xFF1B332D)),
  ];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: animation,
        builder: (context, _) => Align(
          alignment: Alignment.bottomCenter,
          child: FractionalTranslation(
            translation: Offset(0, 1 - animation.value),
            child: SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < _buildings.length; i++)
                    Expanded(
                      child: Container(
                        height: _buildings[i].$2,
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                          color: _buildings[i].$3,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(9)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 13, 8, 0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 11,
                            children: List.generate(
                                ((_buildings[i].$2 - 18) / 22).floor() * 2,
                                (window) => Container(
                                      width: 6,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5D88A)
                                            .withValues(
                                                alpha: .45 +
                                                    ((window + i) % 3) * .2),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    )),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}
