-- Advanced Survey Logic System Migration
-- Phase 5.2 Implementation - Week 1
-- Created: 2025-01-01

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Add conditional_logic column to surveys table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'surveys' AND column_name = 'conditional_logic'
  ) THEN
    ALTER TABLE surveys ADD COLUMN conditional_logic JSONB DEFAULT '{}';
  END IF;
END $$;

-- Create conditional_logic table for better normalization and querying
CREATE TABLE IF NOT EXISTS conditional_logic (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  survey_id UUID REFERENCES surveys(id) ON DELETE CASCADE NOT NULL,
  logic_script JSONB NOT NULL DEFAULT '{"version":1,"variables":{},"rules":[]}',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  
  -- Constraints
  CONSTRAINT valid_logic_script CHECK (
    jsonb_typeof(logic_script) = 'object' AND
    logic_script ? 'version' AND
    logic_script ? 'rules' AND
    jsonb_typeof(logic_script->'rules') = 'array'
  ),
  
  -- Unique constraint - one logic script per survey
  UNIQUE(survey_id)
);

-- Create logic_parts table for reusable logic components
CREATE TABLE IF NOT EXISTS logic_parts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN ('conditional', 'action', 'variable', 'template')),
  difficulty TEXT NOT NULL DEFAULT 'beginner' CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),
  tags TEXT[] DEFAULT '{}',
  icon TEXT, -- Lucide icon name
  color TEXT, -- Tailwind color class
  template_data JSONB NOT NULL DEFAULT '{}',
  usage_count INTEGER DEFAULT 0,
  is_built_in BOOLEAN DEFAULT false,
  is_public BOOLEAN DEFAULT false,
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_template_data CHECK (jsonb_typeof(template_data) = 'object')
);

