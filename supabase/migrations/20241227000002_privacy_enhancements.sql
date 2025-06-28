-- Privacy Enhancement Migration
-- Add functions for IP hashing, anonymous response tracking, and rate limiting

-- Create secure IP hashing function (one-way hash with salt)
CREATE OR REPLACE FUNCTION hash_ip_address(ip_text TEXT)
RETURNS TEXT AS $$
DECLARE
  salt TEXT := 'echowave_privacy_salt_2024'; -- Change this in production
  hashed_ip TEXT;
BEGIN
  -- Create irreversible hash using IP + salt + current date (for rotation)
  hashed_ip := encode(
    sha256(
      (ip_text || salt || CURRENT_DATE::text)::bytea
    ), 
    'hex'
  );
  
  -- Return first 16 characters for rate limiting (collision acceptable for privacy)
  RETURN substring(hashed_ip, 1, 16);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enhanced response fingerprinting (no personally identifiable info)
CREATE OR REPLACE FUNCTION generate_response_hash(survey_id UUID, ip_address TEXT)
RETURNS TEXT AS $$
DECLARE
  response_hash TEXT;
  ip_hash TEXT;
BEGIN
  -- Hash the IP address for abuse prevention (not identification)
  ip_hash := hash_ip_address(ip_address);
  
  -- Generate unique response hash using non-identifying elements
  response_hash := encode(
    sha256(
      (survey_id::text || ip_hash || extract(epoch from now())::text)::bytea
    ),
    'hex'
  );
  
  RETURN substring(response_hash, 1, 24);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Rate limiting function (returns true if request allowed)
CREATE OR REPLACE FUNCTION check_rate_limit(
  survey_id UUID, 
  ip_address TEXT,
  max_requests INTEGER DEFAULT 3,
  time_window_minutes INTEGER DEFAULT 10
)
RETURNS BOOLEAN AS $$
DECLARE
  ip_hash TEXT;
  recent_responses INTEGER;
BEGIN
  -- Hash IP for rate limiting (privacy-preserving)
  ip_hash := hash_ip_address(ip_address);
  
  -- Count recent responses from this hashed IP for this survey
  SELECT COUNT(*)
  INTO recent_responses
  FROM responses 
  WHERE survey_id = check_rate_limit.survey_id
    AND response_hash LIKE ip_hash || '%'
    AND submitted_at > NOW() - INTERVAL '1 minute' * time_window_minutes;
  
  -- Return true if under limit
  RETURN recent_responses < max_requests;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Anonymous response insights (k-anonymity safe aggregation)
CREATE OR REPLACE FUNCTION get_anonymous_insights(survey_id UUID)
RETURNS JSONB AS $$
DECLARE
  response_count INTEGER;
  min_threshold INTEGER := 10;
  insights JSONB := '{}';
BEGIN
  -- Get response count
  SELECT COUNT(*) INTO response_count
  FROM responses 
  WHERE responses.survey_id = get_anonymous_insights.survey_id;
  
  -- Only return insights if k-anonymity threshold is met
  IF response_count >= min_threshold THEN
    SELECT jsonb_build_object(
      'total_responses', response_count,
      'submission_timeline', (
        SELECT jsonb_agg(
          jsonb_build_object(
            'date', DATE(submitted_at),
            'count', count
          ) ORDER BY date
        )
        FROM (
          SELECT DATE(submitted_at) as date, COUNT(*) as count
          FROM responses 
          WHERE responses.survey_id = get_anonymous_insights.survey_id
          GROUP BY DATE(submitted_at)
          ORDER BY DATE(submitted_at)
        ) daily_counts
      ),
      'k_anonymity_status', 'safe'
    ) INTO insights;
  ELSE
    SELECT jsonb_build_object(
      'k_anonymity_status', 'insufficient_responses',
      'required_responses', min_threshold,
      'current_responses', response_count
    ) INTO insights;
  END IF;
  
  RETURN insights;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add privacy metadata to responses table
ALTER TABLE responses 
ADD COLUMN IF NOT EXISTS privacy_level TEXT DEFAULT 'anonymous',
ADD COLUMN IF NOT EXISTS anonymized_at TIMESTAMPTZ DEFAULT NOW();

-- Add index for efficient rate limiting queries
CREATE INDEX IF NOT EXISTS idx_responses_hash_time 
ON responses(response_hash, submitted_at) 
WHERE response_hash IS NOT NULL;

-- Update RLS policies for enhanced privacy
DROP POLICY IF EXISTS "Users can view responses for their surveys with k-anonymity" ON responses;

CREATE POLICY "Survey owners can view anonymized responses" ON responses
FOR SELECT 
USING (
  survey_id IN (
    SELECT id FROM surveys 
    WHERE user_id = auth.uid() 
    AND response_count >= min_responses
  )
);

-- Prevent raw response data access below k-anonymity threshold
CREATE POLICY "Responses are private until k-anonymity threshold" ON responses
FOR SELECT 
USING (
  survey_id IN (
    SELECT s.id FROM surveys s
    WHERE s.user_id = auth.uid() 
    AND s.response_count >= COALESCE(s.min_responses, 10)
  )
);

-- Comment on new functions
COMMENT ON FUNCTION hash_ip_address(TEXT) IS 'One-way hash of IP address for rate limiting without storing PII';
COMMENT ON FUNCTION generate_response_hash(UUID, TEXT) IS 'Generate anonymous response fingerprint for abuse prevention';
COMMENT ON FUNCTION check_rate_limit(UUID, TEXT, INTEGER, INTEGER) IS 'Privacy-preserving rate limiting based on hashed IP';
COMMENT ON FUNCTION get_anonymous_insights(UUID) IS 'K-anonymity safe survey insights aggregation'; 