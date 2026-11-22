import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/kos_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kos_data_provider.dart';

class CustomerBookingsScreen extends StatelessWidget {
  const CustomerBookingsScreen({required this.customerId, super.key});
  final String customerId;
  @override
  Widget build(BuildContext context) {
    final data = context.watch<KosDataProvider>();
    final items = data.customerBookings(customerId);
    return Scaffold(
        appBar: AppBar(title: const Text('Booking & survei')),
        body: items.isEmpty
            ? const _EmptyState(
                icon: Icons.calendar_month_outlined,
                title: 'Belum ada permintaan',
                message:
                    'Buka detail kos untuk booking kamar atau menjadwalkan survei.')
            : ListView(
                padding: const EdgeInsets.all(16),
                children: items.map((b) {
                  final place = data.listing(b.listingId);
                  return Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Icon(Icons.apartment_rounded,
                                      color: AppTheme.teal),
                                  const SizedBox(width: 9),
                                  Expanded(
                                      child: Text(place?.name ?? 'Kos dihapus',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16))),
                                  _StatusPill(b.status)
                                ]),
                                const SizedBox(height: 9),
                                Text(
                                    b.kind == 'survey'
                                        ? 'Survei • ${_date(b.moveIn)}'
                                        : 'Booking mulai • ${_date(b.moveIn)}',
                                    style: const TextStyle(
                                        color: Color(0xFF687572))),
                                if (b.note.isNotEmpty)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(b.note,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF687572)))),
                                const SizedBox(height: 12),
                                Align(
                                    alignment: Alignment.centerRight,
                                    child: OutlinedButton.icon(
                                        onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    KosChatScreen(booking: b))),
                                        icon: const Icon(
                                            Icons.chat_bubble_outline_rounded),
                                        label: const Text('Buka chat'))),
                              ])));
                }).toList()));
  }
}

class OwnerBookingsScreen extends StatelessWidget {
  const OwnerBookingsScreen({required this.ownerId, super.key});
  final String ownerId;
  @override
  Widget build(BuildContext context) {
    final data = context.watch<KosDataProvider>();
    final items = data.ownerBookings(ownerId);
    return Scaffold(
        appBar: AppBar(title: const Text('Booking masuk')),
        body: items.isEmpty
            ? const _EmptyState(
                icon: Icons.inbox_outlined,
                title: 'Belum ada permintaan',
                message:
                    'Permintaan booking dan survei dari pelanggan akan muncul di sini.')
            : ListView(
                padding: const EdgeInsets.all(16),
                children: items.map((b) {
                  final place = data.listing(b.listingId);
                  return Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Icon(Icons.person_outline,
                                      color: AppTheme.teal),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(b.customerName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800))),
                                  _StatusPill(b.status)
                                ]),
                                const SizedBox(height: 7),
                                Text(
                                    '${b.kind == 'survey' ? 'Permintaan survei' : 'Booking kamar'} • ${place?.name ?? 'Kos dihapus'}'),
                                Text('Tanggal: ${_date(b.moveIn)}',
                                    style: const TextStyle(
                                        color: Color(0xFF687572))),
                                const SizedBox(height: 11),
                                Wrap(spacing: 8, runSpacing: 6, children: [
                                  OutlinedButton.icon(
                                      onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  KosChatScreen(booking: b))),
                                      icon: const Icon(Icons.chat_outlined),
                                      label: const Text('Chat')),
                                  if (b.status == 'pending')
                                    OutlinedButton(
                                        onPressed: () => data.setBookingStatus(
                                            b.id, 'rejected'),
                                        child: const Text('Tolak')),
                                  if (b.status == 'pending')
                                    ElevatedButton(
                                        onPressed: () => data.setBookingStatus(
                                            b.id, 'accepted'),
                                        child: Text(b.kind == 'survey'
                                            ? 'Setujui survei'
                                            : 'Terima booking')),
                                  if (b.status == 'accepted')
                                    TextButton(
                                        onPressed: () => data.setBookingStatus(
                                            b.id, 'completed'),
                                        child: const Text('Tandai selesai'))
                                ]),
                              ])));
                }).toList()));
  }
}

class KosChatScreen extends StatefulWidget {
  const KosChatScreen({required this.booking, super.key});
  final KosBooking booking;
  @override
  State<KosChatScreen> createState() => _KosChatScreenState();
}

