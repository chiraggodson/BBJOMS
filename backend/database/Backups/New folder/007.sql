BEGIN;

-- ============================================================
-- BBJOMS 007
-- YARN RETURN ENGINE
-- Database: trial_bbjoms
--
-- Flow:
-- YARN ISSUE
--     ↓
-- ISSUE LINE
--     ↓
-- YARN RETURN
--     ↓
-- RETURN LINE
--     ↓
-- INVENTORY YARN LEDGER
--
-- A return can never exceed the quantity issued
-- against the specific issue line.
-- ============================================================


-- ============================================================
-- 1. RETURN NUMBER SEQUENCE
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS jobwork.yarn_return_no_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1;


-- ============================================================
-- 2. YARN RETURNS HEADER
-- ============================================================

CREATE TABLE IF NOT EXISTS jobwork.yarn_returns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL,
    financial_year_id UUID NOT NULL,

    return_no VARCHAR(50) NOT NULL
        DEFAULT (
            'YR-' ||
            LPAD(
                nextval('jobwork.yarn_return_no_seq')::text,
                6,
                '0'
            )
        ),

    return_date DATE NOT NULL DEFAULT CURRENT_DATE,

    job_order_id UUID NOT NULL,

    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',

    notes TEXT,

    created_by UUID,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT yarn_returns_status_check
        CHECK (
            status IN ('DRAFT', 'POSTED', 'CANCELLED')
        ),

    CONSTRAINT yarn_returns_return_no_unique
        UNIQUE (company_id, return_no),

    CONSTRAINT yarn_returns_company_id_fkey
        FOREIGN KEY (company_id)
        REFERENCES core.companies(id)
        ON DELETE RESTRICT,

    CONSTRAINT yarn_returns_financial_year_id_fkey
        FOREIGN KEY (financial_year_id)
        REFERENCES core.financial_years(id)
        ON DELETE RESTRICT,

    CONSTRAINT yarn_returns_job_order_id_fkey
        FOREIGN KEY (job_order_id)
        REFERENCES jobwork.job_orders(id)
        ON DELETE RESTRICT,

    CONSTRAINT yarn_returns_created_by_fkey
        FOREIGN KEY (created_by)
        REFERENCES core.users(id)
        ON DELETE SET NULL
);


-- ============================================================
-- 3. YARN RETURN LINES
-- ============================================================

CREATE TABLE IF NOT EXISTS jobwork.yarn_return_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    return_id UUID NOT NULL,

    issue_line_id UUID NOT NULL,

    location_id UUID NOT NULL,

    quantity_kg NUMERIC(14,3) NOT NULL,

    remarks TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT yarn_return_lines_quantity_check
        CHECK (quantity_kg > 0),

    CONSTRAINT yarn_return_lines_return_id_fkey
        FOREIGN KEY (return_id)
        REFERENCES jobwork.yarn_returns(id)
        ON DELETE CASCADE,

    CONSTRAINT yarn_return_lines_issue_line_id_fkey
        FOREIGN KEY (issue_line_id)
        REFERENCES jobwork.yarn_issue_lines(id)
        ON DELETE RESTRICT,

    CONSTRAINT yarn_return_lines_location_id_fkey
        FOREIGN KEY (location_id)
        REFERENCES master.locations(id)
        ON DELETE RESTRICT
);


-- ============================================================
-- 4. INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_yarn_returns_company
    ON jobwork.yarn_returns(company_id);

CREATE INDEX IF NOT EXISTS idx_yarn_returns_job
    ON jobwork.yarn_returns(job_order_id);

CREATE INDEX IF NOT EXISTS idx_yarn_returns_status
    ON jobwork.yarn_returns(status);

CREATE INDEX IF NOT EXISTS idx_yarn_return_lines_return
    ON jobwork.yarn_return_lines(return_id);

CREATE INDEX IF NOT EXISTS idx_yarn_return_lines_issue_line
    ON jobwork.yarn_return_lines(issue_line_id);

CREATE INDEX IF NOT EXISTS idx_yarn_return_lines_location
    ON jobwork.yarn_return_lines(location_id);


-- ============================================================
-- 5. UPDATED_AT FUNCTION
-- ============================================================

CREATE OR REPLACE FUNCTION jobwork.set_yarn_return_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


DROP TRIGGER IF EXISTS trg_yarn_returns_updated_at
ON jobwork.yarn_returns;

CREATE TRIGGER trg_yarn_returns_updated_at
BEFORE UPDATE ON jobwork.yarn_returns
FOR EACH ROW
EXECUTE FUNCTION jobwork.set_yarn_return_updated_at();


-- ============================================================
-- 6. VALIDATE RETURN HEADER
--
-- Ensures:
-- - Job belongs to same company
-- - Return company matches job company
-- ============================================================

