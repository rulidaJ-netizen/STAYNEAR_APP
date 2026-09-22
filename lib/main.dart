import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'firebase_options.dart';

import 'services/property_location.dart';

import 'widgets/listing_image_stub.dart'
    if (dart.library.io) 'widgets/listing_image_io.dart';

part 'core/constants/app_constants.dart';
part 'models/app_models.dart';
part 'models/listing.dart';
part 'models/listing_store.dart';
part 'models/property_review.dart';
part 'models/profile_storage.dart';
part 'services/supabase_storage_service.dart';
part 'services/firebase_backend.dart';
part 'app.dart';
part 'widgets/common_widgets.dart';
part 'widgets/auth_widgets.dart';
part 'screens/auth/auth_page.dart';
part 'landowner/landownerDashboard.dart';
part 'landowner/editListing.dart';
part 'landowner/landownerProfile.dart';
part 'landowner/landownerEditProfile.dart';
part 'landowner/landowner_profile_avatar.dart';
part 'landowner/addRoom.dart';
part 'landowner/uploadPhotos.dart';
part 'landowner/pricingANDavailability.dart';
part 'landowner/locationDetails.dart';
part 'landowner/add_room_widgets.dart';
part 'screens/boarder/boarderDashboard.dart';
part 'screens/boarder/favoriteList.dart';
part 'screens/boarder/boarder_pages.dart';
part 'screens/boarder/fullBoardinghouseDetails.dart';
part 'screens/boarder/editProfile.dart';
part 'widgets/profile_avatar.dart';
part 'screens/profile/profile_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? initializationError;
  try {
    await initializeStayNearFirebase();
    await initializeStayNearSupabase();
  } catch (error) {
    debugPrint('BACKEND INITIALIZATION ERROR: $error');
    initializationError = error;
  }
  runApp(StayNearApp(initializationError: initializationError));
}

Future<void> initializeStayNearFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  const emulatorHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
  if (emulatorHost.isNotEmpty && kReleaseMode) {
    throw StateError('Emulators are for debug builds only.');
  }
  await Firebase.initializeApp(
    options: emulatorHost.isEmpty
        ? DefaultFirebaseOptions.currentPlatform
        : const FirebaseOptions(
            apiKey: 'demo-staynear-emulator-key',
            appId: '1:1234567890:web:staynear-emulator',
            messagingSenderId: '1234567890',
            projectId: 'demo-staynear',
            storageBucket: 'demo-staynear.appspot.com',
          ),
  );
  if (emulatorHost.isNotEmpty) {
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }
}

Future<void> initializeStayNearSupabase() async {
  await Supabase.initialize(
    url: 'https://drlaskltdvphtkjualvx.supabase.co',
    publishableKey: 'sb_publishable_jf0OkJS77F19NUOBkrcgeg_xNggWtlh',
  );
}
