-- EchoWave Database Schema
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table (extends auth.users)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'pro', 'enterprise')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Templates table
CREATE TABLE templates (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  questions JSONB NOT NULL,
  is_public BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on templates
ALTER TABLE templates ENABLE ROW LEVEL SECURITY;

-- Templates policies
CREATE POLICY "Anyone can view public templates" ON templates
  FOR SELECT USING (is_public = TRUE);

CREATE POLICY "Users can view own templates" ON templates
  FOR SELECT USING (auth.uid() = created_by);

CREATE POLICY "Users can create templates" ON templates
  FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update own templates" ON templates
  FOR UPDATE USING (auth.uid() = created_by);

CREATE POLICY "Users can delete own templates" ON templates
  FOR DELETE USING (auth.uid() = created_by);

-- Surveys table
CREATE TABLE surveys (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  template_type TEXT NOT NULL,
  questions JSONB NOT NULL,
  settings JSONB DEFAULT '{}',
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'completed')),
  is_active BOOLEAN DEFAULT FALSE,
  min_responses INTEGER DEFAULT 10,
  response_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on surveys
ALTER TABLE surveys ENABLE ROW LEVEL SECURITY;

-- Surveys policies
CREATE POLICY "Users can view own surveys" ON surveys
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view published surveys" ON surveys
  FOR SELECT USING (status = 'published');

CREATE POLICY "Users can create surveys" ON surveys
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own surveys" ON surveys
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own surveys" ON surveys
  FOR DELETE USING (auth.uid() = user_id);

-- Responses table
CREATE TABLE responses (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  survey_id UUID REFERENCES surveys(id) ON DELETE CASCADE NOT NULL,
  answers JSONB NOT NULL,
  response_hash TEXT,
  ip_hash TEXT, -- Hashed IP for abuse prevention
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on responses
ALTER TABLE responses ENABLE ROW LEVEL SECURITY;

-- Responses policies
CREATE POLICY "Anyone can insert responses" ON responses
  FOR INSERT WITH CHECK (TRUE);

CREATE POLICY "Survey owners can view responses after threshold" ON responses
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM surveys 
      WHERE surveys.id = responses.survey_id 
      AND surveys.user_id = auth.uid()
      AND surveys.response_count >= surveys.min_responses
    )
  );

-- Function to update survey response count
CREATE OR REPLACE FUNCTION update_survey_response_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE surveys 
  SET response_count = response_count + 1,
      updated_at = NOW()
  WHERE id = NEW.survey_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update response count
CREATE TRIGGER update_survey_response_count_trigger
  AFTER INSERT ON responses
  FOR EACH ROW
  EXECUTE FUNCTION update_survey_response_count();

-- Function to generate anonymous response hash
CREATE OR REPLACE FUNCTION generate_response_hash(survey_id UUID, ip_address TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN encode(
    digest(survey_id::text || ip_address || extract(epoch from now())::text, 'sha256'),
    'hex'
  );
END;
$$ LANGUAGE plpgsql;

-- Function to hash IP addresses
CREATE OR REPLACE FUNCTION hash_ip(ip_address TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN encode(digest(ip_address || 'echowave_salt', 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql;

-- Insights table for AI-generated analysis
CREATE TABLE insights (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  survey_id UUID REFERENCES surveys(id) ON DELETE CASCADE NOT NULL,
  insight_type TEXT NOT NULL CHECK (insight_type IN ('summary', 'sentiment', 'themes', 'recommendations')),
  content JSONB NOT NULL,
  generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on insights
ALTER TABLE insights ENABLE ROW LEVEL SECURITY;

-- Insights policies
CREATE POLICY "Survey owners can view insights" ON insights
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM surveys 
      WHERE surveys.id = insights.survey_id 
      AND surveys.user_id = auth.uid()
    )
  );

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, full_name)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user registration
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Updated at function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_surveys_updated_at
  BEFORE UPDATE ON surveys
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Insert default templates
INSERT INTO templates (name, description, category, questions, is_public) VALUES 
  ('Individual Feedback', 'Get honest feedback about your performance and growth', 'personal', '[
    {"id": "q1", "type": "rating", "question": "How would you rate my overall performance?", "min_rating": 1, "max_rating": 5, "required": true},
    {"id": "q2", "type": "textarea", "question": "What is one thing I do well that I should continue doing?", "required": true},
    {"id": "q3", "type": "textarea", "question": "What is one area where I could improve?", "required": true},
    {"id": "q4", "type": "textarea", "question": "What specific advice would you give me for my professional growth?", "required": false},
    {"id": "q5", "type": "rating", "question": "How effectively do I communicate?", "min_rating": 1, "max_rating": 5, "required": true}
  ]', true),
  
  ('Health & Wellness', 'Get feedback about your well-being and energy', 'personal', '[
    {"id": "q1", "type": "rating", "question": "How would you rate my overall energy levels lately?", "min_rating": 1, "max_rating": 5, "required": true},
    {"id": "q2", "type": "textarea", "question": "What healthy habits have you noticed in me?", "required": false},
    {"id": "q3", "type": "textarea", "question": "Are there any concerning patterns you have observed?", "required": false},
    {"id": "q4", "type": "multiple_choice", "question": "What area should I focus on most?", "options": ["Physical fitness", "Mental health", "Work-life balance", "Sleep quality", "Nutrition"], "required": true},
    {"id": "q5", "type": "textarea", "question": "Any specific suggestions for improving my well-being?", "required": false}
  ]', true),
  
  ('Leadership Effectiveness', 'Get feedback about your leadership and management style', 'professional', '[
    {"id": "q1", "type": "rating", "question": "How effective am I as a leader?", "min_rating": 1, "max_rating": 5, "required": true},
    {"id": "q2", "type": "textarea", "question": "What leadership qualities do I demonstrate well?", "required": true},
    {"id": "q3", "type": "textarea", "question": "How could I improve my leadership style?", "required": true},
    {"id": "q4", "type": "rating", "question": "How well do I support team members?", "min_rating": 1, "max_rating": 5, "required": true},
    {"id": "q5", "type": "textarea", "question": "What would make me a more effective leader?", "required": false}
  ]', true);

-- Create indexes for better performance
CREATE INDEX idx_surveys_user_id ON surveys(user_id);
CREATE INDEX idx_surveys_status ON surveys(status);
CREATE INDEX idx_responses_survey_id ON responses(survey_id);
CREATE INDEX idx_responses_submitted_at ON responses(submitted_at);
CREATE INDEX idx_templates_category ON templates(category);
CREATE INDEX idx_templates_public ON templates(is_public);

-- Create a view for survey analytics
CREATE VIEW survey_analytics AS
SELECT 
  s.id,
  s.title,
  s.user_id,
  s.response_count,
  s.min_responses,
  s.created_at,
  CASE 
    WHEN s.response_count >= s.min_responses THEN 'available'
    ELSE 'pending'
  END as insights_status,
  COUNT(r.id) as actual_responses
FROM surveys s
LEFT JOIN responses r ON s.id = r.survey_id
GROUP BY s.id, s.title, s.user_id, s.response_count, s.min_responses, s.created_at; 