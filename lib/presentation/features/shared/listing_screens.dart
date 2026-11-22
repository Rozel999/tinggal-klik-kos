import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/kos_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kos_data_provider.dart';
import 'transaction_screens.dart';
import 'kos_map_screen.dart';
export 'kos_map_screen.dart';

class KosDetailScreen extends StatelessWidget {
  const KosDetailScreen({required this.listing, super.key});
  final KosListing listing;

  Future<void> _request(BuildContext context, String kind) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    if (kind == 'booking' &&
        context.read<KosDataProvider>().customerBookings(user.id).any(
            (booking) =>
                booking.listingId == listing.id &&
                booking.kind == 'booking' &&
                (booking.status == 'pending' ||
                    booking.status == 'accepted'))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Kamu sudah punya booking yang diproses untuk kos ini.')));
      return;
    }
    final date = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 7)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        helpText: kind == 'survey'
            ? 'Pilih tanggal survei'
            : 'Pilih tanggal mulai tinggal');
    if (date == null || !context.mounted) return;
    try {
      final booking = await context.read<KosDataProvider>().createBooking(
          listingId: listing.id,
          customerId: user.id,
          customerName: user.name,
          moveIn: date,
          note: kind == 'survey'
              ? 'Permintaan jadwal survei'
              : 'Permintaan booking kamar',
          kind: kind);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(kind == 'survey'
              ? 'Permintaan survei dikirim.'
              : 'Permintaan booking dikirim.')));
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => KosChatScreen(booking: booking)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Permintaan belum terkirim. Periksa koneksi lalu coba lagi.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = context.watch<KosDataProvider>().roomsForListing(listing.id);
    final available = rooms.isEmpty
        ? listing.roomsAvailable
        : rooms.where((room) => room.status == 'available').length;
    final user = context.watch<AuthProvider>().user;
    final bookings =
        context.watch<KosDataProvider>().customerBookings(user?.id ?? '');
    final activeBookings = bookings.where((booking) =>
        booking.listingId == listing.id &&
        booking.kind == 'booking' &&
        (booking.status == 'pending' || booking.status == 'accepted'));
    final hasActiveBooking = activeBookings.isNotEmpty;
    final alreadyAccepted =
        activeBookings.any((booking) => booking.status == 'accepted');
    return Scaffold(
      appBar: AppBar(title: const Text('Detail kos')),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          children: [
            Container(
                height: 220,
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFD8E8DE), Color(0xFFF0E8D2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(24)),
                child: Stack(alignment: Alignment.center, children: [
                  const Positioned(
                      right: 24,
                      top: 20,
                      child: CircleAvatar(
                          radius: 23, backgroundColor: Color(0xFFFFD77D))),
                  const Icon(Icons.house_rounded,
                      color: AppTheme.teal, size: 132),
                  Positioned(
                      left: 13,
                      bottom: 13,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18)),
                          child: const Text('Foto belum tersedia',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700)))),
                ])),
            const SizedBox(height: 19),
            Row(children: [
              Expanded(
                  child: Text(listing.name,
                      style: const TextStyle(
                          fontSize: 23, fontWeight: FontWeight.w800))),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                      color: const Color(0xFFEAF3EF),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(listing.gender,
                      style: const TextStyle(
                          color: AppTheme.teal, fontWeight: FontWeight.w700)))
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.location_on_outlined,
                  color: AppTheme.teal, size: 18),
              const SizedBox(width: 5),
              Expanded(
                  child: Text(listing.address,
                      style: const TextStyle(color: Color(0xFF687572))))
            ]),
            const SizedBox(height: 13),
            Text('Rp${listing.price.toString()} / bulan',
                style: const TextStyle(
                    fontSize: 21,
                    color: AppTheme.teal,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 13),
            _Section(
                title: 'Tentang kos',
                child: Text(listing.description,
                    style: const TextStyle(
                        height: 1.5, color: Color(0xFF56635F)))),
            const SizedBox(height: 17),
            _Section(
                title: 'Fasilitas',
                child: listing.amenities.isEmpty
                    ? const Text('Fasilitas belum ditambahkan pemilik.',
                        style: TextStyle(color: Color(0xFF687572)))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: listing.amenities
                            .map((x) => Chip(
                                avatar: const Icon(Icons.check_circle_outline,
                                    size: 17, color: AppTheme.teal),
                                label: Text(x),
                                side: BorderSide.none,
                                backgroundColor: const Color(0xFFF0F4F0)))
                            .toList())),
            const SizedBox(height: 17),
            _Section(
                title: 'Unit kamar',
                child: rooms.isEmpty
                    ? Text(
                        '${listing.roomsAvailable} dari ${listing.roomsTotal} kamar tersedia. Rincian unit belum ditambahkan.',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF687572)))
                    : Column(
                        children: rooms.map((room) {
                          final isAvailable = room.status == 'available';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: const Color(0xFFE9ECE7))),
                            child: ListTile(
                              dense: true,
                              leading: Icon(
                                  isAvailable
                                      ? Icons.bed_outlined
                                      : Icons.bed_rounded,
                                  color: isAvailable
                                      ? AppTheme.teal
                                      : const Color(0xFFAF711C)),
                              title: Text('Kamar ${room.label}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              subtitle: Text('Rp${room.price} / bulan',
                                  style: const TextStyle(fontSize: 12)),
                              trailing: Text(
                                  isAvailable ? 'Tersedia' : 'Terisi',
                                  style: TextStyle(
                                      color: isAvailable
                                          ? AppTheme.teal
                                          : const Color(0xFFAF711C),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                            ),
                          );
                        }).toList(),
                      )),
            const SizedBox(height: 17),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEAF3EF),
                  child: Icon(Icons.person_outline, color: AppTheme.teal)),
              title: Text(listing.ownerName),
              subtitle: const Text('Pemilik kos'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => KosMapScreen(listings: [listing]))),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Lihat lokasi di peta')),
            const SizedBox(height: 10),
            ElevatedButton.icon(
                onPressed: available == 0 || hasActiveBooking
                    ? null
                    : () => _request(context, 'booking'),
                icon: const Icon(Icons.event_available_outlined),
                label: Text(alreadyAccepted
                    ? 'Kamar sudah dihuni'
                    : hasActiveBooking
                        ? 'Booking sedang diproses'
                        : available == 0
                            ? 'Kamar sudah terisi'
                            : 'Ajukan booking')),
            const SizedBox(height: 8),
            OutlinedButton.icon(
                onPressed: () => _request(context, 'survey'),
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('Jadwalkan survei & chat pemilik')),
          ]),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 9),
        child
      ]);
}

