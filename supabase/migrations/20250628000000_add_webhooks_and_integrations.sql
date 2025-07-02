-- Migration: Add webhooks and integration tables
-- Description: Add support for webhooks, API keys, reminder schedules, and question bank

-- Organizations table (create first)
CREATE TABLE IF NOT EXISTS organizations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  subscription_tier TEXT DEFAULT 'free',
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Organization Members table
CREATE TABLE IF NOT EXISTS organization_members (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member', -- owner, admin, member, viewer
  invited_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  joined_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(organization_id, user_id)
);

-- Webhooks table
CREATE TABLE IF NOT EXISTS webhooks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  survey_id UUID REFERENCES surveys(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  events TEXT[] NOT NULL,
  secret_key TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  failure_count INTEGER DEFAULT 0,
  last_triggered_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- API Keys table
CREATE TABLE IF NOT EXISTS api_keys (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  key_prefix TEXT NOT NULL, -- First 8 characters for display
  hashed_key TEXT NOT NULL, -- SHA-256 hash of the full key
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  permissions TEXT[] NOT NULL,
  last_used_at TIMESTAMP WITH TIME ZONE,
  expires_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Reminder Schedules table
CREATE TABLE IF NOT EXISTS reminder_schedules (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  survey_id UUID REFERENCES surveys(id) ON DELETE CASCADE NOT NULL,
  email_template TEXT NOT NULL,
  send_after_hours INTEGER NOT NULL,
  is_active BOOLEAN DEFAULT true,
  last_sent_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Question Bank table
CREATE TABLE IF NOT EXISTS question_bank (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  question_text TEXT NOT NULL,
  question_type TEXT NOT NULL,
  options JSONB,
  tags TEXT[],
  usage_count INTEGER DEFAULT 0,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_webhooks_survey_id ON webhooks(survey_id);
CREATE INDEX IF NOT EXISTS idx_webhooks_organization_id ON webhooks(organization_id);
CREATE INDEX IF NOT EXISTS idx_webhooks_events ON webhooks USING GIN(events);
CREATE INDEX IF NOT EXISTS idx_webhooks_active ON webhooks(is_active);

CREATE INDEX IF NOT EXISTS idx_api_keys_user_id ON api_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_organization_id ON api_keys(organization_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_active ON api_keys(is_active);
CREATE INDEX IF NOT EXISTS idx_api_keys_hashed_key ON api_keys(hashed_key);

CREATE INDEX IF NOT EXISTS idx_reminder_schedules_survey_id ON reminder_schedules(survey_id);
CREATE INDEX IF NOT EXISTS idx_reminder_schedules_active ON reminder_schedules(is_active);

CREATE INDEX IF NOT EXISTS idx_question_bank_organization_id ON question_bank(organization_id);
CREATE INDEX IF NOT EXISTS idx_question_bank_category ON question_bank(category);
CREATE INDEX IF NOT EXISTS idx_question_bank_public ON question_bank(is_public);
CREATE INDEX IF NOT EXISTS idx_question_bank_tags ON question_bank USING GIN(tags);

CREATE INDEX IF NOT EXISTS idx_organization_members_organization_id ON organization_members(organization_id);
CREATE INDEX IF NOT EXISTS idx_organization_members_user_id ON organization_members(user_id);

-- Row Level Security (RLS) policies

-- Organizations RLS
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Organization members can view their organizations" ON organizations
  FOR SELECT USING (
    id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Organization owners can manage organizations" ON organizations
  FOR ALL USING (
    id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND role = 'owner'
    )
  );

-- Organization Members RLS
ALTER TABLE organization_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Organization members can view their memberships" ON organization_members
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Organization admins can manage memberships" ON organization_members
  FOR ALL USING (
    organization_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

-- Webhooks RLS
ALTER TABLE webhooks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage webhooks for their surveys" ON webhooks
  FOR ALL USING (
    survey_id IN (
      SELECT id FROM surveys WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Organization members can manage organization webhooks" ON webhooks
  FOR ALL USING (
    organization_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

-- API Keys RLS
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own API keys" ON api_keys
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Organization admins can manage organization API keys" ON api_keys
  FOR ALL USING (
    organization_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

-- Reminder Schedules RLS
ALTER TABLE reminder_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage reminder schedules for their surveys" ON reminder_schedules
  FOR ALL USING (
    survey_id IN (
      SELECT id FROM surveys WHERE user_id = auth.uid()
    )
  );

-- Question Bank RLS
ALTER TABLE question_bank ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view public questions" ON question_bank
  FOR SELECT USING (is_public = true);

CREATE POLICY "Users can manage their own questions" ON question_bank
  FOR ALL USING (created_by = auth.uid());

CREATE POLICY "Organization members can view organization questions" ON question_bank
  FOR SELECT USING (
    organization_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Organization admins can manage organization questions" ON question_bank
  FOR ALL USING (
    organization_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  );

-- Functions for webhook signature verification
CREATE OR REPLACE FUNCTION verify_webhook_signature(
  payload TEXT,
  signature TEXT,
  secret TEXT
) RETURNS BOOLEAN AS $$
BEGIN
  RETURN encode(hmac(payload, secret, 'sha256'), 'hex') = signature;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to hash API keys
CREATE OR REPLACE FUNCTION hash_api_key(api_key TEXT) RETURNS TEXT AS $$
BEGIN
  RETURN encode(digest(api_key, 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate API key
CREATE OR REPLACE FUNCTION generate_api_key() RETURNS TEXT AS $$
DECLARE
  key_chars TEXT := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  result TEXT := 'ew_'; -- EchoWave prefix
  i INTEGER;
BEGIN
  FOR i IN 1..40 LOOP
    result := result || substr(key_chars, floor(random() * length(key_chars) + 1)::int, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update triggers
CREATE TRIGGER update_webhooks_updated_at BEFORE UPDATE ON webhooks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_api_keys_updated_at BEFORE UPDATE ON api_keys
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reminder_schedules_updated_at BEFORE UPDATE ON reminder_schedules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_question_bank_updated_at BEFORE UPDATE ON question_bank
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column(); 