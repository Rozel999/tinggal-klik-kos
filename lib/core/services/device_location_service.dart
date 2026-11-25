import 'package:geolocator/geolocator.dart';

class DeviceLocationService {
  DeviceLocationService._();

  static Future<Position> currentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const DeviceLocationException(
          'Aktifkan layanan lokasi/GPS di perangkat lalu coba lagi.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const DeviceLocationException(
          'Izin lokasi ditolak. Izinkan Tinggal Klik Kos mengakses lokasi saat aplikasi digunakan.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const DeviceLocationException(
          'Izin lokasi diblokir. Ubah izin aplikasi dari Pengaturan perangkat.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }
}

class DeviceLocationException implements Exception {
  const DeviceLocationException(this.message);
  final String message;

  @override
  String toString() => message;
}
