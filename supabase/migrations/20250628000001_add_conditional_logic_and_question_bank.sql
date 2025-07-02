-- Migration: Add conditional logic and enhanced question bank
-- Description: Add support for conditional survey logic and improved question bank with AI suggestions

-- Add conditional logic columns to questions table
ALTER TABLE surveys 
ADD COLUMN IF NOT EXISTS conditional_logic JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS ai_suggestions JSONB DEFAULT '[]';

-- Update question_bank table with additional fields
ALTER TABLE question_bank 
ADD COLUMN IF NOT EXISTS confidence_score DECIMAL(3,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS reasoning TEXT,
ADD COLUMN IF NOT EXISTS is_ai_generated BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS parent_survey_id UUID REFERENCES surveys(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS usage_context JSONB DEFAULT '{}';

-- Create conditional_logic table for better normalization
CREATE TABLE IF NOT EXISTS conditional_logic (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  survey_id UUID REFERENCES surveys(id) ON DELETE CASCADE NOT NULL,
  question_id TEXT NOT NULL, -- Reference to question within survey JSON
  depends_on_question_id TEXT NOT NULL,
  operator TEXT NOT NULL CHECK (operator IN (
    'equals', 'not_equals', 'contains', 'not_contains',
    'greater_than', 'less_than', 'greater_than_or_equal', 'less_than_or_equal',
    'is_empty', 'is_not_empty', 'in_list', 'not_in_list'
  )),
  value_condition JSONB, -- Flexible storage for different value types
  action TEXT NOT NULL CHECK (action IN ('show', 'hide', 'require', 'skip', 'end_survey')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create AI suggestions table
CREATE TABLE IF NOT EXISTS ai_suggestions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  survey_id UUID REFERENCES surveys(id) ON DELETE CASCADE NOT NULL,
  question_text TEXT NOT NULL,
  question_type TEXT NOT NULL,
  options JSONB,
  category TEXT,
  tags TEXT[],
  confidence_score DECIMAL(3,2) NOT NULL DEFAULT 0.0,
  reasoning TEXT,
  context_analysis JSONB DEFAULT '{}',
  is_applied BOOLEAN DEFAULT false,
  applied_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create question templates table for better organization
CREATE TABLE IF NOT EXISTS question_templates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  category_id TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  question_text TEXT NOT NULL,
  question_type TEXT NOT NULL,
  options JSONB,
  tags TEXT[],
  usage_count INTEGER DEFAULT 0,
  effectiveness_score DECIMAL(3,2) DEFAULT 0.0,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  is_public BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create question categories table
CREATE TABLE IF NOT EXISTS question_categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  color TEXT,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Insert default question categories
INSERT INTO question_categories (id, name, description, icon, color, sort_order) VALUES
  ('customer-satisfaction', 'Customer Satisfaction', 'Measure customer happiness and loyalty', '😊', 'blue', 1),
  ('product-feedback', 'Product Feedback', 'Gather insights about your products', '📦', 'green', 2),
  ('employee-engagement', 'Employee Engagement', 'Understand your team''s satisfaction', '👥', 'purple', 3),
  ('event-feedback', 'Event Feedback', 'Collect feedback from events and meetings', '🎯', 'orange', 4),
  ('market-research', 'Market Research', 'Understand your market and audience', '📊', 'indigo', 5),
  ('wellness-check', 'Wellness & Health', 'Mental health and wellness questions', '💚', 'emerald', 6)
ON CONFLICT (id) DO NOTHING;

-- Insert sample question templates
INSERT INTO question_templates (category_id, name, description, question_text, question_type, tags, usage_count, effectiveness_score, is_featured) VALUES
  ('customer-satisfaction', 'Overall Satisfaction Rating', 'Standard satisfaction measurement', 'How satisfied are you with our service overall?', 'rating', ARRAY['satisfaction', 'overall', 'rating'], 1247, 0.92, true),
  ('customer-satisfaction', 'Net Promoter Score', 'Measure customer loyalty', 'How likely are you to recommend us to a friend or colleague?', 'rating', ARRAY['nps', 'recommendation', 'loyalty'], 982, 0.89, true),
  ('customer-satisfaction', 'Improvement Feedback', 'Open-ended improvement suggestions', 'What could we do to improve your experience?', 'text', ARRAY['improvement', 'feedback', 'open-ended'], 756, 0.85, false),
  ('product-feedback', 'Feature Usage', 'Identify most used features', 'Which features do you use most frequently?', 'multiple_choice', ARRAY['features', 'usage', 'frequency'], 634, 0.88, true),
  ('product-feedback', 'Onboarding Experience', 'Measure ease of getting started', 'How easy was it to get started with our product?', 'rating', ARRAY['onboarding', 'ease-of-use', 'first-impression'], 523, 0.86, false),
  ('employee-engagement', 'Job Satisfaction', 'Measure role satisfaction', 'How satisfied are you with your current role?', 'rating', ARRAY['job-satisfaction', 'role', 'engagement'], 445, 0.84, true),
  ('employee-engagement', 'Recognition and Value', 'Feel valued by team', 'Do you feel your contributions are valued by the team?', 'yes_no', ARRAY['recognition', 'value', 'team'], 378, 0.82, false)
ON CONFLICT DO NOTHING;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_conditional_logic_survey_id ON conditional_logic(survey_id);
CREATE INDEX IF NOT EXISTS idx_conditional_logic_question_id ON conditional_logic(question_id);
CREATE INDEX IF NOT EXISTS idx_conditional_logic_depends_on ON conditional_logic(depends_on_question_id);
CREATE INDEX IF NOT EXISTS idx_conditional_logic_active ON conditional_logic(is_active);

CREATE INDEX IF NOT EXISTS idx_ai_suggestions_survey_id ON ai_suggestions(survey_id);
CREATE INDEX IF NOT EXISTS idx_ai_suggestions_confidence ON ai_suggestions(confidence_score);
CREATE INDEX IF NOT EXISTS idx_ai_suggestions_applied ON ai_suggestions(is_applied);

CREATE INDEX IF NOT EXISTS idx_question_templates_category ON question_templates(category_id);
CREATE INDEX IF NOT EXISTS idx_question_templates_usage ON question_templates(usage_count);
CREATE INDEX IF NOT EXISTS idx_question_templates_effectiveness ON question_templates(effectiveness_score);
CREATE INDEX IF NOT EXISTS idx_question_templates_public ON question_templates(is_public);
CREATE INDEX IF NOT EXISTS idx_question_templates_featured ON question_templates(is_featured);
CREATE INDEX IF NOT EXISTS idx_question_templates_tags ON question_templates USING GIN(tags);

-- Row Level Security (RLS) policies

-- Conditional Logic RLS
ALTER TABLE conditional_logic ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage conditional logic for their surveys" ON conditional_logic
  FOR ALL USING (
    survey_id IN (
      SELECT id FROM surveys WHERE user_id = auth.uid()
    )
  );

-- AI Suggestions RLS
ALTER TABLE ai_suggestions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view AI suggestions for their surveys" ON ai_suggestions
  FOR ALL USING (
    survey_id IN (
      SELECT id FROM surveys WHERE user_id = auth.uid()
    )
  );

-- Question Templates RLS
ALTER TABLE question_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view public question templates" ON question_templates
  FOR SELECT USING (is_public = true);

CREATE POLICY "Users can manage their own question templates" ON question_templates
  FOR ALL USING (created_by = auth.uid());

-- Question Categories RLS
ALTER TABLE question_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view question categories" ON question_categories
  FOR SELECT USING (is_active = true);

-- Functions for conditional logic evaluation
CREATE OR REPLACE FUNCTION evaluate_conditional_logic(
  survey_answers JSONB,
  question_id TEXT,
  survey_id_param UUID
) RETURNS JSONB AS $$
DECLARE
  logic_rules RECORD;
  result JSONB := '{"show": true, "required": false}'::JSONB;
  condition_value JSONB;
  answer_value TEXT;
BEGIN
  -- Get all active logic rules for this question
  FOR logic_rules IN 
    SELECT * FROM conditional_logic 
    WHERE survey_id = survey_id_param 
    AND question_id = question_id 
    AND is_active = true
  LOOP
    -- Get the answer for the dependent question
    answer_value := survey_answers ->> logic_rules.depends_on_question_id;
    condition_value := logic_rules.value_condition;
    
    -- Evaluate the condition based on operator
    CASE logic_rules.operator
      WHEN 'equals' THEN
        IF answer_value = (condition_value ->> 'value') THEN
          result := result || jsonb_build_object(logic_rules.action, true);
        END IF;
      WHEN 'not_equals' THEN
        IF answer_value != (condition_value ->> 'value') THEN
          result := result || jsonb_build_object(logic_rules.action, true);
        END IF;
      WHEN 'contains' THEN
        IF answer_value ILIKE '%' || (condition_value ->> 'value') || '%' THEN
          result := result || jsonb_build_object(logic_rules.action, true);
        END IF;
      WHEN 'greater_than' THEN
        IF (answer_value::NUMERIC) > (condition_value ->> 'value')::NUMERIC THEN
          result := result || jsonb_build_object(logic_rules.action, true);
        END IF;
      WHEN 'less_than' THEN
        IF (answer_value::NUMERIC) < (condition_value ->> 'value')::NUMERIC THEN
          result := result || jsonb_build_object(logic_rules.action, true);
        END IF;
      WHEN 'is_empty' THEN
        IF answer_value IS NULL OR answer_value = '' THEN
          result := result || jsonb_build_object(logic_rules.action, true);
        END IF;
      WHEN 'is_not_empty' THEN
        IF answer_value IS NOT NULL AND answer_value != '' THEN
          result := result || jsonb_build_object(logic_rules.action, true);
        END IF;
      -- Add more operators as needed
    END CASE;
  END LOOP;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate AI suggestions
CREATE OR REPLACE FUNCTION generate_ai_suggestions(
  survey_id_param UUID,
  context_data JSONB DEFAULT '{}'
) RETURNS JSONB AS $$
DECLARE
  survey_data RECORD;
  suggestion_count INTEGER := 0;
  suggestions JSONB := '[]'::JSONB;
BEGIN
  -- Get survey information
  SELECT * INTO survey_data FROM surveys WHERE id = survey_id_param;
  
  IF NOT FOUND THEN
    RETURN '{"error": "Survey not found"}'::JSONB;
  END IF;
  
  -- This is a placeholder for actual AI integration
  -- In production, this would call an AI service
  
  -- Insert sample AI suggestions based on survey context
  INSERT INTO ai_suggestions (
    survey_id, question_text, question_type, category, tags, 
    confidence_score, reasoning, context_analysis
  ) VALUES 
    (survey_id_param, 'What specific aspect of our service exceeded your expectations?', 'text', 'customer-satisfaction', 
     ARRAY['expectations', 'satisfaction', 'specific'], 0.92, 
     'Based on survey context, this follow-up question helps identify specific strengths', context_data),
    (survey_id_param, 'How would you rate the speed of our service delivery?', 'rating', 'customer-satisfaction',
     ARRAY['speed', 'delivery', 'performance'], 0.87,
     'Speed is a common concern in customer satisfaction surveys', context_data),
    (survey_id_param, 'Which communication channel do you prefer for support?', 'multiple_choice', 'customer-satisfaction',
     ARRAY['communication', 'support', 'preference'], 0.84,
     'Understanding preferred communication channels improves service strategy', context_data);
  
  GET DIAGNOSTICS suggestion_count = ROW_COUNT;
  
  RETURN jsonb_build_object(
    'success', true,
    'suggestions_generated', suggestion_count,
    'survey_id', survey_id_param
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update triggers for updated_at
CREATE TRIGGER update_conditional_logic_updated_at BEFORE UPDATE ON conditional_logic
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_question_templates_updated_at BEFORE UPDATE ON question_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column(); 