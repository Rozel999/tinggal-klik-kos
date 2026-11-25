import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'profile_screen.dart';

class RoleHomeShell extends StatelessWidget {
  const RoleHomeShell(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.accent,
      required this.features,
      super.key});
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isAdmin = user?.role == UserRole.admin;
    final stats = isAdmin
        ? const [
            ('1.248', 'Pengguna', Icons.people_alt_rounded),
            ('86', 'Listing aktif', Icons.apartment_rounded),
            ('7', 'Perlu ditinjau', Icons.pending_actions_rounded)
          ]
        : const [
            ('4', 'Properti', Icons.apartment_rounded),
            ('82%', 'Okupansi', Icons.bed_rounded),
            ('12,8 jt', 'Pendapatan', Icons.payments_rounded)
          ];
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: AppTheme.teal,
                  borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.home_work_rounded,
                  color: Colors.white, size: 19)),
          const SizedBox(width: 9),
          const Text('Tinggal Klik Kos',
              style: TextStyle(fontWeight: FontWeight.w800))
        ]),
        actions: [
          IconButton(
              tooltip: 'Profil saya',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
              icon: const Icon(Icons.account_circle_outlined)),
          IconButton(
              tooltip: 'Keluar',
              onPressed: () async => context.read<AuthProvider>().signOut(),
              icon: const Icon(Icons.logout_rounded)),
          const SizedBox(width: 8)
        ],
      ),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            Text('Halo, ${user?.name ?? 'Pengguna'} 👋',
                style: const TextStyle(color: Color(0xFF5F6B73), fontSize: 14)),
            const SizedBox(height: 5),
            Text(title,
                style: const TextStyle(
                    fontSize: 24,
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [accent, accent.withValues(alpha: .78)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(25)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(icon, color: Colors.white, size: 32),
                        const Spacer(),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .17),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(
                                user?.role.label.toUpperCase() ?? 'DEMO',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: .7)))
                      ]),
                      const SizedBox(height: 17),
                      Text(subtitle,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              height: 1.35,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      const Row(children: [
                        Icon(Icons.location_on_outlined,
                            color: Colors.white70, size: 16),
                        SizedBox(width: 4),
                        Text('Padang, Sumatera Barat',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12))
                      ]),
                    ])),
            const SizedBox(height: 22),
            const Text('Ringkasan',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 11),
            Row(
                children: stats
                    .map((stat) => Expanded(
                        child: Container(
                            margin: EdgeInsets.only(
                                right: stat == stats.last ? 0 : 9),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(19),
                                border:
                                    Border.all(color: const Color(0xFFE9ECE7))),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(stat.$3, color: accent, size: 19),
                                  const SizedBox(height: 12),
                                  Text(stat.$1,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17)),
                                  const SizedBox(height: 3),
                                  Text(stat.$2,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF5F6B73)))
                                ]))))
                    .toList()),
            const SizedBox(height: 24),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text('Kelola layanan',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
            const SizedBox(height: 6),
            GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: features.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.35),
                itemBuilder: (context, index) {
                  final feature = features[index];
                  return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: const Color(0xFFE9ECE7))),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                        color: accent.withValues(alpha: .10),
                                        borderRadius:
                                            BorderRadius.circular(13)),
                                    child: Icon(_iconFor(feature),
                                        color: accent, size: 20)),
                                Text(feature,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12)),
                              ])));
                }),
            const SizedBox(height: 16),
          ]),
    );
  }

  IconData _iconFor(String value) {
    final v = value.toLowerCase();
    if (v.contains('kos') || v.contains('properti') || v.contains('listing')) {
      return Icons.apartment_rounded;
    }
    if (v.contains('booking')) return Icons.calendar_month_rounded;
    if (v.contains('tagihan') ||
        v.contains('transaksi') ||
        v.contains('pembayaran')) {
      return Icons.receipt_long_rounded;
    }
    if (v.contains('pengguna') || v.contains('penghuni')) {
      return Icons.people_alt_rounded;
    }
    if (v.contains('verifikasi')) return Icons.verified_user_rounded;
    if (v.contains('laporan') || v.contains('grafik')) {
      return Icons.bar_chart_rounded;
    }
    if (v.contains('keluhan')) return Icons.support_agent_rounded;
    if (v.contains('favorit')) return Icons.favorite_rounded;
    if (v.contains('kamar')) return Icons.bed_rounded;
    return Icons.dashboard_rounded;
  }
}
