CREATE TABLE IF NOT EXISTS parties (
    id BIGSERIAL PRIMARY KEY,

    party_code VARCHAR(30) NOT NULL UNIQUE,

    name VARCHAR(200) NOT NULL,
    alias VARCHAR(200),

    gstin VARCHAR(20),
    pan VARCHAR(20),

    address_line1 VARCHAR(250),
    address_line2 VARCHAR(250),
    city VARCHAR(100),
    state VARCHAR(100),
    pin_code VARCHAR(20),
    country VARCHAR(100) NOT NULL DEFAULT 'India',

    contact_person VARCHAR(150),
    phone VARCHAR(30),
    email VARCHAR(150),

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS party_roles (
    id BIGSERIAL PRIMARY KEY,

    party_id BIGINT NOT NULL
        REFERENCES parties(id)
        ON DELETE CASCADE,

    role VARCHAR(50) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT party_roles_unique
        UNIQUE (party_id, role)
);

CREATE INDEX IF NOT EXISTS idx_parties_name
    ON parties(name);

CREATE INDEX IF NOT EXISTS idx_parties_city
    ON parties(city);

CREATE INDEX IF NOT EXISTS idx_parties_active
    ON parties(is_active);

CREATE INDEX IF NOT EXISTS idx_party_roles_role
    ON party_roles(role);

CREATE INDEX IF NOT EXISTS idx_party_roles_party_id
    ON party_roles(party_id);

-- ============================================================
-- JOB ORDERS
-- ============================================================

CREATE TABLE IF NOT EXISTS job_orders (
    id BIGSERIAL PRIMARY KEY,

    job_no VARCHAR(50) NOT NULL UNIQUE,

    job_date DATE NOT NULL DEFAULT CURRENT_DATE,

    party_id BIGINT NOT NULL
        REFERENCES parties(id)
        ON DELETE RESTRICT,

    fabric_name VARCHAR(255) NOT NULL,

    design_no VARCHAR(100),

    gsm NUMERIC(10,2),

    order_quantity NUMERIC(12,2) NOT NULL DEFAULT 0,

    status VARCHAR(30) NOT NULL DEFAULT 'Open',

    stitch_length NUMERIC(10,3),

    notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_job_orders_party_id
    ON job_orders(party_id);

CREATE INDEX IF NOT EXISTS idx_job_orders_job_date
    ON job_orders(job_date);

CREATE INDEX IF NOT EXISTS idx_job_orders_status
    ON job_orders(status);

CREATE INDEX IF NOT EXISTS idx_job_orders_job_no
    ON job_orders(job_no);

-- ============================================================
-- JOB ORDER MACHINES
-- ============================================================

CREATE TABLE IF NOT EXISTS job_order_machines (
    id BIGSERIAL PRIMARY KEY,

    job_order_id BIGINT NOT NULL
        REFERENCES job_orders(id)
        ON DELETE CASCADE,

    machine_id BIGINT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT job_order_machines_unique
        UNIQUE (job_order_id, machine_id)
);

CREATE INDEX IF NOT EXISTS idx_job_order_machines_job
    ON job_order_machines(job_order_id);

CREATE INDEX IF NOT EXISTS idx_job_order_machines_machine
    ON job_order_machines(machine_id);

-- ============================================================
-- JOB ORDER YARN REQUIREMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS job_order_yarns (
    id BIGSERIAL PRIMARY KEY,

    job_order_id BIGINT NOT NULL
        REFERENCES job_orders(id)
        ON DELETE CASCADE,

    yarn_name VARCHAR(255) NOT NULL,

    yarn_count VARCHAR(100),

    required_kg NUMERIC(12,3) NOT NULL DEFAULT 0,

    issued_kg NUMERIC(12,3) NOT NULL DEFAULT 0,

    returned_kg NUMERIC(12,3) NOT NULL DEFAULT 0,

    waste_kg NUMERIC(12,3) NOT NULL DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_job_order_yarns_job
    ON job_order_yarns(job_order_id);


-- ============================================================
-- JOB PRODUCTION
-- ============================================================

CREATE TABLE IF NOT EXISTS job_production (
    id BIGSERIAL PRIMARY KEY,

    job_order_id BIGINT NOT NULL
        REFERENCES job_orders(id)
        ON DELETE CASCADE,

    machine_id BIGINT,

    production_date DATE NOT NULL DEFAULT CURRENT_DATE,

    roll_no VARCHAR(100),

    quantity_kg NUMERIC(12,3) NOT NULL DEFAULT 0,

    remarks TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_job_production_job
    ON job_production(job_order_id);

CREATE INDEX IF NOT EXISTS idx_job_production_date
    ON job_production(production_date);