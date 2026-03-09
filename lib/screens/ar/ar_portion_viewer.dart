import 'package:flutter/material.dart';

/// AR Portion Viewer Screen
/// Shows 3D/AR visualization of food portions using WebAR
class ARPortionViewer extends StatefulWidget {
  final String foodName;
  final double portionGrams;
  
  const ARPortionViewer({
    super.key,
    required this.foodName,
    required this.portionGrams,
  });

  @override
  State<ARPortionViewer> createState() => _ARPortionViewerState();
}

class _ARPortionViewerState extends State<ARPortionViewer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Portion Guide'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Instructions Card
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'AR Portion Visualization',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '🥽 WebAR Feature Coming Soon!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This feature will show 3D portion sizes using your camera and augmented reality.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // Food Info Card
          Expanded(
            child: Center(
              child: Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.view_in_ar,
                        size: 80,
                        color: Colors.purple.shade400,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.foodName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        child: Text(
                          'Recommended: ${widget.portionGrams.toInt()}g',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Visual Reference:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _getPortionReference(widget.portionGrams),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Implementation Note
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.amber.shade50,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.construction, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AR Feature in Development',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'To enable full WebAR, add webview_flutter package and create AR assets. See AR_SETUP_GUIDE.md for instructions.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.check),
        label: const Text('Got it!'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _getPortionReference(double grams) {
    String reference = '';
    IconData icon = Icons.circle;
    
    if (grams <= 20) {
      reference = '≈ 1 tablespoon\n(about the size of your thumb)';
      icon = Icons.thumbs_up_down;
    } else if (grams <= 50) {
      reference = '≈ 2-3 tablespoons\n(about the size of a golf ball)';
      icon = Icons.sports_golf;
    } else if (grams <= 100) {
      reference = '≈ 1/2 cup\n(about the size of your fist)';
      icon = Icons.back_hand;
    } else if (grams <= 150) {
      reference = '≈ 3/4 cup\n(about the size of a baseball)';
      icon = Icons.sports_baseball;
    } else if (grams <= 200) {
      reference = '≈ 1 cup\n(fills your cupped hand)';
      icon = Icons.pan_tool;
    } else if (grams <= 300) {
      reference = '≈ 1.5 cups\n(size of a small plate)';
      icon = Icons.dining;
    } else {
      reference = '≈ 2+ cups\n(size of a full plate)';
      icon = Icons.restaurant;
    }

    return Column(
      children: [
        Icon(icon, size: 48, color: Colors.purple.shade300),
        const SizedBox(height: 12),
        Text(
          reference,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