class RoomManagementScreen extends StatelessWidget {
  const RoomManagementScreen({required this.listing, super.key});
  final KosListing listing;

  @override
  Widget build(BuildContext context) {
    final rooms = context.watch<KosDataProvider>().roomsForListing(listing.id);
    return Scaffold(
      appBar: AppBar(title: Text('Kamar • ${listing.name}')),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _edit(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tambah kamar')),
      body: rooms.isEmpty
          ? const Center(child: Text('Belum ada unit kamar. Tambahkan kamar.'))
          : ListView(padding: const EdgeInsets.all(16), children: [
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                          '${rooms.where((x) => x.status == 'available').length} tersedia dari ${rooms.length} unit',
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)))),
              ...rooms.map((room) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: room.status == 'available'
                            ? const Color(0xFFEAF3EF)
                            : const Color(0xFFFFF1E2),
                        child: Icon(
                            room.status == 'available'
                                ? Icons.bed_outlined
                                : room.status == 'occupied'
                                    ? Icons.bed_rounded
                                    : Icons.handyman_outlined,
                            color: room.status == 'available'
                                ? AppTheme.teal
                                : const Color(0xFFAF711C)),
                      ),
                      title: Text(room.label,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          'Rp${room.price} / bulan • ${_roomStatus(room.status)}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                            tooltip: 'Ubah kamar',
                            onPressed: () => _edit(context, room: room),
                            icon: const Icon(Icons.edit_outlined)),
                        IconButton(
                            tooltip: 'Hapus kamar',
                            onPressed: () => context
                                .read<KosDataProvider>()
                                .deleteRoom(room.id),
                            icon: const Icon(Icons.delete_outline_rounded)),
                      ]),
                    ),
                  )),
            ]),
    );
  }

  Future<void> _edit(BuildContext context, {KosRoom? room}) async {
    final form = GlobalKey<FormState>();
    final label = TextEditingController(text: room?.label ?? '');
    final price =
        TextEditingController(text: (room?.price ?? listing.price).toString());
    var status = room?.status ?? 'available';
    await showDialog<void>(
        context: context,
        builder: (dialog) => StatefulBuilder(
            builder: (context, setDialog) => AlertDialog(
                  title: Text(
                      room == null ? 'Tambah kamar' : 'Ubah ${room.label}'),
                  content: Form(
                      key: form,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        TextFormField(
                            controller: label,
                            decoration: const InputDecoration(
                                labelText: 'Nomor / nama kamar'),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Nama kamar wajib diisi.'
                                : null),
                        const SizedBox(height: 10),
                        TextFormField(
                            controller: price,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Harga per bulan (Rp)'),
                            validator: (v) => int.tryParse(v ?? '') == null ||
                                    int.parse(v!) < 100000
                                ? 'Harga minimal Rp100.000.'
                                : null),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                            initialValue: status,
                            decoration: const InputDecoration(
                                labelText: 'Status kamar'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'available', child: Text('Tersedia')),
                              DropdownMenuItem(
                                  value: 'occupied', child: Text('Terisi')),
                              DropdownMenuItem(
                                  value: 'maintenance',
                                  child: Text('Perbaikan'))
                            ],
                            onChanged: (v) =>
                                setDialog(() => status = v ?? 'available')),
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialog),
                        child: const Text('Batal')),
                    ElevatedButton(
                        onPressed: () async {
                          if (!form.currentState!.validate()) return;
                          await context.read<KosDataProvider>().saveRoom(
                              KosRoom(
                                  id: room?.id ?? newUuidV4(),
                                  listingId: listing.id,
                                  label: label.text.trim(),
                                  price: int.parse(price.text),
                                  status: status));
                          if (dialog.mounted) Navigator.pop(dialog);
                        },
                        child: const Text('Simpan')),
                  ],
                )));
    label.dispose();
    price.dispose();
  }

  String _roomStatus(String status) => switch (status) {
        'available' => 'Tersedia',
        'occupied' => 'Terisi',
        _ => 'Perbaikan'
      };
}
