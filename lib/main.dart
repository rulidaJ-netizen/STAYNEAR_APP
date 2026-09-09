import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

part 'core/constants/app_constants.dart';
part 'models/app_models.dart';
part 'models/listing.dart';
part 'app.dart';
part 'widgets/common_widgets.dart';
part 'widgets/auth_widgets.dart';
part 'screens/auth/auth_page.dart';
part 'screens/landowner/landowner_pages.dart';
part 'screens/landowner/room_wizard.dart';
part 'screens/boarder/boarder_pages.dart';
part 'screens/profile/profile_pages.dart';

void main() => runApp(const StayNearApp());
