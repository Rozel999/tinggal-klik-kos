import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/kos_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kos_data_provider.dart';
import '../shared/listing_screens.dart';
import 'admin_listing_editor.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<KosDataProvider>();
    final pending = data.listings.where((x) => x.status == 'pending').toList();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _editListing(context),
          icon: const Icon(Icons.add),
          label: const Text('Tambah kos'),
        ),
        appBar: AppBar(
          title: const Text('Admin Platform'),
          actions: [
            IconButton(
                tooltip: 'Keluar',
                onPressed: () => context.read<AuthProvider>().signOut(),
                icon: const Icon(Icons.logout_rounded))
          ],
          bottom: const TabBar(tabs: [
            Tab(text: 'Ringkasan'),
            Tab(text: 'Kos'),
            Tab(text: 'Platform')
          ]),
        ),
        body: TabBarView(children: [
          _overview(context, data, pending),
          _listings(context, data),
          _platform()
        ]),
      ),
    );
  }

  Future<void> _editListing(BuildContext context, {KosListing? listing}) async {
    await Navigator.push<void>(
        context,
        MaterialPageRoute(
            builder: (_) => AdminListingEditor(listing: listing)));
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
                  Text('Admin mengelola listing dan platform Pencari Kos.',
                      style: TextStyle(color: Colors.white70)),
                ]),
          ),
          if (data.loadError != null) ...[
            const SizedBox(height: 12),
            Card(
                child: ListTile(
                    leading: const Icon(Icons.error_outline, color: Colors.red),
                    title: const Text('Koneksi data bermasalah'),
                    subtitle: Text(data.loadError!))),
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
                style: const TextStyle(color: Color(0xFF78837F)))
          ]),
          const SizedBox(height: 9),
          if (pending.isEmpty)
            const Card(
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Tidak ada listing yang menunggu review.'))),
          ...pending.take(3).map((x) => _ListingCard(
              listing: x, onEdit: () => _editListing(context, listing: x))),
          const SizedBox(height: 16),
          Card(
              child: ListTile(
                  leading: const Icon(Icons.receipt_long_outlined,
                      color: AppTheme.teal),
                  title: const Text('Tagihan'),
                  subtitle: Text(
                      '${data.invoices.where((x) => x.isPaid).length} lunas • ${data.invoices.where((x) => !x.isPaid).length} belum dibayar'))),
          Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                  data.isSupabaseMode
                      ? 'Data disinkronkan dari Supabase.'
                      : 'Mode lokal menampilkan data demo.',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF78837F)))),
        ],
      );

  Widget _listings(BuildContext context, KosDataProvider data) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Kelola listing kos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text('${data.listings.length} total')
          ]),
          const SizedBox(height: 8),
          if (data.listings.isEmpty)
            const Card(
                child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('Belum ada listing pada Supabase.'))),
          ...data.listings.map((x) => _ListingCard(
              listing: x, onEdit: () => _editListing(context, listing: x))),
        ],
      );

  Widget _platform() => ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('Pengaturan platform',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text(
              'Dashboard pemilik aplikasi digabung ke role Admin. Admin mengelola data dan moderasi kos dari aplikasi Pencari Kos.',
              style: TextStyle(color: Color(0xFF687572), height: 1.45)),
          SizedBox(height: 16),
          Card(
              child: ListTile(
                  leading: Icon(Icons.people_alt_outlined),
                  title: Text('Pengguna'),
                  subtitle: Text('Role customer pada database'))),
          Card(
              child: ListTile(
                  leading: Icon(Icons.admin_panel_settings_outlined),
                  title: Text('Admin'),
                  subtitle: Text(
                      'Role istimewa yang hanya ditetapkan dari backend'))),
          Card(
              child: ListTile(
                  leading: Icon(Icons.apartment_outlined),
                  title: Text('Mitra Pemilik Kos'),
                  subtitle: Text('Role kos_owner pada aplikasi Mitra Kos'))),
          Card(
              child: ListTile(
                  leading: Icon(Icons.storage_outlined),
                  title: Text('Backend bersama'),
                  subtitle: Text(
                      'Supabase Auth, PostgreSQL, REST API, dan Realtime'))),
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
                style: const TextStyle(fontSize: 10, color: Color(0xFF78837F)))
          ]),
        ),
      );
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing, required this.onEdit});
  final KosListing listing;
  final VoidCallback onEdit;
  Future<void> _confirmDelete(
      BuildContext context, KosDataProvider data) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Hapus listing?'),
              content: Text('Listing "${listing.name}" akan dihapus permanen.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Batal')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Hapus')),
              ],
            ));
    if (confirmed != true || !context.mounted) return;
    try {
      await data.deleteListing(listing.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing berhasil dihapus.')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing gagal dihapus. Coba lagi.')));
    }
  }

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
              style: const TextStyle(fontSize: 12, color: Color(0xFF687572))),
          Text(
              'Rp${listing.price} / bulan • ${listing.gender} • ${listing.roomsAvailable} kamar kosong',
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            TextButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => KosDetailScreen(listing: listing))),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Tinjau')),
            TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Ubah')),
            if (listing.status != 'approved')
              ElevatedButton(
                  onPressed: () => data.reviewListing(listing.id, true),
                  child: const Text('Setujui')),
            if (listing.status != 'rejected')
              TextButton(
                  onPressed: () => data.reviewListing(listing.id, false),
                  child: const Text('Tolak')),
            TextButton(
                onPressed: () => _confirmDelete(context, data),
                child: const Text('Hapus')),
          ]),
        ]),
      ),
    );
  }
}
