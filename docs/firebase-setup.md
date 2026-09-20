# StayNear Firebase and Supabase integration

The app uses Firebase Authentication, Cloud Firestore and Supabase Storage. The
existing screens and navigation remain in place. FlutterFire is configured for
the live Firebase project `staynear-58ae7`. Firestore rules and indexes are
deployed. Images are not stored in Firebase Storage.

## Run locally without a Firebase account

Install Flutter, Node.js 22 or 24, and Java 21+. Android Studio's bundled Java can
be used. From the repository root in PowerShell:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
Set-Location tool/firebase
npm ci
npm start
```

Leave that terminal running. In a second terminal at the repository root:

```powershell
flutter pub get
flutter run -d chrome --web-port 7357 --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1
```

Open the Emulator UI at `http://127.0.0.1:4000` to inspect Auth users, Firestore
records and Functions logs. Register your own test Boarder and Landowner accounts
in the app. There are no built-in accounts, listings or fabricated ratings.
Registration returns to Login, as in the existing app. One email identifies one
Firebase account, so use different emails for the two roles.

`npm start` imports/exports `.firebase/emulator-data` when stopped normally with
Ctrl+C. This preserves emulator records between runs. Restarting the app preserves
its Auth session; restarting the emulators without exported data does not.
Emulated password reset and email verification links appear in the emulator
terminal; the emulators do not deliver email to real inboxes.

For an installed Android emulator, use:

```powershell
flutter run -d <android-device-id> --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2
```

For a USB-connected Android phone, keep the services on localhost and forward
their ports instead of exposing them to the network:

```powershell
adb reverse tcp:9099 tcp:9099
adb reverse tcp:8080 tcp:8080
flutter run -d <phone-id> --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1
```

Emulator mode is explicitly enabled by the build flag and rejected in release
builds. Its `demo-staynear` identifiers only target the local Emulator Suite.
Android permits emulator HTTP traffic only in the debug manifest.

## Live Firebase project

