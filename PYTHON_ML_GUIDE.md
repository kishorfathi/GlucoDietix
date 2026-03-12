# 🐍 Python & Scikit-Learn Integration Guide

## Overview

This guide shows how to use **Python and Scikit-Learn** for advanced machine learning analysis of research data collected by the GlucoDietix app.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│          Flutter App (Data Collection)                  │
│  - Food detection with YOLOv5 (On-device)              │
│  - Health recommendations (rule-based)                  │
│  - Glucose tracking, meal logging                       │
│  - Research assessments (pre/post)                      │
└────────────────┬────────────────────────────────────────┘
                 │
                 │ Export CSV/JSON
                 ↓
┌─────────────────────────────────────────────────────────┐
│          Supabase Database                              │
│  - glucose_readings, research_assessments               │
│  - dietary_adherence_records, meal_history              │
└────────────────┬────────────────────────────────────────┘
                 │
                 │ ResearchDataExportService
                 ↓
┌─────────────────────────────────────────────────────────┐
│          Python Analysis (research_analysis.py)         │
│  ✅ Statistical tests (paired t-tests, ANOVA)           │
│  ✅ ML models (Random Forest, Linear Regression)        │
│  ✅ Feature importance analysis                         │
│  ✅ Visualizations (Matplotlib, Seaborn)                │
└────────────────┬────────────────────────────────────────┘
                 │
                 ↓
        Research Insights & Publications
```

## What Python/Scikit-Learn Does

### ✅ Statistical Analysis
- **Paired t-tests**: Pre vs Post intervention comparisons
- **Effect sizes**: Cohen's d for clinical significance
- **Correlations**: App usage ↔ health outcomes
- **Power analysis**: Sample size validation

### ✅ Predictive Modeling
- **Glucose prediction**: Forecast glucose levels from meal composition
- **Adherence classification**: Good vs poor adherence prediction
- **Feature engineering**: Identify important nutrition factors
- **Model validation**: Cross-validation, R² scores

### ✅ Pattern Recognition
- **Clustering**: Group similar dietary patterns
- **Dimensionality reduction**: PCA for complex feature sets
- **Time series analysis**: Glucose trends over intervention period

### ✅ Visualization
- **Box plots**: Pre/Post comparisons
- **Scatter plots**: Correlations and relationships
- **Histograms**: Improvement distributions
- **Line charts**: Glucose trends over time

## Installation

### 1. Install Python
Download Python 3.9+ from [python.org](https://www.python.org/downloads/)

### 2. Install Dependencies
```bash
pip install -r requirements.txt
```

This installs:
- **pandas**: Data manipulation
- **numpy**: Numerical computing
- **scikit-learn**: Machine learning
- **scipy**: Statistical tests
- **matplotlib/seaborn**: Visualizations
- **joblib**: Model saving

## Usage Workflow

### Step 1: Collect Data in Flutter App
Users interact with the app for 4-week intervention period.

### Step 2: Export Data
```dart
// In Flutter app
final exporter = ResearchDataExportService();

// Export pre/post comparison
final csv = exporter.exportPrePostComparisonToCSV(
  preAssessments,
  postAssessments,
);
// Save to file

// Export glucose readings
final glucoseCsv = exporter.exportGlucoseReadingsToCSV(readings);

// Export adherence records
final adherenceCsv = exporter.exportDietaryAdherenceToCSV(records);
```

### Step 3: Organize Exported Files
```
GlucoDietix/
├── research_analysis.py
├── requirements.txt
└── exports/
    ├── pre_post_comparison.csv
    ├── glucose_readings.csv
    ├── dietary_adherence.csv
    └── assessments.csv