-- Create logic_execution_logs table for debugging and analytics
CREATE TABLE IF NOT EXISTS logic_execution_logs (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  survey_id UUID REFERENCES surveys(id) ON DELETE CASCADE NOT NULL,
  response_id UUID, -- Reference to response if available
  execution_context JSONB NOT NULL,
  execution_result JSONB NOT NULL,
  execution_time_ms INTEGER NOT NULL,
  rule_count INTEGER NOT NULL,
  error_count INTEGER DEFAULT 0,
  executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Partitioning hint for large datasets
  CONSTRAINT valid_execution_data CHECK (
    jsonb_typeof(execution_context) = 'object' AND
    jsonb_typeof(execution_result) = 'object'
  )
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_conditional_logic_survey_id ON conditional_logic(survey_id);
CREATE INDEX IF NOT EXISTS idx_conditional_logic_active ON conditional_logic(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_conditional_logic_updated ON conditional_logic(updated_at);

CREATE INDEX IF NOT EXISTS idx_logic_parts_category ON logic_parts(category);
CREATE INDEX IF NOT EXISTS idx_logic_parts_difficulty ON logic_parts(difficulty);
CREATE INDEX IF NOT EXISTS idx_logic_parts_public ON logic_parts(is_public) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_logic_parts_built_in ON logic_parts(is_built_in) WHERE is_built_in = true;
CREATE INDEX IF NOT EXISTS idx_logic_parts_organization ON logic_parts(organization_id);
CREATE INDEX IF NOT EXISTS idx_logic_parts_tags ON logic_parts USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_logic_parts_usage ON logic_parts(usage_count DESC);

CREATE INDEX IF NOT EXISTS idx_logic_execution_logs_survey ON logic_execution_logs(survey_id);
CREATE INDEX IF NOT EXISTS idx_logic_execution_logs_executed_at ON logic_execution_logs(executed_at);
CREATE INDEX IF NOT EXISTS idx_logic_execution_logs_errors ON logic_execution_logs(error_count) WHERE error_count > 0;

-- Enable Row Level Security
ALTER TABLE conditional_logic ENABLE ROW LEVEL SECURITY;
ALTER TABLE logic_parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE logic_execution_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for conditional_logic
CREATE POLICY "Users can view logic for their own surveys" ON conditional_logic
  FOR SELECT USING (
    survey_id IN (
      SELECT id FROM surveys WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create logic for their own surveys" ON conditional_logic
  FOR INSERT WITH CHECK (
    survey_id IN (
      SELECT id FROM surveys WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update logic for their own surveys" ON conditional_logic
  FOR UPDATE USING (
    survey_id IN (
      SELECT id FROM surveys WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete logic for their own surveys" ON conditional_logic
  FOR DELETE USING (
    survey_id IN (
      SELECT id FROM surveys WHERE user_id = auth.uid()
    )
  );

-- RLS Policies for logic_parts
CREATE POLICY "Users can view public logic parts" ON logic_parts
  FOR SELECT USING (is_public = true OR created_by = auth.uid());

CREATE POLICY "Users can view organization logic parts" ON logic_parts
  FOR SELECT USING (
    organization_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create logic parts" ON logic_parts
  FOR INSERT WITH CHECK (created_by = auth.uid());

CREATE POLICY "Users can update their own logic parts" ON logic_parts
  FOR UPDATE USING (created_by = auth.uid());

CREATE POLICY "Users can delete their own logic parts" ON logic_parts
  FOR DELETE USING (created_by = auth.uid());

-- RLS Policies for logic_execution_logs
CREATE POLICY "Users can view execution logs for their surveys" ON logic_execution_logs
  FOR SELECT USING (
    survey_id IN (
      SELECT id FROM surveys WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Allow system to insert execution logs" ON logic_execution_logs
  FOR INSERT WITH CHECK (true); -- System can log executions

-- Functions for logic management

-- Function to validate logic script structure
CREATE OR REPLACE FUNCTION validate_logic_script(script JSONB)
RETURNS BOOLEAN AS $$
BEGIN
  -- Check required fields
  IF NOT (script ? 'version' AND script ? 'rules' AND script ? 'variables') THEN
    RETURN FALSE;
  END IF;
  
  -- Check version is a number
  IF jsonb_typeof(script->'version') != 'number' THEN
    RETURN FALSE;
  END IF;
  
  -- Check rules is an array
  IF jsonb_typeof(script->'rules') != 'array' THEN
    RETURN FALSE;
  END IF;
  
  -- Check variables is an object
  IF jsonb_typeof(script->'variables') != 'object' THEN
    RETURN FALSE;
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to get logic script for a survey
CREATE OR REPLACE FUNCTION get_survey_logic(survey_id_param UUID)
RETURNS JSONB AS $$
DECLARE
  logic_script JSONB;
BEGIN
  SELECT cl.logic_script INTO logic_script
  FROM conditional_logic cl
  WHERE cl.survey_id = survey_id_param AND cl.is_active = true;
  
  -- Return empty logic script if none found
  IF logic_script IS NULL THEN
    RETURN '{"version":1,"variables":{},"rules":[],"settings":{}}'::jsonb;
  END IF;
  
  RETURN logic_script;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update logic script for a survey
CREATE OR REPLACE FUNCTION update_survey_logic(
  survey_id_param UUID,
  logic_script_param JSONB,
  created_by_param UUID DEFAULT auth.uid()
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Validate the logic script
  IF NOT validate_logic_script(logic_script_param) THEN
    RAISE EXCEPTION 'Invalid logic script structure';
  END IF;
  
  -- Insert or update logic script
  INSERT INTO conditional_logic (survey_id, logic_script, created_by)
  VALUES (survey_id_param, logic_script_param, created_by_param)
  ON CONFLICT (survey_id) 
  DO UPDATE SET 
    logic_script = EXCLUDED.logic_script,
    updated_at = NOW(),
    is_active = true;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to log logic execution for analytics
CREATE OR REPLACE FUNCTION log_logic_execution(
  survey_id_param UUID,
  response_id_param UUID DEFAULT NULL,
  execution_context_param JSONB,
  execution_result_param JSONB,
  execution_time_ms_param INTEGER,
  rule_count_param INTEGER DEFAULT 0,
  error_count_param INTEGER DEFAULT 0
)
RETURNS UUID AS $$
DECLARE
  log_id UUID;
BEGIN
  INSERT INTO logic_execution_logs (
    survey_id,
    response_id,
    execution_context,
    execution_result,
    execution_time_ms,
    rule_count,
    error_count
  ) VALUES (
    survey_id_param,
    response_id_param,
    execution_context_param,
    execution_result_param,
    execution_time_ms_param,
    rule_count_param,
    error_count_param
  ) RETURNING id INTO log_id;
  
  RETURN log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment logic part usage count
CREATE OR REPLACE FUNCTION increment_logic_part_usage(part_id_param UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE logic_parts 
  SET usage_count = usage_count + 1,
      updated_at = NOW()
  WHERE id = part_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get logic execution statistics
CREATE OR REPLACE FUNCTION get_logic_execution_stats(survey_id_param UUID)
RETURNS TABLE(
  total_executions BIGINT,
  avg_execution_time NUMERIC,
  error_rate NUMERIC,
  last_execution TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) as total_executions,
    ROUND(AVG(execution_time_ms), 2) as avg_execution_time,
    ROUND(
      (COUNT(*) FILTER (WHERE error_count > 0)::NUMERIC / COUNT(*)::NUMERIC) * 100, 2
    ) as error_rate,
    MAX(executed_at) as last_execution
  FROM logic_execution_logs
  WHERE survey_id = survey_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insert built-in logic parts
INSERT INTO logic_parts (name, description, category, difficulty, tags, icon, color, template_data, is_built_in, is_public) VALUES
  (
    'Simple Skip Logic',
    'Skip to another question based on a single answer',
    'conditional',
    'beginner',
    ARRAY['skip', 'basic', 'conditional'],
    'ArrowRight',
    'bg-blue-50 text-blue-600',
    '{"rules":[{"id":"skip_rule","name":"Skip Logic","priority":1,"when":{"type":"simple","condition":{"q":"","operator":"equals","value":""}},"then":[{"action":"jump","to":""}],"enabled":true}]}'::jsonb,
    true,
    true
  ),
  (
    'Show/Hide Question',
    'Show or hide questions based on previous answers',
    'conditional', 
    'beginner',
    ARRAY['show', 'hide', 'visibility'],
    'Eye',
    'bg-green-50 text-green-600',
    '{"rules":[{"id":"visibility_rule","name":"Show/Hide","priority":1,"when":{"type":"simple","condition":{"q":"","operator":"equals","value":""}},"then":[{"action":"show","id":""}],"enabled":true}]}'::jsonb,
    true,
    true
  ),
  (
    'Score Calculator',
    'Add points to a score variable based on answers',
    'variable',
    'intermediate', 
    ARRAY['score', 'calculation', 'points'],
    'Calculator',
    'bg-purple-50 text-purple-600',
    '{"variables":{"score":{"type":"number","initial":0,"description":"Running score total"}},"rules":[{"id":"score_rule","name":"Add Score","priority":1,"when":{"type":"simple","condition":{"q":"","operator":"equals","value":""}},"then":[{"action":"add","var":"score","value":1}],"enabled":true}]}'::jsonb,
    true,
    true
  ),
  (
    'Required Field Logic',
    'Make questions required based on other answers',
    'action',
    'beginner',
    ARRAY['required', 'validation', 'conditional'],
    'AlertCircle',
    'bg-orange-50 text-orange-600',
    '{"rules":[{"id":"require_rule","name":"Make Required","priority":1,"when":{"type":"simple","condition":{"q":"","operator":"equals","value":""}},"then":[{"action":"require","id":""}],"enabled":true}]}'::jsonb,
    true,
    true
  ),
  (
    'End Survey Early',
    'End the survey based on specific conditions',
    'action',
    'beginner',
    ARRAY['end', 'terminate', 'exit'],
    'StopCircle',
    'bg-red-50 text-red-600',
    '{"rules":[{"id":"end_rule","name":"End Survey","priority":1,"when":{"type":"simple","condition":{"q":"","operator":"equals","value":""}},"then":[{"action":"end_survey","message":"Thank you for your response!"}],"enabled":true}]}'::jsonb,
    true,
    true
  ),
  (
    'Multi-Condition Logic',
    'Complex logic with multiple AND/OR conditions',
    'conditional',
    'advanced',
    ARRAY['complex', 'multiple', 'and', 'or'],
    'GitBranch',
    'bg-indigo-50 text-indigo-600',
    '{"rules":[{"id":"complex_rule","name":"Multi-Condition","priority":1,"when":{"type":"complex","operator":"and","conditions":[{"q":"","operator":"equals","value":""},{"q":"","operator":"greater_than","value":0}]},"then":[{"action":"jump","to":""}],"enabled":true}]}'::jsonb,
    true,
    true
  );

-- Add triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER conditional_logic_updated_at
  BEFORE UPDATE ON conditional_logic
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER logic_parts_updated_at
  BEFORE UPDATE ON logic_parts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Create a view for easy logic part discovery
CREATE OR REPLACE VIEW logic_parts_public AS
SELECT 
  id,
  name,
  description,
  category,
  difficulty,
  tags,
  icon,
  color,
  usage_count,
  is_built_in,
  created_at
FROM logic_parts 
WHERE is_public = true 
ORDER BY is_built_in DESC, usage_count DESC, name ASC;

-- Grant necessary permissions
GRANT SELECT ON logic_parts_public TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;

COMMENT ON TABLE conditional_logic IS 'Stores conditional logic rules for surveys';
COMMENT ON TABLE logic_parts IS 'Reusable logic components that can be shared';
COMMENT ON TABLE logic_execution_logs IS 'Analytics and debugging logs for logic execution';
COMMENT ON FUNCTION validate_logic_script(JSONB) IS 'Validates the structure of a logic script';
COMMENT ON FUNCTION get_survey_logic(UUID) IS 'Retrieves the active logic script for a survey';
COMMENT ON FUNCTION update_survey_logic(UUID, JSONB, UUID) IS 'Updates the logic script for a survey';
COMMENT ON FUNCTION log_logic_execution(UUID, UUID, JSONB, JSONB, INTEGER, INTEGER, INTEGER) IS 'Logs logic execution for analytics'; 