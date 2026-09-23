import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stay_near/main.dart';
import 'package:stay_near/services/property_location.dart';

const photo =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAANSURBVBhXY2Bg+P8fAAMCAf/Jsq3uAAAAAElFTkSuQmCC';

class Picker extends ProfilePhotoPicker {
  int count = 0;
  bool cancel = false, fail = false;
  Completer<String?>? pending;
  @override
  bool get supportsCamera => true;
  @override
  Future<String?> recover() async => null;
  @override
  Future<String?> pick(ImageSource source) async {
    if (fail) throw PlatformException(code: 'photo_access_denied');
    if (cancel) return null;
    return pending?.future ??
        Future.value(
          photo.replaceFirst('image/png;', 'image/png;name=${count++};'),
        );
  }
}

Future<void> tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void fill(WidgetTester tester, String hint, String value, {int index = 0}) {
  tester
          .widgetList<TextField>(find.byType(TextField))
          .where((field) => field.decoration?.hintText == hint)
          .elementAt(index)
          .controller!
          .text =
      value;
}

Future<void> show(
  WidgetTester tester,
  Picker picker, {
  int initial = 0,
  FutureOr<void> Function(Listing)? publish,
  VoidCallback? published,
  double scale = 1,
  Size size = const Size(390, 985),
  GlobalKey? capture,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  var step = initial;
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: RepaintBoundary(
          key: capture,
          child: ScreenFrame(
            child: StatefulBuilder(
              builder: (context, update) => RoomWizard(
                step: step,
                photoPicker: picker,
                onBack: () {},
                onProfile: () {},
                onNext: () => update(() => step++),
                onPrevious: () => update(() => step--),
                onPublish: publish ?? (_) {},
                onPublished: published,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'four photo slots validate, preview, remove, retain, and publish every field',
    (tester) async {
      Listing? result;
      final picker = Picker();
      await show(tester, picker, publish: (listing) => result = listing);
      fill(tester, '', 'Test property');
      fill(tester, '', 'Description', index: 1);
      fill(tester, '', '09991234567', index: 2);
      await tap(tester, 'Next');
      await tap(tester, 'Next');
      expect(
        find.text('Please select at least one property photo.'),
        findsOneWidget,
      );
      expect(find.text('Step 2 of 4'), findsOneWidget);
      for (var i = 1; i <= 4; i++) {
        await tap(tester, 'Photo $i');
        await tap(tester, 'Choose from Gallery');
      }
      expect(find.text('Selected: 4 / 4'), findsOneWidget);
      expect(picker.count, 4);
      await tester.ensureVisible(find.byTooltip('Remove Photo 2'));
      await tester.tap(find.byTooltip('Remove Photo 2'));
      await tester.pumpAndSettle();
      expect(find.text('Selected: 3 / 4'), findsOneWidget);
      expect(find.byTooltip('Remove Photo 1'), findsOneWidget);
      expect(find.byTooltip('Remove Photo 3'), findsOneWidget);
      await tap(tester, 'Next');
      final rentField = tester
          .widgetList<TextField>(find.byType(TextField))
          .singleWhere((field) => field.decoration?.hintText == '');
      expect(rentField.controller!.text, isEmpty);
      for (final label in [
        'WiFi',
        'Air Conditioning',
        'Study Desk',
        'Shared Kitchen',
        'Private Bathroom',
        'CCTV',
        'Laundry Area',
        'Parking',
        'Balcony',
      ]) {
        expect(
          tester
              .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
              .selected,
          isFalse,
        );
      }
      rentField.controller!.text = '2500';
      fill(tester, '0', '8');
      fill(tester, '0', '3', index: 1);
      for (final label in ['WiFi', 'Air Conditioning', 'Parking']) {
        await tap(tester, label);
        final chip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, label),
        );
        expect(chip.selected, isTrue);
        expect(chip.showCheckmark, isFalse);
        expect(chip.selectedColor, blue);
        expect(chip.labelStyle!.color, Colors.white);
      }
      await tap(tester, 'Balcony');
      await tap(tester, 'Balcony');
      await tap(tester, 'Previous');
      expect(find.text('Selected: 3 / 4'), findsOneWidget);
      await tap(tester, 'Next');
      await tap(tester, 'Next');
      await tap(tester, 'Publish Listing');
      expect(result, isNull);
      expect(find.text('Please enter the full address.'), findsOneWidget);
      fill(tester, 'Barangay, Municipality, City', 'Clarin, Bohol');
      fill(tester, 'Enter distance information', '800 m');
      fill(
        tester,
        'Paste a Google Maps link',
        'https://www.google.com/maps?q=9.95,124.03',
      );
      await tap(tester, 'Previous');
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Parking'))
            .selected,
        isTrue,
      );
      await tap(tester, 'Next');
      await tap(tester, 'Publish Listing');
      expect(result!.title, 'Test property');
      expect(result!.description, 'Description');
      expect(result!.contact, '09991234567');
      expect(result!.photos.length, 3);
      expect(result!.image, result!.photos.first);
      expect(result!.price, 2500);
      expect(result!.totalRooms, 8);
      expect(result!.availableRooms, 3);
      expect(result!.amenities, ['WiFi', 'Air Conditioning', 'Parking']);
      expect(
        result!.houseInformation['Reference Map'],
        'https://www.google.com/maps?q=9.95,124.03',
      );
      expect(result!.latitude, 9.95);
      expect(result!.longitude, 124.03);
      expect(result!.houseInformation['Distance from University'], '800 m');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'picker cancel, permission error and late completion preserve drafts safely',
    (tester) async {
      final picker = Picker()..cancel = true;
      await show(tester, picker, initial: 1);
      await tap(tester, 'Photo 1');
      await tap(tester, 'Choose from Gallery');
      expect(find.text('Selected: 0 / 4'), findsOneWidget);
      picker
        ..cancel = false
        ..fail = true;
      await tap(tester, 'Photo 1');
      await tap(tester, 'Take Photo');
      expect(find.textContaining('Check photo permissions'), findsOneWidget);
      picker
        ..fail = false
        ..pending = Completer<String?>();
      await tap(tester, 'Photo 1');
      await tester.tap(find.text('Choose from Gallery'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      picker.pending!.complete(photo);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'publish waits for success, prevents duplicates, and reports failure',
    (tester) async {
      final save = Completer<void>();
      var attempts = 0, completed = 0;
      await show(
        tester,
        Picker(),
        publish: (_) {
          attempts++;
          if (attempts == 1) return save.future;
          throw StateError('simulated database failure');
        },
        published: () => completed++,
      );
      fill(tester, '', 'Test property');
      fill(tester, '', 'Description', index: 1);
      fill(tester, '', '09991234567', index: 2);
      await tap(tester, 'Next');
      await tap(tester, 'Photo 1');
      await tap(tester, 'Choose from Gallery');
      await tap(tester, 'Next');
      fill(tester, '', '2500');
      fill(tester, '0', '2');
      fill(tester, '0', '1', index: 1);
      await tap(tester, 'Next');
      fill(tester, 'Barangay, Municipality, City', 'Clarin, Bohol');
      fill(tester, 'Enter distance information', '800 m');
      fill(
        tester,
        'Paste a Google Maps link',
        'https://www.google.com/maps?q=9.96,124.04',
      );

      await tester.ensureVisible(find.text('Publish Listing'));
      await tester.tap(find.text('Publish Listing'));
      await tester.pump();
      expect(attempts, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(FilledButton).last);
      await tester.pump();
      expect(attempts, 1);
      expect(find.text('Listing published successfully'), findsNothing);

      save.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Listing published successfully'), findsOneWidget);
      expect(completed, 0);
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();
      expect(completed, 1);
      expect(find.byType(Dialog), findsNothing);

      for (var step = 0; step < 3; step++) {
        await tap(tester, 'Previous');
      }
      fill(tester, '', 'Retry property');
      fill(tester, '', 'Retry description', index: 1);
      fill(tester, '', '09991234567', index: 2);
      await tap(tester, 'Next');
      await tap(tester, 'Photo 1');
      await tap(tester, 'Choose from Gallery');
      await tap(tester, 'Next');
      fill(tester, '', '2500');
      fill(tester, '0', '2');
      fill(tester, '0', '1', index: 1);
      await tap(tester, 'Next');
      fill(tester, 'Barangay, Municipality, City', 'Clarin, Bohol');
      fill(tester, 'Enter distance information', '800 m');
      fill(
        tester,
        'Paste a Google Maps link',
        'https://www.google.com/maps?q=9.97,124.05',
      );
      await tap(tester, 'Publish Listing');
      expect(attempts, 2);
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('simulated database failure'), findsOneWidget);
      expect(find.text('Publish Listing'), findsOneWidget);
    },
  );

  test('Google Maps accepts full and short links without accepting unrelated hosts', () {
    for (final link in [
      'https://www.google.com/maps?q=9.95,124.03',
      'https://maps.google.com/?q=Clarin',
      'https://maps.app.goo.gl/abc',
      'https://goo.gl/maps/abc',
    ]) {
      expect(PropertyLocationService.savedMapUri(link).toString(), link);
    }
    for (final link in [
      '',
      'javascript:alert(1)',
      'https://google.com.evil.test/maps',
      'https://example.test/maps',
    ]) {
      expect(PropertyLocationService.savedMapUri(link), isNull);
    }
  });

  test('Google Maps extracts exact @ coordinates and rejects invalid ranges', () {
    const sample =
        '  https://www.google.com/maps/@9.9621749,124.0246341,429m/data=!3m1!1e3?entry=ttu&g_ep=EgoyMDI2MDkxNi4wIKXMDSoASAFQAw%3D%3D  ';
    final point = PropertyLocationService.coordinatesFromMapLink(sample);
    expect(point?.latitude, 9.9621749);
    expect(point?.longitude, 124.0246341);
    final negative = PropertyLocationService.coordinatesFromMapLink(
      'https://www.google.com/maps/@-9.5,-124.25,200m/data=!3m1!1e3',
    );
    expect(negative?.latitude, -9.5);
    expect(negative?.longitude, -124.25);
    expect(
      PropertyLocationService.coordinatesFromMapLink(
        'https://www.google.com/maps/@91,124.25,200m',
      ),
      isNull,
    );
    expect(
      PropertyLocationService.coordinatesFromMapLink(
        'https://www.google.com/maps/place/Clarin',
      ),
      isNull,
    );
  });

  for (final step in [1, 2, 3]) {
    testWidgets(
      'step ${step + 1} fits small screens with large text and keyboard',
      (tester) async {
        await show(
          tester,
          Picker(),
          initial: step,
          scale: 2,
          size: const Size(320, 568),
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 220);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.text(step == 3 ? 'Publish Listing' : 'Next'),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('optional steps visual previews', (tester) async {
    if (!const bool.fromEnvironment('ROOM_STEPS_PREVIEW')) return;
    await tester.runAsync(() async {
      const sdk = String.fromEnvironment('FLUTTER_SDK');
      for (final entry in {
        'Roboto': [
          'roboto-regular.ttf',
          'roboto-medium.ttf',
          'roboto-bold.ttf',
        ],
        'MaterialIcons': ['materialicons-regular.otf'],
      }.entries) {
        final loader = FontLoader(entry.key);
        for (final file in entry.value) {
          loader.addFont(
            File('$sdk/bin/cache/artifacts/material_fonts/$file')
                .readAsBytes()
                .then(ByteData.sublistView),
          );
        }
        await loader.load();
      }
    });
    for (final step in [1, 2, 3]) {
      final capture = GlobalKey();
      await tester.pumpWidget(const SizedBox());
      await show(
        tester,
        Picker(),
        initial: step,
        size: Size(390, step == 1 ? 985 : 930),
        capture: capture,
      );
      await tester.runAsync(() async {
        final image =
            await (capture.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('build/room-step-${step + 1}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
