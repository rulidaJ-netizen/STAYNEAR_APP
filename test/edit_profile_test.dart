import 'support/firebase_test_backend.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:stay_near/main.dart';

const _photo =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAANSURBVBhXY2Bg+P8fAAMCAf/Jsq3uAAAAAElFTkSuQmCC';
const _user = UserProfile(
  firstName: 'Maria',
  middleName: 'C.',
  lastName: 'Santos',
  email: 'maria@example.test',
  contact: '09123456789',
  address: 'Clarin, Bohol',
  birthday: '2000-01-01',
  gender: 'Female',
  password: 'Password123!',
  role: UserRole.boarder,
  profilePhoto: _photo,
);

class _Picker extends ProfilePhotoPicker {
  String? nextPhoto;
  Object? failure;
  Completer<String?>? pending;
  ImageSource? source;
  @override
  bool get supportsCamera => true;
  @override
  Future<String?> recover() async => null;
  @override
  Future<String?> pick(ImageSource source) async {
    this.source = source;
    if (failure != null) throw failure!;
    return pending?.future ?? Future.value(nextPhoto);
  }
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String key, String text) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, text);
  await tester.pump();
}

String _value(WidgetTester tester, String key) =>
    tester.widget<TextFormField>(find.byKey(ValueKey(key))).controller!.text;

