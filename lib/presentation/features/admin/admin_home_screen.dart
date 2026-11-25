import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/backend_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/kos_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kos_data_provider.dart';
import '../shared/listing_screens.dart';
import '../shared/profile_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<KosDataProvider>();
    final pending = data.listings.where((x) => x.status == 'pending').toList();
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Platform'),
          actions: [
            IconButton(
                tooltip: 'Profil saya',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen())),
                icon: const Icon(Icons.account_circle_outlined)),
            IconButton(
                tooltip: 'Peta lokasi kos',
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => KosMapScreen(listings: data.listings))),
                icon: const Icon(Icons.map_outlined)),
            IconButton(
                tooltip: 'Keluar',
                onPressed: () => context.read<AuthProvider>().signOut(),
                icon: const Icon(Icons.logout_rounded))
          ],
          bottom: const TabBar(isScrollable: true, tabs: [
            Tab(text: 'Ringkasan'),
            Tab(text: 'Kos'),
            Tab(text: 'Booking'),
            Tab(text: 'Akun'),
            Tab(text: 'Verifikasi'),
            Tab(text: 'Platform')
          ]),
        ),
        body: TabBarView(children: [
          _overview(context, data, pending),
          _listings(context, data),
          _activity(context, data),
          const _AdminUsersTab(),
          const _AdminVerificationsTab(),
          _platform(context)
        ]),
      ),
    );
  }

  Widget _overview(BuildContext context, KosDataProvider data,
          List<KosListing> pending) =>
      ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.teal, Color(0xFF24594F)]),
                borderRadius: BorderRadius.circular(24)),
            child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 34),
                  SizedBox(height: 15),
                  Text('Pusat pengelolaan kos',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20)),
                  SizedBox(height: 6),
                  Text('Admin mengelola listing dan platform Tinggal Klik Kos.',
                      style: TextStyle(color: Colors.white70)),
                ]),
          ),
          if (data.loadError != null) ...[
            const SizedBox(height: 12),
            Card(
                child: ListTile(
                    leading: const Icon(Icons.error_outline, color: Colors.red),
                    title: const Text('Koneksi data bermasalah'),
                    subtitle: Text(data.loadError!),
                    trailing: IconButton(
                        tooltip: 'Muat ulang data',
                        onPressed: data.load,
                        icon: const Icon(Icons.refresh_rounded)))),
          ],
          const SizedBox(height: 18),
          Row(children: [
            _stat('${data.listings.length}', 'Total kos',
                Icons.apartment_rounded),
            const SizedBox(width: 9),
            _stat('${pending.length}', 'Perlu review',
                Icons.pending_actions_rounded),
            const SizedBox(width: 9),
            _stat('${data.bookings.length}', 'Booking',
                Icons.calendar_month_rounded),
          ]),
          const SizedBox(height: 23),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Menunggu moderasi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('${pending.length} listing',
                style: const TextStyle(color: Color(0xFF5F6B73)))
          ]),
          const SizedBox(height: 9),
          if (pending.isEmpty)
            const Card(
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Tidak ada listing yang menunggu review.'))),
          ...pending.take(3).map((x) => _ListingCard(listing: x)),
          const SizedBox(height: 16),
          Card(
              child: ListTile(
                  leading: const Icon(Icons.receipt_long_outlined,
                      color: AppTheme.teal),
                  title: const Text('Tagihan'),
                  subtitle: Text(
                      '${data.invoices.where((x) => x.isPaid).length} lunas • ${data.invoices.where((x) => !x.isPaid).length} belum dibayar'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => DefaultTabController.of(context).animateTo(2))),
          Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                  data.isSupabaseMode
                      ? 'Data disinkronkan dari Supabase.'
                      : 'Koneksi Supabase belum aktif.',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF5F6B73)))),
        ],
      );

  Widget _listings(BuildContext context, KosDataProvider data) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Moderasi listing kos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text('${data.listings.length} total')
          ]),
          const SizedBox(height: 8),
          if (data.listings.isEmpty)
            const Card(
                child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('Belum ada listing pada Supabase.'))),
          const Text(
              'Data kos dibuat dan diperbarui dari aplikasi Mitra. Admin meninjau dan mengubah status publikasi di sini.'),
          const SizedBox(height: 10),
          ...data.listings.map((x) => _ListingCard(listing: x)),
        ],
      );

  Widget _activity(BuildContext context, KosDataProvider data) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Booking dan tagihan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text('Permintaan booking',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          if (data.bookings.isEmpty)
            const Card(
                child: ListTile(
                    leading: Icon(Icons.inbox_outlined),
                    title: Text('Belum ada booking masuk'))),
          ...data.bookings
              .map((booking) => _adminBookingCard(context, data, booking)),
          const SizedBox(height: 18),
          const Text('Tagihan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          if (data.invoices.isEmpty)
            const Card(
                child: ListTile(
                    leading: Icon(Icons.receipt_long_outlined),
                    title: Text('Belum ada tagihan'))),
          ...data.invoices.map((invoice) => Card(
                child: ListTile(
                  leading: Icon(
                      invoice.isPaid
                          ? Icons.check_circle_outline
                          : Icons.schedule_rounded,
                      color: invoice.isPaid ? AppTheme.teal : Colors.orange),
                  title: Text(invoice.listingName),
                  subtitle: Text(
                      'Rp${invoice.amount} • jatuh tempo ${invoice.dueAt.day}/${invoice.dueAt.month}/${invoice.dueAt.year}'),
                  trailing: Text(invoice.isPaid ? 'Lunas' : 'Belum lunas'),
                ),
              )),
        ],
      );

  Widget _adminBookingCard(
      BuildContext context, KosDataProvider data, KosBooking booking) {
    final listing = data.listing(booking.listingId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.person_outline_rounded, color: AppTheme.teal),
            const SizedBox(width: 8),
            Expanded(
                child: Text(booking.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w800))),
            _StatusBadge(booking.status),
          ]),
          const SizedBox(height: 6),
          Text(
              '${booking.kind == 'survey' ? 'Survei' : 'Booking'} • ${listing?.name ?? 'Kos tidak tersedia'}'),
          Text(
              'Mulai ${booking.moveIn.day}/${booking.moveIn.month}/${booking.moveIn.year}',
              style: const TextStyle(color: Color(0xFF5F6B73), fontSize: 12)),
          if (booking.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(booking.note,
                style: const TextStyle(color: Color(0xFF5F6B73), fontSize: 12)),
          ],
          if (booking.status == 'pending' || booking.status == 'accepted')
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(spacing: 6, children: [
                if (booking.status == 'pending')
                  TextButton(
                      onPressed: () => _changeBookingStatus(
                          context, data, booking.id, 'rejected'),
                      child: const Text('Tolak')),
                if (booking.status == 'pending')
                  FilledButton.tonal(
                      onPressed: () => _changeBookingStatus(
                          context, data, booking.id, 'accepted'),
                      child: const Text('Setujui')),
                if (booking.status == 'accepted')
                  TextButton(
                      onPressed: () => _changeBookingStatus(
                          context, data, booking.id, 'completed'),
                      child: const Text('Tandai selesai')),
              ]),
            ),
        ]),
      ),
    );
  }

  Future<void> _changeBookingStatus(BuildContext context, KosDataProvider data,
      String id, String status) async {
    try {
      await data.setBookingStatus(id, status);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status booking gagal diperbarui: $error')));
    }
  }

  Widget _platform(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Pengaturan platform',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
              'Panel operasional admin untuk memantau layanan, meninjau listing dari aplikasi Mitra, dan mengelola aktivitas pengguna. Data kos dibuat dan diperbarui oleh aplikasi Mitra pada database yang sama.',
              style: TextStyle(color: Color(0xFF5F6B73), height: 1.45)),
          const SizedBox(height: 16),
          Card(
              child: ListTile(
                  leading: const Icon(Icons.people_alt_outlined),
                  title: const Text('Pengguna dan mitra'),
                  subtitle: const Text('Lihat daftar akun pada database'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => DefaultTabController.of(context).animateTo(3))),
          const Card(
              child: ListTile(
                  leading: Icon(Icons.admin_panel_settings_outlined),
                  title: Text('Admin'),
                  subtitle: Text(
                      'Role istimewa yang hanya ditetapkan dari backend'))),
          Card(
              child: ListTile(
                  leading: const Icon(Icons.apartment_outlined),
                  title: const Text('Aplikasi Mitra'),
                  subtitle: const Text(
                      'Input dan perubahan data kos dilakukan di aplikasi Mitra'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => DefaultTabController.of(context).animateTo(1))),
          Card(
              child: ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: const Text('Backend bersama'),
                  subtitle: Text(BackendConfig.label))),
        ],
      );

  Widget _stat(String value, String label, IconData icon) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE9ECE7))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: AppTheme.teal, size: 19),
            const SizedBox(height: 10),
            Text(value,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFF5F6B73)))
          ]),
        ),
      );
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing});
  final KosListing listing;
  @override
  Widget build(BuildContext context) {
    final data = context.watch<KosDataProvider>();
    final color = listing.status == 'approved'
        ? AppTheme.teal
        : listing.status == 'rejected'
            ? Colors.redAccent
            : const Color(0xFFAF711C);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.home_work_outlined, color: AppTheme.teal),
            const SizedBox(width: 8),
            Expanded(
                child: Text(listing.name,
                    style: const TextStyle(fontWeight: FontWeight.w800))),
            Text(
                switch (listing.status) {
                  'approved' => 'Aktif',
                  'rejected' => 'Ditolak',
                  _ => 'Review'
                },
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 11))
          ]),
          const SizedBox(height: 7),
          Text('${listing.ownerName} • ${listing.address}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF5F6B73))),
          Text(
              'Rp${listing.price} / bulan • ${listing.gender} • ${listing.roomsAvailable} kamar kosong',
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            TextButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            KosDetailScreen(listing: listing, readOnly: true))),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Tinjau')),
            if (listing.status != 'approved')
              ElevatedButton(
                  onPressed: () => _review(context, data, true),
                  child: const Text('Setujui')),
            if (listing.status != 'rejected')
              TextButton(
                  onPressed: () => _review(context, data, false),
                  child: const Text('Tolak')),
          ]),
        ]),
      ),
    );
  }

  Future<void> _review(
      BuildContext context, KosDataProvider data, bool approve) async {
    try {
      await data.reviewListing(listing.id, approve);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status listing gagal diperbarui: $error')));
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'accepted' => AppTheme.teal,
      'rejected' || 'cancelled' => Colors.redAccent,
      'completed' => Colors.blueGrey,
      _ => const Color(0xFFAF711C),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(18)),
      child: Text(status == 'pending' ? 'Menunggu' : status,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _AdminUsersTab extends StatefulWidget {
  const _AdminUsersTab();

  @override
  State<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<_AdminUsersTab> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _profiles = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    if (BackendConfig.mode == BackendMode.local) {
      setState(() {
        _profiles = [
          {
            'id': 'admin-001',
            'display_name': 'Administrator',
            'role': 'admin',
            'owner_verified': false,
          },
          {
            'id': 'owner-001',
            'display_name': 'Pemilik Demo',
            'role': 'kos_owner',
            'owner_verified': true,
          },
          {
            'id': 'customer-001',
            'display_name': 'Pelanggan Demo',
            'role': 'customer',
            'owner_verified': false,
          },
        ];
        _loading = false;
      });
      return;
    }
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select('id,email,display_name,role,owner_verified,created_at')
          .order('display_name');
      if (!mounted) return;
      setState(() {
        _profiles = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error =
            'Akun gagal dimuat. Pastikan migrasi Supabase 003 dan role admin sudah aktif. $error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, size: 38),
          const SizedBox(height: 10),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi')),
        ]),
      ));
    }
    if (_profiles.isEmpty) {
      return RefreshIndicator(
          onRefresh: _load,
          child: ListView(children: const [
            SizedBox(height: 160),
            Icon(Icons.people_outline_rounded, size: 42),
            SizedBox(height: 12),
            Center(child: Text('Belum ada akun yang dapat ditampilkan.')),
          ]));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${_profiles.length} akun terdaftar',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final profile in _profiles)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE8F3EE),
                  child: Icon(
                    profile['role'] == 'kos_owner'
                        ? Icons.apartment_rounded
                        : profile['role'] == 'admin'
                            ? Icons.admin_panel_settings_rounded
                            : Icons.person_outline_rounded,
                    color: AppTheme.teal,
                  ),
                ),
                title:
                    Text((profile['display_name'] as String?) ?? 'Tanpa nama'),
                onTap: () => _showAccountDetails(context, profile),
                subtitle: Text([
                  (profile['role'] as String?) ?? 'Tidak diketahui',
                  if ((profile['email'] as String?)?.isNotEmpty == true)
                    profile['email'] as String,
                ].join(' • ')),
                trailing: profile['role'] == 'kos_owner'
                    ? Icon(
                        profile['owner_verified'] == true
                            ? Icons.verified_rounded
                            : Icons.pending_outlined,
                        color: profile['owner_verified'] == true
                            ? AppTheme.teal
                            : Colors.orange,
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  void _showAccountDetails(BuildContext context, Map<String, dynamic> profile) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text((profile['display_name'] as String?) ?? 'Tanpa nama',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            _accountInfo(
                'Email', profile['email'] as String? ?? 'Tidak tersedia'),
            _accountInfo(
                'Peran', profile['role'] as String? ?? 'Tidak diketahui'),
            _accountInfo('ID akun', profile['id'] as String? ?? '-'),
            _accountInfo(
                'Status Mitra',
                profile['role'] == 'kos_owner'
                    ? profile['owner_verified'] == true
                        ? 'Terverifikasi'
                        : 'Belum diverifikasi'
                    : 'Tidak berlaku'),
            _accountInfo('Terdaftar', profile['created_at'] as String? ?? '-'),
          ]),
        ),
      ),
    );
  }

  Widget _accountInfo(String label, String value) => ListTile(
        dense: true,
        title: Text(label),
        subtitle: SelectableText(value),
      );
}

