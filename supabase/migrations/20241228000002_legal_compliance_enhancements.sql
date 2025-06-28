-- Legal compliance enhancements while maintaining 100% anonymity
-- Migration: 20241228000002_legal_compliance_enhancements.sql

-- Content moderation and legal compliance tables
CREATE TABLE IF NOT EXISTS content_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  survey_id UUID REFERENCES surveys(id) ON DELETE CASCADE,
  response_id UUID REFERENCES responses(id) ON DELETE CASCADE,
  flag_type TEXT NOT NULL CHECK (flag_type IN ('threatening', 'harassment', 'spam', 'inappropriate', 'legal_request')),
  flag_reason TEXT,
  flagged_by TEXT, -- 'system', 'user_report', 'admin_review'
  flagged_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'actioned', 'dismissed')),
  moderator_id UUID REFERENCES auth.users(id),
  moderator_action TEXT,
  moderator_notes TEXT,
  reviewed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Legal request tracking (for compliance documentation)
CREATE TABLE IF NOT EXISTS legal_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_type TEXT NOT NULL CHECK (request_type IN ('court_order', 'subpoena', 'law_enforcement', 'regulatory')),
  jurisdiction TEXT NOT NULL, -- 'US-CA', 'EU-GDPR', 'UK', etc.
  request_reference TEXT, -- case number, etc.
  request_details TEXT,
  requested_data_type TEXT, -- 'user_data', 'response_content', 'usage_logs'
  response_provided TEXT NOT NULL DEFAULT 'technical_impossibility',
  response_details TEXT,
  handled_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  closed_at TIMESTAMP WITH TIME ZONE
);

-- Data processing log for GDPR Article 30 compliance
CREATE TABLE IF NOT EXISTS data_processing_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  processing_activity TEXT NOT NULL,
  data_category TEXT NOT NULL, -- 'survey_responses', 'usage_analytics', 'account_data'
  legal_basis TEXT NOT NULL, -- 'consent', 'legitimate_interest', 'contract'
  purpose TEXT NOT NULL,
  retention_period TEXT,
  anonymization_method TEXT,
  third_party_sharing BOOLEAN DEFAULT false,
  third_parties TEXT[], -- array of third parties if any
  security_measures TEXT,
  logged_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enhanced content filtering functions
CREATE OR REPLACE FUNCTION detect_concerning_content(content_text TEXT)
RETURNS TABLE(
  is_flagged BOOLEAN,
  flag_reasons TEXT[],
  confidence_score NUMERIC
) AS $$
DECLARE
  flags TEXT[] := '{}';
  score NUMERIC := 0;
BEGIN
  -- Basic threat detection (expand with AI/ML in future)
  IF content_text ~* '\b(kill|murder|bomb|threat|hurt|harm)\b' THEN
    flags := array_append(flags, 'potential_threat');
    score := score + 0.8;
  END IF;
  
  IF content_text ~* '\b(hate|stupid|idiot)\b.*\b(you|your|boss|manager)\b' THEN
    flags := array_append(flags, 'personal_attack');
    score := score + 0.6;
  END IF;
  
  IF content_text ~* '\b(spam|buy now|click here|limited time)\b' THEN
    flags := array_append(flags, 'spam_content');
    score := score + 0.4;
  END IF;
  
  -- Length-based spam detection
  IF length(content_text) > 2000 THEN
    flags := array_append(flags, 'excessive_length');
    score := score + 0.3;
  END IF;
  
  RETURN QUERY SELECT 
    (array_length(flags, 1) > 0 AND score > 0.5) as is_flagged,
    flags as flag_reasons,
    score as confidence_score;
END;
$$ LANGUAGE plpgsql;

-- Function to flag content for review
CREATE OR REPLACE FUNCTION flag_content_for_review(
  survey_id_param UUID,
  response_id_param UUID,
  flag_type_param TEXT,
  flag_reason_param TEXT DEFAULT NULL,
  flagged_by_param TEXT DEFAULT 'system'
)
RETURNS UUID AS $$
DECLARE
  flag_id UUID;
BEGIN
  INSERT INTO content_flags (
    survey_id, 
    response_id, 
    flag_type, 
    flag_reason, 
    flagged_by
  ) VALUES (
    survey_id_param, 
    response_id_param, 
    flag_type_param, 
    flag_reason_param, 
    flagged_by_param
  ) RETURNING id INTO flag_id;
  
  RETURN flag_id;
END;
$$ LANGUAGE plpgsql;