Future<void> _show(
  WidgetTester tester, {
  UserProfile user = _user,
  _Picker? picker,
  Future<void> Function(UserProfile)? save,
  VoidCallback? back,
  Size size = const Size(390, 844),
  double scale = 1,
  GlobalKey? capture,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: RepaintBoundary(
        key: capture,
        child: ScreenFrame(
          child: EditProfilePage(
            user: user,
            photoPicker: picker ?? _Picker(),
            onBack: back ?? () {},
            onSave: save ?? (_) async {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Firestore profile persistence preserves UID and never retains passwords',
    () async {
      final backend = TestFirebaseBackend();
      final user = await backend.signUpAndLogin(_user);
      final edited = user.withProfileEdits(
        fullName: 'Maria de la Cruz',
        phone: '+63 999 111 2222',
        email: user.email,
        address: 'Updated address',
        photo: testPhoto,
      );
      await ProfileStorage(backend: backend).save(edited);
      final restored = await ProfileStorage(backend: backend).load(user);
      expect(restored.id, user.id);
      expect(restored.fullName, 'Maria de la Cruz');
      expect(restored.email, user.email);
      expect(restored.contact, '+63 999 111 2222');
      expect(restored.address, 'Updated address');
      expect(restored.profilePhoto, startsWith('https://'));
      expect(restored.password, isEmpty);
      expect(restored.birthday, _user.birthday);
      expect(restored.role, _user.role);
    },
  );

  testWidgets(
    'actual saved values initialize fields and all edits are submitted together',
    (tester) async {
      UserProfile? submitted;
      await _show(tester, save: (user) async => submitted = user);
      expect(_value(tester, 'profile-name'), 'Maria C. Santos');
      expect(_value(tester, 'profile-phone'), '09123456789');
      expect(_value(tester, 'profile-email'), 'maria@example.test');
      expect(_value(tester, 'profile-address'), 'Clarin, Bohol');
      expect(find.byType(BottomNav), findsNothing);
      await _enter(tester, 'profile-name', 'Maria de la Cruz');
      await _enter(tester, 'profile-phone', '+63 999 111 2222');
      await _enter(tester, 'profile-email', 'updated@example.test');
      await _enter(tester, 'profile-address', 'New address');
      expect(_user.fullName, 'Maria C. Santos');
      await _tap(tester, find.byKey(const ValueKey('save-profile')));
      expect(submitted!.fullName, 'Maria de la Cruz');
      expect(submitted!.contact, '+63 999 111 2222');
      expect(submitted!.email, 'updated@example.test');
      expect(submitted!.address, 'New address');
      expect(submitted!.profilePhoto, _photo);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'photo is a preview until Save; gallery cancellation keeps the preview',
    (tester) async {
      final picker = _Picker()..nextPhoto = 'data:invalid-preview';
      UserProfile? submitted;
      await _show(
        tester,
        picker: picker,
        save: (user) async => submitted = user,
      );
      await _tap(tester, find.text('Change Photo'));
      await _tap(tester, find.text('Choose from Gallery'));
      expect(picker.source, ImageSource.gallery);
      expect(
        tester
            .widget<ProfileAvatar>(
              find.byKey(const ValueKey('edit-profile-photo')),
            )
            .source,
        'data:invalid-preview',
      );
      expect(_user.profilePhoto, _photo);
      picker.nextPhoto = null;
      await _tap(tester, find.text('Change Photo'));
      await _tap(tester, find.text('Choose from Gallery'));
      expect(
        tester
            .widget<ProfileAvatar>(
              find.byKey(const ValueKey('edit-profile-photo')),
            )
            .source,
        'data:invalid-preview',
      );
      await _tap(tester, find.byKey(const ValueKey('save-profile')));
      expect(submitted!.profilePhoto, 'data:invalid-preview');
      expect(tester.takeException(), isNull);
    },
  );

  for (final action in ['Cancel', 'Back', 'System Back']) {
    testWidgets('$action discards both text and selected photo', (
      tester,
    ) async {
      var saves = 0, backs = 0;
      await _show(
        tester,
        picker: _Picker()..nextPhoto = 'data:temporary',
        save: (_) async => saves++,
        back: () => backs++,
      );
      await _tap(tester, find.text('Change Photo'));
      await _tap(tester, find.text('Take Photo'));
      await _enter(tester, 'profile-name', 'Unsaved name');
      if (action == 'System Back') {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
      } else {
        await _tap(
          tester,
          action == 'Back' ? find.byTooltip('Back') : find.text('Cancel'),
        );
      }
      expect(saves, 0);
      expect(backs, 1);
      expect(_user.fullName, 'Maria C. Santos');
      expect(_user.profilePhoto, _photo);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('empty or invalid input does not save and stays editable', (
    tester,
  ) async {
    var saves = 0;
    await _show(tester, save: (_) async => saves++);
    await _enter(tester, 'profile-name', ' ');
    await _enter(tester, 'profile-phone', 'abc');
    await _enter(tester, 'profile-email', 'invalid');
    await _enter(tester, 'profile-address', '');
    await _tap(tester, find.byKey(const ValueKey('save-profile')));
    expect(saves, 0);
    expect(find.text('Please enter your full name.'), findsOneWidget);
    expect(find.text('Please enter a valid phone number.'), findsOneWidget);
    expect(find.text('Please enter a valid email address.'), findsOneWidget);
    expect(find.text('Please enter your address.'), findsOneWidget);
    expect(_value(tester, 'profile-email'), 'invalid');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'save failure keeps edits and loading prevents duplicate commits',
    (tester) async {
      final pending = Completer<void>();
      var saves = 0;
      await _show(
        tester,
        save: (_) {
          saves++;
          return pending.future;
        },
      );
      await _enter(tester, 'profile-name', 'Draft name');
      final save = find.byKey(const ValueKey('save-profile'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) => widget is IconButton && widget.tooltip == 'Back',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(saves, 1);
      pending.completeError(StateError('Disk unavailable'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('profile-error')), findsOneWidget);
      expect(_value(tester, 'profile-name'), 'Draft name');
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('picker permission error and completion after leaving are safe', (
    tester,
  ) async {
    final picker = _Picker()
      ..failure = PlatformException(code: 'photo_access_denied');
    await _show(tester, picker: picker);
    await _tap(tester, find.text('Change Photo'));
    await _tap(tester, find.text('Choose from Gallery'));
    expect(find.textContaining('Photo access was denied'), findsOneWidget);
    picker.failure = null;
    picker.pending = Completer<String?>();
    await _tap(tester, find.text('Change Photo'));
    await _tap(tester, find.text('Choose from Gallery'));
    await tester.pumpWidget(const SizedBox());
    picker.pending!.complete(_photo);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets(
      'small phone form and keyboard remain usable at text scale $scale',
      (tester) async {
        await _show(tester, size: const Size(320, 568), scale: scale);
        await _enter(
          tester,
          'profile-address',
          'A long updated address in Poblacion Norte, Clarin, Bohol',
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 240);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const ValueKey('save-profile')));
        await tester.pumpAndSettle();
        expect(find.text('Save').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Profile displays newly saved data and reopens the editor with the saved values',
    (tester) async {
      final original = SharedPreferencesAsyncPlatform.instance;
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      addTearDown(() => SharedPreferencesAsyncPlatform.instance = original);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMessageHandler('flutter/assets', (message) async {
        final asset = utf8.decode(message!.buffer.asUint8List());
        if (asset == 'AssetManifest.bin') {
          return const StandardMessageCodec().encodeMessage({
            for (final weight in [
              'Thin',
              'ExtraLight',
              'Light',
              'Regular',
              'Medium',
              'SemiBold',
              'Bold',
              'ExtraBold',
              'Black',
            ])
              'PlusJakartaSans-$weight.ttf': [
                {'asset': 'PlusJakartaSans-$weight.ttf'},
              ],
          });
        }
        if (asset.endsWith('.ttf')) return ByteData(0);
        return null;
      });
      addTearDown(
        () => messenger.setMockMessageHandler('flutter/assets', null),
      );
      final backend = TestFirebaseBackend();
      await tester.pumpWidget(StayNearApp(backend: backend));
      await tester.widget<AuthPage>(find.byType(AuthPage)).onRegister(_user);
      await tester.pumpAndSettle();
      expect(
        await tester
            .widget<AuthPage>(find.byType(AuthPage))
            .onLogin(_user.email, _user.password, UserRole.boarder),
        isTrue,
      );
      await tester.pumpAndSettle();
      ScaffoldMessenger.of(tester.element(find.byType(ScreenFrame)))
          .clearSnackBars();
      await tester.pumpAndSettle();
      tester
          .widget<BoarderDashboard>(find.byType(BoarderDashboard))
          .onProfile();
      await tester.pumpAndSettle();
      tester.widget<ProfilePage>(find.byType(ProfilePage)).onEdit();
      await tester.pumpAndSettle();
      await _enter(tester, 'profile-name', 'Saved Maria');
      await _enter(tester, 'profile-phone', '09991112222');
      await _enter(tester, 'profile-email', 'saved@example.test');
      await _enter(tester, 'profile-address', 'Saved address');
      await _tap(tester, find.byKey(const ValueKey('save-profile')));
      final user = tester.widget<ProfilePage>(find.byType(ProfilePage)).user!;
      expect(user.fullName, 'Saved Maria');
      expect(user.contact, '09991112222');
      expect(user.email, _user.email);
      expect(user.address, 'Saved address');
      expect(find.textContaining('Check your new email'), findsOneWidget);
      tester.widget<ProfilePage>(find.byType(ProfilePage)).onEdit();
      await tester.pumpAndSettle();
      expect(_value(tester, 'profile-name'), 'Saved Maria');
      expect(_value(tester, 'profile-email'), _user.email);
      final newPhoto = _photo.replaceFirst(
        'image/png;',
        'image/png;name=updated;',
      );
      await tester
          .widget<EditProfilePage>(find.byType(EditProfilePage))
          .onSave(
            user.withProfileEdits(
              fullName: user.fullName,
              phone: user.contact,
              email: user.email,
              address: user.address,
              photo: newPhoto,
            ),
          );
      await tester.pumpAndSettle();
      expect(
        tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).source,
        startsWith('https://'),
      );
      expect(
        (await backend.loadProfile()).profilePhoto,
        startsWith('https://'),
      );
      tester.widget<ProfilePage>(find.byType(ProfilePage)).onLogout();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      final auth = tester.widget<AuthPage>(find.byType(AuthPage));
      expect(
        await auth.onLogin(_user.email, _user.password, UserRole.boarder),
        isTrue,
      );
      await tester.pumpAndSettle();
      expect(find.byType(BoarderDashboard), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('missing and unreadable avatar sources fall back safely', (
    tester,
  ) async {
    for (final source in [
      '',
      'assets/missing-avatar.png',
      'C:/__staynear_missing_avatar__/avatar.jpg',
      'https://example.invalid/avatar.png',
    ]) {
      await _show(
        tester,
        user: _user.withProfileEdits(
          fullName: _user.fullName,
          phone: _user.contact,
          email: _user.email,
          address: _user.address,
          photo: source,
        ),
      );
      expect(find.byType(ProfileAvatar), findsOneWidget);
      expect(tester.takeException(), isNull, reason: source);
    }
  });

  testWidgets('optional Edit Profile visual preview', (tester) async {
    if (!const bool.fromEnvironment('EDIT_PROFILE_PREVIEW')) return;
    await tester.runAsync(() async {
      const sdk = String.fromEnvironment('FLUTTER_SDK');
      for (final entry in {
        'Roboto': ['roboto-regular.ttf', 'roboto-bold.ttf'],
        'MaterialIcons': ['materialicons-regular.otf'],
      }.entries) {
        final loader = FontLoader(entry.key);
        for (final filename in entry.value) {
          loader.addFont(
            File('$sdk/bin/cache/artifacts/material_fonts/$filename')
                .readAsBytes()
                .then(ByteData.sublistView),
          );
        }
        await loader.load();
      }
    });
    final capture = GlobalKey();
    await _show(tester, size: const Size(390, 792), capture: capture);
    await tester.runAsync(() async {
      final boundary =
          capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('build/edit-profile-preview.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
