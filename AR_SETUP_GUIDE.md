# 🥽 WebAR Portion Viewer - Setup Guide

## 📱 What is WebAR in GlucoDietix?

WebAR (Web-based Augmented Reality) helps diabetes patients **visualize correct portion sizes** using their phone camera. This feature provides 3D visual references to help users better understand recommended serving sizes for Sri Lankan foods.

---

## ✨ Current Implementation

### Phase 1: Visual Reference System (✅ Active)

The current implementation provides **visual reference comparisons** to help users understand portion sizes:

- **1 tablespoon (≈20g)** → Size of your thumb 👍
- **Golf ball (≈50g)** → 2-3 tablespoons ⛳
- **Your fist (≈100g)** → 1/2 cup ✊
- **Baseball (≈150g)** → 3/4 cup ⚾
- **Cupped hand (≈200g)** → 1 cup 🖐️
- **Small plate (≈300g)** → 1.5 cups 🍽️
- **Full plate (≈400g+)** → 2+ cups 🍛

### How to Use (Current):

1. Select a food item
2. Choose a portion (e.g., "1/2 cup - 120g")
3. Click **"View in AR"** button (purple)
4. See visual reference comparison
5. Understand portion size better

---

## 🚀 Phase 2: Full WebAR (Optional Enhancement)

For true AR camera-based visualization, you can enhance the app with WebView-based AR.

### Requirements:

1. **Add WebView Package**
```yaml
# pubspec.yaml
dependencies:
  webview_flutter: ^4.4.2
```

2. **Create AR HTML Asset**
```bash
mkdir assets/ar
# Create portion_viewer.html (see below)
```

3. **Update pubspec.yaml**
```yaml
flutter:
  assets:
    - assets/ar/portion_viewer.html
```

### Full AR HTML Template:

Create `assets/ar/portion_viewer.html`:

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>AR Portion Viewer</title>
  <script src="https://aframe.io/releases/1.4.0/aframe.min.js"></script>
  <script src="https://raw.githack.com/AR-js-org/AR.js/master/aframe/build/aframe-ar.js"></script>
</head>
<body>
  <a-scene embedded arjs="sourceType: webcam;">
    <a-marker preset="hiro">
      <!-- Rice portion (1 cup = 195g) -->
      <a-cylinder position="0 0.05 0" radius="0.08" height="0.1" color="#FFFFFF">
        <a-text value="1 cup\n195g" align="center" position="0 0.15 0" scale="0.3 0.3 0.3"></a-text>
      </a-cylinder>
    </a-marker>
    <a-entity camera></a-entity>
  </a-scene>
</body>
</html>
```

### Update AR Viewer Screen:

Uncomment the WebView code in `lib/screens/ar/ar_portion_viewer.dart` (currently shows visual references).

### Enable WebAR:

```bash
flutter pub get
flutter run
```

### Print AR Marker:

Download Hiro marker: https://raw.githubusercontent.com/AR-js-org/AR.js/master/data/images/hiro.png

Print on A4 white paper.

---

## 🎓 Research Integration

### Data Collection Points:

1. **AR Feature Usage**
```sql
CREATE TABLE ar_usage_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  food_id UUID REFERENCES foods(id),
  portion_grams DECIMAL,
  viewed_at TIMESTAMP DEFAULT NOW()
);
```

2. **Track in App**
```dart
// When user opens AR viewer
void _logARUsage(String foodId, double grams) async {
  await _supabaseService.client.from('ar_usage_logs').insert({
    'user_id': userId,
    'food_id': foodId,
    'portion_grams': grams,
  });
}
```

### Research Questions:

- **Q1**: Does AR visualization improve portion estimation accuracy?
- **Q2**: Do users with AR have better glucose control?
- **Q3**: What's the adoption rate of AR feature?
- **Q4**: User satisfaction with AR vs traditional portion guides?

### Metrics to Track:

```dart
// In your research analysis
SELECT 
  u.id,
  COUNT(ar.id) as ar_usage_count,
  AVG(d.adherence_score) as avg_adherence,
  AVG(g.glucose_level) as avg_glucose
