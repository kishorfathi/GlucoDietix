-- ================================================
-- GlucoDietix Research Extension Schema
-- For ML-Based Dietary Management Research Study
-- ================================================

-- ================================================
-- GLUCOSE READINGS TABLE
-- Tracks blood glucose measurements for research
-- ================================================
CREATE TABLE IF NOT EXISTS glucose_readings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  glucose_level DECIMAL(5,1) NOT NULL CHECK (glucose_level > 0 AND glucose_level < 600),
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reading_type TEXT NOT NULL CHECK (reading_type IN ('fasting', 'before_meal', 'after_meal', 'random')),
  meal_id UUID, -- Reference to meal if after_meal
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_glucose_user_timestamp ON glucose_readings(user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_glucose_reading_type ON glucose_readings(reading_type);

-- ================================================
-- RESEARCH ASSESSMENTS TABLE
-- Pre/Post intervention surveys
-- ================================================
CREATE TABLE IF NOT EXISTS research_assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  assessment_type TEXT NOT NULL CHECK (assessment_type IN ('pre_intervention', 'post_intervention', 'weekly_followup')),
  completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Quantitative Metrics (1-10 scale)
  dietary_adherence_score INT NOT NULL CHECK (dietary_adherence_score BETWEEN 1 AND 10),
  portion_control_score INT NOT NULL CHECK (portion_control_score BETWEEN 1 AND 10),
  meal_selection_accuracy INT NOT NULL CHECK (meal_selection_accuracy BETWEEN 1 AND 10),
  
  -- Health Metrics
  average_glucose DECIMAL(5,1), -- mg/dL (last 7 days)
  weight DECIMAL(5,2), -- kg
  hba1c DECIMAL(4,2), -- %
  
  -- Qualitative Metrics (1-5 Likert scale)
  usability_score INT NOT NULL CHECK (usability_score BETWEEN 1 AND 5),
  engagement_score INT NOT NULL CHECK (engagement_score BETWEEN 1 AND 5),
  perceived_usefulness_score INT NOT NULL CHECK (perceived_usefulness_score BETWEEN 1 AND 5),
  ar_feature_usefulness_score INT NOT NULL CHECK (ar_feature_usefulness_score BETWEEN 1 AND 5),
  
  -- Open-ended Feedback
  challenges_faced TEXT,
  suggestions_for_improvement TEXT,
  additional_comments TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_assessment_user_type ON research_assessments(user_id, assessment_type);
CREATE INDEX IF NOT EXISTS idx_assessment_completed ON research_assessments(completed_at DESC);

-- ================================================
-- DIETARY ADHERENCE RECORDS TABLE
-- Tracks compliance with recommendations
-- ================================================
CREATE TABLE IF NOT EXISTS dietary_adherence_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  meal_id UUID NOT NULL, -- Reference to meal
  
  -- Recommendations Given
  recommendations_given JSONB NOT NULL DEFAULT '[]'::jsonb,
  recommended_calories DECIMAL(7,2) NOT NULL,
  recommended_carbs DECIMAL(6,2) NOT NULL,
  recommended_portion_grams DECIMAL(7,2) NOT NULL,
  
  -- Actual Consumption
  actual_calories DECIMAL(7,2) NOT NULL,
  actual_carbs DECIMAL(6,2) NOT NULL,
  actual_portion_grams DECIMAL(7,2) NOT NULL,
  
  -- Compliance Metrics
  followed_portion_advice BOOLEAN NOT NULL DEFAULT FALSE,
  avoided_high_gi_foods BOOLEAN NOT NULL DEFAULT FALSE,
  included_recommended_foods BOOLEAN NOT NULL DEFAULT FALSE,
  
  -- Adherence Score (0-100)
  adherence_score DECIMAL(5,2) NOT NULL CHECK (adherence_score BETWEEN 0 AND 100),
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_adherence_user_date ON dietary_adherence_records(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_adherence_score ON dietary_adherence_records(adherence_score);

-- ================================================
-- INFORMED CONSENT TABLE
-- Ethical research compliance
-- ================================================
CREATE TABLE IF NOT EXISTS informed_consent (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  consent_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Consent Checkboxes
  agreed_to_participate BOOLEAN NOT NULL DEFAULT FALSE,
  agreed_to_data_collection BOOLEAN NOT NULL DEFAULT FALSE,
  agreed_to_health_data_sharing BOOLEAN NOT NULL DEFAULT FALSE,
  understood_voluntary_participation BOOLEAN NOT NULL DEFAULT FALSE,
  understood_data_confidentiality BOOLEAN NOT NULL DEFAULT FALSE,
  understood_right_to_withdraw BOOLEAN NOT NULL DEFAULT FALSE,
  
  -- Signature
  signature TEXT, -- Digital signature or participant name
  
  -- Withdrawal
  withdrawal_date TIMESTAMPTZ, -- If participant withdraws
  withdrawal_reason TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_consent_user ON informed_consent(user_id);
CREATE INDEX IF NOT EXISTS idx_consent_status ON informed_consent(agreed_to_participate, withdrawal_date);

-- ================================================
-- MEAL HISTORY TABLE (Extended for Research)
-- Stores meals for longitudinal tracking
-- ================================================
CREATE TABLE IF NOT EXISTS meal_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  meal_date DATE NOT NULL DEFAULT CURRENT_DATE,
  meal_time TIME NOT NULL DEFAULT CURRENT_TIME,
  meal_type TEXT CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
  
  -- Meal Data
  foods JSONB NOT NULL, -- Array of {food_id, grams, calories, carbs, etc.}
  total_calories DECIMAL(7,2) NOT NULL,
  total_carbs DECIMAL(6,2) NOT NULL,
  total_protein DECIMAL(6,2) NOT NULL,
  total_fat DECIMAL(6,2) NOT NULL,
  
  -- Health Analysis
  health_score DECIMAL(5,2), -- 0-100
  warnings JSONB, -- Array of warning messages
  recommendations JSONB, -- Array of recommendations
  
  -- Photo (if available)
  photo_url TEXT,
  detected_foods JSONB, -- ML detection results
  detection_confidence DECIMAL(3,2), -- 0-1
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_meal_user_date ON meal_history(user_id, meal_date DESC);
CREATE INDEX IF NOT EXISTS idx_meal_type ON meal_history(meal_type);

-- ================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ================================================

-- Glucose Readings Policies
ALTER TABLE glucose_readings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own glucose readings" ON glucose_readings;
CREATE POLICY "Users can view own glucose readings" ON glucose_readings
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own glucose readings" ON glucose_readings;
CREATE POLICY "Users can insert own glucose readings" ON glucose_readings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own glucose readings" ON glucose_readings;
CREATE POLICY "Users can update own glucose readings" ON glucose_readings
  FOR UPDATE USING (auth.uid() = user_id);

-- Research Assessments Policies
ALTER TABLE research_assessments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own assessments" ON research_assessments;
CREATE POLICY "Users can view own assessments" ON research_assessments
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own assessments" ON research_assessments;
CREATE POLICY "Users can insert own assessments" ON research_assessments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Dietary Adherence Policies
ALTER TABLE dietary_adherence_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own adherence records" ON dietary_adherence_records;
CREATE POLICY "Users can view own adherence records" ON dietary_adherence_records
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own adherence records" ON dietary_adherence_records;
CREATE POLICY "Users can insert own adherence records" ON dietary_adherence_records
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Informed Consent Policies
ALTER TABLE informed_consent ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own consent" ON informed_consent;
CREATE POLICY "Users can view own consent" ON informed_consent
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own consent" ON informed_consent;
CREATE POLICY "Users can insert own consent" ON informed_consent
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own consent" ON informed_consent;
CREATE POLICY "Users can update own consent" ON informed_consent
  FOR UPDATE USING (auth.uid() = user_id);

-- Meal History Policies
ALTER TABLE meal_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own meal history" ON meal_history;
CREATE POLICY "Users can view own meal history" ON meal_history
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own meal history" ON meal_history;
CREATE POLICY "Users can insert own meal history" ON meal_history
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ================================================
-- FUNCTIONS & TRIGGERS
-- ================================================

-- Function to calculate average glucose for last 7 days
CREATE OR REPLACE FUNCTION calculate_average_glucose_7days(p_user_id UUID)
RETURNS DECIMAL(5,1) AS $$
BEGIN
  RETURN (
    SELECT AVG(glucose_level)
    FROM glucose_readings
    WHERE user_id = p_user_id
      AND timestamp >= NOW() - INTERVAL '7 days'
  );
END;
$$ LANGUAGE plpgsql;

-- Function to get weekly adherence summary
CREATE OR REPLACE FUNCTION get_weekly_adherence_summary(
  p_user_id UUID,
  p_week_start DATE
)
RETURNS TABLE (
  total_meals BIGINT,
  meals_with_recommendations BIGINT,
  average_adherence_score DECIMAL(5,2),
  portion_compliance_rate DECIMAL(5,2),
  gi_compliance_rate DECIMAL(5,2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::BIGINT as total_meals,
    COUNT(*) FILTER (WHERE jsonb_array_length(recommendations_given) > 0)::BIGINT as meals_with_recommendations,
    AVG(adherence_score)::DECIMAL(5,2) as average_adherence_score,
    (COUNT(*) FILTER (WHERE followed_portion_advice = TRUE)::DECIMAL / COUNT(*)::DECIMAL * 100)::DECIMAL(5,2) as portion_compliance_rate,
    (COUNT(*) FILTER (WHERE avoided_high_gi_foods = TRUE)::DECIMAL / COUNT(*)::DECIMAL * 100)::DECIMAL(5,2) as gi_compliance_rate
  FROM dietary_adherence_records
  WHERE user_id = p_user_id
    AND date >= p_week_start
    AND date < p_week_start + INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- RESEARCH DATA VIEWS
-- ================================================

-- View for participant summary
CREATE OR REPLACE VIEW participant_summary AS
SELECT
  u.id as user_id,
  up.diabetes,
  up.glucose_range,
  up.cholesterol_concern,
  ic.agreed_to_participate,
  ic.consent_date,
  COUNT(DISTINCT gr.id) as total_glucose_readings,
  COUNT(DISTINCT ra.id) as total_assessments,
  COUNT(DISTINCT dar.id) as total_meals_tracked,
  AVG(dar.adherence_score) as average_adherence_score
FROM auth.users u
LEFT JOIN user_profiles up ON u.id = up.id
LEFT JOIN informed_consent ic ON u.id = ic.user_id
LEFT JOIN glucose_readings gr ON u.id = gr.user_id
LEFT JOIN research_assessments ra ON u.id = ra.user_id
LEFT JOIN dietary_adherence_records dar ON u.id = dar.user_id
WHERE ic.agreed_to_participate = TRUE
  AND ic.withdrawal_date IS NULL
GROUP BY u.id, up.diabetes, up.glucose_range, up.cholesterol_concern, 
         ic.agreed_to_participate, ic.consent_date;

-- ================================================
-- SAMPLE DATA QUERIES (For Reference)
-- ================================================

-- Get pre/post assessment comparison for a user
-- SELECT * FROM research_assessments 
-- WHERE user_id = '<uuid>' 
-- AND assessment_type IN ('pre_intervention', 'post_intervention')
-- ORDER BY completed_at;

-- Get glucose trend for a user
-- SELECT DATE(timestamp) as date, AVG(glucose_level) as avg_glucose
-- FROM glucose_readings
-- WHERE user_id = '<uuid>'
-- GROUP BY DATE(timestamp)
-- ORDER BY date DESC;

-- Get weekly adherence stats
-- SELECT * FROM get_weekly_adherence_summary('<uuid>', '2026-03-01');

-- ================================================
-- END OF RESEARCH EXTENSION SCHEMA
-- ================================================
