part of '../main.dart';

class Listing {
  Listing({
    required this.title,
    required this.address,
    required this.price,
    required this.image,
    this.availableRooms = 0,
    this.totalRooms = 0,
    this.views = 0,
    this.averageRating = 0,
    this.reviewCount = 0,
    this.available = true,
  });
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
}
