import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stay_near/main.dart';

Future<XFile> testFile(String name, Uint8List bytes, String mimeType) async {
  final directory = await Directory.systemTemp.createTemp('staynear-image-');
  addTearDown(() => directory.delete(recursive: true));
  final file = File('${directory.path}${Platform.pathSeparator}$name');
  await file.writeAsBytes(bytes);
  return XFile(file.path, name: name, mimeType: mimeType);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('accepts supported image extensions and MIME types under 10 MB', () async {
    for (final file in <XFile>[
      await testFile('photo.jpg', Uint8List.fromList([1]), 'image/jpeg'),
      await testFile('photo.jpeg', Uint8List.fromList([1]), 'image/jpeg'),
      await testFile('photo.png', Uint8List.fromList([1]), 'image/png'),
      await testFile('photo.webp', Uint8List.fromList([1]), 'image/webp'),
    ]) {
      await expectLater(
        SupabaseStorageService.validatePickerFile(file),
        completes,
      );
    }
  });

  test('rejects unsupported image formats', () async {
    final file = await testFile(
      'photo.gif',
      Uint8List.fromList([1]),
      'image/gif',
    );
    await expectLater(
      SupabaseStorageService.validatePickerFile(file),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Only JPG, JPEG, PNG, and WEBP'),
        ),
      ),
    );
  });

  test('rejects images over 10 MB', () async {
    final file = await testFile(
      'large.png',
      Uint8List(SupabaseStorageService.maxImageSize + 1),
      'image/png',
    );
    await expectLater(
      SupabaseStorageService.validatePickerFile(file),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('10 MB'),
        ),
      ),
    );
  });
}
