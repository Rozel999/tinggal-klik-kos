import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/backend_config.dart';
import '../../domain/entities/kos_models.dart';

class KosDataProvider extends ChangeNotifier {
  KosDataProvider() {
    if (isSupabaseMode) {
      _authSubscription =
          Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        unawaited(_loadSupabase());
      });
    }
  }

  static const _storeKey = 'tinggal_klik_demo_data_v1';
  List<KosListing> _listings = List<KosListing>.of(_seedListings);
  List<KosRoom> _rooms = _seedRooms;
  List<KosBooking> _bookings = [];
  List<KosChatMessage> _messages = [];
  List<KosInvoice> _invoices = [];
  List<KosReview> _reviews = [];
  Map<String, Set<String>> _favorites = {};
  final List<StreamSubscription<dynamic>> _remoteSubscriptions = [];
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _pollingFallback;
  bool _realtimeFailed = false;
  bool _pollingInProgress = false;
  bool isLoaded = false;
  String? loadError;
  String? syncNotice;

  void _appendLoadError(String message, Object error) {
    loadError = [
      if (loadError != null && loadError!.isNotEmpty) loadError!,
      '$message: $error',
    ].join('\n');
  }

  List<KosListing> get listings => List.unmodifiable(_listings);
  List<KosBooking> get bookings => List.unmodifiable(_bookings);
  List<KosInvoice> get invoices => List.unmodifiable(_invoices);
  List<KosReview> reviewsForListing(String listingId) =>
      _reviews.where((review) => review.listingId == listingId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  bool hasReviewedBooking(String bookingId) =>
      _reviews.any((review) => review.bookingId == bookingId);
  List<KosListing> get approvedListings =>
      _listings.where((x) => x.isApproved).toList();
  List<KosRoom> roomsForListing(String id) =>
      _rooms.where((x) => x.listingId == id).toList()
        ..sort((a, b) => a.label.compareTo(b.label));
  KosListing? listing(String id) =>
      _listings.where((x) => x.id == id).firstOrNull;
  List<KosListing> ownerListings(String id) =>
      _listings.where((x) => x.ownerId == id).toList();
  List<KosBooking> customerBookings(String id) =>
      _bookings.where((x) => x.customerId == id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  List<KosBooking> ownerBookings(String id) {
    final ids = ownerListings(id).map((x) => x.id).toSet();
    return _bookings.where((x) => ids.contains(x.listingId)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<KosInvoice> customerInvoices(String id) =>
      _invoices.where((x) => x.customerId == id).toList()
        ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  List<KosChatMessage> messages(String id) =>
      _messages.where((x) => x.bookingId == id).toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
  bool isFavorite(String customerId, String listingId) =>
      _favorites[customerId]?.contains(listingId) ?? false;
  int get pendingReviewCount =>
      _listings.where((x) => x.status == 'pending').length;
  bool get isSupabaseMode =>
      BackendConfig.mode == BackendMode.supabase && BackendConfig.isConfigured;

  Future<void> load() async {
    if (isSupabaseMode) {
      await _loadSupabase();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _listings = (data['listings'] as List)
            .map(
                (x) => KosListing.fromJson(Map<String, dynamic>.from(x as Map)))
            .toList();
        _rooms = (data['rooms'] as List?)
                ?.map((x) =>
                    KosRoom.fromJson(Map<String, dynamic>.from(x as Map)))
                .toList() ??
            _makeRooms(_listings);
        _bookings = (data['bookings'] as List)
            .map(
                (x) => KosBooking.fromJson(Map<String, dynamic>.from(x as Map)))
            .toList();
        _messages = (data['messages'] as List)
            .map((x) =>
                KosChatMessage.fromJson(Map<String, dynamic>.from(x as Map)))
            .toList();
        _invoices = (data['invoices'] as List)
            .map(
                (x) => KosInvoice.fromJson(Map<String, dynamic>.from(x as Map)))
            .toList();
        _reviews = (data['reviews'] as List? ?? const [])
            .map((x) => KosReview.fromJson(Map<String, dynamic>.from(x as Map)))
            .toList();
        _favorites = (data['favorites'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as List).cast<String>().toSet()));
      } catch (_) {
        await prefs.remove(_storeKey);
        _resetSeed();
      }
    }
    isLoaded = true;
    notifyListeners();
  }

  Future<void> _loadSupabase() async {
    await _cancelRemoteSubscriptions();
    final client = Supabase.instance.client;
    final currentUserId = client.auth.currentUser?.id;
    _listings = [];
    _rooms = [];
    _bookings = [];
    _messages = [];
    _invoices = [];
    _reviews = [];
    _favorites = {};
    loadError = null;

    try {
      final rows = await client.from('kos_listings').select();
      _listings = _listingRows(rows);
    } catch (error) {
      _appendLoadError('Listing Supabase belum dapat dibaca', error);
    }
    try {
      final rows = await client.from('kos_rooms').select();
      _rooms = _roomRows(rows);
      _syncAllRoomCounts();
    } catch (error) {
      _appendLoadError('Kamar Supabase belum dapat dibaca', error);
    }
    if (currentUserId != null) {
      try {
        _bookings = _bookingRows(await client.from('bookings').select());
      } catch (error) {
        _appendLoadError('Booking Supabase belum dapat dibaca', error);
      }
      try {
        _messages = _messageRows(await client.from('chat_messages').select());
      } catch (error) {
        _appendLoadError('Chat Supabase belum dapat dibaca', error);
      }
      try {
        _invoices = _invoiceRows(await client.from('invoices').select());
      } catch (error) {
        _appendLoadError('Tagihan Supabase belum dapat dibaca', error);
      }
      try {
        _reviews = _reviewRows(await client.from('kos_reviews').select());
      } catch (error) {
        _appendLoadError('Ulasan Supabase belum dapat dibaca', error);
      }
      try {
        final rows =
            await client.from('favorites').select('customer_id,listing_id');
        _favorites[currentUserId] =
            rows.map((r) => r['listing_id'].toString()).toSet();
      } catch (error) {
        _appendLoadError('Favorit Supabase belum dapat dibaca', error);
      }
    }
    isLoaded = true;
    notifyListeners();
    if (_realtimeFailed) {
      _startPollingFallback();
    } else {
      _startRemoteStreams(client, currentUserId);
    }
  }

  void _startRemoteStreams(SupabaseClient client, String? userId) {
    _listen(client.from('kos_listings').stream(primaryKey: ['id']), (rows) {
      _listings = _listingRows(rows);
      _syncAllRoomCounts();
    });
    _listen(client.from('kos_rooms').stream(primaryKey: ['id']), (rows) {
      _rooms = _roomRows(rows);
      _syncAllRoomCounts();
    });
    if (userId == null) return;
    _listen(client.from('bookings').stream(primaryKey: ['id']),
        (rows) => _bookings = _bookingRows(rows));
    _listen(client.from('chat_messages').stream(primaryKey: ['id']),
        (rows) => _messages = _messageRows(rows));
    _listen(client.from('invoices').stream(primaryKey: ['id']),
        (rows) => _invoices = _invoiceRows(rows));
    _listen(client.from('kos_reviews').stream(primaryKey: ['id']),
        (rows) => _reviews = _reviewRows(rows));
    _listen(
        client
            .from('favorites')
            .stream(primaryKey: ['customer_id', 'listing_id']), (rows) {
      _favorites[userId] = rows.map((r) => r['listing_id'].toString()).toSet();
    });
  }

  void _listen(Stream<List<Map<String, dynamic>>> stream,
      void Function(List<Map<String, dynamic>>) apply) {
    _remoteSubscriptions.add(stream.listen((rows) {
      apply(rows);
      notifyListeners();
    }, onError: (Object error) {
      _switchToPolling(error);
    }));
  }

  void _switchToPolling(Object error) {
    if (_realtimeFailed) return;
    _realtimeFailed = true;
    syncNotice =
        'Realtime terputus; data tetap disinkronkan otomatis setiap 60 detik.';
    debugPrint('Supabase Realtime tidak tersedia; gunakan polling: $error');
    unawaited(_cancelRemoteSubscriptions());
    _startPollingFallback();
    notifyListeners();
  }

  void _startPollingFallback() {
    _pollingFallback ??= Timer.periodic(const Duration(seconds: 60), (_) {
      if (_pollingInProgress) return;
      if (Supabase.instance.client.auth.currentSession == null) {
        _pollingFallback?.cancel();
        _pollingFallback = null;
        return;
      }
      _pollingInProgress = true;
      unawaited(_loadSupabase().whenComplete(
          () => _pollingInProgress = false));
    });
  }

  List<KosListing> _listingRows(dynamic rows) => (rows as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .map((r) => KosListing(
            id: r['id'].toString(),
            ownerId: r['owner_id'].toString(),
            ownerName: (r['owner_name'] as String?) ?? 'Pemilik kos',
            name: r['name'] as String,
            address: r['address'] as String,
            description: (r['description'] as String?) ?? '',
            price: (r['monthly_price'] as num).toInt(),
            gender: r['gender'] as String,
            roomsTotal: (r['rooms_total'] as num).toInt(),
            roomsAvailable: (r['rooms_available'] as num).toInt(),
            amenities: List<String>.from(r['amenities'] as List? ?? const []),
            status: r['status'] as String,
            latitude: (r['latitude'] as num).toDouble(),
            longitude: (r['longitude'] as num).toDouble(),
          ))
      .toList();

  List<KosRoom> _roomRows(dynamic rows) => (rows as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .map((r) => KosRoom(
          id: r['id'].toString(),
          listingId: r['listing_id'].toString(),
          label: r['label'] as String,
          price: (r['monthly_price'] as num).toInt(),
          status: r['status'] as String))
      .toList();

  List<KosBooking> _bookingRows(dynamic rows) => (rows as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .map((r) => KosBooking(
          id: r['id'].toString(),
          listingId: r['listing_id'].toString(),
          customerId: r['customer_id'].toString(),
          customerName: (r['customer_name'] as String?) ?? 'Pengguna',
          moveIn: DateTime.parse(r['move_in'].toString()),
          createdAt: DateTime.parse(r['created_at'].toString()),
          status: r['status'] as String,
          note: (r['note'] as String?) ?? '',
          kind: (r['kind'] as String?) ?? 'booking'))
      .toList();

  List<KosChatMessage> _messageRows(dynamic rows) => (rows as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .map((r) => KosChatMessage(
          id: r['id'].toString(),
          bookingId: r['booking_id'].toString(),
          senderId: r['sender_id'].toString(),
          senderName: (r['sender_name'] as String?) ?? 'Pengguna',
          text: r['body'] as String,
          sentAt: DateTime.parse(r['sent_at'].toString())))
      .toList();

  List<KosInvoice> _invoiceRows(dynamic rows) => (rows as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .map((r) => KosInvoice(
          id: r['id'].toString(),
          bookingId: r['booking_id'].toString(),
          customerId: r['customer_id'].toString(),
          listingName: (r['listing_name'] as String?) ?? 'Kos',
          amount: (r['amount'] as num).toInt(),
          dueAt: DateTime.parse(r['due_at'].toString()),
          isPaid: r['status'] == 'paid'))
      .toList();

  List<KosReview> _reviewRows(dynamic rows) => (rows as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .map((r) => KosReview(
            id: r['id'].toString(),
            bookingId: r['booking_id'].toString(),
            listingId: r['listing_id'].toString(),
            customerId: r['customer_id'].toString(),
            customerName: (r['customer_name'] as String?) ?? 'Pengguna',
            rating: (r['rating'] as num).toInt(),
            comment: (r['comment'] as String?) ?? '',
            createdAt: DateTime.parse(r['created_at'].toString()),
          ))
      .toList();

  void _syncAllRoomCounts() {
    for (var i = 0; i < _listings.length; i++) {
      final rooms = roomsForListing(_listings[i].id);
      if (rooms.isNotEmpty) {
        _listings[i] = _listings[i].copyWith(
            roomsTotal: rooms.length,
            roomsAvailable: rooms.where((r) => r.status == 'available').length);
      }
    }
  }

  Future<void> _cancelRemoteSubscriptions() async {
    await Future.wait(_remoteSubscriptions.map((s) => s.cancel()));
    _remoteSubscriptions.clear();
  }

  void _resetSeed() {
    _listings = List<KosListing>.of(_seedListings);
    _rooms = _seedRooms;
    _bookings = [];
    _messages = [];
    _invoices = [];
    _reviews = [];
    _favorites = {};
  }

  Future<void> _save() async {
    if (isSupabaseMode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storeKey,
        jsonEncode({
          'listings': _listings.map((x) => x.toJson()).toList(),
          'rooms': _rooms.map((x) => x.toJson()).toList(),
          'bookings': _bookings.map((x) => x.toJson()).toList(),
          'messages': _messages.map((x) => x.toJson()).toList(),
          'invoices': _invoices.map((x) => x.toJson()).toList(),
          'reviews': _reviews.map((x) => x.toJson()).toList(),
          'favorites': _favorites.map((k, v) => MapEntry(k, v.toList())),
        }));
  }

  Future<void> toggleFavorite(String customerId, String listingId) async {
    final set = _favorites.putIfAbsent(customerId, () => <String>{});
    if (isSupabaseMode) {
      final client = Supabase.instance.client;
      if (set.contains(listingId)) {
        await client
            .from('favorites')
            .delete()
            .eq('customer_id', customerId)
            .eq('listing_id', listingId);
        set.remove(listingId);
      } else {
        await client
            .from('favorites')
            .upsert({'customer_id': customerId, 'listing_id': listingId});
        set.add(listingId);
      }
    } else {
      set.contains(listingId) ? set.remove(listingId) : set.add(listingId);
      await _save();
    }
    notifyListeners();
  }

  Future<void> submitReview({
    required KosBooking booking,
    required String customerName,
    required int rating,
    required String comment,
  }) async {
    if (booking.status != 'completed' || booking.kind != 'booking') {
      throw Exception('Ulasan hanya dapat diberikan setelah sewa selesai.');
    }
    if (hasReviewedBooking(booking.id)) {
      throw Exception('Booking ini sudah memiliki ulasan.');
    }
    final review = KosReview(
      id: newUuidV4(),
      bookingId: booking.id,
      listingId: booking.listingId,
      customerId: booking.customerId,
      customerName: customerName,
      rating: rating,
      comment: comment.trim(),
      createdAt: DateTime.now(),
    );
    if (isSupabaseMode) {
      await Supabase.instance.client.from('kos_reviews').insert({
        'id': review.id,
        'booking_id': review.bookingId,
        'listing_id': review.listingId,
        'customer_id': review.customerId,
        'customer_name': review.customerName,
        'rating': review.rating,
        'comment': review.comment,
      });
    }
    _reviews.add(review);
    await _save();
    notifyListeners();
  }

  Future<void> saveListing(KosListing value,
      {bool preserveStatus = false}) async {
    final index = _listings.indexWhere((x) => x.id == value.id);
    final adjusted = roomsForListing(value.id).take(value.roomsTotal).toList();
    while (adjusted.length < value.roomsTotal) {
      final n = adjusted.length + 1;
      adjusted.add(KosRoom(
          id: newUuidV4(),
          listingId: value.id,
          label: 'Kamar ${n.toString().padLeft(2, '0')}',
          price: value.price,
          status: n <= value.roomsAvailable ? 'available' : 'occupied'));
    }
    for (var i = 0; i < adjusted.length; i++) {
      adjusted[i] = adjusted[i].copyWith(
          price: value.price,
          status: i < value.roomsAvailable ? 'available' : 'occupied');
    }
    // Owner edits return a listing to moderation; only platform staff can approve it.
    final savedValue = isSupabaseMode && !preserveStatus
        ? value.copyWith(status: 'pending')
        : value;
    if (isSupabaseMode) {
      await Supabase.instance.client.from('kos_listings').upsert({
        'id': savedValue.id,
        'owner_id': savedValue.ownerId,
        'owner_name': savedValue.ownerName,
        'name': savedValue.name,
        'address': savedValue.address,
        'description': savedValue.description,
        'monthly_price': savedValue.price,
        'gender': savedValue.gender,
        'rooms_total': savedValue.roomsTotal,
        'rooms_available': savedValue.roomsAvailable,
        'amenities': savedValue.amenities,
        'status': savedValue.status,
        'latitude': savedValue.latitude,
        'longitude': savedValue.longitude,
      });
      if (adjusted.isNotEmpty) {
        await Supabase.instance.client.from('kos_rooms').upsert(adjusted
            .map((r) => {
                  'id': r.id,
                  'listing_id': r.listingId,
                  'label': r.label,
                  'monthly_price': r.price,
                  'status': r.status,
                })
            .toList());
      }
    }
    _rooms.removeWhere((x) => x.listingId == value.id);
    _rooms.addAll(adjusted);
    if (index < 0) {
      _listings.insert(0, savedValue);
    } else {
      _listings[index] = savedValue;
    }
    await _save();
    notifyListeners();
  }

  Future<void> saveRoom(KosRoom room) async {
    if (isSupabaseMode) {
      await Supabase.instance.client.from('kos_rooms').upsert({
        'id': room.id,
        'listing_id': room.listingId,
        'label': room.label,
        'monthly_price': room.price,
        'status': room.status
      });
    }
    final i = _rooms.indexWhere((x) => x.id == room.id);
    if (i < 0) {
      _rooms.add(room);
    } else {
      _rooms[i] = room;
    }
    _syncRoomCount(room.listingId);
    await _save();
    notifyListeners();
  }

  Future<void> deleteRoom(String id) async {
    final room = _rooms.where((x) => x.id == id).firstOrNull;
    if (room == null) return;
    if (isSupabaseMode) {
      await Supabase.instance.client.from('kos_rooms').delete().eq('id', id);
    }
    _rooms.removeWhere((x) => x.id == id);
    _syncRoomCount(room.listingId);
    await _save();
    notifyListeners();
  }

  void _syncRoomCount(String listingId) {
    final i = _listings.indexWhere((x) => x.id == listingId);
    if (i < 0) return;
    final rooms = roomsForListing(listingId);
    _listings[i] = _listings[i].copyWith(
        roomsTotal: rooms.length,
        roomsAvailable: rooms.where((x) => x.status == 'available').length);
  }

  Future<void> deleteListing(String id) async {
    if (isSupabaseMode) {
      await Supabase.instance.client.from('kos_listings').delete().eq('id', id);
    }
    _listings.removeWhere((x) => x.id == id);
    _rooms.removeWhere((x) => x.listingId == id);
    for (final set in _favorites.values) {
      set.remove(id);
    }
    await _save();
    notifyListeners();
  }

  Future<void> reviewListing(String id, bool approve) async {
    final i = _listings.indexWhere((x) => x.id == id);
    if (i < 0) return;
    if (isSupabaseMode) {
      await Supabase.instance.client
          .from('kos_listings')
          .update({'status': approve ? 'approved' : 'rejected'}).eq('id', id);
    }
    _listings[i] =
        _listings[i].copyWith(status: approve ? 'approved' : 'rejected');
    await _save();
    notifyListeners();
  }

  Future<void> setBookingStatus(String id, String status) async {
    final i = _bookings.indexWhere((x) => x.id == id);
    if (i < 0) return;
    final booking = _bookings[i];
    KosRoom? assignedRoom;
    if (isSupabaseMode) {
      if (status == 'accepted' && booking.kind == 'booking') {
        assignedRoom = roomsForListing(booking.listingId)
            .where((room) => room.status == 'available')
            .firstOrNull;
        await Supabase.instance.client
            .rpc('accept_kos_booking', params: {'p_booking_id': id});
      } else {
        await Supabase.instance.client
            .from('bookings')
            .update({'status': status}).eq('id', id);
      }
    }
    _bookings[i] = booking.copyWith(status: status);
    if (status == 'accepted' && booking.kind == 'booking') {
      if (assignedRoom != null) {
        final roomIndex = _rooms.indexWhere((r) => r.id == assignedRoom!.id);
        if (roomIndex >= 0) {
          _rooms[roomIndex] = _rooms[roomIndex].copyWith(status: 'occupied');
          _syncRoomCount(booking.listingId);
        }
      } else if (!isSupabaseMode) {
        final roomIndex = _rooms.indexWhere(
            (r) => r.listingId == booking.listingId && r.status == 'available');
        if (roomIndex >= 0) {
          _rooms[roomIndex] = _rooms[roomIndex].copyWith(status: 'occupied');
          _syncRoomCount(booking.listingId);
        }
      }
    }
    if (!isSupabaseMode &&
        status == 'accepted' &&
        booking.kind == 'booking' &&
        !_invoices.any((x) => x.bookingId == id)) {
      final place = listing(booking.listingId);
      if (place != null) {
        _invoices.add(KosInvoice(
            id: 'inv-${DateTime.now().microsecondsSinceEpoch}',
            bookingId: id,
            customerId: booking.customerId,
            listingName: place.name,
            amount: place.price,
            dueAt: DateTime.now().add(const Duration(days: 30)),
            isPaid: false));
      }
    }
    await _save();
    notifyListeners();
  }

  Future<void> markInvoicePaid(String id) async {
    final i = _invoices.indexWhere((x) => x.id == id);
    if (i < 0) return;
    if (isSupabaseMode) {
      await Supabase.instance.client
          .rpc('mark_demo_invoice_paid', params: {'p_invoice_id': id});
    }
    _invoices[i] = _invoices[i].copyWith(isPaid: true);
    await _save();
    notifyListeners();
  }

  Future<void> sendMessage(
      {required String bookingId,
      required String senderId,
      required String senderName,
      required String text}) async {
    final value = text.trim();
    if (value.isEmpty) return;
    final message = KosChatMessage(
        id: newUuidV4(),
        bookingId: bookingId,
        senderId: senderId,
        senderName: senderName,
        text: value,
        sentAt: DateTime.now());
    if (isSupabaseMode) {
      await Supabase.instance.client.from('chat_messages').insert({
        'id': message.id,
        'booking_id': bookingId,
        'sender_id': senderId,
        'sender_name': senderName,
        'body': value,
        'sent_at': message.sentAt.toIso8601String()
      });
    }
    _messages.add(message);
    await _save();
    notifyListeners();
  }

  Future<KosBooking> createBooking(
      {required String listingId,
      required String customerId,
      required String customerName,
      required DateTime moveIn,
      required String note,
      required String kind}) async {
    final now = DateTime.now();
    final booking = KosBooking(
        id: newUuidV4(),
        listingId: listingId,
        customerId: customerId,
        customerName: customerName,
        moveIn: moveIn,
        createdAt: now,
        status: 'pending',
        note: note,
        kind: kind);
    if (isSupabaseMode) {
      await Supabase.instance.client.from('bookings').insert({
        'id': booking.id,
        'listing_id': listingId,
        'customer_id': customerId,
        'customer_name': customerName,
        'move_in': moveIn.toIso8601String().split('T').first,
        'created_at': now.toIso8601String(),
        'status': 'pending',
        'note': note,
        'kind': kind
      });
    }
    _bookings.insert(0, booking);
    await _save();
    notifyListeners();
    return booking;
  }

  @override
  void dispose() {
    _pollingFallback?.cancel();
    unawaited(_cancelRemoteSubscriptions());
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }

  static List<KosRoom> get _seedRooms => _makeRooms(_seedListings);
  static List<KosRoom> _makeRooms(List<KosListing> listings) => [
        for (final place in listings)
          for (var i = 1; i <= place.roomsTotal; i++)
            KosRoom(
                id: 'room-${place.id}-$i',
                listingId: place.id,
                label: 'Kamar ${i.toString().padLeft(2, '0')}',
                price: place.price,
                status: i <= place.roomsAvailable ? 'available' : 'occupied'),
      ];

  static const _seedListings = <KosListing>[
    KosListing(
        id: 'kos-101',
        ownerId: 'owner-001',
        ownerName: 'Pemilik Demo',
        name: 'Kost Rumah Padi',
        address: 'Koto Tangah, Padang • 1,2 km dari kampus',
        description:
            'Hunian nyaman dengan suasana tenang, akses mudah ke kampus dan pusat kuliner.',
        price: 850000,
        gender: 'Putri',
        roomsTotal: 12,
        roomsAvailable: 3,
        amenities: ['Wi-Fi', 'Kamar mandi dalam', 'Parkir motor'],
        status: 'approved',
        latitude: -0.897,
        longitude: 100.353),
    KosListing(
        id: 'kos-102',
        ownerId: 'owner-001',
        ownerName: 'Pemilik Demo',
        name: 'Griya Andalas Residence',
        address: 'Padang Timur, dekat pusat kota',
        description:
            'Kamar bersih dan terang di lingkungan aman, cocok untuk mahasiswa dan pekerja.',
        price: 1200000,
        gender: 'Putra',
        roomsTotal: 10,
        roomsAvailable: 2,
        amenities: ['Wi-Fi', 'AC', 'Dapur bersama'],
        status: 'approved',
        latitude: -0.923,
        longitude: 100.367),
    KosListing(
        id: 'kos-103',
        ownerId: 'owner-002',
        ownerName: 'Mitra Kos Padang',
        name: 'Pondok Rantau Nyaman',
        address: 'Kuranji, Padang • lingkungan tenang',
        description:
            'Pilihan hemat dengan fasilitas dasar dan akses transportasi yang mudah.',
        price: 700000,
        gender: 'Campur',
        roomsTotal: 8,
        roomsAvailable: 4,
        amenities: ['Parkir motor', 'Dapur bersama'],
        status: 'approved',
        latitude: -0.914,
        longitude: 100.411),
    KosListing(
        id: 'kos-104',
        ownerId: 'owner-002',
        ownerName: 'Mitra Kos Padang',
        name: 'Kos Pelangi',
        address: 'Lubuk Begalung, Padang',
        description: 'Kamar berperabot dengan area bersama yang nyaman.',
        price: 950000,
        gender: 'Putri',
        roomsTotal: 9,
        roomsAvailable: 1,
        amenities: ['Wi-Fi', 'Kasur', 'Lemari'],
        status: 'approved',
        latitude: -0.967,
        longitude: 100.397),
  ];
}
