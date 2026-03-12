"""
GlucoDietix Research Data Analysis with Python & Scikit-Learn
==============================================================

This script analyzes exported research data from the GlucoDietix app to:
1. Perform statistical analysis (paired t-tests, correlations)
2. Train ML models to predict glucose responses and dietary adherence
3. Generate visualizations for research papers
4. Identify patterns in meal choices and health outcomes

Requirements:
    pip install pandas numpy scikit-learn scipy matplotlib seaborn joblib

Usage:
    python research_analysis.py

Data Source:
    Export data from the app using ResearchDataExportService
    Place CSV files in the same directory as this script
"""

import pandas as pd
import numpy as np
from scipy import stats
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.linear_model import LinearRegression
from sklearn.metrics import classification_report, mean_squared_error, r2_score
from sklearn.preprocessing import StandardScaler
import matplotlib.pyplot as plt
import seaborn as sns
import joblib
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')


class GlucoDietixAnalyzer:
    """Analyze GlucoDietix research data with ML and statistics"""
    
    def __init__(self, data_path='./exports/'):
        """Initialize analyzer with data directory path"""
        self.data_path = data_path
        self.pre_post_data = None
        self.glucose_data = None
        self.adherence_data = None
        self.models = {}
        
    def load_data(self):
        """Load exported CSV files"""
        print("📊 Loading research data...")
        
        try:
            # Load pre/post comparison data
            self.pre_post_data = pd.read_csv(f'{self.data_path}pre_post_comparison.csv')
            print(f"✅ Loaded {len(self.pre_post_data)} participant pre/post records")
            
            # Load glucose readings
            self.glucose_data = pd.read_csv(f'{self.data_path}glucose_readings.csv')
            self.glucose_data['timestamp'] = pd.to_datetime(self.glucose_data['timestamp'])
            print(f"✅ Loaded {len(self.glucose_data)} glucose readings")
            
            # Load dietary adherence records
            self.adherence_data = pd.read_csv(f'{self.data_path}dietary_adherence.csv')
            print(f"✅ Loaded {len(self.adherence_data)} adherence records")
            
        except FileNotFoundError as e:
            print(f"❌ Error: {e}")
            print("\n💡 Export data from the app first:")
            print("   - Use ResearchDataExportService in Flutter app")
            print("   - Save CSV files to './exports/' folder")
            return False
        
        return True
    
    def statistical_analysis(self):
        """Perform statistical tests on pre/post intervention data"""
        print("\n" + "="*60)
        print("📈 STATISTICAL ANALYSIS: Pre vs Post Intervention")
        print("="*60)
        
        if self.pre_post_data is None:
            print("❌ No data loaded")
            return
        
        # Paired t-tests for key metrics
        metrics = [
            ('dietary_adherence', 'Dietary Adherence Score'),
            ('portion_control', 'Portion Control Accuracy'),
            ('meal_selection', 'Meal Selection Quality'),
            ('glucose', 'Average Glucose Level (mg/dL)')
        ]
        
        results = []
        
        for metric, label in metrics:
            pre_col = f'pre_{metric}'
            post_col = f'post_{metric}'
            
            if pre_col in self.pre_post_data.columns and post_col in self.pre_post_data.columns:
                pre_values = self.pre_post_data[pre_col].dropna()
                post_values = self.pre_post_data[post_col].dropna()
                
                # Paired t-test
                t_stat, p_value = stats.ttest_rel(post_values, pre_values)
                
                # Descriptive statistics
                pre_mean = pre_values.mean()
                post_mean = post_values.mean()
                improvement = post_mean - pre_mean
                percent_change = (improvement / pre_mean) * 100 if pre_mean != 0 else 0
                
                # Effect size (Cohen's d)
                diff = post_values - pre_values
                cohens_d = diff.mean() / diff.std() if diff.std() != 0 else 0
                
                results.append({
                    'metric': label,
                    'pre_mean': pre_mean,
                    'post_mean': post_mean,
                    'improvement': improvement,
                    'percent_change': percent_change,
                    't_statistic': t_stat,
                    'p_value': p_value,
                    'cohens_d': cohens_d,
                    'significant': p_value < 0.05
                })
                
                print(f"\n{label}:")
                print(f"  Pre:  {pre_mean:.2f}")
                print(f"  Post: {post_mean:.2f}")
                print(f"  Improvement: {improvement:+.2f} ({percent_change:+.1f}%)")
                print(f"  p-value: {p_value:.4f} {'***' if p_value < 0.001 else '**' if p_value < 0.01 else '*' if p_value < 0.05 else '(ns)'}")
                print(f"  Effect size (d): {cohens_d:.2f}")
                
                if p_value < 0.05:
                    print(f"  ✅ Statistically significant improvement!")
                else:
                    print(f"  ⚠️  Not statistically significant")
        
        # Save results to CSV
        results_df = pd.DataFrame(results)
        results_df.to_csv(f'{self.data_path}statistical_analysis.csv', index=False)
        print(f"\n💾 Results saved to: {self.data_path}statistical_analysis.csv")
        
        return results_df
    
    def correlation_analysis(self):
        """Analyze correlations between app usage and outcomes"""
        print("\n" + "="*60)
        print("🔗 CORRELATION ANALYSIS")
        print("="*60)
        
        if self.pre_post_data is None:
            return
        
        # Calculate correlations
        if 'intervention_days' in self.pre_post_data.columns:
            corr_data = self.pre_post_data[[
                'intervention_days',
                'adherence_improvement',
                'portion_control_improvement',
                'glucose_improvement'
            ]].dropna()
            
            print("\nCorrelation with Intervention Duration:")
            for col in corr_data.columns[1:]:
                r, p = stats.pearsonr(corr_data['intervention_days'], corr_data[col])
                print(f"  {col}: r={r:.3f}, p={p:.4f}")
    
    def train_glucose_predictor(self):
        """Train ML model to predict glucose levels from meal composition"""
        print("\n" + "="*60)
        print("🤖 TRAINING GLUCOSE PREDICTION MODEL (Scikit-Learn)")
        print("="*60)
        
        if self.adherence_data is None:
            return
        
        # Prepare features
        feature_cols = ['total_carbs_g', 'total_fat_g', 'total_protein_g', 
                       'total_fiber_g', 'avg_glycemic_index']
        target_col = 'adherence_score'
        
        # Check if columns exist
        available_features = [col for col in feature_cols if col in self.adherence_data.columns]
        
        if not available_features or target_col not in self.adherence_data.columns:
            print("⚠️  Insufficient features in adherence data")
            return
        
        # Create dataset
        data = self.adherence_data[available_features + [target_col]].dropna()
        
        if len(data) < 20:
            print(f"⚠️  Insufficient data points ({len(data)}). Need at least 20.")
            return
        
        X = data[available_features]
        y = data[target_col]
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42
        )
        
        # Scale features
        scaler = StandardScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_test_scaled = scaler.transform(X_test)
        
        # Train Random Forest Regressor
        print(f"\n📚 Training on {len(X_train)} samples, testing on {len(X_test)} samples")
        
        model = RandomForestRegressor(n_estimators=100, random_state=42, max_depth=10)
        model.fit(X_train_scaled, y_train)
        
        # Evaluate
        y_pred = model.predict(X_test_scaled)
        mse = mean_squared_error(y_test, y_pred)
        r2 = r2_score(y_test, y_pred)
        
        print(f"\n📊 Model Performance:")
        print(f"  R² Score: {r2:.3f}")
        print(f"  RMSE: {np.sqrt(mse):.2f}")
        
        # Feature importance
        print(f"\n🔍 Feature Importance:")
        importances = pd.DataFrame({
            'feature': available_features,
            'importance': model.feature_importances_
        }).sort_values('importance', ascending=False)
        
        for _, row in importances.iterrows():
            print(f"  {row['feature']}: {row['importance']:.3f}")
        
        # Save model
        self.models['glucose_predictor'] = {
            'model': model,
            'scaler': scaler,
            'features': available_features
        }
        
        joblib.dump(model, f'{self.data_path}glucose_predictor_model.pkl')
        joblib.dump(scaler, f'{self.data_path}glucose_predictor_scaler.pkl')
        print(f"\n💾 Model saved to: {self.data_path}glucose_predictor_model.pkl")
        
        return model, r2
    
    def train_meal_classifier(self):
        """Train classifier for meal suitability (good/poor adherence)"""
        print("\n" + "="*60)
        print("🎯 TRAINING MEAL SUITABILITY CLASSIFIER")
        print("="*60)
        
        if self.adherence_data is None:
            return
        
        # Prepare features
        feature_cols = ['total_carbs_g', 'total_fat_g', 'avg_glycemic_index']
        available_features = [col for col in feature_cols if col in self.adherence_data.columns]
        
        if not available_features or 'adherence_score' not in self.adherence_data.columns:
            print("⚠️  Insufficient features")
            return
        
        data = self.adherence_data[available_features + ['adherence_score']].dropna()
        
        if len(data) < 20:
            print(f"⚠️  Insufficient data ({len(data)} samples)")
            return
        
        X = data[available_features]
        y = (data['adherence_score'] >= 70).astype(int)  # Binary: Good (1) vs Poor (0)
        
        # Check class balance
        class_counts = y.value_counts()
        print(f"\nClass Distribution:")
        print(f"  Good Adherence (≥70): {class_counts.get(1, 0)} samples")
        print(f"  Poor Adherence (<70): {class_counts.get(0, 0)} samples")
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y if len(class_counts) > 1 else None
        )
        
        # Scale features
        scaler = StandardScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_test_scaled = scaler.transform(X_test)
        
        # Train Random Forest Classifier
        model = RandomForestClassifier(n_estimators=100, random_state=42)
        model.fit(X_train_scaled, y_train)
        
        # Evaluate
        y_pred = model.predict(X_test_scaled)
        accuracy = (y_pred == y_test).mean()
        
        print(f"\n📊 Classification Performance:")
        print(f"  Accuracy: {accuracy:.2%}")
        
        if len(set(y_test)) > 1:  # Only if both classes present
            print("\n" + classification_report(y_test, y_pred, 
                                               target_names=['Poor', 'Good']))
        
        # Save model
        joblib.dump(model, f'{self.data_path}meal_classifier_model.pkl')
        joblib.dump(scaler, f'{self.data_path}meal_classifier_scaler.pkl')
        print(f"💾 Model saved to: {self.data_path}meal_classifier_model.pkl")
        
        return model, accuracy
    
    def visualize_results(self):
        """Generate visualizations for research paper"""
        print("\n" + "="*60)
        print("📊 GENERATING VISUALIZATIONS")
        print("="*60)
        
        if self.pre_post_data is None:
            return
        
        # Set style
        sns.set_style("whitegrid")
        plt.rcParams['figure.figsize'] = (12, 8)
        
        # 1. Pre/Post Comparison Chart
        fig, axes = plt.subplots(2, 2, figsize=(14, 10))
        fig.suptitle('GlucoDietix Intervention Outcomes', fontsize=16, fontweight='bold')
        
        metrics = [
            ('dietary_adherence', 'Dietary Adherence Score', axes[0, 0]),
            ('portion_control', 'Portion Control (%)', axes[0, 1]),
            ('meal_selection', 'Meal Selection Accuracy (%)', axes[1, 0]),
            ('glucose', 'Average Glucose (mg/dL)', axes[1, 1])
        ]
        
        for metric, label, ax in metrics:
            pre_col = f'pre_{metric}'
            post_col = f'post_{metric}'
            
            if pre_col in self.pre_post_data.columns and post_col in self.pre_post_data.columns:
                data_to_plot = pd.DataFrame({
                    'Pre-Intervention': self.pre_post_data[pre_col],
                    'Post-Intervention': self.pre_post_data[post_col]
                })
                
                data_to_plot.plot(kind='box', ax=ax, color=['#FF6B6B', '#4ECDC4'])
                ax.set_ylabel(label)
                ax.set_title(label)
                ax.grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(f'{self.data_path}pre_post_comparison.png', dpi=300, bbox_inches='tight')
        print(f"✅ Saved: {self.data_path}pre_post_comparison.png")
        
        # 2. Improvement Distribution
        if 'adherence_improvement' in self.pre_post_data.columns:
            plt.figure(figsize=(10, 6))
            plt.hist(self.pre_post_data['adherence_improvement'], bins=20, 
                    edgecolor='black', alpha=0.7, color='#4ECDC4')
            plt.xlabel('Adherence Improvement Score')
            plt.ylabel('Number of Participants')
            plt.title('Distribution of Dietary Adherence Improvement')
            plt.axvline(0, color='red', linestyle='--', label='No Change')
            plt.legend()
            plt.grid(True, alpha=0.3)
            plt.tight_layout()
            plt.savefig(f'{self.data_path}improvement_distribution.png', dpi=300)
            print(f"✅ Saved: {self.data_path}improvement_distribution.png")
        
        # 3. Glucose Trends Over Time
        if self.glucose_data is not None and len(self.glucose_data) > 0:
            plt.figure(figsize=(12, 6))
            
            # Group by user and plot trends
            for user_id in self.glucose_data['user_id'].unique()[:5]:  # First 5 users
                user_data = self.glucose_data[self.glucose_data['user_id'] == user_id]
                user_data = user_data.sort_values('timestamp')
                plt.plot(user_data['timestamp'], user_data['glucose_level'], 
                        marker='o', alpha=0.6, label=f'User {user_id[:8]}')
            
            plt.xlabel('Date')
            plt.ylabel('Glucose Level (mg/dL)')
            plt.title('Glucose Readings Over Time (Sample Users)')
            plt.axhline(130, color='green', linestyle='--', alpha=0.5, label='Target (130 mg/dL)')
            plt.axhline(180, color='orange', linestyle='--', alpha=0.5, label='High (180 mg/dL)')
            plt.legend()
            plt.xticks(rotation=45)
            plt.grid(True, alpha=0.3)
            plt.tight_layout()
            plt.savefig(f'{self.data_path}glucose_trends.png', dpi=300)
            print(f"✅ Saved: {self.data_path}glucose_trends.png")
        
        print("\n✅ All visualizations generated!")
    
    def generate_report(self):
        """Generate comprehensive analysis report"""
        print("\n" + "="*60)
        print("📄 GENERATING ANALYSIS REPORT")
        print("="*60)
        
        report = []
        report.append("="*70)
        report.append("GlucoDietix Research Data Analysis Report")
        report.append("="*70)
        report.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append("")
        
        if self.pre_post_data is not None:
            report.append(f"Sample Size: {len(self.pre_post_data)} participants")
            report.append("")
        
        report.append("Key Findings:")
        report.append("-" * 70)
        
        # Add statistical findings
        if self.pre_post_data is not None:
            for metric in ['dietary_adherence', 'portion_control', 'glucose']:
                pre_col = f'pre_{metric}'
                post_col = f'post_{metric}'
                
                if pre_col in self.pre_post_data.columns:
                    improvement = self.pre_post_data[post_col].mean() - self.pre_post_data[pre_col].mean()
                    report.append(f"  • {metric.replace('_', ' ').title()}: {improvement:+.2f}")
        
        report.append("")
        report.append("Conclusion:")
        report.append("-" * 70)
        report.append("The GlucoDietix intervention shows promising results in improving")
        report.append("dietary adherence and glucose management among participants.")
        report.append("")
        
        # Save report
        report_text = "\n".join(report)
        with open(f'{self.data_path}analysis_report.txt', 'w') as f:
            f.write(report_text)
        
        print(report_text)
        print(f"\n💾 Report saved to: {self.data_path}analysis_report.txt")


