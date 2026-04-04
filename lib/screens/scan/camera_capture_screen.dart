import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CapturedPhoto {
  final XFile file;
  final Uint8List bytes;

  CapturedPhoto({
    required this.file,
    required this.bytes,
  });
}

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No camera found on this device.';
          _isInitializing = false;
        });
        return;
      }

      final backIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      _selectedCameraIndex = backIndex >= 0 ? backIndex : 0;
      await _startController(_selectedCameraIndex);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to open camera: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _startController(int index) async {
    final oldController = _controller;

    final newController = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await oldController?.dispose();
    await newController.initialize();

    if (!mounted) {
      await newController.dispose();
      return;
    }

    setState(() {
      _controller = newController;
      _isInitializing = false;
      _errorMessage = null;
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isInitializing) return;

    setState(() {
      _isInitializing = true;
    });

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _startController(_selectedCameraIndex);
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isCapturing ||
        controller.value.isTakingPicture) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final photo = await controller.takePicture();
      final bytes = await photo.readAsBytes();

      if (!mounted) return;
      Navigator.pop(
        context,
        CapturedPhoto(file: photo, bytes: bytes),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isCapturing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _errorMessage != null
            ? Center(
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
                        onPressed: _initializeCamera,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Back',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              )
            : _isInitializing ||
                    controller == null ||
                    !controller.value.isInitialized
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(controller),
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
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                            ),
                            const Spacer(),
                            if (_cameras.length > 1)
                              IconButton(
                                onPressed: _switchCamera,
                                icon: const Icon(
                                  Icons.flip_camera_ios,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 26,
                        child: Column(
                          children: [
                            Text(
                              'Center your plate and tap capture',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: 82,
                              height: 82,
                              child: FloatingActionButton(
                                heroTag: 'capture_button',
                                onPressed: _isCapturing ? null : _capturePhoto,
                                backgroundColor: theme.colorScheme.primary,
                                child: _isCapturing
                                    ? const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.camera_alt, size: 34),
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