class _AdminVerificationsTab extends StatefulWidget {
  const _AdminVerificationsTab();

  @override
  State<_AdminVerificationsTab> createState() => _AdminVerificationsTabState();
}

class _AdminVerificationsTabState extends State<_AdminVerificationsTab> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _queue = [];
  Map<String, Map<String, dynamic>> _profiles = {};
  StreamSubscription<List<Map<String, dynamic>>>? _verificationSubscription;

  @override
  void initState() {
    super.initState();
    _load();
    _verificationSubscription = Supabase.instance.client
        .from('owner_verifications')
        .stream(primaryKey: ['owner_id'])
        .listen((_) {
          if (mounted) unawaited(_load());
        }, onError: (Object _) {});
  }

  @override
  void dispose() {
    unawaited(_verificationSubscription?.cancel());
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = Supabase.instance.client;
      final rows = await client
          .from('owner_verifications')
          .select(
              'owner_id,legal_name,phone,bank_name,account_holder,account_number,ktp_object_path,selfie_object_path,submitted_at')
          .eq('status', 'submitted')
          .order('submitted_at');
      final queue = List<Map<String, dynamic>>.from(rows);
      final ids = queue.map((row) => row['owner_id'].toString()).toList();
      var profiles = <String, Map<String, dynamic>>{};
      if (ids.isNotEmpty) {
        final profileRows = await client
            .from('profiles')
            .select('id,display_name,email')
            .inFilter('id', ids);
        profiles = {
          for (final row in profileRows)
            row['id'].toString(): Map<String, dynamic>.from(row)
        };
      }
      if (!mounted) return;
      setState(() {
        _queue = queue;
        _profiles = profiles;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error =
            'Antrean verifikasi gagal dimuat. Pastikan migrasi 009 dan Storage bucket sudah aktif. $error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, size: 40),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi')),
        ]),
      ));
    }
    if (_queue.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(children: const [
          SizedBox(height: 170),
          Icon(Icons.verified_user_outlined, size: 46),
          SizedBox(height: 12),
          Center(child: Text('Belum ada pengajuan verifikasi Mitra.')),
          SizedBox(height: 6),
          Center(
              child: Text('Pengajuan muncul setelah data dan dokumen dikirim.',
                  textAlign: TextAlign.center)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${_queue.length} pengajuan menunggu tinjauan',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (final submission in _queue)
            Builder(builder: (context) {
              final id = submission['owner_id'].toString();
              final profile = _profiles[id] ?? const <String, dynamic>{};
              return Card(
                child: ListTile(
                  leading:
                      const CircleAvatar(child: Icon(Icons.apartment_rounded)),
                  title: Text((submission['legal_name'] as String?) ??
                      (profile['display_name'] as String? ?? 'Mitra')),
                  subtitle: Text([
                    (profile['email'] as String?) ?? 'Email tidak tersedia',
                    (submission['phone'] as String?) ??
                        'Telepon tidak tersedia',
                  ].join(' • ')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final reviewed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => _OwnerVerificationReviewScreen(
                                submission: submission, profile: profile)));
                    if (reviewed == true && mounted) await _load();
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _OwnerVerificationReviewScreen extends StatefulWidget {
  const _OwnerVerificationReviewScreen(
      {required this.submission, required this.profile});
  final Map<String, dynamic> submission;
  final Map<String, dynamic> profile;

  @override
  State<_OwnerVerificationReviewScreen> createState() =>
      _OwnerVerificationReviewScreenState();
}

class _OwnerVerificationReviewScreenState
    extends State<_OwnerVerificationReviewScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _ktpUrl;
  String? _selfieUrl;
  String? _error;

  String get _ownerId => widget.submission['owner_id'].toString();

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final storage =
          Supabase.instance.client.storage.from('owner-verification-docs');
      final ktp = await storage.createSignedUrl(
          widget.submission['ktp_object_path'] as String, 600);
      final selfie = await storage.createSignedUrl(
          widget.submission['selfie_object_path'] as String, 600);
      if (!mounted) return;
      setState(() {
        _ktpUrl = ktp;
        _selfieUrl = selfie;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Dokumen tidak dapat dibuka: $error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.submission['legal_name'] as String?) ??
        (widget.profile['display_name'] as String? ?? 'Mitra');
    return Scaffold(
      appBar: AppBar(title: const Text('Tinjau verifikasi Mitra')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _reviewInfo('Email', widget.profile['email'] as String? ?? '—'),
        _reviewInfo('Telepon', widget.submission['phone'] as String? ?? '—'),
        _reviewInfo('Nama pemilik rekening',
            widget.submission['account_holder'] as String? ?? '—'),
        _reviewInfo('Bank', widget.submission['bank_name'] as String? ?? '—'),
        _reviewInfo('Nomor rekening',
            widget.submission['account_number'] as String? ?? '—'),
        _reviewInfo('ID Mitra', _ownerId),
        const SizedBox(height: 10),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(14), child: Text(_error!)))
        else ...[
          _documentCard('KTP', _ktpUrl!),
          _documentCard('Foto selfie', _selfieUrl!),
        ],
        if (_saving) const LinearProgressIndicator(),
        const SizedBox(height: 12),
        FilledButton.icon(
            onPressed: _saving || _loading || _error != null
                ? null
                : () => _review(approved: true),
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('Setujui dan aktifkan Mitra')),
        OutlinedButton.icon(
            onPressed: _saving || _loading || _error != null ? null : _reject,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Tolak dan minta perbaikan')),
      ]),
    );
  }

  Widget _reviewInfo(String label, String value) => ListTile(
        dense: true,
        title: Text(label),
        subtitle: SelectableText(value),
      );

  Widget _documentCard(String title, String url) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.all(12),
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w800))),
          InkWell(
            onTap: () => showDialog<void>(
                context: context,
                builder: (context) => Dialog.fullscreen(
                      child: Stack(children: [
                        Center(
                            child: InteractiveViewer(
                                child:
                                    Image.network(url, fit: BoxFit.contain))),
                        Positioned(
                            top: 12,
                            right: 12,
                            child: IconButton.filledTonal(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close))),
                      ]),
                    )),
            child: SizedBox(
                height: 230,
                width: double.infinity,
                child: Image.network(url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                        child: Text('Gambar dokumen gagal dimuat')))),
          ),
        ]),
      );

  Future<void> _reject() async {
    final note = TextEditingController();
    final reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Alasan penolakan'),
              content: TextField(
                  controller: note,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      hintText: 'Contoh: foto KTP kurang jelas')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Batal')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, note.text),
                    child: const Text('Tolak')),
              ],
            ));
    note.dispose();
    if (reason == null || reason.trim().isEmpty || !mounted) return;
    await _review(approved: false, note: reason.trim());
  }

  Future<void> _review({required bool approved, String? note}) async {
    setState(() => _saving = true);
    try {
      await Supabase.instance.client
          .rpc('admin_review_owner_verification', params: {
        'p_owner_id': _ownerId,
        'p_approved': approved,
        'p_note': note,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approved
              ? 'Mitra disetujui dan dapat mengaktifkan listing.'
              : 'Pengajuan ditolak. Mitra harus memperbaiki data.')));
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Keputusan verifikasi gagal disimpan: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
