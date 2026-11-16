-- Finished fabric lots, cutting history, and dispatch challans.
BEGIN;

CREATE SEQUENCE IF NOT EXISTS jobwork.fabric_lot_no_seq;
CREATE SEQUENCE IF NOT EXISTS jobwork.fabric_split_no_seq;
CREATE SEQUENCE IF NOT EXISTS jobwork.fabric_dispatch_no_seq;

CREATE TABLE IF NOT EXISTS jobwork.fabric_lots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES core.companies(id) ON DELETE RESTRICT,
  job_order_id UUID NOT NULL REFERENCES jobwork.job_orders(id) ON DELETE RESTRICT,
  origin_roll_id UUID NOT NULL REFERENCES production.fabric_production_rolls(id) ON DELETE RESTRICT,
  parent_lot_id UUID REFERENCES jobwork.fabric_lots(id) ON DELETE RESTRICT,
  lot_no VARCHAR(60) NOT NULL,
  quantity_kg NUMERIC(14,3) NOT NULL CHECK (quantity_kg > 0),
  status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE'
    CHECK (status IN ('AVAILABLE','SPLIT','DISPATCHED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(company_id, lot_no)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_fabric_lot_origin_root
  ON jobwork.fabric_lots(origin_roll_id) WHERE parent_lot_id IS NULL;
CREATE INDEX IF NOT EXISTS idx_fabric_lots_available
  ON jobwork.fabric_lots(company_id, status, job_order_id);

CREATE TABLE IF NOT EXISTS jobwork.fabric_lot_splits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES core.companies(id) ON DELETE RESTRICT,
  split_no VARCHAR(60) NOT NULL,
  source_lot_id UUID NOT NULL UNIQUE REFERENCES jobwork.fabric_lots(id) ON DELETE RESTRICT,
  source_quantity_kg NUMERIC(14,3) NOT NULL CHECK (source_quantity_kg > 0),
  cutting_loss_kg NUMERIC(14,3) NOT NULL DEFAULT 0 CHECK (cutting_loss_kg >= 0),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(company_id, split_no)
);

ALTER TABLE jobwork.fabric_lots
  ADD COLUMN IF NOT EXISTS split_id UUID REFERENCES jobwork.fabric_lot_splits(id) ON DELETE RESTRICT;

CREATE TABLE IF NOT EXISTS jobwork.fabric_dispatches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES core.companies(id) ON DELETE RESTRICT,
  financial_year_id UUID NOT NULL REFERENCES core.financial_years(id) ON DELETE RESTRICT,
  party_id UUID NOT NULL REFERENCES master.parties(id) ON DELETE RESTRICT,
  dispatch_no VARCHAR(60) NOT NULL,
  challan_date DATE NOT NULL DEFAULT CURRENT_DATE,
  transporter VARCHAR(150),
  vehicle_no VARCHAR(40),
  notes TEXT,
  status VARCHAR(20) NOT NULL DEFAULT 'POSTED' CHECK (status IN ('POSTED','CANCELLED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(company_id, dispatch_no)
);

CREATE TABLE IF NOT EXISTS jobwork.fabric_dispatch_lines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dispatch_id UUID NOT NULL REFERENCES jobwork.fabric_dispatches(id) ON DELETE RESTRICT,
  lot_id UUID NOT NULL UNIQUE REFERENCES jobwork.fabric_lots(id) ON DELETE RESTRICT,
  quantity_kg NUMERIC(14,3) NOT NULL CHECK (quantity_kg > 0)
);

CREATE INDEX IF NOT EXISTS idx_fabric_dispatches_party_date
  ON jobwork.fabric_dispatches(company_id, party_id, challan_date DESC);
CREATE INDEX IF NOT EXISTS idx_fabric_dispatch_lines_dispatch
  ON jobwork.fabric_dispatch_lines(dispatch_id);

-- Existing production is not automatically treated as available stock. It needs
-- a physical stock reconciliation before it can be dispatched.

CREATE OR REPLACE FUNCTION jobwork.create_fabric_lots_for_posted_production()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE roll_row RECORD;
BEGIN
  IF NEW.status='POSTED' AND OLD.status IS DISTINCT FROM NEW.status THEN
    FOR roll_row IN SELECT id, net_weight_kg FROM production.fabric_production_rolls WHERE production_id=NEW.id LOOP
    INSERT INTO jobwork.fabric_lots(company_id, job_order_id, origin_roll_id, lot_no, quantity_kg)
    VALUES(NEW.company_id, NEW.job_order_id, roll_row.id,
      'LOT-' || lpad(nextval('jobwork.fabric_lot_no_seq')::text, 7, '0'), roll_row.net_weight_kg)
    ON CONFLICT (origin_roll_id) WHERE parent_lot_id IS NULL DO NOTHING;
    END LOOP;
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_create_fabric_lots_for_posted_production ON production.fabric_production;
CREATE TRIGGER trg_create_fabric_lots_for_posted_production
AFTER UPDATE OF status ON production.fabric_production
FOR EACH ROW EXECUTE FUNCTION jobwork.create_fabric_lots_for_posted_production();

COMMIT;
