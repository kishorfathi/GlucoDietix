# GlucoDietix - Enhanced Features Guide

## 🎉 New Features Overview

GlucoDietix has been significantly enhanced with 6 innovative features to help you better manage your diabetes through smart health tracking and personalized guidance.

---

## ✨ Feature 1: ML-Based Meal Recommendation

### What It Does
The app analyzes your personal health data including age, BMI, blood glucose level, and diet preferences to recommend personalized meals for breakfast, lunch, and dinner.

### How It Works
- **BMI Calculation**: Automatically calculates your BMI from height and weight
- **Calorie Targeting**: Determines optimal daily calorie needs based on your BMI and diabetes status
- **Glucose-Aware**: Adjusts recommendations based on your current glucose levels
- **Time-Based**: Distributes calories appropriately (30% breakfast, 40% lunch, 30% dinner)
- **Smart Filtering**: Avoids high GI foods when glucose is elevated
- **Portion Control**: Suggests appropriate portion sizes for better glucose management

### How to Use
1. Navigate to **"AI Meal Recommendations"** from the home screen
2. View personalized meal plans for breakfast, lunch, and dinner
3. Each meal shows:
   - Recommended foods with portion sizes
   - Reason for recommendation
   - Nutritional breakdown (calories, carbs, protein)
   - Daily summary and tips
4. Tap refresh to update recommendations based on latest glucose readings

### Key Benefits
- Personalized to your health profile
- Helps maintain target glucose levels
- Balanced nutrition across all meals
- Educational tips for success

---

## 📸 Feature 2: Food Image Recognition

### What It Does
Capture a photo of your meal and the app automatically identifies foods and estimates nutritional values including calories, carbohydrates, and sugar content.

### How It Works
- **On-Device ML**: Uses Google ML Kit for fast, private food detection on Android/iOS
- **Cloud Vision API**: Optional cloud-based detection for enhanced accuracy
- **Food Matching**: Matches detected labels to comprehensive Sri Lankan food database
- **Portion Estimation**: Estimates reasonable portion sizes based on detected foods
- **Nutrition Calculation**: Provides detailed nutritional breakdown

### How to Use
1. Go to **"Food Image Recognition"** or **"Log Meal"**
2. Tap the camera icon
3. Take a photo of your meal
4. Review detected foods and adjust portions if needed
5. Save to your meal log

### Supported Foods
- Sri Lankan traditional dishes
- International cuisine
- Fruits and vegetables
- Grains and proteins
- Common snacks and beverages

---

## 🚨 Feature 3: Smart Glucose Alert System

### What It Does
Continuously monitors your glucose readings and sends intelligent alerts when levels are too high or too low, along with specific recommended actions.

### Alert Levels

#### 🔴 Critical Low (<54 mg/dL)
- **Action**: IMMEDIATE - Eat 15-20g fast-acting carbs
- **Follow-up**: Recheck in 15 minutes
- **Warning**: Do NOT exercise or drive

#### ⚠️ Warning Low (54-70 mg/dL)
- **Action**: Consume 15g fast-acting carbs
- **Follow-up**: Rest and recheck in 15 minutes
- **Tip**: Have snack if next meal >1 hour away

#### ⚠️ Warning High (180-250 mg/dL)
- **Action**: Drink water, light exercise
- **Avoid**: Additional carbohydrates
- **Monitor**: Check levels regularly

#### 🔴 Critical High (>250 mg/dL)
- **Action**: Contact doctor immediately
- **Hydrate**: Drink plenty of water
- **Warning**: Do NOT exercise if >240 mg/dL

### Trend Analysis
The system also analyzes:
- **Rising trends**: Warns you to reduce carb intake
- **Falling trends**: Alerts you to have carbs ready
- **Stability**: Confirms good glucose control
- **Patterns**: Identifies recurring high/low periods

### How to Use
1. Alerts appear automatically on the home screen when you log glucose readings
2. View detailed recommendations for each alert
3. Track glucose trends in Progress & Reports
4. Set up reminders for regular glucose checks

---

## 🏃 Feature 4: Exercise Recommendation

### What It Does
Provides personalized daily exercise suggestions based on your health condition, BMI, and current glucose levels, with detailed safety guidelines.

### Recommended Exercises

#### 🌅 Morning Walk (20 min)
- **Intensity**: Low
- **Calories**: ~80
- **Best for**: Lowering fasting blood sugar
- **Safety**: Check glucose before and after

#### 🧘 Yoga & Stretching (15 min)
- **Intensity**: Low
- **Calories**: ~50
- **Best for**: Stress reduction, flexibility
- **Safety**: Avoid inverted poses if high BP

