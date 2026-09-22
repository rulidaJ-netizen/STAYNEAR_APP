part of '../main.dart';

class Listing {
  Listing({
    required this.title,
    required this.address,
    required this.price,
    required this.image,
    String? id,
    this.ownerId,
    List<String> amenities = const [],
    this.description = '',
    this.contact = '',
    this.availableRooms = 0,
    this.totalRooms = 0,
    this.views = 0,
    this.averageRating = 0,
    this.reviewCount = 0,
    this.available = true,
    List<String> photos = const [],
    this.latitude,
    this.longitude,
    this.billingInfo = '',
    Map<String, String> houseInformation = const {},
  }) : id =
           id ??
           'listing-${DateTime.now().microsecondsSinceEpoch}-${_nextId++}',
       amenities = List.unmodifiable(amenities),
       photos = List.unmodifiable({
         if (image != null && image.trim().isNotEmpty) image.trim(),
         ...photos
             .map((photo) => photo.trim())
             .where((photo) => photo.isNotEmpty),
       }),
       houseInformation = Map.unmodifiable(houseInformation);
  static int _nextId = 0;
  final String id;
  final String? ownerId;
  final String title;
  final String address;
  final int price;
  final String? image;
  final int availableRooms;
  final int totalRooms;
  final int views;
  final double averageRating;
  final int reviewCount;
  final bool available;
  final List<String> amenities;
  final String description;
  final String contact;
  final List<String> photos;
  final double? latitude, longitude;
  final String billingInfo;
  final Map<String, String> houseInformation;

  Listing withRating(double average, int count) => Listing(
    id: id,
    ownerId: ownerId,
    title: title,
    address: address,
    price: price,
    image: image,
    availableRooms: availableRooms,
    totalRooms: totalRooms,
    views: views,
    averageRating: average,
    reviewCount: count,
    available: available,
    amenities: amenities,
    description: description,
    contact: contact,
    photos: photos,
    latitude: latitude,
    longitude: longitude,
    billingInfo: billingInfo,
    houseInformation: houseInformation,
  );

  /// Copies editable values while retaining the record's other property data.
  /// Supplying photos also updates the cover, including removing the last photo.
  Listing copyWith({
    String? ownerId,
    String? title,
    String? address,
    int? price,
    int? availableRooms,
    bool? available,
    List<String>? photos,
    String? description,
    String? contact,
    Map<String, String>? houseInformation,
  }) => Listing(
    id: id,
    ownerId: ownerId ?? this.ownerId,
    title: title ?? this.title,
    address: address ?? this.address,
    price: price ?? this.price,
    image: photos == null ? image : photos.firstOrNull,
    photos: photos ?? this.photos,
    availableRooms: availableRooms ?? this.availableRooms,
    totalRooms: totalRooms,
    available: available ?? this.available,
    views: views,
    averageRating: averageRating,
    reviewCount: reviewCount,
    amenities: amenities,
    description: description ?? this.description,
    contact: contact ?? this.contact,
    latitude: latitude,
    longitude: longitude,
    billingInfo: billingInfo,
    houseInformation: houseInformation ?? this.houseInformation,
  );

  String get formattedPrice => price.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );

  bool matches(String query, Set<String> selectedAmenities) {
    final normalizedAmenities = amenities.map(normalizeListingText).toSet();
    final searchableText = normalizeListingText(
      '$title $address $description ${amenities.join(' ')}',
    );
    return searchableText.contains(normalizeListingText(query)) &&
        selectedAmenities.every(
          (amenity) =>
              normalizedAmenities.contains(normalizeListingText(amenity)),
        );
  }
}

String normalizeListingText(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'wi[\s-]*fi'), 'wifi')
    .replaceAll(RegExp(r'\s+'), ' ');
