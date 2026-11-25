import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/kos_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kos_data_provider.dart';
import '../shared/kos_map_screen.dart';

class AdminListingEditor extends StatefulWidget {
  const AdminListingEditor({this.listing, super.key});
  final KosListing? listing;
  @override
  State<AdminListingEditor> createState() => _AdminListingEditorState();
}

class _AdminListingEditorState extends State<AdminListingEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.listing?.name ?? '');
  late final _address =
      TextEditingController(text: widget.listing?.address ?? '');
  late final _description =
      TextEditingController(text: widget.listing?.description ?? '');
  late final _amenities =
      TextEditingController(text: widget.listing?.amenities.join(', ') ?? '');
  late final _price =
      TextEditingController(text: '${widget.listing?.price ?? 850000}');
  late final _total =
      TextEditingController(text: '${widget.listing?.roomsTotal ?? 1}');
  late final _available =
      TextEditingController(text: '${widget.listing?.roomsAvailable ?? 1}');
  late String _gender = widget.listing?.gender ?? 'Campur';
  LatLng? _point;
  List<_ListingOwner> _owners = [];
  String? _selectedOwnerId;
  bool _loadingOwners = true;
  String? _ownerError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.listing;
    if (item != null) {
      _point = LatLng(item.latitude, item.longitude);
      _selectedOwnerId = item.ownerId;
    }
    _loadOwners();
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _description.dispose();
    _amenities.dispose();
    _price.dispose();
    _total.dispose();
    _available.dispose();
    super.dispose();
  }

  Future<void> _loadOwners() async {
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select('id,display_name')
          .eq('role', 'kos_owner')
          .order('display_name');
      final owners = rows
          .map((row) => _ListingOwner(
                id: row['id'].toString(),
                name:
                    (row['display_name'] as String?)?.trim().isNotEmpty == true
                        ? row['display_name'] as String
                        : 'Mitra tanpa nama',
              ))
          .toList();
      final existing = widget.listing;
      if (existing != null &&
          !owners.any((owner) => owner.id == existing.ownerId)) {
        owners.insert(
            0, _ListingOwner(id: existing.ownerId, name: existing.ownerName));
      }
      if (!mounted) return;
      setState(() {
        _owners = owners;
        _loadingOwners = false;
        _ownerError = null;
        if (_selectedOwnerId == null && owners.length == 1) {
          _selectedOwnerId = owners.first.id;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingOwners = false;
        _ownerError = 'Daftar mitra belum bisa dimuat: $error';
      });
    }
  }

  Future<void> _choosePoint() async {
    final point = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
          builder: (_) => KosLocationPickerScreen(initialPoint: _point)),
    );
    if (point != null && mounted) setState(() => _point = point);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_selectedOwnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih akun mitra pemilik kos.')));
      return;
    }
    if (_point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih lokasi kos di peta.')));
      return;
    }
    final admin = context.read<AuthProvider>().user;
    if (admin == null || admin.role != UserRole.admin) return;
    final owner =
        _owners.where((item) => item.id == _selectedOwnerId).firstOrNull;
    if (owner == null) return;
    final old = widget.listing;
    final total = int.parse(_total.text);
    final item = KosListing(
      id: old?.id ?? newUuidV4(),
      ownerId: owner.id,
      ownerName: owner.name,
      name: _name.text.trim(),
      address: _address.text.trim(),
      description: _description.text.trim(),
      price: int.parse(_price.text),
      gender: _gender,
      roomsTotal: total,
      roomsAvailable: int.parse(_available.text),
      amenities: _amenities.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(),
      status: old?.status ?? 'approved',
      latitude: _point!.latitude,
      longitude: _point!.longitude,
    );
    setState(() => _saving = true);
    try {
      await context
          .read<KosDataProvider>()
          .saveListing(item, preserveStatus: true);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Listing belum tersimpan: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(widget.listing == null ? 'Tambah kos' : 'Ubah kos')),
        body: Form(
          key: _form,
          child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              children: [
                const Text('Data kos',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Nama kos'),
                    validator: (v) => v == null || v.trim().length < 3
                        ? 'Nama minimal 3 karakter.'
                        : null),
                const SizedBox(height: 10),
                TextFormField(
                    controller: _address,
                    decoration:
                        const InputDecoration(labelText: 'Alamat lengkap'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Alamat wajib diisi.'
                        : null),
                const SizedBox(height: 10),
                TextFormField(
                    controller: _description,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                    validator: (v) => v == null || v.trim().length < 10
                        ? 'Deskripsi minimal 10 karakter.'
                        : null),
                const SizedBox(height: 10),
                TextFormField(
                    controller: _amenities,
                    decoration: const InputDecoration(
                        labelText: 'Fasilitas',
                        hintText:
                            'Pisahkan dengan koma, mis. Wi-Fi, parkir motor')),
                const SizedBox(height: 20),
                const Text('Pemilik dan lokasi',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                if (_loadingOwners) const LinearProgressIndicator(),
                if (_ownerError != null) ...[
                  Text(_ownerError!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12)),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                          onPressed: _loadOwners,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Muat ulang mitra'))),
                ],
                if (!_loadingOwners && _owners.isEmpty && _ownerError == null)
                  const Text(
                      'Belum ada akun Mitra Pemilik Kos. Buat akun mitra terlebih dahulu sebelum menambahkan listing.',
                      style: TextStyle(color: Color(0xFF5F6B73), height: 1.4)),
                if (_owners.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedOwnerId,
                    decoration:
                        const InputDecoration(labelText: 'Akun pemilik kos'),
                    items: _owners
                        .map((owner) => DropdownMenuItem(
                            value: owner.id,
                            child: Text(owner.name,
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedOwnerId = value),
                    validator: (value) =>
                        value == null ? 'Pilih pemilik kos.' : null,
                  ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _choosePoint,
                  icon: const Icon(Icons.map_outlined),
                  label: Text(_point == null
                      ? 'Pilih titik lokasi di peta'
                      : '${_point!.latitude.toStringAsFixed(5)}, ${_point!.longitude.toStringAsFixed(5)}'),
                ),
                const SizedBox(height: 20),
                const Text('Harga dan ketersediaan',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Harga per bulan (Rp)'),
                    validator: (v) =>
                        int.tryParse(v ?? '') == null || int.parse(v!) < 100000
                            ? 'Harga minimal Rp100.000.'
                            : null),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration:
                        const InputDecoration(labelText: 'Tipe penghuni'),
                    items: const ['Putra', 'Putri', 'Campur']
                        .map((value) =>
                            DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _gender = value ?? 'Campur')),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: TextFormField(
                          controller: _total,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Total kamar'),
                          validator: (value) =>
                              int.tryParse(value ?? '') == null ||
                                      int.parse(value!) < 1
                                  ? 'Minimal 1 kamar.'
                                  : null)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: TextFormField(
                          controller: _available,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Kamar tersedia'),
                          validator: (value) {
                            final available = int.tryParse(value ?? '');
                            final total = int.tryParse(_total.text);
                            return available == null ||
                                    total == null ||
                                    available > total ||
                                    available < 0
                                ? 'Periksa jumlah kamar.'
                                : null;
                          })),
                ]),
                const SizedBox(height: 20),
                FilledButton.icon(
                    onPressed: _saving || _loadingOwners || _owners.isEmpty
                        ? null
                        : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Menyimpan...' : 'Simpan listing')),
              ]),
        ),
      );
}

class _ListingOwner {
  const _ListingOwner({required this.id, required this.name});
  final String id;
  final String name;
}