#### 🚴 Cycling/Swimming (30 min)
- **Intensity**: Moderate
- **Calories**: ~200
- **Best for**: Cardiovascular health
- **Condition**: BMI <30, glucose not "high"

#### 💪 Light Resistance Training (20 min)
- **Intensity**: Moderate
- **Calories**: ~100
- **Best for**: Building muscle, improving insulin sensitivity
- **Frequency**: 2-3 times per week

#### 🌙 Post-Dinner Walk (15 min)
- **Intensity**: Low
- **Calories**: ~60
- **Best for**: Reducing post-meal glucose spike
- **Timing**: 30 minutes after dinner

### Safety Features
- **Glucose-Based Recommendations**: Adjusts based on current levels
- **Safety Warnings**: Clear guidelines for when NOT to exercise
- **Preparation Checklist**: Ensures you're ready before starting
- **Detailed Instructions**: Step-by-step guidance for each exercise

### How to Use
1. Navigate to **"Exercise Recommendations"**
2. Review your personalized exercise plan
3. Check the safety card at the top
4. Expand each exercise to see:
   - Benefits
   - Detailed instructions
   - Safety notes
   - Best timing
5. Tap "Start Exercise" when ready

---

## 📊 Feature 5: Progress Tracking and Reports

### What It Does
Displays comprehensive weekly and monthly charts showing glucose trends, time-in-range analysis, and health improvements. Generate detailed reports to share with your doctor.

### Available Charts

#### 📈 Glucose Trend Chart
- Line graph showing glucose levels over time
- Color-coded points (green=normal, orange/red=abnormal)
- Touch to see exact values and timestamps
- Shows patterns and variations

#### 🕐 Glucose by Time of Day
- Bar chart showing average glucose at different hours
- Identifies problematic times (e.g., high morning readings)
- Helps optimize meal and medication timing

#### 📊 Glucose Distribution
- Breakdown of readings by range:
  - Very Low (<70 mg/dL)
  - Normal (70-130 mg/dL)
  - High (130-180 mg/dL)
  - Very High (>180 mg/dL)
- Percentage in each category
- Visual progress bars

### Summary Metrics
- **Average Glucose**: Overall control indicator
- **Time in Range**: Percentage of readings in target
- **High/Low Count**: Number of abnormal readings

### Smart Insights
The app analyzes your data to provide:
- Trend identification
- Variability warnings
- Time-based patterns
- Actionable recommendations

### Report Generation
1. Tap the share icon in Progress & Reports
2. Generate comprehensive PDF report including:
   - All charts and trends
   - Summary statistics
   - Meal and medication logs
   - Personalized insights
3. Email directly to your doctor

### How to Use
1. Navigate to **"Progress & Reports"**
2. Toggle between 7-day and 30-day views
3. Scroll through charts and insights
4. Use findings to adjust your diabetes management plan

---

## 💊 Feature 6: Water Intake and Medication Reminders

### What It Does
Sends timely reminders for medications, meals, water intake, and glucose checks to support consistent diabetes management.

### Reminder Types

#### 💊 Medication Reminders
- Morning medication (8:00 AM)
- Evening medication (8:00 PM)
- Customizable for your medication schedule

#### 🍽️ Meal Reminders
- Breakfast (7:30 AM)
- Lunch (12:30 PM)
- Dinner (7:00 PM)
- Helps maintain regular eating schedule

#### 💧 Water Intake Reminders
- Morning hydration (9:00 AM)
- Afternoon hydration (3:00 PM)
- Evening hydration (6:00 PM)
- Daily goal: 2 liters

#### 🩸 Glucose Check Reminders
- Fasting check (7:00 AM)
- Bedtime check (10:00 PM)
- Regular monitoring

### Water Tracking
- Track daily water intake
- Visual progress bar showing goal completion
- Quick-add buttons for common amounts:
  - Glass: 250ml
  - Bottle: 500ml
  - Large: 750ml
- Celebrates when you reach your 2L goal!

### Features
- **Mark as Complete**: Check off reminders as you complete them
- **Completion History**: Track how many times you've completed each reminder
- **Daily Reset**: Checklist resets each day
- **Smart Scheduling**: Only shows reminders for scheduled days
- **Quick Actions**: Fast access to common tasks

### How to Use
1. Navigate to **"Reminders & Tracking"**
2. View today's reminders sorted by time
3. Monitor water intake progress
4. Tap checkboxes to mark reminders as complete
5. Use quick action buttons for common tasks
6. Add custom reminders as needed

