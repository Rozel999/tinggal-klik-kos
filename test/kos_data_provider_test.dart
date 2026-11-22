import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinggal_klik_kos/domain/entities/kos_models.dart';
import 'package:tinggal_klik_kos/presentation/providers/kos_data_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('listing, favorite, booking, chat and invoice persist locally', () async {
    final store = KosDataProvider();
    await store.load();
    expect(store.approvedListings, isNotEmpty);

    final listing = store.approvedListings.first;
    await store.toggleFavorite('customer-001', listing.id);
    expect(store.isFavorite('customer-001', listing.id), isTrue);

    final booking = await store.createBooking(
      listingId: listing.id,
      customerId: 'customer-001',
      customerName: 'Pelanggan Demo',
      moveIn: DateTime(2027, 1, 1),
      note: 'Ingin kamar dekat kampus',
      kind: 'booking',
    );
    await store.sendMessage(
      bookingId: booking.id,
      senderId: 'customer-001',
      senderName: 'Pelanggan Demo',
      text: 'Apakah kamar masih tersedia?',
    );
    await store.setBookingStatus(booking.id, 'accepted');
    expect(store.customerInvoices('customer-001'), hasLength(1));
    await store.markInvoicePaid(store.customerInvoices('customer-001').single.id);

    final restored = KosDataProvider();
    await restored.load();
    expect(restored.isFavorite('customer-001', listing.id), isTrue);
    expect(restored.customerBookings('customer-001').single.status, 'accepted');
    expect(restored.messages(booking.id).single.text, 'Apakah kamar masih tersedia?');
    expect(restored.customerInvoices('customer-001').single.isPaid, isTrue);
  });

  test('survey approval does not create a payment invoice', () async {
    final store = KosDataProvider();
    await store.load();
    final listing = store.approvedListings.first;
    final booking = await store.createBooking(
      listingId: listing.id,
      customerId: 'customer-001',
      customerName: 'Pelanggan Demo',
      moveIn: DateTime(2027, 1, 1),
      note: 'Survei kamar',
      kind: 'survey',
    );
    await store.setBookingStatus(booking.id, 'accepted');
    expect(store.customerInvoices('customer-001'), isEmpty);
  });


  test('owner listing stays hidden until admin review and can be removed', () async {
    final store = KosDataProvider();
    await store.load();
    const draft = KosListing(
      id: 'kos-draft', ownerId: 'owner-001', ownerName: 'Pemilik Demo',
      name: 'Kos Uji', address: 'Padang', description: 'Listing uji moderasi.',
      price: 900000, gender: 'Campur', roomsTotal: 4, roomsAvailable: 2,
      amenities: ['Wi-Fi'], status: 'pending', latitude: -0.9, longitude: 100.3,
    );
    await store.saveListing(draft);
    expect(store.approvedListings.any((x) => x.id == draft.id), isFalse);
    await store.reviewListing(draft.id, true);
    expect(store.approvedListings.any((x) => x.id == draft.id), isTrue);
    await store.deleteListing(draft.id);
    expect(store.listing(draft.id), isNull);
  });


  test('room CRUD keeps listing availability in sync', () async {
    final store = KosDataProvider();
    await store.load();
    final listing = store.ownerListings('owner-001').first;
    final original = store.roomsForListing(listing.id).first;
    await store.saveRoom(original.copyWith(status: 'maintenance'));
    expect(store.listing(listing.id)!.roomsAvailable, listing.roomsAvailable - 1);
    final changed = store.roomsForListing(listing.id).firstWhere((x) => x.id == original.id);
    await store.deleteRoom(changed.id);
    expect(store.listing(listing.id)!.roomsTotal, listing.roomsTotal - 1);
  });
}
