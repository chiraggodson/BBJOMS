-- Run this while connected to trial_bbjoms.
-- Required because the Party UI has a Contact Person field.

ALTER TABLE master.parties
ADD COLUMN IF NOT EXISTS contact_person VARCHAR(150);

CREATE INDEX IF NOT EXISTS idx_parties_company_phone
ON master.parties (company_id, phone);
