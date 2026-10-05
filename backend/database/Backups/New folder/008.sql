BEGIN;

-- ============================================================
-- BBJOMS 008
-- PRODUCTION + ROLL ENGINE
--
-- Flow:
--
-- Job Order
--     ↓
-- Job Machine
--     ↓
-- Production Entry
--     ↓
-- Production Rolls
--     ↓
-- Future:
-- Checking → Cutting → Firing → Finishing → Fabric Stock
--
-- Production is transaction based.
-- Posted records cannot be edited/deleted.
-- ============================================================


-- ============================================================
-- 1. PRODUCTION NUMBER SEQUENCE
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS production.production_no_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1;


-- ============================================================
-- 2. PRODUCTION ENTRIES
-- ============================================================

CREATE TABLE IF NOT EXISTS production.fabric_production (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL,

    financial_year_id UUID NOT NULL,

    production_no VARCHAR(50) NOT NULL
        DEFAULT (
            'PR-' ||
            LPAD(
                nextval('production.production_no_seq')::text,
                6,
                '0'
            )
        ),

    production_date DATE NOT NULL DEFAULT CURRENT_DATE,

    job_order_id UUID NOT NULL,

    machine_id UUID NOT NULL,

    operator_name VARCHAR(150),

    shift VARCHAR(30),

    start_time TIMESTAMPTZ,

    end_time TIMESTAMPTZ,

    rpm NUMERIC(10,2),

    counter NUMERIC(14,2),

    kg_per_hour NUMERIC(14,3),

    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',

    notes TEXT,

    created_by UUID,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),


    -- --------------------------------------------------------
    -- CHECKS
    -- --------------------------------------------------------

    CONSTRAINT fabric_production_status_check
        CHECK (
            status IN (
                'DRAFT',
                'POSTED',
                'CANCELLED'
            )
        ),

    CONSTRAINT fabric_production_rpm_check
        CHECK (
            rpm IS NULL OR rpm >= 0
        ),

    CONSTRAINT fabric_production_counter_check
        CHECK (
            counter IS NULL OR counter >= 0
        ),

    CONSTRAINT fabric_production_kg_hour_check
        CHECK (
            kg_per_hour IS NULL OR kg_per_hour >= 0
        ),

    CONSTRAINT fabric_production_time_check
        CHECK (
            end_time IS NULL
            OR start_time IS NULL
            OR end_time >= start_time
        ),


    -- --------------------------------------------------------
    -- FOREIGN KEYS
    -- --------------------------------------------------------

    CONSTRAINT fabric_production_company_fkey
        FOREIGN KEY (company_id)
        REFERENCES core.companies(id)
        ON DELETE RESTRICT,

    CONSTRAINT fabric_production_financial_year_fkey
        FOREIGN KEY (financial_year_id)
        REFERENCES core.financial_years(id)
        ON DELETE RESTRICT,

    CONSTRAINT fabric_production_job_fkey
        FOREIGN KEY (job_order_id)
        REFERENCES jobwork.job_orders(id)
        ON DELETE RESTRICT,

    CONSTRAINT fabric_production_machine_fkey
        FOREIGN KEY (machine_id)
        REFERENCES master.machines(id)
        ON DELETE RESTRICT,

    CONSTRAINT fabric_production_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES core.users(id)
        ON DELETE SET NULL,


    -- --------------------------------------------------------
    -- DOCUMENT NUMBER
    -- --------------------------------------------------------

    CONSTRAINT fabric_production_no_unique
        UNIQUE (company_id, production_no)
);


-- ============================================================
-- 3. PRODUCTION ROLLS
-- ============================================================

CREATE TABLE IF NOT EXISTS production.fabric_production_rolls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    production_id UUID NOT NULL,

    roll_no VARCHAR(50) NOT NULL,

    gross_weight_kg NUMERIC(14,3) NOT NULL DEFAULT 0,

    tare_weight_kg NUMERIC(14,3) NOT NULL DEFAULT 0,

    net_weight_kg NUMERIC(14,3) NOT NULL,

    meters NUMERIC(14,2),

    width_inches NUMERIC(10,2),

    gsm NUMERIC(10,2),

    remarks TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),


    -- --------------------------------------------------------
    -- CHECKS
    -- --------------------------------------------------------

    CONSTRAINT production_roll_gross_check
        CHECK (gross_weight_kg >= 0),

    CONSTRAINT production_roll_tare_check
        CHECK (tare_weight_kg >= 0),

    CONSTRAINT production_roll_net_check
        CHECK (net_weight_kg > 0),

    CONSTRAINT production_roll_meters_check
        CHECK (
            meters IS NULL OR meters >= 0
        ),

    CONSTRAINT production_roll_width_check
        CHECK (
            width_inches IS NULL OR width_inches > 0
        ),

    CONSTRAINT production_roll_gsm_check
        CHECK (
            gsm IS NULL OR gsm > 0
        ),


    -- --------------------------------------------------------
    -- FOREIGN KEY
    -- --------------------------------------------------------

    CONSTRAINT production_roll_production_fkey
        FOREIGN KEY (production_id)
        REFERENCES production.fabric_production(id)
        ON DELETE CASCADE,


    -- --------------------------------------------------------
    -- UNIQUE ROLL NUMBER PER PRODUCTION
    -- --------------------------------------------------------

    CONSTRAINT production_roll_no_unique
        UNIQUE (production_id, roll_no)
);


