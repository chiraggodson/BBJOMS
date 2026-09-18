BEGIN;

-- ============================================================
-- BBJOMS 2.0
-- MIGRATION 004 — YARN INVENTORY ENGINE
-- Database: trial_bbjoms
-- ============================================================

-- ============================================================
-- YARN RECEIPTS
-- ============================================================

CREATE TABLE inventory.yarn_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES core.companies(id)
        ON DELETE RESTRICT,

    financial_year_id UUID NOT NULL
        REFERENCES core.financial_years(id)
        ON DELETE RESTRICT,

    receipt_no VARCHAR(50) NOT NULL,

    receipt_date DATE NOT NULL,

    party_id UUID
        REFERENCES master.parties(id)
        ON DELETE RESTRICT,

    location_id UUID
        REFERENCES master.locations(id)
        ON DELETE RESTRICT,

    reference_no VARCHAR(100),

    challan_no VARCHAR(100),

    bill_no VARCHAR(100),

    status VARCHAR(30) NOT NULL DEFAULT 'DRAFT',

    notes TEXT,

    created_by UUID
        REFERENCES core.users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT yarn_receipts_no_unique
        UNIQUE (company_id, receipt_no),

    CONSTRAINT yarn_receipts_status_check
        CHECK (
            status IN (
                'DRAFT',
                'POSTED',
                'CANCELLED'
            )
        )
);


CREATE INDEX idx_yarn_receipts_date
ON inventory.yarn_receipts(company_id, receipt_date);

CREATE INDEX idx_yarn_receipts_party
ON inventory.yarn_receipts(party_id);

CREATE INDEX idx_yarn_receipts_location
ON inventory.yarn_receipts(location_id);

CREATE INDEX idx_yarn_receipts_status
ON inventory.yarn_receipts(company_id, status);


-- ============================================================
-- YARN RECEIPT LINES
-- ============================================================

CREATE TABLE inventory.yarn_receipt_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    receipt_id UUID NOT NULL
        REFERENCES inventory.yarn_receipts(id)
        ON DELETE CASCADE,

    yarn_lot_id UUID NOT NULL
        REFERENCES master.yarn_lots(id)
        ON DELETE RESTRICT,

    quantity NUMERIC(14,3) NOT NULL,

    unit_rate NUMERIC(14,4),

    box_count INTEGER,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT yarn_receipt_lines_quantity_check
        CHECK (quantity > 0),

    CONSTRAINT yarn_receipt_lines_rate_check
        CHECK (
            unit_rate IS NULL
            OR unit_rate >= 0
        ),

    CONSTRAINT yarn_receipt_lines_box_check
        CHECK (
            box_count IS NULL
            OR box_count >= 0
        )
);


CREATE INDEX idx_yarn_receipt_lines_receipt
ON inventory.yarn_receipt_lines(receipt_id);

CREATE INDEX idx_yarn_receipt_lines_lot
ON inventory.yarn_receipt_lines(yarn_lot_id);


-- ============================================================
-- YARN LEDGER
-- SINGLE SOURCE OF TRUTH FOR YARN STOCK
-- ============================================================

CREATE TABLE inventory.yarn_ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES core.companies(id)
        ON DELETE RESTRICT,

    financial_year_id UUID NOT NULL
        REFERENCES core.financial_years(id)
        ON DELETE RESTRICT,

    yarn_lot_id UUID NOT NULL
        REFERENCES master.yarn_lots(id)
        ON DELETE RESTRICT,

    location_id UUID
        REFERENCES master.locations(id)
        ON DELETE RESTRICT,

    movement_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    movement_type VARCHAR(40) NOT NULL,

    quantity_in NUMERIC(14,3) NOT NULL DEFAULT 0,

    quantity_out NUMERIC(14,3) NOT NULL DEFAULT 0,

    reference_type VARCHAR(50),

    reference_id UUID,

    remarks TEXT,

    created_by UUID
        REFERENCES core.users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT yarn_ledger_quantity_check
        CHECK (
            quantity_in >= 0
            AND quantity_out >= 0
        ),

    CONSTRAINT yarn_ledger_one_direction_check
        CHECK (
            NOT (
                quantity_in > 0
                AND quantity_out > 0
            )
        ),

    CONSTRAINT yarn_ledger_nonzero_check
        CHECK (
            quantity_in > 0
            OR quantity_out > 0
        ),

    CONSTRAINT yarn_ledger_movement_type_check
        CHECK (
            movement_type IN (
                'RECEIPT',
                'ISSUE',
                'RETURN',
                'TRANSFER_IN',
                'TRANSFER_OUT',
                'ADJUSTMENT_IN',
                'ADJUSTMENT_OUT',
                'OPENING'
            )
        )
);


