BEGIN;

-- Yarn Master is a generic specification. Supplier/company belongs to the lot/receipt.
-- Keep existing data intact while removing the company requirement from master.yarns.

ALTER TABLE master.yarns
  DROP CONSTRAINT IF EXISTS yarns_company_id_not_null;

ALTER TABLE master.yarns
  DROP CONSTRAINT IF EXISTS yarns_company_id_fkey;

ALTER TABLE master.yarns
  DROP COLUMN IF EXISTS company_id;

-- yarn_code_uq is already backed by the global code uniqueness in the live DB.
-- Recreate a clean global unique constraint only if it does not already exist.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'master.yarns'::regclass
      AND conname = 'yarn_code_uq'
  ) THEN
    ALTER TABLE master.yarns
      ADD CONSTRAINT yarn_code_uq UNIQUE (code);
  END IF;
END $$;

COMMIT;
