import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// GlucoDietix Food Detection Service
/// Communicates with FastAPI backend for YOLO11 food detection
class GlucoDietixDetectionService {
  // Backend URL - change this to your backend address
  static const String _backendUrl = 'http://localhost:8000';

  /// Detect foods from an image file
  /// Returns list of detected food names
  Future<List<String>> detectFoodsFromFile(File imageFile) async {
    try {
      print('📤 Sending image to backend: ${imageFile.path}');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_backendUrl/detect'),
      );

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Parse JSON response
        final jsonResponse = json.decode(response.body);
        final List<dynamic> foods = jsonResponse['foods'] ?? [];

        // Convert to list of strings
        final detectedFoods = foods.map((f) => f.toString()).toList();

        print('✅ Detected ${detectedFoods.length} foods: $detectedFoods');
        return detectedFoods;
      } else {
        print('❌ Detection failed: ${response.statusCode}');
        print('   Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error detecting foods: $e');
      return [];
    }
  }

  /// Detect foods from image bytes
  /// Returns list of detected food names
  Future<List<String>> detectFoodsFromBytes(Uint8List imageBytes,
      String filename) async {
    try {
      print('📤 Sending image bytes to backend...');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_backendUrl/detect'),
      );

      // Add image bytes
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
        ),
      );

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Parse JSON response
        final jsonResponse = json.decode(response.body);
        final List<dynamic> foods = jsonResponse['foods'] ?? [];

        // Convert to list of strings
        final detectedFoods = foods.map((f) => f.toString()).toList();

        print('✅ Detected ${detectedFoods.length} foods: $detectedFoods');
        return detectedFoods;
      } else {
        print('❌ Detection failed: ${response.statusCode}');
        print('   Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error detecting foods: $e');
      return [];
    }
  }

  /// Get detailed detection results with confidence scores and bounding boxes
  Future<List<DetectionResult>> detectFoodsDetailed(File imageFile) async {
    try {
      print('📤 Sending image for detailed detection...');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_backendUrl/detect-detailed'),
      );

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Parse JSON response
        final jsonResponse = json.decode(response.body);
        final List<dynamic> detections = jsonResponse['detections'] ?? [];

        // Convert to DetectionResult objects
        return detections.map((d) => DetectionResult.fromJson(d)).toList();
      } else {
        print('❌ Detection failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error in detailed detection: $e');
      return [];
    }
  }

  /// Check if backend is healthy and running
  Future<bool> checkBackendHealth() async {
    try {
      final response = await http.get(Uri.parse('$_backendUrl/health'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Backend healthy: ${data['status']}');
        print('   Model loaded: ${data['model_status']}');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Backend not reachable: $e');
      return false;
    }
  }
}

/// Detailed detection result with confidence and bounding box
class DetectionResult {
  final String food;
  final double confidence;
  final List<double> bbox;

  DetectionResult({
    required this.food,
    required this.confidence,
    required this.bbox,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      food: json['food'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      bbox: (json['bbox'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }
}
