BEGIN;

-- ============================================================
-- BBJOMS 2.0
-- MIGRATION 005 — JOBWORK CORE
-- Database: trial_bbjoms
-- ============================================================

-- ============================================================
-- 0. REMOVE OLD EMPTY JOBWORK STRUCTURE
-- ============================================================

DROP TABLE IF EXISTS
    jobwork.yarn_return_lines,
    jobwork.yarn_returns,
    jobwork.yarn_issue_lines,
    jobwork.yarn_issues,
    jobwork.job_order_yarns,
    jobwork.job_order_machines,
    jobwork.job_orders
CASCADE;


-- ============================================================
-- 1. JOB NUMBER SEQUENCE
-- ============================================================

CREATE SEQUENCE jobwork.job_no_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ============================================================
-- 2. JOB ORDERS
-- ============================================================

CREATE TABLE jobwork.job_orders (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES core.companies(id)
        ON DELETE RESTRICT,

    financial_year_id UUID NOT NULL
        REFERENCES core.financial_years(id)
        ON DELETE RESTRICT,

    job_no VARCHAR(50) NOT NULL DEFAULT
        (
            'BBJO-' ||
            LPAD(
                nextval('jobwork.job_no_seq')::TEXT,
                5,
                '0'
            )
        ),

    job_date DATE NOT NULL DEFAULT CURRENT_DATE,

    party_id UUID NOT NULL
        REFERENCES master.parties(id)
        ON DELETE RESTRICT,

    fabric_id UUID NOT NULL
        REFERENCES master.fabrics(id)
        ON DELETE RESTRICT,

    design_no VARCHAR(100),

    order_quantity_kg NUMERIC(14,3) NOT NULL,

    status VARCHAR(30) NOT NULL DEFAULT 'OPEN',

    notes TEXT,

    created_by UUID
        REFERENCES core.users(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT job_orders_job_no_unique
        UNIQUE (company_id, job_no),

    CONSTRAINT job_orders_quantity_check
        CHECK (order_quantity_kg > 0),

    CONSTRAINT job_orders_status_check
        CHECK (
            status IN (
                'OPEN',
                'RUNNING',
                'PAUSED',
                'COMPLETED',
                'CLOSED',
                'CANCELLED'
            )
        )
);


CREATE INDEX idx_job_orders_company
ON jobwork.job_orders(company_id);

CREATE INDEX idx_job_orders_date
ON jobwork.job_orders(company_id, job_date);

CREATE INDEX idx_job_orders_party
ON jobwork.job_orders(party_id);

CREATE INDEX idx_job_orders_fabric
ON jobwork.job_orders(fabric_id);

CREATE INDEX idx_job_orders_status
ON jobwork.job_orders(company_id, status);


-- ============================================================
-- 3. JOB ORDER → MACHINE
-- ============================================================

CREATE TABLE jobwork.job_order_machines (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    job_order_id UUID NOT NULL
        REFERENCES jobwork.job_orders(id)
        ON DELETE CASCADE,

    machine_id UUID NOT NULL
        REFERENCES master.machines(id)
        ON DELETE RESTRICT,

    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    released_at TIMESTAMPTZ,

    is_primary BOOLEAN NOT NULL DEFAULT FALSE,

    notes TEXT,

    CONSTRAINT job_order_machine_unique
        UNIQUE (job_order_id, machine_id),

    CONSTRAINT job_order_machine_dates_check
        CHECK (
            released_at IS NULL
            OR released_at >= assigned_at
        )
);


CREATE INDEX idx_job_order_machines_job
ON jobwork.job_order_machines(job_order_id);

CREATE INDEX idx_job_order_machines_machine
ON jobwork.job_order_machines(machine_id);


-- ============================================================
-- 4. JOB ORDER → YARN REQUIREMENTS
--
-- This stores what the job NEEDS.
--
-- Actual physical yarn consumption will be recorded later
-- through yarn_issues → inventory.yarn_ledger.
-- ============================================================

CREATE TABLE jobwork.job_order_yarns (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    job_order_id UUID NOT NULL
        REFERENCES jobwork.job_orders(id)
        ON DELETE CASCADE,

    yarn_id UUID NOT NULL
        REFERENCES master.yarns(id)
        ON DELETE RESTRICT,

    requirement_percent NUMERIC(7,3),

    required_kg NUMERIC(14,3) NOT NULL,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT job_order_yarn_unique
        UNIQUE (job_order_id, yarn_id),

    CONSTRAINT job_order_yarn_required_check
        CHECK (required_kg > 0),

    CONSTRAINT job_order_yarn_percent_check
        CHECK (
            requirement_percent IS NULL
            OR (
                requirement_percent >= 0
                AND requirement_percent <= 100
            )
        )
);


CREATE INDEX idx_job_order_yarns_job
ON jobwork.job_order_yarns(job_order_id);

CREATE INDEX idx_job_order_yarns_yarn
ON jobwork.job_order_yarns(yarn_id);


-- ============================================================
-- 5. UPDATED_AT FUNCTION
--
-- Create only if it does not already exist.
-- ============================================================

CREATE OR REPLACE FUNCTION jobwork.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


CREATE TRIGGER job_orders_updated_at
BEFORE UPDATE ON jobwork.job_orders
FOR EACH ROW
EXECUTE FUNCTION jobwork.set_updated_at();


-- ============================================================
-- 6. PRIMARY MACHINE SAFETY
--
-- Maximum one primary machine per job.
-- ============================================================

CREATE UNIQUE INDEX uq_job_order_primary_machine
ON jobwork.job_order_machines(job_order_id)
WHERE is_primary = TRUE;


-- ============================================================
-- 7. JOB ORDER SUMMARY VIEW
-- ============================================================

CREATE OR REPLACE VIEW jobwork.job_order_summary AS

SELECT

    j.id,

    j.company_id,

    j.financial_year_id,

    j.job_no,

    j.job_date,

    j.party_id,

    p.code AS party_code,

    p.name AS party_name,

    j.fabric_id,

    f.code AS fabric_code,

    f.name AS fabric_name,

    j.design_no,

    j.order_quantity_kg,

    j.status,

    COUNT(DISTINCT jm.id) AS machine_count,

    COUNT(DISTINCT jy.id) AS yarn_count,

    COALESCE(
        SUM(jy.required_kg),
        0
    ) AS total_required_yarn_kg,

    j.created_at,

    j.updated_at

FROM jobwork.job_orders j

JOIN master.parties p
    ON p.id = j.party_id

JOIN master.fabrics f
    ON f.id = j.fabric_id

LEFT JOIN jobwork.job_order_machines jm
    ON jm.job_order_id = j.id

LEFT JOIN jobwork.job_order_yarns jy
    ON jy.job_order_id = j.id

GROUP BY

    j.id,
    j.company_id,
    j.financial_year_id,
    j.job_no,
    j.job_date,
    j.party_id,
    p.code,
    p.name,
    j.fabric_id,
    f.code,
    f.name,
    j.design_no,
    j.order_quantity_kg,
    j.status,
    j.created_at,
    j.updated_at;


COMMIT;