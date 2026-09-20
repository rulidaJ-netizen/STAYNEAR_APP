# Boarder dashboard changes

The Search/Home screen is defined only by `BoarderDashboard` in
`lib/screens/boarder/boarderDashboard.dart`. The former `BoarderHome` and its
dashboard-only helpers were removed from `boarder_pages.dart`. The existing
Dart `part` organization and `AppPage` routes are retained.

## Files changed

| Files | Purpose |
| --- | --- |
| `lib/screens/boarder/boarderDashboard.dart` | Extracted dashboard, responsive header and search layout, horizontally scrolling amenity chips, result count, clear filters, lazy property list and empty state. |
| `lib/screens/boarder/boarder_pages.dart` | Shared property cards, existing Favorites and Property Details screens; removed the old dashboard. |
| `lib/main.dart`, `lib/app.dart` | Register the dashboard and shared store; wire owner publishing/editing/deleting and selection by property ID to the existing routes. |
| `lib/models/listing.dart`, `lib/models/listing_store.dart` | Stable session IDs, amenities, description/contact fields, normalized search, shared property collection and favorite IDs. |
| `lib/widgets/auth_widgets.dart` | Optional role label on the existing logo; its default branding remains unchanged. |
| `lib/screens/profile/profile_pages.dart` | Update the shared bottom navigation and Photo widget defined in this file; Profile screens retain their existing design. |
| `lib/widgets/listing_image_io.dart`, `lib/widgets/listing_image_stub.dart` | Local image support on Android/desktop with a compatible web fallback. |
| `lib/landowner/addRoom.dart`, `lib/landowner/landownerDashboard.dart`, `lib/landowner/editListing.dart` | Save selected amenities, descriptions and contact data; preserve IDs and amenities on edits. The dashboard and editor use the shared listing store. |
| `android/app/src/main/AndroidManifest.xml` | Internet permission for uploaded network images in Android builds. |
| `test/listing_store_test.dart`, `test/boarder_dashboard_test.dart` | Regression coverage for data, interactions, navigation, images and layouts. |

The user's pre-existing changes to `lib/screens/auth/auth_page.dart` were preserved.

## Behavior

- Search matches partial names, addresses, descriptions and amenities, ignoring
  case and extra whitespace. WiFi and Wi-Fi also match. Text search combines
  with **all** selected amenities without changing the source collection.
- Favorites are stored once, by property ID, and immediately update Search,
  Favorites and Details. Editing a listing preserves its identity. Hearts do
  not open Details; card taps open the selected property. Details returns to
  the originating Search or Favorites page.
- Owner publishing and editing feed the same collection. Screenshot sample
  listings are used only until the first real listing is published.
- Listings and favorites use the existing app's in-memory session approach.
  Navigation preserves favorites; restarting the app does not persist them.
- Cards show real prices, availability, ratings, reviews, locations and images.
  Network, asset, local-file and data images have a safe fallback on failure.

## Validation

- `dart format .` ran; unrelated formatting changes were removed and the
  user's existing auth edits were restored byte for byte.
- `flutter analyze --no-pub`: no issues found.
- `flutter test --no-pub`: 10 tests, covering live keyword/location search,
  combined amenities, horizontal and vertical scrolling, clear/empty results,
  synchronized favorites, exact Details/Profile navigation, owner updates,
  decoded images and safe image failures.
- Layout coverage includes 390×844 and 320×568, enlarged text, and keyboard
  insets. The tested flows produce no overflow or framework exceptions.
- `flutter build bundle --debug --no-pub --target-platform android-arm64`
  succeeded.

## Remaining verification limits

- `flutter build apk --debug --no-pub` failed during native toolchain setup:
  NDK `28.2.13676358` is absent and the SDK installer failed. A direct install
  attempt also failed with `No url for ndk`. The project's Android build
  configuration was left intact.
- Device discovery found no Android device or configured emulator, so an
  Android runtime test could not be performed.
- The attachment contains text instructions only. The UI follows that written
  reference; exact screenshot comparison remains unverified.
