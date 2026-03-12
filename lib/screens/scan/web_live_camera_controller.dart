import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class WebLiveCameraController {
  final String viewId;
  html.VideoElement? _video;
  html.MediaStream? _stream;
  bool _isInitialized = false;
  String? _error;
  final Completer<void> _elementReady = Completer<void>();

  WebLiveCameraController({String? viewId})
      : viewId = viewId ?? 'web-live-camera-${DateTime.now().millisecondsSinceEpoch}' {
    _registerView();
  }

  bool get isInitialized => _isInitialized;
  String? get error => _error;

  void _registerView() {
    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int viewId) {
        final video = html.VideoElement()
          ..autoplay = true
          ..muted = true
          ..setAttribute('playsinline', 'true')
          ..setAttribute('autoplay', 'true')
          ..setAttribute('muted', 'true')
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover';
        _video = video;
        if (!_elementReady.isCompleted) {
          _elementReady.complete();
        }
        return video;
      },
    );
  }

  Future<void> initialize() async {
    try {
      await _elementReady.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Camera view is not ready yet.');
        },
      );

      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        throw Exception('Camera is not supported in this browser.');
      }

      final stream = await mediaDevices.getUserMedia({
        'video': {
          'facingMode': 'environment',
          'width': {'ideal': 1920},
          'height': {'ideal': 1080},
        },
        'audio': false,
      });

      _stream = stream;
      final video = _video;
      if (video == null) {
        throw Exception('Camera element is not ready.');
      }
      video.srcObject = stream;

      final ready = Completer<void>();
      late final html.EventListener listener;
      listener = (event) {
        ready.complete();
        video.removeEventListener('loadedmetadata', listener);
      };
      video.addEventListener('loadedmetadata', listener);

      try {
        await video.play();
      } catch (e) {
        throw Exception('Camera playback blocked. Tap to allow camera.');
      }

      await ready.future.timeout(const Duration(seconds: 3), onTimeout: () {
        throw Exception('Camera is not providing frames.');
      });

      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = 'Unable to access camera: $e';
      _isInitialized = false;
    }
  }

  Widget buildPreview() {
    return HtmlElementView(viewType: viewId);
  }

  Future<Uint8List?> captureFrame() async {
    final video = _video;
    if (video == null || video.videoWidth == 0 || video.videoHeight == 0) {
      return null;
    }

    final canvas = html.CanvasElement(
      width: video.videoWidth,
      height: video.videoHeight,
    );
    final ctx = canvas.context2D;
    ctx.drawImage(video, 0, 0);

    final dataUrl = canvas.toDataUrl('image/jpeg', 0.85);
    final base64Data = dataUrl.split(',').last;
    final bytes = base64.decode(base64Data);
    return Uint8List.fromList(bytes);
  }

  void dispose() {
    final tracks = _stream?.getTracks();
    if (tracks != null) {
      for (final track in tracks) {
        track.stop();
      }
    }
    _stream = null;
  }
}