```

### Step 4: Run Python Analysis
```bash
python research_analysis.py
```

### Step 5: Review Results
Check the `exports/` folder for:
- **statistical_analysis.csv**: Statistical test results
- **glucose_predictor_model.pkl**: Trained ML model
- **meal_classifier_model.pkl**: Meal suitability classifier
- **pre_post_comparison.png**: Outcome visualizations
- **glucose_trends.png**: Glucose trend charts
- **analysis_report.txt**: Summary report

## Machine Learning Models

### 1. Glucose Level Predictor (Random Forest Regressor)

**Purpose**: Predict adherence score from meal composition

**Features**:
- Total carbohydrates (g)
- Total fat (g)
- Total protein (g)
- Total fiber (g)
- Average glycemic index

**Target**: Adherence score (0-100)

**Usage**:
```python
import joblib
import numpy as np

# Load model
model = joblib.load('exports/glucose_predictor_model.pkl')
scaler = joblib.load('exports/glucose_predictor_scaler.pkl')

# Predict for new meal
meal = np.array([[50, 10, 20, 5, 55]])  # carbs, fat, protein, fiber, GI
meal_scaled = scaler.transform(meal)
predicted_score = model.predict(meal_scaled)

print(f"Predicted adherence score: {predicted_score[0]:.1f}")
```

### 2. Meal Suitability Classifier (Random Forest Classifier)

**Purpose**: Classify meals as suitable (good adherence) or not

**Features**:
- Total carbohydrates
- Total fat
- Average glycemic index

**Target**: Binary (1 = Good adherence ≥70, 0 = Poor adherence <70)

**Usage**:
```python
import joblib

# Load classifier
classifier = joblib.load('exports/meal_classifier_model.pkl')
scaler = joblib.load('exports/meal_classifier_scaler.pkl')

# Classify meal
meal = np.array([[45, 8, 50]])  # carbs, fat, GI
meal_scaled = scaler.transform(meal)
is_suitable = classifier.predict(meal_scaled)[0]

print(f"Suitable for diabetic patient: {'Yes' if is_suitable else 'No'}")
```

## Example Analysis Output

```
========================================================================
📈 STATISTICAL ANALYSIS: Pre vs Post Intervention
========================================================================

Dietary Adherence Score:
  Pre:  5.67
  Post: 8.23
  Improvement: +2.56 (+45.1%)
  p-value: 0.0002 ***
  Effect size (d): 1.24
  ✅ Statistically significant improvement!

Portion Control Accuracy:
  Pre:  62.4%
  Post: 81.7%
  Improvement: +19.3%
  p-value: 0.0001 ***
  Effect size (d): 1.38
  ✅ Statistically significant improvement!

Average Glucose Level:
  Pre:  148.3 mg/dL
  Post: 122.5 mg/dL
  Improvement: -25.8 mg/dL (-17.4%)
  p-value: 0.0003 ***
  Effect size (d): 1.15
  ✅ Statistically significant improvement!

========================================================================
🤖 TRAINING GLUCOSE PREDICTION MODEL (Scikit-Learn)
========================================================================

📚 Training on 80 samples, testing on 20 samples

📊 Model Performance:
  R² Score: 0.742
  RMSE: 8.34

🔍 Feature Importance:
  avg_glycemic_index: 0.385
  total_carbs_g: 0.302
  total_fiber_g: 0.178
  total_fat_g: 0.089
  total_protein_g: 0.046

💾 Model saved to: exports/glucose_predictor_model.pkl
```

## Research Paper Integration

### Statistical Reporting
```
The intervention group showed significant improvements in dietary 
adherence (M_pre = 5.67, SD = 1.23; M_post = 8.23, SD = 1.45; 
t(49) = 12.34, p < .001, d = 1.24) and average glucose levels 
(M_pre = 148.3 mg/dL; M_post = 122.5 mg/dL; t(49) = 8.76, 
p < .001, d = 1.15).
```

### Machine Learning Results
```
A Random Forest model trained on meal composition data (n = 100 meals) 
achieved R² = 0.742 in predicting dietary adherence scores. Feature 
importance analysis revealed that glycemic index (38.5%) and total 
carbohydrates (30.2%) were the strongest predictors of adherence 
outcomes.
```

## Advanced Analysis Examples

### Custom Correlation Analysis
```python
import pandas as pd
from scipy import stats

