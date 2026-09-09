part of '../main.dart';

enum UserRole { landlord, boarder }

class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.birthday,
    required this.gender,
    required this.contact,
    required this.address,
    required this.password,
    required this.role,
  });

  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String birthday;
  final String gender;
  final String contact;
  final String address;
  final String password;
  final UserRole role;

  String get fullName => [firstName, middleName, lastName]
      .where((part) => part.trim().isNotEmpty)
      .join(' ');

  String get roleLabel => role == UserRole.boarder ? 'Boarder' : 'Landowner';
}

enum AppPage {
  auth,
  landlordDashboard,
  editListing,
  roomWizard,
  boarderHome,
  favorites,
  listing,
  profile,
  editProfile,
}
