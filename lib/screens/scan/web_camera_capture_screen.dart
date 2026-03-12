import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

class WebCameraCaptureScreen extends StatefulWidget {
  const WebCameraCaptureScreen({super.key});

  @override
  State<WebCameraCaptureScreen> createState() => _WebCameraCaptureScreenState();
}

class _WebCameraCaptureScreenState extends State<WebCameraCaptureScreen> {
  late final String _viewId;
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _viewId = 'web-camera-${DateTime.now().millisecondsSinceEpoch}';
    _registerView();
    _startCamera();
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  void _registerView() {
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        final video = html.VideoElement()
          ..autoplay = true
          ..muted = true
          ..setAttribute('playsinline', 'true')
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover';
        _videoElement = video;
        return video;
      },
    );
  }

  Future<void> _startCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
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

      _mediaStream = stream;
      _videoElement?.srcObject = stream;

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to access camera: $e';
        _isInitializing = false;
      });
    }
  }

  void _stopCamera() {
    final tracks = _mediaStream?.getTracks();
    if (tracks != null) {
      for (final track in tracks) {
        track.stop();
      }
    }
    _mediaStream = null;
  }

  Future<void> _captureFrame() async {
    final video = _videoElement;
    if (video == null || video.videoWidth == 0 || video.videoHeight == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera not ready yet. Try again in a moment.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final canvas = html.CanvasElement(
      width: video.videoWidth,
      height: video.videoHeight,
    );
    final ctx = canvas.context2D;
    ctx.drawImage(video, 0, 0);

    final dataUrl = canvas.toDataUrl('image/jpeg', 0.9);
    final base64Data = dataUrl.split(',').last;
    final bytes = base64.decode(base64Data);

    if (!mounted) return;
    Navigator.pop(context, Uint8List.fromList(bytes));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            HtmlElementView(viewType: _viewId),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.55),
                    Colors.transparent,
                    Color.fromRGBO(0, 0, 0, 0.75),
                  ],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Live Camera',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _startCamera,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                  ),
                ],
              ),
            ),
            if (_isInitializing)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.white, size: 56),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _startCamera,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Positioned(
                left: 20,
                right: 20,
                bottom: 26,
                child: Column(
                  children: [
                    const Text(
                      'Center your plate and tap capture',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 82,
                      height: 82,
                      child: FloatingActionButton(
                        heroTag: 'web_capture_button',
                        onPressed: _captureFrame,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.camera_alt, size: 34),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
