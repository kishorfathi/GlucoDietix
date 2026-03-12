import 'dart:typed_data';
import 'package:flutter/material.dart';

class WebLiveCameraController {
  WebLiveCameraController({String? viewId});

  bool get isInitialized => false;
  String? get error => 'Web camera is only available on web builds.';

  Future<void> initialize() async {}

  Widget buildPreview() {
    return const SizedBox.shrink();
  }

  Future<Uint8List?> captureFrame() async => null;

  void dispose() {}
}
