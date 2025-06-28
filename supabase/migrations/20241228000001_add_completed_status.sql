-- Add completed status and expiration date functionality
-- Migration: 20241228000001_add_completed_status.sql

-- First, let's add the expiration_date column
ALTER TABLE surveys 
ADD COLUMN expiration_date TIMESTAMP WITH TIME ZONE;

-- Create an index for expiration date queries
CREATE INDEX idx_surveys_expiration_date ON surveys(expiration_date);

-- Function to auto-complete expired surveys
CREATE OR REPLACE FUNCTION auto_complete_expired_surveys()
RETURNS INTEGER AS $$
DECLARE
  updated_count INTEGER;
BEGIN
  -- Update surveys that have passed their expiration date
  UPDATE surveys 
  SET 
    status = 'completed',
    is_active = false,
    updated_at = now()
  WHERE 
    expiration_date IS NOT NULL 
    AND expiration_date <= now()
    AND status = 'published'
    AND status != 'completed';
  
  GET DIAGNOSTICS updated_count = ROW_COUNT;
  
  RETURN updated_count;
END;
$$ LANGUAGE plpgsql;

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
  
  -- Return false if survey doesn't exist
  IF NOT FOUND THEN
    RETURN false;
  END IF;
  
  -- Return false if survey is completed
  IF survey_record.status = 'completed' THEN
    RETURN false;
  END IF;
  
  -- Return false if survey is not published or active
  IF survey_record.status != 'published' OR NOT survey_record.is_active THEN
    RETURN false;
  END IF;
  
  -- Return false if survey has expired
  IF survey_record.expiration_date IS NOT NULL AND survey_record.expiration_date <= now() THEN
    RETURN false;
  END IF;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Function to manually complete a survey
CREATE OR REPLACE FUNCTION complete_survey(survey_id_param UUID)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE surveys 
  SET 
    status = 'completed',
    is_active = false,
    updated_at = now()
  WHERE 
    id = survey_id_param
    AND status = 'published';
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Create a function to get survey completion stats
CREATE OR REPLACE FUNCTION get_survey_completion_stats(user_id_param UUID)
RETURNS TABLE(
  total_surveys INTEGER,
  draft_surveys INTEGER,
  published_surveys INTEGER,
  completed_surveys INTEGER,
  expired_surveys INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INTEGER as total_surveys,
    COUNT(*) FILTER (WHERE status = 'draft')::INTEGER as draft_surveys,
    COUNT(*) FILTER (WHERE status = 'published')::INTEGER as published_surveys,
    COUNT(*) FILTER (WHERE status = 'completed')::INTEGER as completed_surveys,
    COUNT(*) FILTER (WHERE expiration_date IS NOT NULL AND expiration_date <= now())::INTEGER as expired_surveys
  FROM surveys
  WHERE user_id = user_id_param;
END;
$$ LANGUAGE plpgsql;

-- Add a check constraint to ensure valid status values
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.check_constraints 
    WHERE constraint_name = 'surveys_status_check'
  ) THEN
    ALTER TABLE surveys 
    ADD CONSTRAINT surveys_status_check 
    CHECK (status IN ('draft', 'published', 'completed'));
  END IF;
END $$;

-- Create a scheduled job function (to be called by external cron or similar)
CREATE OR REPLACE FUNCTION scheduled_survey_maintenance()
RETURNS TEXT AS $$
DECLARE
  completed_count INTEGER;
  result_text TEXT;
BEGIN
  -- Auto-complete expired surveys
  SELECT auto_complete_expired_surveys() INTO completed_count;
  
  result_text := format('Maintenance completed. Auto-completed %s expired surveys.', completed_count);
  
  -- Log the maintenance run (optional - could store in a maintenance_log table)
  INSERT INTO maintenance_log (operation, details, created_at)
  VALUES ('auto_complete_surveys', result_text, now())
  ON CONFLICT DO NOTHING; -- Ignore if table doesn't exist
  
  RETURN result_text;
EXCEPTION
  WHEN OTHERS THEN
    -- If maintenance_log table doesn't exist, just return the result
    RETURN result_text;
END;
$$ LANGUAGE plpgsql;

-- Add privacy/legal compliance helper functions
CREATE OR REPLACE FUNCTION get_survey_response_count_by_date(survey_id_param UUID)
RETURNS TABLE(
  response_date DATE,
  response_count INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    submitted_at::DATE as response_date,
    COUNT(*)::INTEGER as response_count
  FROM responses
  WHERE survey_id = survey_id_param
  GROUP BY submitted_at::DATE
  ORDER BY response_date;
END;
$$ LANGUAGE plpgsql;

-- Function to help with content moderation (without breaking anonymity)
CREATE OR REPLACE FUNCTION flag_response_for_review(
  survey_id_param UUID,
  response_id_param UUID,
  reason TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Create a flagged_responses table if it doesn't exist
  CREATE TABLE IF NOT EXISTS flagged_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    survey_id UUID REFERENCES surveys(id) ON DELETE CASCADE,
    response_id UUID REFERENCES responses(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    flagged_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    reviewed BOOLEAN DEFAULT false,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    action_taken TEXT
  );
  
  -- Insert the flag
  INSERT INTO flagged_responses (survey_id, response_id, reason)
  VALUES (survey_id_param, response_id_param, reason);
  
  RETURN true;
EXCEPTION
  WHEN OTHERS THEN
    RETURN false;
END;
$$ LANGUAGE plpgsql; 