import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stay_near/main.dart';

Future<void> tap(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [
    const Size(390, 825),
    const Size(320, 568),
    const Size(430, 900),
  ]) {
    testWidgets('Add Room callbacks, draft retention and keyboard at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var step = 0, cancelled = 0, profile = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ScreenFrame(
            child: StatefulBuilder(
              builder: (context, update) => RoomWizard(
                step: step,
                onBack: () => cancelled++,
                onProfile: () => profile++,
                onNext: () => update(() => step++),
                onPrevious: () => update(() => step--),
                onPublish: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fields = tester
          .widgetList<TextFieldBox>(find.byType(TextFieldBox))
          .toList();
      expect(
        fields.map((field) => field.controller!.text),
        everyElement(isEmpty),
      );
      for (var i = 0; i < fields.length; i++) {
        fields[i].controller!.text = [
          'Owner room',
          'Owner description',
          '09991234567',
        ][i];
      }
      await tap(tester, 'Next');
      expect(step, 1);
      await tap(tester, 'Previous');
      expect(step, 0);
      expect(
        tester
            .widgetList<TextFieldBox>(find.byType(TextFieldBox))
            .map((field) => field.controller!.text),
        ['Owner room', 'Owner description', '09991234567'],
      );
      await tester.tap(find.byTooltip('Profile'));
      expect(profile, 1);
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tap(tester, 'Cancel');
      expect(cancelled, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('large text keeps the first step scrollable', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: ScreenFrame(
            child: RoomWizard(
              step: 0,
              onBack: () {},
              onProfile: () {},
              onNext: () {},
              onPrevious: () {},
              onPublish: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('optional Add Room reference preview', (tester) async {
    if (!const bool.fromEnvironment('ADD_ROOM_PREVIEW')) return;
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
    tester.view.physicalSize = const Size(390, 825);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final capture = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: capture,
          child: ScreenFrame(
            child: RoomWizard(
              step: 0,
              onBack: () {},
              onProfile: () {},
              onNext: () {},
              onPrevious: () {},
              onPublish: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image =
          await (capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('build/add-room-preview.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
  });
}
