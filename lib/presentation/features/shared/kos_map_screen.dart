import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/services/device_location_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/kos_models.dart';

const padangCenter = LatLng(-0.9471, 100.4172);

class KosMapScreen extends StatefulWidget {
  const KosMapScreen({required this.listings, super.key});
  final List<KosListing> listings;

  @override
  State<KosMapScreen> createState() => _KosMapScreenState();
}

class _KosMapScreenState extends State<KosMapScreen> {
  final _mapController = MapController();
  LatLng? _myLocation;
  bool _locating = false;

  Future<void> _locateMe() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final position = await DeviceLocationService.currentPosition();
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() => _myLocation = point);
      _mapController.move(point, 15);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lokasi belum tersedia: $error')));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valid = widget.listings
        .where((x) => x.latitude.abs() > 0.0001 && x.longitude.abs() > 0.0001)
        .toList();
    final center = valid.isEmpty
        ? padangCenter
        : LatLng(valid.first.latitude, valid.first.longitude);
    return Scaffold(
      appBar: AppBar(title: const Text('Peta kos')),
      body: Column(children: [
        Expanded(
          flex: 6,
          child: Stack(children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                  initialCenter: center,
                  initialZoom: valid.length == 1 ? 15 : 12),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.tinggal_klik_kos',
                ),
                MarkerLayer(markers: [
                  for (final listing in valid)
                    Marker(
                      point: LatLng(listing.latitude, listing.longitude),
                      width: 44,
                      height: 52,
                      child: Tooltip(
                        message: listing.name,
                        child: const Icon(Icons.location_on,
                            color: AppTheme.teal, size: 42),
                      ),
                    ),
                  if (_myLocation case final location?)
                    Marker(
                      point: location,
                      width: 28,
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2878E8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 8)
                          ],
                        ),
                      ),
                    ),
                ]),
                const RichAttributionWidget(
                  alignment: AttributionAlignment.bottomRight,
                  attributions: [
                    TextSourceAttribution('• OpenStreetMap contributors')
                  ],
                ),
              ],
            ),
            Positioned(
              right: 14,
              top: 14,
              child: FloatingActionButton.small(
                heroTag: 'map-my-location',
                tooltip: 'Lokasi saya (GPS)',
                onPressed: _locating ? null : _locateMe,
                child: _locating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location_rounded),
              ),
            ),
          ]),
        ),
        if (valid.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Belum ada kos dengan koordinat lokasi yang valid.'),
          )
        else
          Expanded(
            flex: 4,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final x in valid)
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEAF3EF),
                        child: Icon(Icons.location_on_rounded,
                            color: AppTheme.teal),
                      ),
                      title: Text(x.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          '${x.address}\n${x.latitude.toStringAsFixed(5)}, ${x.longitude.toStringAsFixed(5)}'),
                      isThreeLine: true,
                      trailing: Text('Rp${(x.price / 1000).round()}rb'),
                    ),
                  ),
              ],
            ),
          ),
      ]),
    );
  }
}

class KosLocationPickerScreen extends StatefulWidget {
  const KosLocationPickerScreen({this.initialPoint, super.key});
  final LatLng? initialPoint;

  @override
  State<KosLocationPickerScreen> createState() =>
      _KosLocationPickerScreenState();
}

class _KosLocationPickerScreenState extends State<KosLocationPickerScreen> {
  final _mapController = MapController();
  late LatLng _selected = widget.initialPoint ?? padangCenter;
  late bool _hasSelection = widget.initialPoint != null;
  bool _locating = false;

  Future<void> _locateMe() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final position = await DeviceLocationService.currentPosition();
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _selected = point;
        _hasSelection = true;
      });
      _mapController.move(point, 16);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS belum dapat dipakai: $error')));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pilih lokasi kos')),
        body: Stack(children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selected,
              initialZoom: widget.initialPoint == null ? 12 : 15,
              onTap: (_, point) => setState(() {
                _selected = point;
                _hasSelection = true;
              }),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.tinggal_klik_kos',
              ),
              if (_hasSelection)
                MarkerLayer(markers: [
                  Marker(
                    point: _selected,
                    width: 48,
                    height: 56,
                    child: const Icon(Icons.location_on,
                        color: AppTheme.teal, size: 46),
                  ),
                ]),
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomRight,
                attributions: [
                  TextSourceAttribution('• OpenStreetMap contributors')
                ],
              ),
            ],
          ),
          Positioned(
            right: 16,
            top: 106,
            child: FloatingActionButton.small(
              heroTag: 'picker-my-location',
              tooltip: 'Gunakan lokasi perangkat',
              onPressed: _locating ? null : _locateMe,
              child: _locating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_hasSelection
                    ? 'Geser peta lalu ketuk titik lokasi kos.\n${_selected.latitude.toStringAsFixed(6)}, ${_selected.longitude.toStringAsFixed(6)}'
                    : 'Geser peta lalu ketuk titik lokasi kos.'),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: FilledButton.icon(
              onPressed: _hasSelection
                  ? () => Navigator.pop(context, _selected)
                  : null,
              icon: const Icon(Icons.check),
              label: const Text('Gunakan lokasi ini'),
            ),
          ),
        ]),
      );
}
