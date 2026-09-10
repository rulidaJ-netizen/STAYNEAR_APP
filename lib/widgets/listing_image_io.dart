import 'dart:io';

import 'package:flutter/painting.dart';

ImageProvider<Object>? localListingImage(String source) {
  try {
    final file = source.startsWith('file:')
        ? File.fromUri(Uri.parse(source))
        : File(source);
    return FileImage(file);
  } on ArgumentError {
    return null;
  } on FormatException {
    return null;
  }
}
