-- Enhance survey sharing and duplicate prevention
-- Migration: 20241228000000_enhance_survey_sharing.sql

-- Function to generate URL tokens for surveys
CREATE OR REPLACE FUNCTION generate_survey_url_token()
RETURNS TEXT AS $$
BEGIN
  RETURN encode(gen_random_bytes(16), 'hex');
END;
$$ LANGUAGE plpgsql;

-- Function to automatically set URL token when survey is created
CREATE OR REPLACE FUNCTION handle_new_survey()
RETURNS TRIGGER AS $$
BEGIN
  -- Set url_token if not provided
  IF NEW.url_token IS NULL THEN
    NEW.url_token := generate_survey_url_token();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new surveys
DROP TRIGGER IF EXISTS trigger_handle_new_survey ON surveys;
CREATE TRIGGER trigger_handle_new_survey
  BEFORE INSERT ON surveys
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_survey();

-- Enhanced fingerprinting function for anonymous users
CREATE OR REPLACE FUNCTION generate_enhanced_fingerprint(
  user_agent TEXT,
  accept_language TEXT,
  timezone TEXT,
  screen_resolution TEXT,
  color_depth TEXT,
  ip_address INET
) RETURNS TEXT AS $$
DECLARE
  fingerprint_data TEXT;
  hashed_ip TEXT;
BEGIN
  -- Hash IP with daily salt for privacy
  hashed_ip := encode(
    digest(
      ip_address::TEXT || current_date::TEXT || 'fingerprint_salt_2024',
      'sha256'
    ),
    'hex'
  );
  
  -- Combine fingerprint elements
  fingerprint_data := COALESCE(user_agent, '') || '|' ||
                      COALESCE(accept_language, '') || '|' ||
                      COALESCE(timezone, '') || '|' ||
                      COALESCE(screen_resolution, '') || '|' ||
                      COALESCE(color_depth, '') || '|' ||
                      hashed_ip;
  
  -- Return hashed fingerprint
  RETURN encode(digest(fingerprint_data, 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql;

-- Function to check if user already responded using fingerprint
CREATE OR REPLACE FUNCTION check_duplicate_response(
  survey_id_param UUID,
  fingerprint TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  existing_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO existing_count
  FROM responses
  WHERE survey_id = survey_id_param
    AND user_fingerprint = fingerprint;
  
  RETURN existing_count > 0;
END;
$$ LANGUAGE plpgsql;

-- Add fingerprint column to responses if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'responses' AND column_name = 'user_fingerprint'
  ) THEN
    ALTER TABLE responses ADD COLUMN user_fingerprint TEXT;
    CREATE INDEX idx_responses_fingerprint ON responses(survey_id, user_fingerprint);
  END IF;
END $$;

-- Add share_count column to surveys for analytics
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'surveys' AND column_name = 'share_count'
  ) THEN
    ALTER TABLE surveys ADD COLUMN share_count INTEGER DEFAULT 0;
  END IF;
END $$;

-- Function to increment share count
CREATE OR REPLACE FUNCTION increment_share_count(survey_id_param UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE surveys 
  SET share_count = COALESCE(share_count, 0) + 1
  WHERE id = survey_id_param;
END;
$$ LANGUAGE plpgsql;

-- Update existing surveys to have URL tokens if they don't
UPDATE surveys 
SET url_token = generate_survey_url_token()
WHERE url_token IS NULL; 