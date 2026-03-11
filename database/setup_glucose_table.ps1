# PowerShell script to create glucose_readings table in Supabase
# This will execute the SQL directly via Supabase REST API

$supabaseUrl = "https://hondqqvhuzcxajehzrlo.supabase.co"
$supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhvbmRxcXZodXpjeGFqZWh6cmxvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2NDc0MzUsImV4cCI6MjA4NjIyMzQzNX0.u-Ru1PcD7mQ8K4KgNIBvwoNobYxNXIBGo77j2rGk8FY"

Write-Host "Creating glucose_readings table in Supabase..." -ForegroundColor Yellow

# SQL to create the table
$sql = @"
CREATE TABLE IF NOT EXISTS glucose_readings (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  glucose_level DECIMAL(5,1) NOT NULL CHECK (glucose_level > 0 AND glucose_level < 600),
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reading_type TEXT NOT NULL CHECK (reading_type IN ('fasting', 'before_meal', 'after_meal', 'random')),
  meal_id TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_glucose_user_timestamp ON glucose_readings(user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_glucose_reading_type ON glucose_readings(reading_type);

ALTER TABLE glucose_readings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own glucose readings" ON glucose_readings;
CREATE POLICY "Users can view own glucose readings" ON glucose_readings
  FOR SELECT USING (auth.uid()::text = user_id);

DROP POLICY IF EXISTS "Users can insert own glucose readings" ON glucose_readings;
CREATE POLICY "Users can insert own glucose readings" ON glucose_readings
  FOR INSERT WITH CHECK (auth.uid()::text = user_id);

DROP POLICY IF EXISTS "Users can update own glucose readings" ON glucose_readings;
CREATE POLICY "Users can update own glucose readings" ON glucose_readings
  FOR UPDATE USING (auth.uid()::text = user_id);
"@

# Try to execute using Supabase SQL API
try {
    # Note: The anon key doesn't have permission to execute raw SQL
    # You need to use the Supabase Dashboard SQL Editor or service_role key
    Write-Host ""
    Write-Host "IMPORTANT: The Supabase anon key cannot execute raw SQL for security reasons." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please follow these steps:" -ForegroundColor Cyan
    Write-Host "1. Go to: https://supabase.com/dashboard/project/hondqqvhuzcxajehzrlo/sql/new" -ForegroundColor Green
    Write-Host "2. Copy the SQL from: database\setup_glucose_table.sql" -ForegroundColor Green
    Write-Host "3. Paste it in the SQL Editor" -ForegroundColor Green
    Write-Host "4. Click 'Run' button" -ForegroundColor Green
    Write-Host ""
    Write-Host "OR press any key to open the SQL Editor in your browser..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    
    Start-Process "https://supabase.com/dashboard/project/hondqqvhuzcxajehzrlo/sql/new"
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
