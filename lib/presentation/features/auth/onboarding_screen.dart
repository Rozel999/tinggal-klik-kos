import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 42),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BrandHeader(),
                    const SizedBox(height: 24),
                    _WelcomeHero(
                        height: constraints.maxHeight < 700 ? 290 : 330),
                    const SizedBox(height: 26),
                    Text('Temukan kos yang pas\nuntuk langkah barumu',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w800,
                              height: 1.12,
                              letterSpacing: -.6,
                            )),
                    const SizedBox(height: 10),
                    const Text(
                      'Bandingkan harga, alamat, dan fasilitas kos di Padang. Lihat titik lokasinya langsung di peta.',
                      style: TextStyle(
                          color: Color(0xFF687572), fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    const Row(children: [
                      _Benefit(
                          icon: Icons.map_outlined, text: 'Peta lokasi nyata'),
                      SizedBox(width: 14),
                      _Benefit(
                          icon: Icons.verified_user_outlined,
                          text: 'Info dari pemilik'),
                    ]),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.go('/login'),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Masuk dan cari kos'),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/register'),
                        child: const Text('Belum punya akun? Daftar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
              color: AppTheme.teal, borderRadius: BorderRadius.circular(15)),
          child: const Icon(Icons.home_work_rounded,
              color: Colors.white, size: 25),
        ),
        const SizedBox(width: 11),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tinggal Klik Kos',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink)),
          SizedBox(height: 2),
          Text('Pencarian kos di Padang',
              style: TextStyle(fontSize: 12, color: Color(0xFF687572))),
        ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
              color: const Color(0xFFEAF3EF),
              borderRadius: BorderRadius.circular(20)),
          child: const Row(children: [
            Icon(Icons.location_on_rounded, size: 14, color: AppTheme.teal),
            SizedBox(width: 4),
            Text('PADANG',
                style: TextStyle(
                    color: AppTheme.teal,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5)),
          ]),
        ),
      ]);
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF0A766C), Color(0xFF174E4A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(children: [
          const Positioned(right: -40, top: -48, child: _Glow(size: 210)),
          const Positioned(left: -34, bottom: -90, child: _Glow(size: 230)),
          Positioned(
              right: 27,
              top: 48,
              child: Icon(Icons.location_city_rounded,
                  size: height * .68,
                  color: Colors.white.withValues(alpha: .13))),
          const Positioned(
              left: 20,
              top: 22,
              child: _HeroChip(
                  icon: Icons.map_outlined, label: 'Peta interaktif')),
          Positioned(
              left: 23,
              bottom: 25,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(25)),
                      child: const Icon(Icons.home_work_rounded,
                          size: 42, color: Colors.white),
                    ),
                    const SizedBox(height: 14),
                    const Text('Cari tempat\nuntuk merasa di rumah.',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            height: 1.14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.3)),
                  ])),
          const Positioned(
              right: 16,
              top: 105,
              child: _HeroChip(
                  icon: Icons.place_rounded, label: 'Pin lokasi kos')),
          Positioned(
              right: 17,
              bottom: 27,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppTheme.orange,
                    borderRadius: BorderRadius.circular(17)),
                child: const Icon(Icons.search_rounded,
                    color: AppTheme.ink, size: 25),
              )),
        ]),
      );
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: Colors.white.withValues(alpha: .06)),
      );
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: AppTheme.teal),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ]),
      );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Expanded(
          child: Row(children: [
        Icon(icon, size: 17, color: AppTheme.teal),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink))),
      ]));
}
