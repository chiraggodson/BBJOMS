BEGIN;

-- ============================================================
-- BBJOMS 2.0
-- MIGRATION 002 — MASTER FOUNDATION
-- Database: trial_bbjoms
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

-- ============================================================
-- 1. UNITS
-- ============================================================

CREATE TABLE master.units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID
        REFERENCES core.companies(id)
        ON DELETE CASCADE,

    code VARCHAR(30) NOT NULL,
    name VARCHAR(100) NOT NULL,

    decimal_places SMALLINT NOT NULL DEFAULT 3,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT units_decimal_places_check
        CHECK (decimal_places BETWEEN 0 AND 6),

    CONSTRAINT units_code_unique
        UNIQUE (company_id, code)
);

-- ============================================================
-- 2. PARTY ROLES
-- ============================================================

CREATE TABLE master.party_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT party_roles_code_unique
        UNIQUE (code)
);

-- ============================================================
-- 3. PARTIES
-- ============================================================

CREATE TABLE master.parties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES core.companies(id)
        ON DELETE CASCADE,

    code VARCHAR(40) NOT NULL,
    name VARCHAR(200) NOT NULL,
    alias VARCHAR(200),

    gstin VARCHAR(20),
    pan VARCHAR(20),

    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(20),
    country VARCHAR(100) NOT NULL DEFAULT 'India',

    phone VARCHAR(30),
    email CITEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT parties_code_unique
        UNIQUE (company_id, code)
);

CREATE INDEX idx_parties_name
ON master.parties(company_id, LOWER(name));

-- ============================================================
-- 4. PARTY ↔ ROLE
-- ============================================================

CREATE TABLE master.party_role_assignments (
    party_id UUID NOT NULL
        REFERENCES master.parties(id)
        ON DELETE CASCADE,

    role_id UUID NOT NULL
        REFERENCES master.party_roles(id)
        ON DELETE RESTRICT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (party_id, role_id)
);

-- ============================================================
-- 5. YARN TYPES
-- ============================================================

CREATE TABLE master.yarn_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID
        REFERENCES core.companies(id)
        ON DELETE CASCADE,

    code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,

    description TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT yarn_types_code_unique
        UNIQUE (company_id, code)
);

-- ============================================================
-- 6. YARN MASTER
-- Generic yarn definition.
-- Ownership/supplier/color belong to the LOT.
-- ============================================================

CREATE TABLE master.yarns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID
        REFERENCES core.companies(id)
        ON DELETE CASCADE,

    code VARCHAR(40) NOT NULL,
    name VARCHAR(200) NOT NULL,

    yarn_type_id UUID
        REFERENCES master.yarn_types(id)
        ON DELETE RESTRICT,

    unit_id UUID
        REFERENCES master.units(id)
        ON DELETE RESTRICT,

    description TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT yarns_code_unique
        UNIQUE (company_id, code)
);

CREATE INDEX idx_yarns_name
ON master.yarns(LOWER(name));

-- ============================================================
-- 7. COLORS
-- ============================================================

CREATE TABLE master.colors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    code VARCHAR(40) NOT NULL,
    name VARCHAR(100) NOT NULL,

    description TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT colors_code_unique
        UNIQUE (code),

    CONSTRAINT colors_name_unique
        UNIQUE (name)
);

-- ============================================================
-- 8. YARN LOTS
--
-- company_id          = BBJOMS operating company
-- supplier_party_id   = who supplied the yarn
-- stock_owner_party_id= who owns the yarn
-- ============================================================

CREATE TABLE master.yarn_lots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES core.companies(id)
        ON DELETE CASCADE,

    lot_no VARCHAR(50) NOT NULL,

    yarn_id UUID NOT NULL
        REFERENCES master.yarns(id)
        ON DELETE RESTRICT,

    color_id UUID
        REFERENCES master.colors(id)
        ON DELETE RESTRICT,

    supplier_party_id UUID
        REFERENCES master.parties(id)
        ON DELETE RESTRICT,

    stock_owner_party_id UUID
        REFERENCES master.parties(id)
        ON DELETE RESTRICT,

    supplier_lot_no VARCHAR(100),

    received_date DATE,

    remarks TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT yarn_lots_no_unique
        UNIQUE (company_id, lot_no)
);