-- ============================================================
-- 4. PRODUCTION INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fabric_production_company
    ON production.fabric_production(company_id);

CREATE INDEX IF NOT EXISTS idx_fabric_production_job
    ON production.fabric_production(job_order_id);

CREATE INDEX IF NOT EXISTS idx_fabric_production_machine
    ON production.fabric_production(machine_id);

CREATE INDEX IF NOT EXISTS idx_fabric_production_date
    ON production.fabric_production(production_date);

CREATE INDEX IF NOT EXISTS idx_fabric_production_status
    ON production.fabric_production(status);


CREATE INDEX IF NOT EXISTS idx_production_rolls_production
    ON production.fabric_production_rolls(production_id);


-- ============================================================
-- 5. UPDATED_AT
-- ============================================================

CREATE OR REPLACE FUNCTION production.set_fabric_production_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


DROP TRIGGER IF EXISTS trg_fabric_production_updated_at
ON production.fabric_production;


CREATE TRIGGER trg_fabric_production_updated_at
BEFORE UPDATE
ON production.fabric_production
FOR EACH ROW
EXECUTE FUNCTION production.set_fabric_production_updated_at();


-- ============================================================
-- 6. VALIDATE PRODUCTION ENTRY
--
-- Production job + machine must belong to same company.
--
-- Machine must also be assigned to the job.
-- ============================================================

CREATE OR REPLACE FUNCTION production.validate_fabric_production()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_job_company UUID;
    v_machine_company UUID;
    v_machine_assigned BOOLEAN;
BEGIN

    -- --------------------------------------------------------
    -- Job company
    -- --------------------------------------------------------

    SELECT company_id
    INTO v_job_company
    FROM jobwork.job_orders
    WHERE id = NEW.job_order_id;


    IF v_job_company IS NULL THEN
        RAISE EXCEPTION
            'Job order % does not exist',
            NEW.job_order_id;
    END IF;


    -- --------------------------------------------------------
    -- Machine company
    -- --------------------------------------------------------

    SELECT company_id
    INTO v_machine_company
    FROM master.machines
    WHERE id = NEW.machine_id;


    IF v_machine_company IS NULL THEN
        RAISE EXCEPTION
            'Machine % does not exist',
            NEW.machine_id;
    END IF;


    -- --------------------------------------------------------
    -- Company consistency
    -- --------------------------------------------------------

    IF v_job_company <> NEW.company_id THEN
        RAISE EXCEPTION
            'Production company does not match job order company';
    END IF;


    IF v_machine_company <> NEW.company_id THEN
        RAISE EXCEPTION
            'Production company does not match machine company';
    END IF;


    -- --------------------------------------------------------
    -- Machine must belong to the job
    -- --------------------------------------------------------

    SELECT EXISTS (
        SELECT 1
        FROM jobwork.job_order_machines jm
        WHERE jm.job_order_id = NEW.job_order_id
          AND jm.machine_id = NEW.machine_id
    )
    INTO v_machine_assigned;


    IF NOT v_machine_assigned THEN
        RAISE EXCEPTION
            'Machine % is not assigned to job order %',
            NEW.machine_id,
            NEW.job_order_id;
    END IF;


    RETURN NEW;
END;
$$;


DROP TRIGGER IF EXISTS trg_validate_fabric_production
ON production.fabric_production;


CREATE TRIGGER trg_validate_fabric_production
BEFORE INSERT OR UPDATE
ON production.fabric_production
FOR EACH ROW
EXECUTE FUNCTION production.validate_fabric_production();


-- ============================================================
-- 7. VALIDATE PRODUCTION ROLL
-- ============================================================

CREATE OR REPLACE FUNCTION production.validate_fabric_production_roll()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(20);
BEGIN

    SELECT status
    INTO v_status
    FROM production.fabric_production
    WHERE id = NEW.production_id;


    IF v_status IS NULL THEN
        RAISE EXCEPTION
            'Production entry % does not exist',
            NEW.production_id;
    END IF;


    -- Posted production cannot receive new/changed rolls.
    IF v_status = 'POSTED' THEN
        RAISE EXCEPTION
            'Cannot modify rolls of POSTED production %',
            NEW.production_id;
    END IF;


    -- Net weight should normally equal gross minus tare.
    IF NEW.gross_weight_kg > 0
       AND NEW.net_weight_kg >
           NEW.gross_weight_kg
    THEN
        RAISE EXCEPTION
            'Net weight cannot exceed gross weight';
    END IF;


    IF NEW.gross_weight_kg > 0
       AND NEW.tare_weight_kg >
           NEW.gross_weight_kg
    THEN
        RAISE EXCEPTION
            'Tare weight cannot exceed gross weight';
    END IF;


    RETURN NEW;
