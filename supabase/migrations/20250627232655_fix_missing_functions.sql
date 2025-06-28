-- Fix missing database functions
-- Migration: 20250627232655_fix_missing_functions.sql

-- Drop existing functions first to avoid conflicts
DROP FUNCTION IF EXISTS survey_accepts_responses(UUID);
DROP FUNCTION IF EXISTS submit_response_with_compliance(UUID, JSONB, TEXT);
DROP FUNCTION IF EXISTS complete_survey(UUID);

-- Function to check if survey accepts responses
CREATE OR REPLACE FUNCTION survey_accepts_responses(survey_id_param UUID)
RETURNS BOOLEAN AS $$
DECLARE
  survey_record RECORD;
BEGIN
  SELECT status, is_active, expiration_date
  INTO survey_record
  FROM surveys
  WHERE id = survey_id_param;
  
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;
  
  -- Check if survey is published and active
  IF survey_record.status != 'published' OR NOT survey_record.is_active THEN
    RETURN FALSE;
  END IF;
  
  -- Check if survey has expired
  IF survey_record.expiration_date IS NOT NULL AND survey_record.expiration_date <= NOW() THEN
    RETURN FALSE;
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to submit response with compliance checking
CREATE OR REPLACE FUNCTION submit_response_with_compliance(
  survey_id_param UUID,
  answers_param JSONB,
  user_fingerprint_param TEXT
)
RETURNS TABLE(
  success BOOLEAN,
  message TEXT,
  response_id UUID,
  flags_detected TEXT[]
) AS $$
DECLARE
  new_response_id UUID;
  content_flags TEXT[] := '{}';
  answer_text TEXT;
  answer_value JSONB;
BEGIN
  -- Generate new response ID
  new_response_id := uuid_generate_v4();
  
  -- Basic content moderation (check for inappropriate content)
  FOR answer_value IN SELECT jsonb_array_elements(answers_param) LOOP
    IF jsonb_typeof(answer_value) = 'string' THEN
      answer_text := lower(answer_value #>> '{}');
      
      -- Check for inappropriate content (basic implementation)
      IF answer_text ~ '.*(spam|scam|fraud|hate|abuse).*' THEN
        content_flags := array_append(content_flags, 'inappropriate_content');
      END IF;
    END IF;
  END LOOP;
  
  -- Insert response
  INSERT INTO responses (
    id,
    survey_id,
    answers,
    user_fingerprint,
    submitted_at
  ) VALUES (
    new_response_id,
    survey_id_param,
    answers_param,
    user_fingerprint_param,
    NOW()
  );
  
  -- Return success result
  RETURN QUERY SELECT 
    TRUE as success,
    'Response submitted successfully' as message,
    new_response_id as response_id,
    content_flags as flags_detected;
END;
$$ LANGUAGE plpgsql;

-- Function to complete a survey
CREATE OR REPLACE FUNCTION complete_survey(survey_id_param UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE surveys 
  SET status = 'completed',
      is_active = FALSE,
      updated_at = NOW()
  WHERE id = survey_id_param;
END;
$$ LANGUAGE plpgsql;

-- Add expiration_date column to surveys if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'surveys' AND column_name = 'expiration_date'
  ) THEN
    ALTER TABLE surveys ADD COLUMN expiration_date TIMESTAMP WITH TIME ZONE;
  END IF;
END $$;

-- Update surveys table status to include 'completed'
DO $$
BEGIN
  -- Drop existing constraint if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE table_name = 'surveys' AND constraint_name = 'surveys_status_check'
  ) THEN
    ALTER TABLE surveys DROP CONSTRAINT surveys_status_check;
  END IF;
  
  -- Add new constraint with 'completed' status
  ALTER TABLE surveys ADD CONSTRAINT surveys_status_check 
    CHECK (status IN ('draft', 'published', 'completed'));
END $$; 