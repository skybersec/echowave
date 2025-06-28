-- AI Insights System Migration
-- This migration creates the infrastructure for privacy-preserving AI insights

-- Survey insights table to cache AI-generated insights
CREATE TABLE IF NOT EXISTS survey_insights (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  survey_id UUID REFERENCES surveys(id) ON DELETE CASCADE NOT NULL,
  insights_data JSONB NOT NULL,
  response_count INTEGER NOT NULL,
  generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '6 hours'),
  trend_id TEXT, -- For tracking improvement over time
  
  -- Constraints
  UNIQUE(survey_id)
);

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_survey_insights_survey_id ON survey_insights(survey_id);
CREATE INDEX IF NOT EXISTS idx_survey_insights_expires_at ON survey_insights(expires_at);

-- Row Level Security
ALTER TABLE survey_insights ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access insights for their own surveys
CREATE POLICY "Users can access insights for their own surveys" ON survey_insights
  FOR ALL
  TO authenticated
  USING (
    survey_id IN (
      SELECT id FROM surveys WHERE user_id = auth.uid()
    )
  );

-- Function to check if survey meets minimum threshold for insights
CREATE OR REPLACE FUNCTION can_generate_insights(survey_id_param UUID)
RETURNS BOOLEAN AS $$
DECLARE
  response_count INTEGER;
  min_responses INTEGER;
BEGIN
  SELECT s.response_count, s.min_responses
  INTO response_count, min_responses
  FROM surveys s
  WHERE s.id = survey_id_param;
  
  RETURN response_count >= min_responses;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get anonymized responses for AI processing
CREATE OR REPLACE FUNCTION get_anonymized_responses(survey_id_param UUID)
RETURNS TABLE(
  question_text TEXT,
  answer TEXT,
  question_type TEXT
) AS $$
BEGIN
  -- Only return data if minimum threshold is met
  IF NOT can_generate_insights(survey_id_param) THEN
    RAISE EXCEPTION 'Insufficient responses for insights generation';
  END IF;
  
  RETURN QUERY
  WITH response_data AS (
    SELECT 
      r.answers,
      s.questions
    FROM responses r
    JOIN surveys s ON s.id = r.survey_id
    WHERE r.survey_id = survey_id_param
  ),
  parsed_responses AS (
    SELECT 
      (jsonb_array_elements(rd.answers)->>'question')::TEXT as response_question,
      (jsonb_array_elements(rd.answers)->>'answer')::TEXT as response_answer,
      (jsonb_array_elements(rd.questions)->>'question')::TEXT as survey_question,
      COALESCE((jsonb_array_elements(rd.questions)->>'type')::TEXT, 'text') as survey_question_type
    FROM response_data rd
  )
  SELECT 
    pr.survey_question as question_text,
    pr.response_answer as answer,
    pr.survey_question_type as question_type
  FROM parsed_responses pr
  WHERE pr.response_question = pr.survey_question
    AND pr.response_answer IS NOT NULL
    AND LENGTH(TRIM(pr.response_answer)) > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to save insights
CREATE OR REPLACE FUNCTION save_insights(
  survey_id_param UUID,
  insights_data_param JSONB,
  response_count_param INTEGER,
  trend_id_param TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  insight_id UUID;
BEGIN
  -- Insert or update insights
  INSERT INTO survey_insights (
    survey_id,
    insights_data,
    response_count,
    trend_id
  )
  VALUES (
    survey_id_param,
    insights_data_param,
    response_count_param,
    trend_id_param
  )
  ON CONFLICT (survey_id)
  DO UPDATE SET
    insights_data = insights_data_param,
    response_count = response_count_param,
    generated_at = NOW(),
    expires_at = NOW() + INTERVAL '6 hours',
    trend_id = COALESCE(trend_id_param, survey_insights.trend_id)
  RETURNING id INTO insight_id;
  
  RETURN insight_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get cached insights
CREATE OR REPLACE FUNCTION get_cached_insights(survey_id_param UUID)
RETURNS JSONB AS $$
DECLARE
  cached_insights JSONB;
BEGIN
  SELECT insights_data
  INTO cached_insights
  FROM survey_insights
  WHERE survey_id = survey_id_param
    AND expires_at > NOW();
  
  RETURN cached_insights;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to clean up expired insights (run via cron)
CREATE OR REPLACE FUNCTION cleanup_expired_insights()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM survey_insights
  WHERE expires_at < NOW();
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON TABLE survey_insights TO authenticated;
GRANT EXECUTE ON FUNCTION can_generate_insights(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_anonymized_responses(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION save_insights(UUID, JSONB, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_cached_insights(UUID) TO authenticated; 