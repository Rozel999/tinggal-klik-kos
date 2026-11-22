import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/kos_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kos_data_provider.dart';
import '../shared/transaction_screens.dart';
import '../shared/listing_screens.dart';

class OwnerHomeScreen extends StatelessWidget {
  const OwnerHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final data = context.watch<KosDataProvider>();
    final ownerId = user?.id ?? 'owner-001';
    final listings = data.ownerListings(ownerId);
    final ownerBookings = data.ownerBookings(ownerId);
    final pendingBookings =
        ownerBookings.where((x) => x.status == 'pending').toList();
    final requests = pendingBookings.length;
    final totalRooms =
        listings.fold<int>(0, (sum, item) => sum + item.roomsTotal);
    final availableRooms =
        listings.fold<int>(0, (sum, item) => sum + item.roomsAvailable);
    final occupiedRooms = totalRooms - availableRooms;
    final occupancy =
        totalRooms == 0 ? 0 : (occupiedRooms * 100 / totalRooms).round();
    final monthlyIncome = listings.fold<int>(
        0,
        (sum, item) =>
            sum + (item.roomsTotal - item.roomsAvailable) * item.price);
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Pemilik'), actions: [
        IconButton(
            tooltip: 'Booking masuk',
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => OwnerBookingsScreen(ownerId: ownerId))),
            icon: Badge(
                isLabelVisible: requests > 0,
                label: Text('$requests'),
                child: const Icon(Icons.inbox_outlined))),
        IconButton(
            tooltip: 'Keluar',
            onPressed: () => context.read<AuthProvider>().signOut(),
            icon: const Icon(Icons.logout_rounded))
      ]),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _edit(context, ownerId, user?.name ?? 'Pemilik Kos'),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tambah kos')),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppTheme.teal, Color(0xFF24594F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Halo, ${user?.name ?? 'Pemilik kos'}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                        '${listings.length} properti • $requests permintaan baru',
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 15),
                    Row(children: [
                      Expanded(
                          child: _metric('$occupiedRooms/$totalRooms',
                              'Kamar terisi • $occupancy%')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _metric(
                              monthlyIncome >= 1000000
                                  ? 'Rp${(monthlyIncome / 1000000).toStringAsFixed(1)} jt'
                                  : 'Rp${(monthlyIncome / 1000).round()} rb',
                              'Potensi sewa / bulan'))
                    ]),
                  ]),
            ),
            const SizedBox(height: 22),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Permintaan booking',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              TextButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              OwnerBookingsScreen(ownerId: ownerId))),
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: const Text('Booking'))
            ]),
            if (pendingBookings.isEmpty)
              const Card(
                  child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('Belum ada permintaan booking baru.'))),
            ...pendingBookings.take(3).map((booking) {
              final listing = data.listing(booking.listingId);
              return Card(
                  child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE8F1EC),
                    child: Text(
                        booking.customerName.isEmpty
                            ? 'P'
                            : booking.customerName
                                .substring(0, 1)
                                .toUpperCase(),
                        style: const TextStyle(color: AppTheme.teal))),
                title: Text(booking.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    '${listing?.name ?? 'Kos'} • mulai ${booking.moveIn.day}/${booking.moveIn.month}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => OwnerBookingsScreen(ownerId: ownerId))),
              ));
            }),
            const SizedBox(height: 9),
            const Text('Properti saya',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            if (listings.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(25),
                  child:
                      Text('Belum ada properti. Tambahkan kos pertama Anda.')),
            ...listings.map((x) => _ListingCard(
                listing: x,
                onEdit: () => _edit(
                    context, ownerId, user?.name ?? 'Pemilik Kos', existing: x),
                onDelete: () => _delete(context, x),
                onRooms: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => RoomManagementScreen(listing: x))))),
          ]),
    );
  }

  Widget _metric(String number, String label) => Expanded(
      child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(15)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(number,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11))
          ])));

  Future<void> _edit(BuildContext context, String ownerId, String ownerName,
      {KosListing? existing}) async {
    final key = GlobalKey<FormState>();
    final name = TextEditingController(text: existing?.name ?? '');
    final address = TextEditingController(text: existing?.address ?? '');
    final description =
        TextEditingController(text: existing?.description ?? '');
    final price =
        TextEditingController(text: existing?.price.toString() ?? '850000');
    final total =
        TextEditingController(text: existing?.roomsTotal.toString() ?? '5');
    final available =
        TextEditingController(text: existing?.roomsAvailable.toString() ?? '5');
    var gender = existing?.gender ?? 'Campur';
    LatLng? selectedLocation =
        existing == null ? null : LatLng(existing.latitude, existing.longitude);
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialog) => AlertDialog(
                  title: Text(
                      existing == null ? 'Tambah properti' : 'Ubah properti'),
                  content: SizedBox(
                      width: 440,
                      child: SingleChildScrollView(
                          child: Form(
                              key: key,
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextFormField(
                                        controller: name,
                                        decoration: const InputDecoration(
                                            labelText: 'Nama kos'),
                                        validator: (v) =>
                                            v == null || v.trim().length < 3
                                                ? 'Nama minimal 3 karakter.'
                                                : null),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                        controller: address,
                                        decoration: const InputDecoration(
                                            labelText: 'Alamat / area'),
                                        validator: (v) =>
                                            v == null || v.trim().isEmpty
                                                ? 'Alamat wajib diisi.'
                                                : null),
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final point = await Navigator.push<
                                                LatLng>(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    KosLocationPickerScreen(
                                                        initialPoint:
                                                            selectedLocation)));
                                        if (point != null) {
                                          setDialog(
                                              () => selectedLocation = point);
                                        }
                                      },
                                      icon: const Icon(Icons.map_outlined),
                                      label: Text(selectedLocation == null
                                          ? 'Pilih titik lokasi di peta'
                                          : 'Lokasi: ${selectedLocation!.latitude.toStringAsFixed(5)}, ${selectedLocation!.longitude.toStringAsFixed(5)}'),
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                        controller: description,
                                        maxLines: 2,
                                        decoration: const InputDecoration(
                                            labelText: 'Deskripsi'),
                                        validator: (v) => v == null ||
                                                v.trim().length < 10
                                            ? 'Deskripsi minimal 10 karakter.'
                                            : null),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                        controller: price,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                            labelText: 'Harga per bulan (Rp)'),
                                        validator: (v) =>
                                            int.tryParse(v ?? '') == null ||
                                                    int.parse(v!) < 100000
                                                ? 'Harga minimal Rp100.000.'
                                                : null),
                                    const SizedBox(height: 10),
                                    DropdownButtonFormField<String>(
                                        initialValue: gender,
                                        decoration: const InputDecoration(
                                            labelText: 'Tipe penghuni'),
                                        items: const [
                                          'Putra',
                                          'Putri',
                                          'Campur'
                                        ]
                                            .map((x) => DropdownMenuItem(
                                                value: x, child: Text(x)))
                                            .toList(),
                                        onChanged: (x) => setDialog(
                                            () => gender = x ?? 'Campur')),
                                    const SizedBox(height: 10),
                                    Row(children: [
                                      Expanded(
                                          child: TextFormField(
                                              controller: total,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                  labelText: 'Total kamar'),
                                              validator: (v) =>
                                                  int.tryParse(v ?? '') == null
                                                      ? 'Angka tidak valid.'
                                                      : null)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: TextFormField(
                                              controller: available,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                  labelText: 'Kamar kosong'),
                                              validator: (v) {
                                                final a = int.tryParse(v ?? '');
                                                final t =
                                                    int.tryParse(total.text);
                                                return a == null ||
                                                        t == null ||
                                                        a > t ||
                                                        a < 0
                                                    ? 'Periksa jumlah kamar.'
                                                    : null;
                                              }))
                                    ]),
                                  ])))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Batal')),
                    ElevatedButton(
                        onPressed: () async {
                          if (!key.currentState!.validate()) return;
                          if (selectedLocation == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Pilih titik lokasi kos di peta terlebih dahulu.')));
                            return;
                          }
                          final item = KosListing(
                              id: existing?.id ?? newUuidV4(),
                              ownerId: ownerId,
                              ownerName: ownerName,
                              name: name.text.trim(),
                              address: address.text.trim(),
                              description: description.text.trim(),
                              price: int.parse(price.text),
                              gender: gender,
                              roomsTotal: int.parse(total.text),
                              roomsAvailable: int.parse(available.text),
                              amenities: existing?.amenities ?? const [],
                              status: 'pending',
                              latitude: selectedLocation!.latitude,
                              longitude: selectedLocation!.longitude);
                          await context
                              .read<KosDataProvider>()
                              .saveListing(item);
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                        child: Text(existing == null
                            ? 'Ajukan listing'
                            : 'Simpan & review'))
                  ],
                )));
    name.dispose();
    address.dispose();
    description.dispose();
    price.dispose();
    total.dispose();
    available.dispose();
  }

  Future<void> _delete(BuildContext context, KosListing listing) async {
    final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Hapus properti?'),
                content: Text('${listing.name} akan dihapus dari demo lokal.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Batal')),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Hapus'))
                ]));
    if (yes == true && context.mounted) {
      context.read<KosDataProvider>().deleteListing(listing.id);
    }
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard(
      {required this.listing,
      required this.onEdit,
      required this.onDelete,
      required this.onRooms});
  final KosListing listing;
  final VoidCallback onEdit, onDelete, onRooms;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(15),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const CircleAvatar(
                  backgroundColor: Color(0xFFEAF3EF),
                  child: Icon(Icons.apartment_rounded, color: AppTheme.teal)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(listing.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15))),
              _StateChip(listing.status)
            ]),
            const SizedBox(height: 10),
            Text(listing.address,
                style: const TextStyle(color: Color(0xFF687572), fontSize: 12)),
            const SizedBox(height: 7),
            Text(
                'Rp${listing.price} / bulan • ${listing.roomsAvailable}/${listing.roomsTotal} kamar kosong',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            if (listing.status == 'pending')
              const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: Text(
                      'Listing ditinjau admin sebelum tampil ke pelanggan.',
                      style:
                          TextStyle(color: Color(0xFFAF711C), fontSize: 11))),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Hapus')),
              const SizedBox(width: 6),
              TextButton.icon(
                  onPressed: onRooms,
                  icon: const Icon(Icons.bed_outlined),
                  label: const Text('Kamar')),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Ubah'))
            ])
          ])));
}

class _StateChip extends StatelessWidget {
  const _StateChip(this.status);
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = status == 'approved'
        ? AppTheme.teal
        : status == 'rejected'
            ? Colors.redAccent
            : const Color(0xFFAF711C);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(20)),
        child: Text(
            switch (status) {
              'approved' => 'Aktif',
              'rejected' => 'Ditolak',
              _ => 'Review'
            },
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w700)));
  }
}