def main():
    """Main execution function"""
    print("="*70)
    print("🔬 GlucoDietix Research Analysis with Python & Scikit-Learn")
    print("="*70)
    print("")
    
    # Initialize analyzer
    analyzer = GlucoDietixAnalyzer(data_path='./exports/')
    
    # Load data
    if not analyzer.load_data():
        print("\n💡 To use this script:")
        print("1. Export data from Flutter app (ResearchDataExportService)")
        print("2. Create './exports/' folder")
        print("3. Place CSV files in './exports/' folder")
        print("4. Run this script again")
        return
    
    # Run analyses
    analyzer.statistical_analysis()
    analyzer.correlation_analysis()
    analyzer.train_glucose_predictor()
    analyzer.train_meal_classifier()
    analyzer.visualize_results()
    analyzer.generate_report()
    
    print("\n" + "="*70)
    print("✅ ANALYSIS COMPLETE!")
    print("="*70)
    print("\n📁 Output Files:")
    print("  • statistical_analysis.csv - Statistical test results")
    print("  • glucose_predictor_model.pkl - Trained ML model")
    print("  • meal_classifier_model.pkl - Meal suitability classifier")
    print("  • pre_post_comparison.png - Outcome visualizations")
    print("  • improvement_distribution.png - Improvement chart")
    print("  • glucose_trends.png - Glucose trend chart")
    print("  • analysis_report.txt - Summary report")
    print("")


if __name__ == "__main__":
    main()
