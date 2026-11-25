import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/kos_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kos_data_provider.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({required this.booking, super.key});
  final KosBooking booking;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _comment = TextEditingController();
  int _rating = 5;
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final place =
        context.watch<KosDataProvider>().listing(widget.booking.listingId);
    return Scaffold(
      appBar: AppBar(title: const Text('Tulis ulasan')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(place?.name ?? 'Kos',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        const Text('Bagaimana pengalaman tinggal di kos ini?'),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (index) => IconButton(
              tooltip: '${index + 1} bintang',
              onPressed: () => setState(() => _rating = index + 1),
              icon: Icon(
                  index < _rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: const Color(0xFFE6A52F),
                  size: 34),
            ),
          ),
        ),
        Text('$_rating dari 5', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        TextField(
          controller: _comment,
          minLines: 4,
          maxLines: 7,
          maxLength: 1000,
          decoration: const InputDecoration(
              labelText: 'Ceritakan pengalaman',
              hintText: 'Kebersihan, fasilitas, lokasi, dan pemilik kos',
              alignLabelWithHint: true,
              border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send_rounded),
          label: const Text('Kirim ulasan'),
        ),
      ]),
    );
  }

  Future<void> _submit() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await context.read<KosDataProvider>().submitReview(
          booking: widget.booking,
          customerName: user.name,
          rating: _rating,
          comment: _comment.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ulasan berhasil dikirim.')));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ulasan gagal dikirim: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
