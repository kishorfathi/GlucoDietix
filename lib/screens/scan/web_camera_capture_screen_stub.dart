import 'dart:typed_data';
import 'package:flutter/material.dart';

class WebCameraCaptureScreen extends StatelessWidget {
  const WebCameraCaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Web camera is only available on the web build.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop<Uint8List?>(context, null),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