CREATE INDEX idx_yarn_ledger_company
ON inventory.yarn_ledger(company_id);

CREATE INDEX idx_yarn_ledger_lot
ON inventory.yarn_ledger(yarn_lot_id);

CREATE INDEX idx_yarn_ledger_location
ON inventory.yarn_ledger(location_id);

CREATE INDEX idx_yarn_ledger_date
ON inventory.yarn_ledger(company_id, movement_date);

CREATE INDEX idx_yarn_ledger_reference
ON inventory.yarn_ledger(reference_type, reference_id);


-- ============================================================
-- STOCK ADJUSTMENTS
-- ============================================================

CREATE TABLE inventory.stock_adjustments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES core.companies(id)
        ON DELETE RESTRICT,

    financial_year_id UUID NOT NULL
        REFERENCES core.financial_years(id)
        ON DELETE RESTRICT,

    adjustment_no VARCHAR(50) NOT NULL,

    adjustment_date DATE NOT NULL,

    location_id UUID
        REFERENCES master.locations(id)
        ON DELETE RESTRICT,

    reason TEXT NOT NULL,

    status VARCHAR(30) NOT NULL DEFAULT 'DRAFT',

    created_by UUID
        REFERENCES core.users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT stock_adjustments_no_unique
        UNIQUE (company_id, adjustment_no),

    CONSTRAINT stock_adjustments_status_check
        CHECK (
            status IN (
                'DRAFT',
                'POSTED',
                'CANCELLED'
            )
        )
);


-- ============================================================
-- YARN STOCK VIEW
--
-- IMPORTANT:
-- location comes from yarn_ledger,
-- NOT yarn_lots.
-- ============================================================

CREATE OR REPLACE VIEW inventory.yarn_stock AS
SELECT
    ledger.company_id,

    ledger.location_id,

    ledger.yarn_lot_id,

    y.id AS yarn_id,

    y.code AS yarn_code,

    y.name AS yarn_name,

    yl.lot_no,

    yl.color_id,

    c.code AS color_code,

    c.name AS color_name,

    COALESCE(
        SUM(
            ledger.quantity_in
            - ledger.quantity_out
        ),
        0
    ) AS balance_kg

FROM inventory.yarn_ledger ledger

JOIN master.yarn_lots yl
    ON yl.id = ledger.yarn_lot_id

JOIN master.yarns y
    ON y.id = yl.yarn_id

LEFT JOIN master.colors c
    ON c.id = yl.color_id

GROUP BY
    ledger.company_id,
    ledger.location_id,
    ledger.yarn_lot_id,
    y.id,
    y.code,
    y.name,
    yl.lot_no,
    yl.color_id,
    c.code,
    c.name;


-- ============================================================
-- TOTAL YARN STOCK
-- ============================================================

CREATE OR REPLACE VIEW inventory.yarn_total_stock AS
SELECT
    company_id,

    yarn_id,

    yarn_code,

    yarn_name,

    SUM(balance_kg) AS balance_kg

FROM inventory.yarn_stock

GROUP BY
    company_id,
    yarn_id,
    yarn_code,
    yarn_name;


COMMIT;