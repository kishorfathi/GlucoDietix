import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:js_interop';
// ignore: deprecated_member_use
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';

class WebLiveCameraController {
  final String viewId;
  web.HTMLVideoElement? _video;
  web.MediaStream? _stream;
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
        final video = web.HTMLVideoElement()
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

      final mediaDevices = web.window.navigator.mediaDevices;

      final constraints = <String, dynamic>{
        'video': <String, dynamic>{
          'facingMode': 'environment',
          'width': <String, int>{'ideal': 1920},
          'height': <String, int>{'ideal': 1080},
        },
        'audio': false,
      }.jsify() as web.MediaStreamConstraints;

      final streamPromise = mediaDevices.getUserMedia(constraints);
      final stream = await streamPromise.toDart;

      _stream = stream;
      final video = _video;
      if (video == null) {
        throw Exception('Camera element is not ready.');
      }
      video.srcObject = stream;

      final ready = Completer<void>();
      void listener(web.Event event) {
        ready.complete();
        video.removeEventListener('loadedmetadata', listener.toJS);
      }
      video.addEventListener('loadedmetadata', listener.toJS);

      try {
        await video.play().toDart;
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

    final canvas = web.HTMLCanvasElement()
      ..width = video.videoWidth
      ..height = video.videoHeight;
    final ctx = canvas.getContext('2d')! as web.CanvasRenderingContext2D;
    ctx.drawImage(video, 0, 0);

    final dataUrl = canvas.toDataURL('image/jpeg', 0.85.toJS);
    final base64Data = dataUrl.split(',').last;
    final bytes = base64.decode(base64Data);
    return Uint8List.fromList(bytes);
  }

  void dispose() {
    final stream = _stream;
    if (stream != null) {
      final tracks = stream.getTracks();
      final dartTracks = tracks.toDart;
      for (var i = 0; i < dartTracks.length; i++) {
        dartTracks[i].stop();
      }
    }
    _stream = null;
  }
}
