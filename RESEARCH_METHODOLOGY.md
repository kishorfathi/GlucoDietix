# 🔬 GlucoDietix Research Methodology Implementation

## Overview
This document describes the research methodology implementation for the study: **"Machine Learning-Based Mobile Application for Personalized Dietary Management of Diabetes in Sri Lanka"**

---

## 📊 Research Design: Mixed-Methods Approach

### Quantitative Components
- Blood glucose tracking (mg/dL)
- Dietary adherence scores (0-100)
- Portion control accuracy
- Meal selection improvements
- Pre/Post intervention assessments

### Qualitative Components
- User experience questionnaires
- Usability feedback (Likert scale 1-5)
- Engagement surveys
- Open-ended feedback
- Challenges and suggestions

---

## 🎯 Research Objectives Mapped to Features

| Research Objective | Implementation | Data Collected |
|-------------------|----------------|----------------|
| Measure dietary adherence | `DietaryAdherenceRecord` model | Adherence scores, compliance rates |
| Track blood glucose | `GlucoseReading` model | Glucose levels, timestamps, meal links |
| Assess portion control | ML portion detection + tracking | Recommended vs actual portions |
| Evaluate meal selection | ML recommendations + user choices | Food selections, GI avoidance |
| Gather user feedback | `ResearchAssessment` surveys | Likert scores, comments, suggestions |
| Ensure ethics | `InformedConsent` model | Consent checkboxes, signatures |
| Analyze intervention effect | Pre/Post assessments | Score improvements, health metrics |

---

## 📱 Participant Journey

### Phase 1: Enrollment & Consent (Day 0)
1. **Informed Consent Screen**
   - Display study purpose, procedures, risks/benefits
   - Explain voluntary participation
   - Explain data confidentiality
   - Collect digital signature
   - Store consent in database

2. **Pre-Intervention Assessment**
   - Baseline dietary adherence (self-reported 1-10)
   - Baseline portion control skills (1-10)
   - Baseline meal selection habits (1-10)
   - Current average glucose (if available)
   - Weight, height, HbA1c (if available)

### Phase 2: Intervention Period (Weeks 1-4)
1. **Daily App Usage**
   - Scan meals with camera (ML food detection)
   - Manual food selection (traditional method)
   - Portion guidance (AR optional feature)
   - Receive personalized recommendations
   - Log blood glucose readings

2. **Weekly Follow-up Surveys**
   - Engagement level (1-5)
   - Usability feedback (1-5)
   - Challenges faced (open text)
   - App usefulness perception (1-5)

3. **Automatic Tracking**
   - Every meal logged creates `DietaryAdherenceRecord`
   - Adherence score calculated (0-100)
   - Compliance metrics tracked:
     - Followed portion advice? (Y/N)
     - Avoided high GI foods? (Y/N)
     - Included recommended foods? (Y/N)

### Phase 3: Post-Intervention (Week 5)
1. **Post-Intervention Assessment**
   - Same questions as pre-assessment
   - Additional usability questions
   - AR feature usefulness (1-5)
   - Suggestions for improvement (open text)
   - Overall satisfaction

2. **Data Export for Analysis**
   - Compare pre vs post scores
   - Calculate improvements
   - Generate statistical summaries
   - Export CSV for SPSS/R/Python analysis

---

## 📊 Data Collection Schema

### 1. Glucose Readings (`glucose_readings` table)
```sql
Fields:
- user_id (participant ID)
- glucose_level (mg/dL)
- timestamp (date & time)
- reading_type (fasting, before_meal, after_meal, random)
- meal_id (linked to meal if applicable)
- notes (participant comments)
```

### 2. Research Assessments (`research_assessments` table)
```sql
Quantitative Metrics (1-10 scale):
- dietary_adherence_score
- portion_control_score
- meal_selection_accuracy

Health Metrics:
- average_glucose (last 7 days)
- weight (kg)
- hba1c (%)

Qualitative Metrics (1-5 Likert):
- usability_score
- engagement_score
- perceived_usefulness_score
- ar_feature_usefulness_score

Open-ended:
- challenges_faced (TEXT)
- suggestions_for_improvement (TEXT)
- additional_comments (TEXT)
```

### 3. Dietary Adherence Records (`dietary_adherence_records` table)
```sql
Recommendations Given:
- recommended_calories
- recommended_carbs
- recommended_portion_grams
- recommendations_given (JSON array)

Actual Consumption:
- actual_calories
- actual_carbs
- actual_portion_grams

Compliance Booleans:
- followed_portion_advice
- avoided_high_gi_foods
- included_recommended_foods

Score:
- adherence_score (0-100)
```

### 4. Informed Consent (`informed_consent` table)
```sql
Consent Checkboxes (all required):
- agreed_to_participate
- agreed_to_data_collection
- agreed_to_health_data_sharing
- understood_voluntary_participation
- understood_data_confidentiality
- understood_right_to_withdraw

Signature:
- signature (TEXT)
- consent_date

Withdrawal:
- withdrawal_date (if participant withdraws)
- withdrawal_reason
```

