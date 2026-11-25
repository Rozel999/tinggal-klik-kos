import 'dart:math';

String newUuidV4() {
  final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class KosListing {
  const KosListing(
      {required this.id,
      required this.ownerId,
      required this.ownerName,
      required this.name,
      required this.address,
      required this.description,
      required this.price,
      required this.gender,
      required this.roomsTotal,
      required this.roomsAvailable,
      required this.amenities,
      required this.status,
      required this.latitude,
      required this.longitude});
  final String id,
      ownerId,
      ownerName,
      name,
      address,
      description,
      gender,
      status;
  final int price, roomsTotal, roomsAvailable;
  final List<String> amenities;
  final double latitude, longitude;
  bool get isApproved => status == 'approved';
  KosListing copyWith(
          {String? name,
          String? address,
          String? description,
          int? price,
          String? gender,
          int? roomsTotal,
          int? roomsAvailable,
          List<String>? amenities,
          String? status}) =>
      KosListing(
          id: id,
          ownerId: ownerId,
          ownerName: ownerName,
          name: name ?? this.name,
          address: address ?? this.address,
          description: description ?? this.description,
          price: price ?? this.price,
          gender: gender ?? this.gender,
          roomsTotal: roomsTotal ?? this.roomsTotal,
          roomsAvailable: roomsAvailable ?? this.roomsAvailable,
          amenities: amenities ?? this.amenities,
          status: status ?? this.status,
          latitude: latitude,
          longitude: longitude);
  Map<String, Object?> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'name': name,
        'address': address,
        'description': description,
        'price': price,
        'gender': gender,
        'roomsTotal': roomsTotal,
        'roomsAvailable': roomsAvailable,
        'amenities': amenities,
        'status': status,
        'latitude': latitude,
        'longitude': longitude
      };
  factory KosListing.fromJson(Map<String, dynamic> j) => KosListing(
      id: j['id'] as String,
      ownerId: j['ownerId'] as String,
      ownerName: j['ownerName'] as String,
      name: j['name'] as String,
      address: j['address'] as String,
      description: j['description'] as String,
      price: (j['price'] as num).toInt(),
      gender: j['gender'] as String,
      roomsTotal: (j['roomsTotal'] as num).toInt(),
      roomsAvailable: (j['roomsAvailable'] as num).toInt(),
      amenities: (j['amenities'] as List).cast<String>(),
      status: j['status'] as String,
      latitude: (j['latitude'] as num).toDouble(),
      longitude: (j['longitude'] as num).toDouble());
}

class KosBooking {
  const KosBooking(
      {required this.id,
      required this.listingId,
      required this.customerId,
      required this.customerName,
      required this.moveIn,
      required this.createdAt,
      required this.status,
      required this.note,
      required this.kind});
  final String id, listingId, customerId, customerName, status, note, kind;
  final DateTime moveIn, createdAt;
  Map<String, Object?> toJson() => {
        'id': id,
        'listingId': listingId,
        'customerId': customerId,
        'customerName': customerName,
        'moveIn': moveIn.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        'note': note,
        'kind': kind
      };
  factory KosBooking.fromJson(Map<String, dynamic> j) => KosBooking(
      id: j['id'] as String,
      listingId: j['listingId'] as String,
      customerId: j['customerId'] as String,
      customerName: j['customerName'] as String,
      moveIn: DateTime.parse(j['moveIn'] as String),
      createdAt: DateTime.parse(j['createdAt'] as String),
      status: j['status'] as String,
      note: j['note'] as String,
      kind: j['kind'] as String? ?? 'booking');
  KosBooking copyWith({String? status}) => KosBooking(
      id: id,
      listingId: listingId,
      customerId: customerId,
      customerName: customerName,
      moveIn: moveIn,
      createdAt: createdAt,
      status: status ?? this.status,
      note: note,
      kind: kind);
}

class KosChatMessage {
  const KosChatMessage(
      {required this.id,
      required this.bookingId,
      required this.senderId,
      required this.senderName,
      required this.text,
      required this.sentAt});
  final String id, bookingId, senderId, senderName, text;
  final DateTime sentAt;
  Map<String, Object?> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'sentAt': sentAt.toIso8601String()
      };
  factory KosChatMessage.fromJson(Map<String, dynamic> j) => KosChatMessage(
      id: j['id'] as String,
      bookingId: j['bookingId'] as String,
      senderId: j['senderId'] as String,
      senderName: j['senderName'] as String,
      text: j['text'] as String,
      sentAt: DateTime.parse(j['sentAt'] as String));
}

class KosInvoice {
  const KosInvoice(
      {required this.id,
      required this.bookingId,
      required this.customerId,
      required this.listingName,
      required this.amount,
      required this.dueAt,
      required this.isPaid});
  final String id, bookingId, customerId, listingName;
  final int amount;
  final DateTime dueAt;
  final bool isPaid;
  Map<String, Object?> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'customerId': customerId,
        'listingName': listingName,
        'amount': amount,
        'dueAt': dueAt.toIso8601String(),
        'isPaid': isPaid
      };
  factory KosInvoice.fromJson(Map<String, dynamic> j) => KosInvoice(
      id: j['id'] as String,
      bookingId: j['bookingId'] as String,
      customerId: j['customerId'] as String,
      listingName: j['listingName'] as String,
      amount: (j['amount'] as num).toInt(),
      dueAt: DateTime.parse(j['dueAt'] as String),
      isPaid: j['isPaid'] as bool);
  KosInvoice copyWith({bool? isPaid}) => KosInvoice(
      id: id,
      bookingId: bookingId,
      customerId: customerId,
      listingName: listingName,
      amount: amount,
      dueAt: dueAt,
      isPaid: isPaid ?? this.isPaid);
}

class KosReview {
  const KosReview({
    required this.id,
    required this.bookingId,
    required this.listingId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id, bookingId, listingId, customerId, customerName, comment;
  final int rating;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'listingId': listingId,
        'customerId': customerId,
        'customerName': customerName,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };

  factory KosReview.fromJson(Map<String, dynamic> json) => KosReview(
        id: json['id'] as String,
        bookingId: json['bookingId'] as String,
        listingId: json['listingId'] as String,
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        rating: (json['rating'] as num).toInt(),
        comment: json['comment'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class KosRoom {
  const KosRoom(
      {required this.id,
      required this.listingId,
      required this.label,
      required this.price,
      required this.status});
  final String id, listingId, label, status;
  final int price;
  Map<String, Object?> toJson() => {
        'id': id,
        'listingId': listingId,
        'label': label,
        'price': price,
        'status': status
      };
  factory KosRoom.fromJson(Map<String, dynamic> j) => KosRoom(
      id: j['id'] as String,
      listingId: j['listingId'] as String,
      label: j['label'] as String,
      price: (j['price'] as num).toInt(),
      status: j['status'] as String);
  KosRoom copyWith({String? label, int? price, String? status}) => KosRoom(
      id: id,
      listingId: listingId,
      label: label ?? this.label,
      price: price ?? this.price,
      status: status ?? this.status);
}