CREATE OR REPLACE FUNCTION jobwork.validate_yarn_return_header()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_job_company UUID;
BEGIN

    SELECT company_id
    INTO v_job_company
    FROM jobwork.job_orders
    WHERE id = NEW.job_order_id;

    IF v_job_company IS NULL THEN
        RAISE EXCEPTION
            'Job order % does not exist',
            NEW.job_order_id;
    END IF;

    IF v_job_company <> NEW.company_id THEN
        RAISE EXCEPTION
            'Return company does not match job order company';
    END IF;

    RETURN NEW;
END;
$$;


DROP TRIGGER IF EXISTS trg_validate_yarn_return_header
ON jobwork.yarn_returns;

CREATE TRIGGER trg_validate_yarn_return_header
BEFORE INSERT OR UPDATE
ON jobwork.yarn_returns
FOR EACH ROW
EXECUTE FUNCTION jobwork.validate_yarn_return_header();


-- ============================================================
-- 7. VALIDATE RETURN LINE
--
-- Every return line must:
--
-- Return → Issue Line → Issue → Job
--
-- and:
--
-- issue_line.yarn_lot_id
-- remains the exact lot being returned.
-- ============================================================

CREATE OR REPLACE FUNCTION jobwork.validate_yarn_return_line()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_return_job UUID;
    v_return_company UUID;

    v_issue_job UUID;
    v_issue_company UUID;

    v_issue_status VARCHAR(20);
BEGIN

    SELECT
        r.job_order_id,
        r.company_id
    INTO
        v_return_job,
        v_return_company
    FROM jobwork.yarn_returns r
    WHERE r.id = NEW.return_id;

    IF v_return_job IS NULL THEN
        RAISE EXCEPTION
            'Yarn return % does not exist',
            NEW.return_id;
    END IF;


    SELECT
        yi.job_order_id,
        yi.company_id,
        yi.status
    INTO
        v_issue_job,
        v_issue_company,
        v_issue_status
    FROM jobwork.yarn_issue_lines il
    JOIN jobwork.yarn_issues yi
        ON yi.id = il.issue_id
    WHERE il.id = NEW.issue_line_id;


    IF v_issue_job IS NULL THEN
        RAISE EXCEPTION
            'Issue line % does not exist',
            NEW.issue_line_id;
    END IF;


    IF v_issue_job <> v_return_job THEN
        RAISE EXCEPTION
            'Return line issue does not belong to the selected job order';
    END IF;


    IF v_issue_company <> v_return_company THEN
        RAISE EXCEPTION
            'Return line company does not match issue company';
    END IF;


    IF v_issue_status <> 'POSTED' THEN
        RAISE EXCEPTION
            'Only POSTED yarn issues can be returned. Current status: %',
            v_issue_status;
    END IF;


    RETURN NEW;
END;
$$;


DROP TRIGGER IF EXISTS trg_validate_yarn_return_line
ON jobwork.yarn_return_lines;

CREATE TRIGGER trg_validate_yarn_return_line
BEFORE INSERT OR UPDATE
ON jobwork.yarn_return_lines
FOR EACH ROW
EXECUTE FUNCTION jobwork.validate_yarn_return_line();


-- ============================================================
-- 8. VALIDATE RETURN QUANTITY
--
-- CRITICAL BUSINESS RULE:
--
-- Total returns against an issue line
-- must never exceed the issued quantity.
-- ============================================================

CREATE OR REPLACE FUNCTION jobwork.validate_yarn_return_quantity()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_issued NUMERIC(14,3);
    v_returned NUMERIC(14,3);
    v_available NUMERIC(14,3);
BEGIN

    SELECT quantity_kg
    INTO v_issued
    FROM jobwork.yarn_issue_lines
    WHERE id = NEW.issue_line_id;


    IF v_issued IS NULL THEN
        RAISE EXCEPTION
            'Issue line % not found',
            NEW.issue_line_id;
    END IF;


    SELECT COALESCE(SUM(quantity_kg), 0)
    INTO v_returned
    FROM jobwork.yarn_return_lines
    WHERE issue_line_id = NEW.issue_line_id
      AND id <> NEW.id
      AND return_id IN (
          SELECT id
          FROM jobwork.yarn_returns
          WHERE status = 'POSTED'
      );


    v_available := v_issued - v_returned;


    -- If this return itself is being posted,
    -- it must fit inside the available quantity.
    IF EXISTS (
        SELECT 1
        FROM jobwork.yarn_returns r
        WHERE r.id = NEW.return_id
          AND r.status = 'POSTED'
    ) THEN

        IF NEW.quantity_kg > v_available THEN
            RAISE EXCEPTION
                'Return quantity %.3f KG exceeds available quantity %.3f KG for issue line %',
                NEW.quantity_kg,
                v_available,
                NEW.issue_line_id;
        END IF;

    END IF;


    RETURN NEW;
