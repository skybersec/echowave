-- Add url_token column to surveys table for shareable survey links
ALTER TABLE surveys 
ADD COLUMN url_token TEXT UNIQUE;

-- Create index for better performance on url_token lookups
CREATE INDEX idx_surveys_url_token ON surveys(url_token);

-- Update existing surveys to have url_tokens
UPDATE surveys 
SET url_token = encode(gen_random_bytes(16), 'hex')
WHERE url_token IS NULL;
