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
    this.password = '',
    required this.role,
    this.profilePhoto,
    this.displayName,
    this.accountId,
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
  final String? profilePhoto, displayName, accountId;
  String get id => accountId ?? '${role.name}:${email.trim().toLowerCase()}';

  String get fullName =>
      displayName ??
      [
        firstName,
        middleName,
        lastName,
      ].where((part) => part.trim().isNotEmpty).join(' ');

  String get roleLabel => role == UserRole.boarder ? 'Boarder' : 'Landowner';

  UserProfile withProfileEdits({
    required String fullName,
    required String phone,
    required String email,
    required String address,
    String? photo,
  }) => UserProfile(
    firstName: firstName,
    middleName: middleName,
    lastName: lastName,
    displayName: fullName.trim(),
    email: email.trim(),
    contact: phone.trim(),
    address: address.trim(),
    profilePhoto: photo ?? profilePhoto,
    birthday: birthday,
    gender: gender,
    role: role,
    accountId: id,
  );
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
