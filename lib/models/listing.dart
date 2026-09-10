part of '../main.dart';

class Listing {
  Listing({
    required this.title,
    required this.address,
    required this.price,
    required this.image,
    String? id,
    List<String> amenities = const [],
    this.description = '',
    this.contact = '',
    this.availableRooms = 0,
    this.totalRooms = 0,
    this.views = 0,
    this.averageRating = 0,
    this.reviewCount = 0,
    this.available = true,
  }) : id = id ?? 'listing-${_nextId++}',
       amenities = List.unmodifiable(amenities);
  static int _nextId = 0;
  final String id;
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