---

## 🎨 User Interface Design

### Color Scheme
- **Primary Teal** (#0B8F87): Main actions and headers
- **Accent Cyan** (#47BAC1): Secondary elements
- **Dark Blue** (#113B69): App bar and emphasis
- **Soft Background** (#F2FAFB): Easy on the eyes
- **Alert Colors**: 
  - Green: Normal/safe
  - Orange: Warning/caution
  - Red: Critical/danger

### Design Principles
- **Clean and Modern**: Minimalist healthcare interface
- **Easy Navigation**: Intuitive bottom navigation and clear pathways
- **Visual Feedback**: Color-coded status indicators
- **Accessibility**: Large text, clear icons, high contrast
- **Responsive**: Adapts to different screen sizes

---

## 🏠 Enhanced Home Dashboard

The new home dashboard is your central hub for all features:

### Quick Status
- Latest glucose reading with color-coded status
- Active alerts (if any) with recommendations
- Personalized greeting

### Quick Actions
- **Log Meal**: Instantly access meal builder
- **Add Glucose**: Quick glucose entry
- **Water**: Jump to water tracking

### Feature Cards
One-tap access to all 6 major features:
1. AI Meal Recommendations
2. Food Image Recognition
3. Exercise Recommendations
4. Reminders & Tracking
5. Progress & Reports
6. Profile Settings

---

## 🚀 Getting Started

### First Time Setup
1. **Create Account**: Sign up with email and password
2. **Complete Profile**: Enter your health information:
   - Age, weight, height
   - Diabetes type and treatment
   - Glucose targets
   - Cholesterol concerns
3. **Set Up Reminders**: Review and customize default reminders
4. **Log First Glucose Reading**: Establish baseline
5. **Explore Features**: Take a tour of all 6 new features

### Daily Routine
1. **Morning**:
   - Check fasting glucose
   - Mark morning medication as taken
   - View meal recommendations for breakfast
   - Check exercise plan

2. **Throughout Day**:
   - Log meals (with camera feature)
   - Track water intake
   - Monitor glucose alerts
   - Complete exercises

3. **Evening**:
   - Review daily progress
   - Log dinner
   - Take evening medication
   - Check bedtime glucose

4. **Weekly**:
   - Review progress charts
   - Adjust meal and exercise plans
   - Generate report for doctor if needed

---

## 💡 Tips for Success

### Glucose Management
- Check glucose at consistent times daily
- Log readings immediately for accurate trends
- Follow alert recommendations promptly
- Share progress reports with your healthcare provider

### Meal Planning
- Use AI recommendations as a starting point
- Adjust portions based on hunger and activity
- Focus on low GI foods when glucose is elevated
- Distribute carbs evenly across meals

### Exercise
- Start gradually and build up intensity
- Always check glucose before exercising
- Carry fast-acting carbs during exercise
- Exercise with a friend when possible

### Medication Adherence
- Set up all medication reminders
- Check them off as you take them
- Track completion rate
- Notify doctor of any missed doses

### Hydration
- Aim for 2 liters (8 glasses) daily
- Use quick-add buttons for easy tracking
- Increase intake during hot weather or exercise
- Consistent hydration helps glucose control

---

## 🔧 Technical Features

### Data Privacy
- All data stored securely in Supabase
- On-device ML processing (when possible)
- Encrypted communications
- User owns their health data

### Cross-Platform
- Android, iOS support
- Responsive design
- Optimized performance

### Offline Capability
- View recent data offline
- Sync when connection restored
- Local caching for performance

---

## 📞 Support & Feedback

### Need Help?
- Check TROUBLESHOOTING.md for common issues
- Review setup guides for specific features
- Contact support through the app

### Share Feedback
- Report bugs or issues
- Suggest new features
- Share success stories
- Help improve the app for everyone

---

## 📄 Additional Documentation

- **START_HERE.md**: Quick start guide
- **SETUP_GUIDE.md**: Detailed setup instructions
- **GOOGLE_VISION_SETUP.md**: Configure food detection
- **TROUBLESHOOTING.md**: Common issues and solutions

---

## 🎯 Health Disclaimer

GlucoDietix is designed to support your diabetes management but is not a substitute for professional medical advice. Always consult with your healthcare provider about:
- Medication adjustments
- Exercise programs
- Diet changes
- Treatment plans

In case of emergency or severe glucose abnormalities, contact your doctor or emergency services immediately.

---

**Version**: 2.0.0 (Enhanced Edition)
**Last Updated**: March 2026

**Developed with ❤️ for better diabetes management**