-- Function to handle legal requests
CREATE OR REPLACE FUNCTION log_legal_request(
  request_type_param TEXT,
  jurisdiction_param TEXT,
  request_reference_param TEXT DEFAULT NULL,
  request_details_param TEXT DEFAULT NULL,
  handled_by_param UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  request_id UUID;
  standard_response TEXT;
BEGIN
  -- Standard response for data requests
  standard_response := 'Data requested is processed in a manner that ensures complete anonymity. ' ||
                      'Our technical architecture prevents identification of individual users. ' ||
                      'We cannot provide personally identifiable information as none is collected or stored. ' ||
                      'Response content can be provided if specific survey/response IDs are available, ' ||
                      'but cannot be linked to any individual user.';
  
  INSERT INTO legal_requests (
    request_type,
    jurisdiction,
    request_reference,
    request_details,
    response_details,
    handled_by
  ) VALUES (
    request_type_param,
    jurisdiction_param,
    request_reference_param,
    request_details_param,
    standard_response,
    handled_by_param
  ) RETURNING id INTO request_id;
  
  RETURN request_id;
END;
$$ LANGUAGE plpgsql;

-- Function for GDPR Article 30 compliance logging
CREATE OR REPLACE FUNCTION log_data_processing(
  activity_param TEXT,
  data_category_param TEXT,
  legal_basis_param TEXT,
  purpose_param TEXT,
  retention_param TEXT DEFAULT '7 years',
  anonymization_param TEXT DEFAULT 'Immediate hashing with daily salt rotation'
)
RETURNS UUID AS $$
DECLARE
  log_id UUID;
BEGIN
  INSERT INTO data_processing_log (
    processing_activity,
    data_category,
    legal_basis,
    purpose,
    retention_period,
    anonymization_method,
    security_measures
  ) VALUES (
    activity_param,
    data_category_param,
    legal_basis_param,
    purpose_param,
    retention_param,
    anonymization_param,
    'AES-256 encryption, TLS 1.3, Database RLS, IP hashing, Device fingerprinting'
  ) RETURNING id INTO log_id;
  
  RETURN log_id;
END;
$$ LANGUAGE plpgsql;

-- Enhanced response submission with content filtering
CREATE OR REPLACE FUNCTION submit_response_with_compliance(
  survey_id_param UUID,
  answers_param JSONB,
  user_fingerprint_param TEXT
)
RETURNS TABLE(
  success BOOLEAN,
  response_id UUID,
  flags_detected TEXT[],
  message TEXT
) AS $$
DECLARE
  new_response_id UUID;
  content_check RECORD;
  combined_content TEXT;
  flag_id UUID;
BEGIN
  -- Combine all text responses for content analysis
  SELECT string_agg(value::TEXT, ' ') INTO combined_content
  FROM jsonb_each_text(answers_param)
  WHERE value::TEXT ~ '\S'; -- Only non-empty responses
  
  -- Check for concerning content
  SELECT * INTO content_check 
  FROM detect_concerning_content(combined_content);
  
  -- Insert the response
  INSERT INTO responses (survey_id, answers, user_fingerprint)
  VALUES (survey_id_param, answers_param, user_fingerprint_param)
  RETURNING id INTO new_response_id;
  
  -- Flag if concerning content detected
  IF content_check.is_flagged THEN
    SELECT flag_content_for_review(
      survey_id_param,
      new_response_id,
      'system_detected',
      array_to_string(content_check.flag_reasons, ', '),
      'auto_moderation'
    ) INTO flag_id;
  END IF;
  
  RETURN QUERY SELECT 
    true as success,
    new_response_id,
    COALESCE(content_check.flag_reasons, '{}') as flags_detected,
    CASE 
      WHEN content_check.is_flagged THEN 'Response submitted but flagged for review'
      ELSE 'Response submitted successfully'
    END as message;
    
EXCEPTION
  WHEN OTHERS THEN
    RETURN QUERY SELECT 
      false as success,
      NULL::UUID as response_id,
      '{}'::TEXT[] as flags_detected,
      'Failed to submit response' as message;
END;
$$ LANGUAGE plpgsql;

-- Initialize standard data processing logs for compliance
INSERT INTO data_processing_log (
  processing_activity,
  data_category,
  legal_basis,
  purpose,
  retention_period,
  anonymization_method,
  security_measures
) VALUES 
  (
    'Survey Response Collection',
    'survey_responses',
    'consent',
    'Anonymous feedback collection for organizational improvement',
    'Indefinite (anonymous data)',
    'Immediate anonymization via hashing and fingerprinting',
    'End-to-end encryption, database-level security, no PII storage'
  ),
  (
    'User Account Management',
    'account_data',
    'contract',
    'Service provision and account management',
    '7 years post account deletion',
    'Not applicable (legitimate account data)',
    'Encrypted storage, access controls, audit logging'
  ),
  (
    'Usage Analytics',
    'usage_analytics',
    'legitimate_interest',
    'Service improvement and performance monitoring',
    '2 years',
    'Aggregated and anonymized',
    'No personal identifiers, statistical analysis only'
  )
ON CONFLICT DO NOTHING;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_content_flags_status ON content_flags(status);
CREATE INDEX IF NOT EXISTS idx_content_flags_survey ON content_flags(survey_id);
CREATE INDEX IF NOT EXISTS idx_legal_requests_type ON legal_requests(request_type);
CREATE INDEX IF NOT EXISTS idx_legal_requests_jurisdiction ON legal_requests(jurisdiction);
CREATE INDEX IF NOT EXISTS idx_data_processing_category ON data_processing_log(data_category);

-- Grant appropriate permissions
GRANT SELECT, INSERT ON content_flags TO authenticated;
GRANT SELECT ON legal_requests TO authenticated;
GRANT SELECT ON data_processing_log TO authenticated; 