END;
$$;


DROP TRIGGER IF EXISTS trg_validate_yarn_return_quantity
ON jobwork.yarn_return_lines;

CREATE TRIGGER trg_validate_yarn_return_quantity
BEFORE INSERT OR UPDATE
ON jobwork.yarn_return_lines
FOR EACH ROW
EXECUTE FUNCTION jobwork.validate_yarn_return_quantity();


-- ============================================================
-- 9. PREVENT MODIFICATION OF POSTED RETURNS
-- ============================================================

CREATE OR REPLACE FUNCTION jobwork.prevent_posted_yarn_return_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    IF TG_OP = 'DELETE' THEN

        IF OLD.status = 'POSTED' THEN
            RAISE EXCEPTION
                'POSTED yarn return % cannot be deleted',
                OLD.return_no;
        END IF;

        RETURN OLD;

    END IF;


    IF OLD.status = 'POSTED' THEN
        RAISE EXCEPTION
            'POSTED yarn return % cannot be modified',
            OLD.return_no;
    END IF;


    RETURN NEW;
END;
$$;


DROP TRIGGER IF EXISTS trg_prevent_posted_yarn_return_changes
ON jobwork.yarn_returns;

CREATE TRIGGER trg_prevent_posted_yarn_return_changes
BEFORE UPDATE OR DELETE
ON jobwork.yarn_returns
FOR EACH ROW
EXECUTE FUNCTION jobwork.prevent_posted_yarn_return_changes();


-- ============================================================
-- 10. PREVENT MODIFICATION OF POSTED RETURN LINES
-- ============================================================

CREATE OR REPLACE FUNCTION jobwork.prevent_posted_yarn_return_line_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(20);
BEGIN

    SELECT status
    INTO v_status
    FROM jobwork.yarn_returns
    WHERE id = COALESCE(OLD.return_id, NEW.return_id);


    IF v_status = 'POSTED' THEN

        RAISE EXCEPTION
            'Lines of a POSTED yarn return cannot be modified';
    END IF;


    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$;


DROP TRIGGER IF EXISTS trg_prevent_posted_yarn_return_line_changes
ON jobwork.yarn_return_lines;

CREATE TRIGGER trg_prevent_posted_yarn_return_line_changes
BEFORE UPDATE OR DELETE
ON jobwork.yarn_return_lines
FOR EACH ROW
EXECUTE FUNCTION jobwork.prevent_posted_yarn_return_line_changes();


-- ============================================================
-- 11. POST RETURN → YARN LEDGER
--
-- One ledger entry is created per return line.
--
-- RETURN = quantity_in
-- ============================================================

CREATE OR REPLACE FUNCTION jobwork.post_yarn_return_to_ledger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_line RECORD;
BEGIN

    -- Only execute when changing into POSTED.
    IF NEW.status = 'POSTED'
       AND (TG_OP = 'INSERT' OR OLD.status <> 'POSTED')
    THEN

        -- A posted return must contain at least one line.
        IF NOT EXISTS (
            SELECT 1
            FROM jobwork.yarn_return_lines
            WHERE return_id = NEW.id
        ) THEN
            RAISE EXCEPTION
                'Cannot post yarn return % without return lines',
                NEW.return_no;
        END IF;


        -- Re-check total quantities before ledger posting.
        FOR v_line IN
            SELECT
                rl.id,
                rl.issue_line_id,
                rl.location_id,
                rl.quantity_kg
            FROM jobwork.yarn_return_lines rl
            WHERE rl.return_id = NEW.id
        LOOP

            IF v_line.quantity_kg >
               (
                   SELECT
                       il.quantity_kg
                       -
                       COALESCE(
                           (
                               SELECT SUM(previous.quantity_kg)
                               FROM jobwork.yarn_return_lines previous
                               JOIN jobwork.yarn_returns pr
                                   ON pr.id = previous.return_id
                               WHERE previous.issue_line_id = il.id
                                 AND previous.return_id <> NEW.id
                                 AND pr.status = 'POSTED'
                           ),
                           0
                       )
                   FROM jobwork.yarn_issue_lines il
                   WHERE il.id = v_line.issue_line_id
               )
            THEN

                RAISE EXCEPTION
                    'Return quantity exceeds issued quantity for issue line %',
                    v_line.issue_line_id;

            END IF;


            -- Create inventory movement.
            INSERT INTO inventory.yarn_ledger (
                company_id,
                financial_year_id,
                yarn_lot_id,
                location_id,
                movement_date,
                movement_type,
                quantity_in,
                quantity_out,
                reference_type,
                reference_id,
                remarks,
                created_by
            )
            SELECT
                NEW.company_id,
                NEW.financial_year_id,
                il.yarn_lot_id,
                v_line.location_id,
                NEW.return_date::timestamptz,
                'RETURN',
                v_line.quantity_kg,
                0,
                'YARN_RETURN',
                NEW.id,
                COALESCE(
                    v_line.quantity_kg::text || ' KG returned against ' ||
                    NEW.return_no,
                    NEW.return_no
                ),
                NEW.created_by
            FROM jobwork.yarn_issue_lines il
            WHERE il.id = v_line.issue_line_id;

        END LOOP;

    END IF;


    RETURN NEW;