CREATE INDEX idx_yarn_lots_yarn
ON master.yarn_lots(yarn_id);

CREATE INDEX idx_yarn_lots_supplier
ON master.yarn_lots(supplier_party_id);

CREATE INDEX idx_yarn_lots_owner
ON master.yarn_lots(stock_owner_party_id);

-- ============================================================
-- 9. FABRIC CATEGORIES
-- ============================================================

CREATE TABLE master.fabric_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES core.companies(id)
        ON DELETE CASCADE,

    code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,

    parent_id UUID
        REFERENCES master.fabric_categories(id)
        ON DELETE RESTRICT,

    description TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fabric_categories_code_unique
        UNIQUE (company_id, code)
);

-- ============================================================
-- 10. FABRICS
-- ============================================================

CREATE TABLE master.fabrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES core.companies(id)
        ON DELETE CASCADE,

    code VARCHAR(50) NOT NULL,
    name VARCHAR(200) NOT NULL,

    category_id UUID
        REFERENCES master.fabric_categories(id)
        ON DELETE RESTRICT,

    unit_id UUID
        REFERENCES master.units(id)
        ON DELETE RESTRICT,

    gsm NUMERIC(10,3),
    width_inches NUMERIC(10,3),

    composition TEXT,

    description TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fabrics_code_unique
        UNIQUE (company_id, code),

    CONSTRAINT fabrics_gsm_check
        CHECK (gsm IS NULL OR gsm > 0),

    CONSTRAINT fabrics_width_check
        CHECK (width_inches IS NULL OR width_inches > 0)
);

CREATE INDEX idx_fabrics_name
ON master.fabrics(company_id, LOWER(name));

-- ============================================================
-- 11. FLOORS
-- ============================================================

CREATE TABLE master.floors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES core.companies(id)
        ON DELETE CASCADE,

    code VARCHAR(40) NOT NULL,
    name VARCHAR(100) NOT NULL,

    sort_order INTEGER NOT NULL DEFAULT 0,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT floors_code_unique
        UNIQUE (company_id, code)
);

-- ============================================================
-- 12. LOCATIONS
-- ============================================================

CREATE TABLE master.locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES core.companies(id)
        ON DELETE CASCADE,

    code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,

    floor_id UUID
        REFERENCES master.floors(id)
        ON DELETE RESTRICT,

    parent_location_id UUID
        REFERENCES master.locations(id)
        ON DELETE RESTRICT,

    location_type VARCHAR(50) NOT NULL DEFAULT 'STORAGE',

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT locations_code_unique
        UNIQUE (company_id, code),

    CONSTRAINT locations_type_check
        CHECK (
            location_type IN (
                'STORAGE',
                'PRODUCTION',
                'YARN_STORAGE',
                'FABRIC_STORAGE',
                'DISPATCH',
                'OTHER'
            )
        )
);

-- ============================================================
-- 13. MACHINE GROUPS
-- ============================================================

CREATE TABLE master.machine_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES core.companies(id)
        ON DELETE CASCADE,

    code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,

    description TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT machine_groups_code_unique
        UNIQUE (company_id, code)
);

-- ============================================================
-- 14. MACHINES
-- ============================================================

CREATE TABLE master.machines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES core.companies(id)
        ON DELETE CASCADE,

    machine_no VARCHAR(50) NOT NULL,

    machine_group_id UUID
        REFERENCES master.machine_groups(id)
        ON DELETE RESTRICT,

    floor_id UUID
        REFERENCES master.floors(id)
        ON DELETE RESTRICT,

    location_id UUID
        REFERENCES master.locations(id)
        ON DELETE RESTRICT,

    status VARCHAR(30) NOT NULL DEFAULT 'IDLE',

    rpm NUMERIC(10,2) NOT NULL DEFAULT 0,
    counter NUMERIC(14,2) NOT NULL DEFAULT 0,

    roll_size NUMERIC(10,2),

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT machines_no_unique
        UNIQUE (company_id, machine_no),

    CONSTRAINT machines_status_check
        CHECK (
            status IN (
                'IDLE',
                'RUNNING',
                'PAUSED',
                'MAINTENANCE',
                'OFFLINE'
            )
        ),

    CONSTRAINT machines_rpm_check
        CHECK (rpm >= 0),

    CONSTRAINT machines_counter_check
        CHECK (counter >= 0)
);