### 5. Meal History (`meal_history` table)
```sql
Meal Data:
- meal_date, meal_time, meal_type
- foods (JSON: [{food_id, grams, calories, carbs}])
- total_calories, total_carbs, total_protein, total_fat

Health Analysis:
- health_score (0-100)
- warnings (JSON array)
- recommendations (JSON array)

ML Detection:
- photo_url
- detected_foods (JSON)
- detection_confidence (0-1)
```

---

## 🤖 Machine Learning Integration

### Food Detection (Already Implemented)
**File**: `lib/services/food_detection_service.dart`

**Current**: Mock implementation with pattern matching
**For Production**: 
- Google Cloud Vision API
- AWS Rekognition
- Custom TensorFlow Lite model

**Features**:
- Detects Sri Lankan foods from photos
- Estimates portions automatically
- Confidence scoring (0-100%)
- Smart portion adjustment based on health profile

### Health Recommendations (Already Implemented)
**File**: `lib/services/health_recommendation_service.dart`

**Algorithm**:
1. Analyze meal composition (carbs, GI, fat, protein, fiber)
2. Compare to user health profile (diabetes, cholesterol)
3. Generate health score (0-100)
4. Identify warnings (high GI, high fat, etc.)
5. Suggest portion reductions (specific grams)
6. Recommend food swaps (e.g., white rice → red rice)

**ML Potential**:
- Train model on: {meal_composition, health_profile} → {adherence_outcome, glucose_response}
- Personalized recommendations based on individual response patterns
- Predict glucose spike from meal composition

### Proposed Python ML Pipeline (Future)
```python
# Using Scikit-Learn for meal suitability prediction

import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier

# Load data exported from GlucoDietix
data = pd.read_csv('dietary_adherence_export.csv')

# Features: meal composition + health profile
X = data[['total_carbs', 'total_fat', 'glycemic_index', 
          'has_diabetes', 'glucose_target_min', 'cholesterol_concern']]

# Target: good adherence outcome (score >= 70)
y = (data['adherence_score'] >= 70).astype(int)

# Train model
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)
model = RandomForestClassifier(n_estimators=100)
model.fit(X_train, y_train)

# Export model for app integration
import joblib
joblib.dump(model, 'meal_suitability_model.pkl')
```

---

## 📈 Data Analysis Plan

### Statistical Analysis (Quantitative)

**1. Paired t-tests** (Pre vs Post):
- H0: No improvement in dietary adherence scores
- H1: Significant improvement post-intervention
- Variables: adherence, portion control, meal selection, glucose

**2. Descriptive Statistics**:
- Mean, median, SD of all scores
- Adherence rate percentages
- Glucose trends over time

**3. Correlation Analysis**:
- App usage frequency ↔ adherence improvement
- AR feature use ↔ portion accuracy
- Recommendation follow-up ↔ glucose control

**Export Format**: CSV files ready for SPSS, R, Python
```csv
user_id,pre_adherence,post_adherence,improvement,pre_glucose,post_glucose,glucose_change
uuid1,5,8,3,150,120,-30
uuid2,6,9,3,140,115,-25
```

### Thematic Analysis (Qualitative)

**1. Open-ended Responses**:
- Challenges faced (barriers to adherence)
- Suggestions for improvement (app features)
- Additional comments (user experiences)

**2. Coding Themes**:
- Usability issues
- Motivational factors
- Cultural food preferences
- Technical difficulties

**3. Satisfaction Metrics**:
- Overall satisfaction score (mean of usability, engagement, usefulness)
- AR feature adoption rate
- Net Promoter Score (would recommend?)

---

## 🔒 Ethical Considerations

### Informed Consent Process
1. **Screen 1**: Study purpose and procedures explained
2. **Screen 2**: Risks and benefits outlined
3. **Screen 3**: Data confidentiality assured
4. **Screen 4**: Voluntary participation emphasized
5. **Screen 5**: Right to withdraw explained
6. **Screen 6**: Checkbox consent + digital signature
7. **Confirmation**: Consent stored in database with timestamp

### Data Confidentiality
- All personal data encrypted in Supabase
- Participant IDs anonymized (UUIDs)
- Export removes identifying information
- Only aggregated data in research papers
- Secure authentication (Row Level Security)

### Voluntary Participation
- No coercion or incentives mentioned
- Can withdraw at any time via app settings
- Withdrawal triggers `withdrawal_date` in database
- Data deletion option available

### Risk Mitigation
- App is educational tool, not medical device
- Disclaimers: "Consult doctor for medical decisions"
- No diagnosis or treatment provided
- Emergency glucose ranges trigger doctor advice

---

## 📊 Sample Size & Power Analysis

### Target Sample Size
- **Minimum**: 30 participants (paired t-test power ≥ 0.80)
- **Recommended**: 50-100 participants (account for dropouts)

### Inclusion Criteria
- Diagnosed with Type 2 diabetes
- Age 18-65
- Own smartphone (Android/iOS)
- Literate in English/Sinhala/Tamil
- Willing to log meals daily
- Able to check blood glucose