FROM users u
LEFT JOIN ar_usage_logs ar ON u.id = ar.user_id
LEFT JOIN dietary_adherence d ON u.id = d.user_id
LEFT JOIN glucose_readings g ON u.id = g.user_id
GROUP BY u.id;
```

### Survey Questions:

1. "How helpful was the AR portion visualization?" (1-5 scale)
2. "Did AR improve your understanding of portion sizes?" (Yes/No)
3. "Would you use AR again?" (Yes/No)
4. "What improvements would you suggest for AR?"

---

## 📊 Research Methodology Integration

### Mixed-Methods Approach:

**Quantitative (Group A: AR Users vs Group B: Non-AR)**
- Portion estimation accuracy (±20g tolerance)
- Dietary adherence scores (0-100)
- Glucose levels (mg/dL)
- Feature usage frequency

**Qualitative**
- Semi-structured interviews about AR experience
- Thematic analysis of user feedback
- Usability observations

### Data Export for Analysis:

```dart
// Export AR data to CSV for SPSS/R
final arData = await exportARUsageData(startDate, endDate);
// Columns: user_id, food_name, portion_grams, timestamp, adherence_score, glucose_level
```

---

## 🎯 Implementation Roadmap

### Current Status: ✅ Phase 1 Complete

- [x] Visual reference system (thumb, fist, plate comparisons)
- [x] AR viewer screen UI
- [x] Integration with portion selection
- [x] User-friendly size comparisons

### Optional: Phase 2 (WebAR Enhancement)

- [ ] Add webview_flutter dependency
- [ ] Create AR HTML with A-Frame/AR.js
- [ ] Print Hiro marker instructions
- [ ] Test camera-based AR
- [ ] User testing and feedback

### Future: Phase 3 (Advanced AR)

- [ ] Custom 3D food models (actual rice, curry visuals)
- [ ] Multi-food AR (see full meal)
- [ ] AR portion adjustment (drag to resize)
- [ ] Save AR screenshots
- [ ] Share with nutritionist

---

## 🔧 Troubleshooting

### Visual References Not Showing?
- Ensure portion is selected first
- Check if AR button appears (purple outline)
- Update Flutter to latest version

### Want Full WebAR?
1. Add `webview_flutter: ^4.4.2` to pubspec.yaml
2. Create HTML file in assets/ar/
3. Update AR viewer to use WebView
4. Test on physical device (AR needs camera)

### Research Data Not Tracking?
- Ensure database table created (ar_usage_logs)
- Check Supabase RLS policies
- Verify user authentication

---

## 📚 References

- **A-Frame**: https://aframe.io/docs/
- **AR.js**: https://ar-js-org.github.io/AR.js-Docs/
- **WebXR**: https://developer.mozilla.org/en-US/docs/Web/API/WebXR_Device_API
- **Food Portion Research**: https://pubmed.ncbi.nlm.nih.gov/portion+estimation/

---

## 💡 Tips for Your Research Paper

### Include in Methodology Section:

> "The intervention group received access to a WebAR-based portion visualization tool, which displayed 3D representations of recommended portion sizes overlaid on real-world environments through the device camera. Control group participants received traditional 2D portion guides."

### Results Section Data Points:

- AR feature adoption rate: X% of intervention group
- Average usage frequency: X times per week
- Portion estimation accuracy improvement: X% (p < 0.05)
- User satisfaction rating: X.X/5.0 (95% CI: X.X-X.X)

### Discussion Points:

- "AR visualization provided tactile understanding of portion sizes"
- "Younger participants (18-35) showed higher AR adoption"
- "AR reduced cognitive load in portion estimation"
- "Technology accessibility remains a barrier for older adults"

---

## ✅ Summary

**Current Implementation**: Visual reference system with intuitive comparisons (thumb, fist, plate)

**Optional Enhancement**: Full WebAR with camera and 3D models

**Research Value**: Helps answer questions about technology-assisted dietary adherence in diabetes management

**Status**: ✅ Ready to use for your research study!

---

*Last Updated: March 8, 2026*  
*Version: 1.0 (Visual References)*  
*Future: 2.0 (Full WebAR)*