1. Open the [StayNear Firebase project](https://console.firebase.google.com/project/staynear-58ae7/overview).
2. Enable **Authentication > Sign-in method > Email/Password**.
3. The default **Cloud Firestore** database already exists. Configure the
   Supabase `staynear-images` bucket and deploy the `storage-authorize` Edge
   Function as described below. Firebase Cloud Functions and the Blaze plan are
   not required for image uploads.
4. Android **com.example.stay_near**, Web and iOS **com.example.stayNear** are
   registered already.
5. To regenerate the configuration later, authenticate the Firebase CLI, install
   FlutterFire CLI, add its executable directory to the current PowerShell
   session, and run this from the repository root:

   ```powershell
   .\tool\firebase\node_modules\.bin\firebase.cmd login
   dart pub global activate flutterfire_cli
   $env:PATH = "$env:LOCALAPPDATA\Pub\Cache\bin;$(Get-Location)\tool\firebase\node_modules\.bin;$env:PATH"
   flutterfire configure --project=staynear-58ae7 --platforms=android,web,ios --yes
   ```

   `flutterfire configure` replaces `lib/firebase_options.dart` with the actual
   platform options. It also configures the native Firebase files as applicable.
   There is one initialization point in `main.dart`; do not add another.
   See [Firebase's Flutter setup](https://firebase.google.com/docs/flutter/setup).
6. Run/build without `FIREBASE_EMULATOR_HOST`, and perform the live checklist
   below. Complete production signing separately before distributing a release.

The checked-in `firebase_options.dart` contains FlutterFire-generated Web,
Android and iOS client options for `staynear-58ae7`.
Never put an Admin SDK/service-account key in a client app.

## Supabase image-upload authorization

Image uploads do not require Firebase Cloud Functions or a Firebase custom
claim. The Flutter app sends its Firebase ID token to the Supabase
`storage-authorize` Edge Function. The function verifies the token's signature,
issuer and audience against Firebase, checks that the requested path contains
the verified Firebase UID, and returns a short-lived signed Supabase upload
token. Deletes pass through the same ownership check.

Authenticate the Supabase CLI through `npx`, link this repository, apply the
bucket migration, and deploy the function:

```powershell
npx supabase login
npx supabase link --project-ref drlaskltdvphtkjualvx
npx supabase db push
npx supabase functions deploy storage-authorize --no-verify-jwt
```

Alternatively, run
`supabase/migrations/20260916000000_configure_staynear_images.sql` in the
Supabase SQL Editor, then create/deploy a dashboard Edge Function named
`storage-authorize` using `supabase/functions/storage-authorize/index.ts` and
disable the platform JWT check for that function. The function performs its own
strict Firebase JWT verification; disabling the platform check is necessary
because the token is issued by Firebase rather than Supabase Auth.

Supabase Third-Party Auth does not need to be enabled for this flow. The normal
Supabase client uses only the publishable key, while the Firebase token is sent
solely to the Edge Function and verified there.

The `staynear-images` bucket is public only so listing and profile images can be
rendered from their public URLs. Upload and delete access is not public: those
operations require the signed token or the verified Edge Function respectively.

## Persistence and behavior

| Data | Location / behavior |
| --- | --- |
| Accounts and passwords | Firebase Auth; no passwords in Firestore |
| Profiles | `users/{authUid}`; roles are `boarder` / `landowner` |
| Profile photos | Supabase `profiles/{authUid}/{uniqueId}`; URL stored on profile |
| Listings | `listings/{listingId}`; `landownerId` is the Auth UID |
| Listing photos | Supabase `listings/{ownerUid}/{uniqueId}`; at most four |
| Favorites | `users/{boarderUid}/favorites/{listingId}` |
| Reviews | `listings/{listingId}/reviews/{reviewId}`; Boarder authorship enforced |
| Ratings | Computed from streamed reviews, not client-writable aggregates |
| Views | Atomic increment when a Boarder opens a listing, once per app session |
| Location | Listing coordinates and saved map reference; university distance optional |

Firebase feeds the existing `ListingStore` / `ChangeNotifier`. Landowners query
their own listings, while Boarder Search displays available records. The details,
favorites and dashboard respond to the same streams. Session changes clear all
account data and cancel old listeners.

Profile email edits send a verification link using `verifyBeforeUpdateEmail`.
The saved/sign-in email remains the old address until verification completes;
sign in again with the verified new email to synchronize it to the profile.
Other profile edits and the uploaded photo save normally. Recent-login errors
appear through the existing feedback.

Uploads finish before Firestore saves their URLs. Failed writes clean up newly
uploaded files where possible. Removed photos are deleted after a successful
edit. Deletes mark a listing as deleting, clean up its reviews/photos, then remove
the parent. A failed review cleanup can be retried by the owner from the dashboard.
Storage deletion is best effort: network failures can leave an unused image for
later administrative cleanup. Other accounts' private favorite records are not
deleted by a Landowner; references to deleted listings are hidden. This avoids
granting owners access to someone else's private favorites.

Device-selected photos remain draft bytes until Save/Publish. Android picker
recovery, cancellation and permission handling are retained. GPS is requested by
the existing directions action. After permission is granted, its existing text
shows the straight-line distance from the current device position to the stored
property coordinates, in meters or kilometers. That personal distance is never
saved to the listing. Address geocoding is used when no map pin is supplied;
failures preserve address-based Maps navigation and nullable coordinates. An
address edit clears an old pin/map link and attempts to resolve the new address.

Firebase writes are awaited and duplicate submissions are guarded. Firestore can
queue a write while offline; the app does not announce a successful save until
Firebase acknowledges it. Reconnect to complete a queued save. Read listeners
retain their last data during reconnection; errors use the existing snackbars.

No FCM integration was added: there is a decorative notification icon, but no
existing notification delivery flow.

## Validation commands

```powershell
flutter analyze
flutter test
Set-Location functions
npm test
Set-Location ..\tool\firebase
npm test
```

`npm test` starts isolated Auth/Firestore emulators, checks positive and
negative security cases, and stops them. Stop `npm start` first because both use
the same local ports. SDK test doubles in `test/support` exercise the production
repository and existing UI flows without a Firebase account. They are never used
by the runtime app.

## Live and physical-device acceptance

Before marking the original milestone complete, verify:

- Separate Boarder/Landowner registration, corresponding Auth UID/profile, login,
  correct role routing, logout and session restoration after restarting the app.
- Password reset reaches a real inbox; verified email changes retain the UID.
- Both profiles save names, phone/address and Supabase Storage photos after restart.
- Publish all four Add Room steps; check Firestore fields and at most four photos.
  Leave university distance blank on at least one listing.
- Edit and delete one listing, preserving another listing and the same record ID
  on edit; check owner statistics and realtime Boarder details.
- Favorites and submitted reviews persist after restart. A Landowner sees reviews
  read-only and cannot create a Boarder review or favorite.
- On a phone, test camera and gallery, canceled/denied picker access, GPS allowed,
  denied, permanently denied and services off, distance, and external Google Maps.
- Test offline saves and reconnect; verify that failed uploads do not show success.

These live-account/email and physical-device checks cannot be replaced by local
emulator or widget-test results.