### Exclusion Criteria
- Type 1 diabetes
- Pregnancy
- Severe complications
- Unable to use smartphone

---

## 📱 App Features Supporting Research

### ✅ Already Implemented
1. **ML Food Detection** - Automatic meal composition analysis
2. **Health Recommendations** - Personalized dietary advice
3. **Portion Guidance** - Smart portion suggestions
4. **Meal Tracking** - Food diary with photos
5. **User Profiles** - Health parameter storage

### 🆕 Research Extensions (This Implementation)
1. **Glucose Tracking** - Log blood glucose readings
2. **Research Assessments** - Pre/Post/Weekly surveys
3. **Adherence Monitoring** - Automatic compliance scoring
4. **Informed Consent** - Digital consent workflow
5. **Data Export** - CSV/JSON for analysis

### 🔮 Optional AR Feature (Future)
**Technology**: WebAR (A-Frame/Three.js)
**Purpose**: Visual portion size guidance
**Implementation**:
- Browser-based (no app installation needed)
- Show 3D models of portions on plate
- Compare "ideal portion" vs "current portion"
- Accessibility: Works on low-end devices
**Research Question**: Does AR improve portion accuracy?

---

## 📤 Data Export Examples

### Export 1: Pre/Post Comparison CSV
```csv
user_id,pre_adherence,post_adherence,adherence_improvement,pre_glucose,post_glucose,glucose_improvement,intervention_days
uuid1,5,8,3,150,120,30,28
uuid2,6,9,3,140,115,25,30
```

### Export 2: Statistical Summary JSON
```json
{
  "sample_size": 50,
  "mean_dietary_adherence_improvement": 2.8,
  "std_deviation": 1.2,
  "mean_glucose_improvement": 18.5,
  "portion_compliance_rate": 72.3,
  "overall_satisfaction": 4.2
}
```

### Export 3: Qualitative Feedback
```csv
user_id,challenge,suggestion,satisfaction
uuid1,"Hard to estimate portions","Add portion comparison images",4
uuid2,"Too many notifications","Make notifications optional",5
```

---

## 🎓 Research Output

### Expected Publications
1. **Conference Paper**: ICHCC, Springer
2. **Journal Article**: Health informatics journal
3. **Thesis Chapter**: Methodology & results

### Key Findings (Expected)
- Significant improvement in dietary adherence (p < 0.05)
- Positive user feedback on ML features (mean > 4.0/5)
- Reduction in average glucose levels
- High usability scores for Sri Lankan context

### Contributions
1. **Practical**: Mobile app for diabetes management in Sri Lanka
2. **Theoretical**: ML application in dietary adherence
3. **Methodological**: Mixed-methods study design
4. **Cultural**: Sri Lankan food database integration

---

## 🚀 Implementation Checklist

### Database Setup
- [ ] Run `database/research_schema.sql` in Supabase
- [ ] Verify all tables created
- [ ] Test RLS policies
- [ ] Create database backups

### App Integration
- [ ] Implement Informed Consent screen
- [ ] Implement Pre-Assessment screen
- [ ] Implement Glucose Tracking screen
- [ ] Implement Weekly Survey screen
- [ ] Implement Post-Assessment screen
- [ ] Add "Withdraw from Study" option
- [ ] Test data export functionality

### Ethical Approval
- [ ] Submit to IRB/Ethics Committee
- [ ] Get approval letter
- [ ] Register study (if required)
- [ ] Prepare participant information sheet

### Data Collection
- [ ] Recruit participants
- [ ] Obtain informed consent
- [ ] Conduct pre-assessment
- [ ] Monitor compliance weekly
- [ ] Conduct post-assessment
- [ ] Export data for analysis

---

## 📞 Support & Resources

### Research Documentation
- [RESEARCH_METHODOLOGY.md](RESEARCH_METHODOLOGY.md) - This file
- [database/research_schema.sql](database/research_schema.sql) - Database structure
- [lib/models/](lib/models/) - Data models
- [lib/services/research_data_export_service.dart](lib/services/research_data_export_service.dart) - Export tools

### Data Models
- `GlucoseReading` - Blood glucose tracking
- `ResearchAssessment` - Pre/Post surveys
- `DietaryAdherenceRecord` - Compliance tracking
- `InformedConsent` - Ethics compliance
- `WeeklyAdherenceSummary` - Progress summaries

### Analysis Tools
- **ResearchDataExportService**: CSV/JSON export
- **Statistical functions**: Mean, SD, correlations
- **SQL queries**: Aggregations, summaries

---

**Research Investigator**: [Your Name]  
**Study Title**: Machine Learning-Based Mobile Application for Personalized Dietary Management of Diabetes in Sri Lanka  
**Institution**: [Your Institution]  
**Study Duration**: [Start Date] to [End Date]  
**IRB Approval**: Pending  

**Last Updated**: March 8, 2026  
**Version**: 1.0.0  
**Status**: ✅ Research Features Implemented