END;
$$;


DROP TRIGGER IF EXISTS trg_validate_fabric_production_roll
ON production.fabric_production_rolls;


CREATE TRIGGER trg_validate_fabric_production_roll
BEFORE INSERT OR UPDATE
ON production.fabric_production_rolls
FOR EACH ROW
EXECUTE FUNCTION production.validate_fabric_production_roll();


-- ============================================================
-- 8. PREVENT EDITING POSTED PRODUCTION
-- ============================================================

CREATE OR REPLACE FUNCTION production.prevent_posted_production_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    IF TG_OP = 'DELETE' THEN

        IF OLD.status = 'POSTED' THEN
            RAISE EXCEPTION
                'POSTED production % cannot be deleted',
                OLD.production_no;
        END IF;

        RETURN OLD;

    END IF;


    IF OLD.status = 'POSTED' THEN
        RAISE EXCEPTION
            'POSTED production % cannot be modified',
            OLD.production_no;
    END IF;


    RETURN NEW;
END;
$$;


DROP TRIGGER IF EXISTS trg_prevent_posted_production_changes
ON production.fabric_production;


CREATE TRIGGER trg_prevent_posted_production_changes
BEFORE UPDATE OR DELETE
ON production.fabric_production
FOR EACH ROW
EXECUTE FUNCTION production.prevent_posted_production_changes();


-- ============================================================
-- 9. PRODUCTION SUMMARY VIEW
-- ============================================================

CREATE OR REPLACE VIEW production.fabric_production_summary AS
SELECT
    p.id,

    p.production_no,

    p.production_date,

    p.company_id,

    p.financial_year_id,

    p.job_order_id,

    j.job_no,

    j.fabric_id,

    p.machine_id,

    m.machine_no AS machine_code,

    m.machine_no AS machine_name,

    p.operator_name,

    p.shift,

    p.rpm,

    p.counter,

    p.kg_per_hour,

    p.status,

    COUNT(r.id) AS roll_count,

    COALESCE(
        SUM(r.net_weight_kg),
        0
    ) AS total_production_kg,

    COALESCE(
        SUM(r.meters),
        0
    ) AS total_meters,

    p.notes,

    p.created_at,

    p.updated_at

FROM production.fabric_production p

JOIN jobwork.job_orders j
    ON j.id = p.job_order_id

JOIN master.machines m
    ON m.id = p.machine_id

LEFT JOIN production.fabric_production_rolls r
    ON r.production_id = p.id

GROUP BY
    p.id,
    p.production_no,
    p.production_date,
    p.company_id,
    p.financial_year_id,
    p.job_order_id,
    j.job_no,
    j.fabric_id,
    p.machine_id,
    m.machine_no,
    m.machine_no,
    p.operator_name,
    p.shift,
    p.rpm,
    p.counter,
    p.kg_per_hour,
    p.status,
    p.notes,
    p.created_at,
    p.updated_at;


-- ============================================================
-- 10. ROLL DETAIL VIEW
-- ============================================================

CREATE OR REPLACE VIEW production.fabric_roll_detail AS
SELECT
    r.id AS roll_id,

    p.id AS production_id,

    p.production_no,

    p.production_date,

    p.company_id,

    p.job_order_id,

    j.job_no,

    j.fabric_id,

    f.code AS fabric_code,

    f.name AS fabric_name,

    p.machine_id,

    m.machine_no AS machine_code,

    m.machine_no AS machine_name,

    r.roll_no,

    r.gross_weight_kg,

    r.tare_weight_kg,

    r.net_weight_kg,

    r.meters,

    r.width_inches,

    r.gsm,

    p.status AS production_status,

    r.remarks,

    r.created_at

FROM production.fabric_production_rolls r

JOIN production.fabric_production p
    ON p.id = r.production_id

JOIN jobwork.job_orders j
    ON j.id = p.job_order_id

JOIN master.fabrics f
    ON f.id = j.fabric_id

JOIN master.machines m
    ON m.id = p.machine_id;


-- ============================================================
-- 11. COMMENTS
-- ============================================================

COMMENT ON TABLE production.fabric_production IS
'Production header recording job, machine, shift, operator and machine production parameters.';

COMMENT ON TABLE production.fabric_production_rolls IS
'Individual fabric rolls produced from a production entry.';

COMMENT ON VIEW production.fabric_production_summary IS
'Production summary by production entry including total rolls, KG and meters.';

COMMENT ON VIEW production.fabric_roll_detail IS
'Detailed traceability from fabric roll back to job order, fabric and machine.';


COMMIT;