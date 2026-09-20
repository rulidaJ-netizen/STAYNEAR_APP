# Landowner dashboard and listing editor

The active pages are `lib/landowner/landownerDashboard.dart` and
`lib/landowner/editListing.dart`. They retain the public `LandlordDashboard`
and `EditListingPage` classes and the existing Dart `part` / `AppPage` routing.
There is one Landowner directory, `lib/landowner/`. Old file references were
removed from source and updated in the earlier validation document.

The dashboard reads `ListingStore.forOwner(activeUser.id)` and listens to store
changes. Publishing attaches the authenticated account's stable ID. Cards,
editing, and deletion carry the selected listing ID. Statistics aggregate the
owner's listings; available-room totals exclude listings marked unavailable,
consistent with the existing shared details screen.

Editing keeps controllers, status, and four photo slots in a draft. It reuses
`ListingPhotoPicker`, `Photo`, and the existing dashed photo border. Save validates
the form and updates the existing record through `updateOwnedListing`; Cancel
discards the draft. The store retains current reviews, views, room totals,
amenities, billing information, coordinates, and map/distance references. Photos
replace the saved photo collection and its cover together. Deleted or
foreign-owned records cannot be updated through the owner-save operation.

Boarder layouts and callbacks are preserved. Shared details accept additional
information so the owner view can display the saved view count using its existing
information rows. Search, Favorites, details, and the owner dashboard all use the
same store. The Add Room wizard and Profile flow retain their existing screens.

## Validation

- Twenty focused tests pass across `landowner_listing_test.dart`,
  `boarder_dashboard_test.dart`, and `listing_store_test.dart`.
- Covered ownership filtering, multiple listings, independent card actions,
  exact-record navigation, Save/Cancel, validation, failed-save retry, photo
  replacement/removal, preserved metadata, and Boarder synchronization.
- Dashboard/editor layout checks pass at 320, 390, and 430 pixels, including
  enlarged text and the editor keyboard scenario.
- Rendered previews were inspected at `build/landowner-dashboard-preview.png`
  and `build/landowner-edit-preview.png`. The previews use test property data;
  production screens display the owner's actual records.
- The full suite passed 88 tests and reported the four existing wizard failures
  below. These tests instantiate `RoomWizard` directly and do not exercise the
  changed `_AddRoomFlow` publication binding.
- `flutter analyze` reports no errors or warnings and one existing informational
  lint: `use_null_aware_elements` in
  `test/full_boardinghouse_details_test.dart:63`. Its default exit status is 1
  because informational findings are fatal by default.
- Flutter generated the release web application in `build/web`.

### Existing wizard test failures

| File | Test | Finding |
| --- | --- | --- |
| `test/add_room_steps_test.dart` | four photo slots validate, preview, remove, retain, and publish every field | `pumpAndSettle` waits for the continuously animated photo-picker progress indicator. |
| `test/add_room_steps_test.dart` | picker cancel, permission error and late completion preserve drafts safely | Same photo-picker wait. |
| `test/add_room_steps_test.dart` | step 2 fits small screens with large text and keyboard | Existing upload-step overflow at 320 pixels with doubled text. |
| `test/full_boardinghouse_details_test.dart` | published owner contact, map pin and distance reach shared listing data | Same wizard photo-picker wait. |

Logs are in `build/landowner-focused-final.log`, `build/full-regression.log`,
`build/landowner-analyze.log`, and `build/landowner-web-build.log`.

## Storage and persistence

Listings persist in Cloud Firestore and flow through the shared realtime
`ListingStore`. Listing and profile images persist in Supabase Storage; Firestore
stores their public URLs only.