class _KosChatScreenState extends State<KosChatScreen> {
  final _text = TextEditingController();
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final user = context.read<AuthProvider>().user;
    if (user == null || _text.text.trim().isEmpty) return;
    final text = _text.text;
    _text.clear();
    await context.read<KosDataProvider>().sendMessage(
        bookingId: widget.booking.id,
        senderId: user.id,
        senderName: user.name,
        text: text);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final data = context.watch<KosDataProvider>();
    final place = data.listing(widget.booking.listingId);
    final messages = data.messages(widget.booking.id);
    return Scaffold(
        appBar: AppBar(
            title:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(place?.name ?? 'Chat kos', style: const TextStyle(fontSize: 16)),
          Text(
              user?.role == UserRole.kosOwner
                  ? widget.booking.customerName
                  : 'Pemilik ${place?.ownerName ?? ''}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF687572)))
        ])),
        body: Column(children: [
          Expanded(
              child: messages.isEmpty
                  ? const _EmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: 'Mulai percakapan',
                      message:
                          'Tanyakan detail kos atau koordinasikan jadwal di sini.')
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: messages.map((m) {
                        final mine = m.senderId == user?.id;
                        return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 300),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: mine
                                        ? AppTheme.teal
                                        : const Color(0xFFEAF0EC),
                                    borderRadius: BorderRadius.circular(16)),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (!mine)
                                        Text(m.senderName,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                                color: mine
                                                    ? Colors.white
                                                    : AppTheme.teal)),
                                      Text(m.text,
                                          style: TextStyle(
                                              color: mine
                                                  ? Colors.white
                                                  : AppTheme.ink)),
                                      const SizedBox(height: 4),
                                      Text(
                                          '${m.sentAt.hour.toString().padLeft(2, '0')}:${m.sentAt.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: mine
                                                  ? Colors.white70
                                                  : Colors.black45))
                                    ])));
                      }).toList())),
          SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(children: [
                    Expanded(
                        child: TextField(
                            controller: _text,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: const InputDecoration(
                                hintText: 'Tulis pesan...',
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 12)))),
                    const SizedBox(width: 8),
                    IconButton.filled(
                        onPressed: _send, icon: const Icon(Icons.send_rounded))
                  ]))),
        ]));
  }
}

class InvoiceListScreen extends StatelessWidget {
  const InvoiceListScreen({required this.customerId, super.key});
  final String customerId;
  @override
  Widget build(BuildContext context) {
    final items = context.watch<KosDataProvider>().customerInvoices(customerId);
    return Scaffold(
      appBar: AppBar(title: const Text('Tagihan')),
      body: items.isEmpty
          ? const _EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Belum ada tagihan',
              message:
                  'Tagihan akan muncul setelah booking diterima oleh pemilik.')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: items
                  .map((i) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                              backgroundColor: i.isPaid
                                  ? const Color(0xFFEAF3EF)
                                  : const Color(0xFFFFF1E2),
                              child: Icon(
                                  i.isPaid
                                      ? Icons.check_rounded
                                      : Icons.receipt_long_rounded,
                                  color: i.isPaid
                                      ? AppTheme.teal
                                      : const Color(0xFFBE7B20))),
                          title: Text(i.listingName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              'Jatuh tempo ${_date(i.dueAt)} • ${i.isPaid ? 'Lunas' : 'Belum dibayar'}'),
                          trailing: i.isPaid
                              ? const Icon(Icons.verified_rounded,
                                  color: AppTheme.teal)
                              : TextButton(
                                  onPressed: () => _paymentInfo(context),
                                  child: const Text('Info bayar')),
                        ),
                      ))
                  .toList()),
    );
  }

  void _paymentInfo(BuildContext context) {
    showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
              title: const Text('Pembayaran online belum tersedia'),
              content: const Text(
                  'Hubungi pemilik kos untuk metode pembayaran. Status tagihan baru diperbarui setelah gateway pembayaran resmi dihubungkan.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Mengerti'))
              ],
            ));
  }
}

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final data = context.watch<KosDataProvider>();
    final bookings =
        user == null ? const <KosBooking>[] : data.customerBookings(user.id);
    final invoices =
        user == null ? const <KosInvoice>[] : data.customerInvoices(user.id);
    final items = <Widget>[];
    for (final b in bookings) {
      if (b.status != 'pending') {
        items.add(ListTile(
            leading: const Icon(Icons.event_available, color: AppTheme.teal),
            title: Text(b.kind == 'survey'
                ? 'Jadwal survei diperbarui'
                : 'Status booking diperbarui'),
            subtitle: Text('Status: ${_statusText(b.status)}')));
      }
    }
    for (final i in invoices.where((x) => !x.isPaid)) {
      items.add(ListTile(
          leading: const Icon(Icons.receipt_long, color: Color(0xFFBE7B20)),
          title: const Text('Tagihan baru'),
          subtitle: Text('${i.listingName} • jatuh tempo ${_date(i.dueAt)}')));
    }
    return Scaffold(
        appBar: AppBar(title: const Text('Notifikasi')),
        body: items.isEmpty
            ? const _EmptyState(
                icon: Icons.notifications_none,
                title: 'Semua tenang',
                message: 'Notifikasi booking dan tagihan akan muncul di sini.')
            : ListView(children: items));
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);
  final String status;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: status == 'accepted' || status == 'completed'
              ? const Color(0xFFEAF3EF)
              : status == 'rejected'
                  ? const Color(0xFFFFEBE9)
                  : const Color(0xFFFFF1E2),
          borderRadius: BorderRadius.circular(18)),
      child: Text(_statusText(status),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: status == 'accepted' || status == 'completed'
                  ? AppTheme.teal
                  : status == 'rejected'
                      ? Colors.redAccent
                      : const Color(0xFFAF711C))));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title, message;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(34),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 50, color: AppTheme.teal.withValues(alpha: .6)),
            const SizedBox(height: 14),
            Text(title,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF687572), height: 1.4))
          ])));
}

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String _statusText(String status) => switch (status) {
      'pending' => 'Menunggu',
      'accepted' => 'Disetujui',
      'rejected' => 'Ditolak',
      'completed' => 'Selesai',
      _ => status
    };