END;
$$;


DROP TRIGGER IF EXISTS trg_post_yarn_return_to_ledger
ON jobwork.yarn_returns;

CREATE TRIGGER trg_post_yarn_return_to_ledger
AFTER INSERT OR UPDATE
ON jobwork.yarn_returns
FOR EACH ROW
EXECUTE FUNCTION jobwork.post_yarn_return_to_ledger();


-- ============================================================
-- 12. RETURN SUMMARY VIEW
--
-- Convenient source for backend/API.
-- ============================================================

CREATE OR REPLACE VIEW jobwork.yarn_return_summary AS
SELECT
    r.id,
    r.return_no,
    r.return_date,
    r.company_id,
    r.financial_year_id,
    r.job_order_id,
    j.job_no,
    r.status,
    r.notes,

    COUNT(rl.id) AS line_count,

    COALESCE(
        SUM(rl.quantity_kg),
        0
    ) AS total_returned_kg,

    r.created_by,
    r.created_at,
    r.updated_at

FROM jobwork.yarn_returns r

JOIN jobwork.job_orders j
    ON j.id = r.job_order_id

LEFT JOIN jobwork.yarn_return_lines rl
    ON rl.return_id = r.id

GROUP BY
    r.id,
    r.return_no,
    r.return_date,
    r.company_id,
    r.financial_year_id,
    r.job_order_id,
    j.job_no,
    r.status,
    r.notes,
    r.created_by,
    r.created_at,
    r.updated_at;


-- ============================================================
-- 13. RETURN DETAIL VIEW
--
-- Shows exactly which yarn/lot was returned.
-- ============================================================

CREATE OR REPLACE VIEW jobwork.yarn_return_detail AS
SELECT
    r.id AS return_id,
    r.return_no,
    r.return_date,
    r.status,

    r.job_order_id,
    j.job_no,

    rl.id AS return_line_id,
    rl.issue_line_id,

    il.yarn_id,
    y.code AS yarn_code,
    y.name AS yarn_name,

    il.yarn_lot_id,
    yl.lot_no,

    c.id AS color_id,
    c.code AS color_code,
    c.name AS color_name,

    rl.location_id,
    loc.code AS location_code,
    loc.name AS location_name,

    il.quantity_kg AS issued_kg,
    rl.quantity_kg AS returned_kg,

    (
        il.quantity_kg
        -
        COALESCE(
            (
                SELECT SUM(other.quantity_kg)
                FROM jobwork.yarn_return_lines other
                JOIN jobwork.yarn_returns rr
                    ON rr.id = other.return_id
                WHERE other.issue_line_id = il.id
                  AND rr.status = 'POSTED'
            ),
            0
        )
    ) AS remaining_returnable_kg,

    rl.remarks

FROM jobwork.yarn_return_lines rl

JOIN jobwork.yarn_returns r
    ON r.id = rl.return_id

JOIN jobwork.job_orders j
    ON j.id = r.job_order_id

JOIN jobwork.yarn_issue_lines il
    ON il.id = rl.issue_line_id

JOIN master.yarns y
    ON y.id = il.yarn_id

JOIN master.yarn_lots yl
    ON yl.id = il.yarn_lot_id

LEFT JOIN master.colors c
    ON c.id = yl.color_id

JOIN master.locations loc
    ON loc.id = rl.location_id;


-- ============================================================
-- 14. COMMENTS
-- ============================================================

COMMENT ON TABLE jobwork.yarn_returns IS
'Yarn returned from a job back into inventory. Posted returns create inventory ledger RETURN transactions.';

COMMENT ON TABLE jobwork.yarn_return_lines IS
'Lot-specific yarn return lines linked directly to the original yarn issue line.';

COMMENT ON VIEW jobwork.yarn_return_summary IS
'Summary of yarn returns by job.';

COMMENT ON VIEW jobwork.yarn_return_detail IS
'Detailed yarn return information including yarn, lot, color, location and remaining returnable quantity.';


COMMIT;