CREATE INDEX idx_machines_group
ON master.machines(machine_group_id);

CREATE INDEX idx_machines_floor
ON master.machines(floor_id);

-- ============================================================
-- 15. UPDATED_AT TRIGGERS
-- ============================================================

CREATE TRIGGER parties_updated_at
BEFORE UPDATE ON master.parties
FOR EACH ROW
EXECUTE FUNCTION core.set_updated_at();

CREATE TRIGGER yarns_updated_at
BEFORE UPDATE ON master.yarns
FOR EACH ROW
EXECUTE FUNCTION core.set_updated_at();

CREATE TRIGGER yarn_lots_updated_at
BEFORE UPDATE ON master.yarn_lots
FOR EACH ROW
EXECUTE FUNCTION core.set_updated_at();

CREATE TRIGGER colors_updated_at
BEFORE UPDATE ON master.colors
FOR EACH ROW
EXECUTE FUNCTION core.set_updated_at();

CREATE TRIGGER fabrics_updated_at
BEFORE UPDATE ON master.fabrics
FOR EACH ROW
EXECUTE FUNCTION core.set_updated_at();

CREATE TRIGGER machines_updated_at
BEFORE UPDATE ON master.machines
FOR EACH ROW
EXECUTE FUNCTION core.set_updated_at();

-- ============================================================
-- 16. BASIC UNITS
-- ============================================================

INSERT INTO master.units (
    company_id,
    code,
    name,
    decimal_places
)
SELECT
    c.id,
    x.code,
    x.name,
    x.decimal_places
FROM core.companies c
CROSS JOIN (
    VALUES
        ('KG',    'Kilogram', 3),
        ('MTR',   'Meter',    3),
        ('PCS',   'Pieces',   0),
        ('ROLL',  'Roll',     0),
        ('BOX',   'Box',      0)
) AS x(code, name, decimal_places)
WHERE c.code = 'BBKF';

-- ============================================================
-- 17. PARTY ROLES
-- ============================================================

INSERT INTO master.party_roles (
    code,
    name,
    description
)
VALUES
    ('CUSTOMER',    'Customer',    'Customer / jobwork party'),
    ('SUPPLIER',    'Supplier',    'Supplier of yarn, material or services'),
    ('TRANSPORTER', 'Transporter', 'Transport / logistics provider'),
    ('JOBWORK',     'Jobwork',     'Jobwork-related party'),
    ('OTHER',       'Other',       'Other business party');

-- ============================================================
-- 18. YARN TYPES
-- ============================================================

INSERT INTO master.yarn_types (
    code,
    name,
    description
)
VALUES
    ('COTTON',      'Cotton',      'Cotton yarn'),
    ('POLYESTER',   'Polyester',   'Polyester yarn'),
    ('VISCOSE',     'Viscose',     'Viscose yarn'),
    ('LYCRA',       'Lycra',       'Lycra / elastane'),
    ('PC',          'PC',          'Polyester cotton'),
    ('CHENILLE',    'Chenille',    'Chenille yarn'),
    ('OTHER',       'Other',       'Other yarn type');

-- ============================================================
-- 19. FABRIC CATEGORIES
-- ============================================================

INSERT INTO master.fabric_categories (
    company_id,
    code,
    name
)
SELECT
    c.id,
    x.code,
    x.name
FROM core.companies c
CROSS JOIN (
    VALUES
        ('INTERLOCK',          'Interlock'),
        ('SINKER',             'Sinker'),
        ('INTERLOCK_JACQUARD', 'Interlock Jacquard'),
        ('SINKER_JACQUARD',    'Sinker Jacquard'),
        ('OTHER',              'Other')
) AS x(code, name)
WHERE c.code = 'BBKF';

-- ============================================================
-- 20. FLOORS
-- ============================================================

INSERT INTO master.floors (
    company_id,
    code,
    name,
    sort_order
)
SELECT
    c.id,
    x.code,
    x.name,
    x.sort_order