data = pd.read_csv('exports/pre_post_comparison.csv')

# Correlation between intervention duration and glucose improvement
r, p = stats.pearsonr(
    data['intervention_days'],
    data['glucose_improvement']
)
print(f"Correlation: r={r:.3f}, p={p:.4f}")
```

### Time Series Analysis
```python
import pandas as pd
import matplotlib.pyplot as plt

glucose = pd.read_csv('exports/glucose_readings.csv')
glucose['timestamp'] = pd.to_datetime(glucose['timestamp'])
glucose = glucose.sort_values('timestamp')

# Rolling average (7-day window)
glucose['glucose_7day_avg'] = glucose['glucose_level'].rolling(window=7).mean()

plt.plot(glucose['timestamp'], glucose['glucose_7day_avg'])
plt.xlabel('Date')
plt.ylabel('7-Day Average Glucose (mg/dL)')
plt.title('Glucose Control Over Intervention Period')
plt.show()
```

### Subgroup Analysis
```python
# Compare outcomes by diabetes type
type1 = data[data['diabetes_type'] == 'Type 1']
type2 = data[data['diabetes_type'] == 'Type 2']

t_stat, p_value = stats.ttest_ind(
    type1['adherence_improvement'],
    type2['adherence_improvement']
)
print(f"Type 1 vs Type 2 improvement: p={p_value:.4f}")
```

## Model Deployment (Future)

### Option 1: API Endpoint
Deploy trained model as Flask/FastAPI service:
```python
from flask import Flask, request, jsonify
import joblib

app = Flask(__name__)
model = joblib.load('glucose_predictor_model.pkl')

@app.route('/predict', methods=['POST'])
def predict():
    meal_data = request.json
    prediction = model.predict([meal_data['features']])
    return jsonify({'predicted_score': float(prediction[0])})
```

### Option 2: TensorFlow Lite Conversion
Convert Scikit-Learn model to TensorFlow Lite for on-device inference:
```python
# Requires conversion pipeline (sklearn → ONNX → TFLite)
# Then integrate .tflite file into Flutter app
```

## Best Practices

1. **Data Quality**: Clean exported data before analysis
2. **Sample Size**: Ensure sufficient participants (n ≥ 30 recommended)
3. **Cross-Validation**: Use k-fold validation for robust models
4. **Feature Scaling**: Always scale features before ML training
5. **Model Selection**: Try multiple algorithms (RF, GBM, SVM)
6. **Interpretability**: Use feature importance for clinical insights
7. **Validation**: Test models on hold-out data before deployment

## Troubleshooting

### Issue: FileNotFoundError
**Solution**: Ensure CSV files are in `./exports/` folder

### Issue: Insufficient data points
**Solution**: Collect more research data from app users

### Issue: Poor model performance (R² < 0.5)
**Solution**: 
- Add more features (user demographics, activity level)
- Collect more training data
- Try different algorithms (GradientBoosting, SVM)

## References

- **Scikit-Learn**: https://scikit-learn.org/
- **Pandas**: https://pandas.pydata.org/
- **Statistical Analysis**: https://docs.scipy.org/doc/scipy/
- **Visualization**: https://matplotlib.org/, https://seaborn.pydata.org/

## Support

For questions about:
- **Data export**: See [lib/services/research_data_export_service.dart](lib/services/research_data_export_service.dart)
- **Research methodology**: See [RESEARCH_METHODOLOGY.md](RESEARCH_METHODOLOGY.md)
- **Python script**: See [research_analysis.py](research_analysis.py)

---

**Last Updated**: March 11, 2026  
**Status**: ✅ Ready for Research Data Analysis