FROM core.companies c
CROSS JOIN (
    VALUES
        ('MAIN-FLOOR',   'Main Floor',   1),
        ('SECOND-FLOOR', 'Second Floor', 2),
        ('THIRD-FLOOR',  'Third Floor',  3)
) AS x(code, name, sort_order)
WHERE c.code = 'BBKF';

-- ============================================================
-- 21. LOCATIONS
-- ============================================================

INSERT INTO master.locations (
    company_id,
    code,
    name,
    location_type
)
SELECT
    c.id,
    x.code,
    x.name,
    x.location_type
FROM core.companies c
CROSS JOIN (
    VALUES
        ('YARN-STORAGE',  'Yarn Storage',  'YARN_STORAGE'),
        ('FAB-DISPATCH',  'Fabric Dispatch', 'DISPATCH'),
        ('MAIN-FLOOR',    'Main Floor',    'PRODUCTION'),
        ('SECOND-FLOOR',  'Second Floor',  'PRODUCTION'),
        ('THIRD-FLOOR',   'Third Floor',   'PRODUCTION')
) AS x(code, name, location_type)
WHERE c.code = 'BBKF';

-- ============================================================
-- 22. MACHINE GROUPS
-- ============================================================

INSERT INTO master.machine_groups (
    company_id,
    code,
    name
)
SELECT
    c.id,
    x.code,
    x.name
FROM core.companies c
CROSS JOIN (
    VALUES
        ('INTERLOCK',            'Interlock'),
        ('SINKER',               'Sinker'),
        ('INTERLOCK_JACQUARD',   'Interlock Jacquard'),
        ('SINKER_JACQUARD',      'Sinker Jacquard'),
        ('SINKER_JACQUARD_12G',  '12G Sinker Jacquard'),
        ('TRANSFER_INTERLOCK_32', 'Transfer Interlock 32"'),
        ('TRANSFER_INTERLOCK',   'Transfer Interlock')
) AS x(code, name)
WHERE c.code = 'BBKF';

-- ============================================================
-- 23. SEED 31 MACHINES
--
-- Floor intentionally left NULL.
-- We will assign floors after confirming the physical layout.
-- ============================================================

INSERT INTO master.machines (
    company_id,
    machine_no,
    machine_group_id,
    status,
    rpm,
    counter,
    roll_size
)
SELECT
    c.id,
    m.machine_no,
    mg.id,
    'IDLE',
    0,
    0,
    0
FROM core.companies c
JOIN (
    VALUES
        ('1',  'INTERLOCK'),
        ('2',  'INTERLOCK'),

        ('3',  'SINKER'),
        ('4',  'SINKER'),

        ('5',  'INTERLOCK_JACQUARD'),
        ('6',  'INTERLOCK_JACQUARD'),
        ('7',  'INTERLOCK_JACQUARD'),
        ('8',  'INTERLOCK_JACQUARD'),

        ('9',  'SINKER_JACQUARD'),
        ('10', 'SINKER_JACQUARD'),
        ('11', 'SINKER_JACQUARD'),
        ('12', 'SINKER_JACQUARD'),

        ('13', 'SINKER_JACQUARD_12G'),

        ('14', 'SINKER_JACQUARD'),

        ('15', 'INTERLOCK_JACQUARD'),
        ('16', 'INTERLOCK_JACQUARD'),
        ('17', 'INTERLOCK_JACQUARD'),
        ('18', 'INTERLOCK_JACQUARD'),
        ('19', 'INTERLOCK_JACQUARD'),

        ('20', 'TRANSFER_INTERLOCK_32'),
        ('21', 'TRANSFER_INTERLOCK_32'),

        ('22', 'INTERLOCK'),
        ('23', 'INTERLOCK'),
        ('24', 'INTERLOCK'),
        ('25', 'INTERLOCK'),
        ('26', 'INTERLOCK'),
        ('27', 'INTERLOCK'),
        ('28', 'INTERLOCK'),
        ('29', 'INTERLOCK'),

        ('30', 'TRANSFER_INTERLOCK'),
        ('31', 'TRANSFER_INTERLOCK')
) AS m(machine_no, group_code)
    ON TRUE
JOIN master.machine_groups mg
    ON mg.company_id = c.id
   AND mg.code = m.group_code
WHERE c.code = 'BBKF';

COMMIT;