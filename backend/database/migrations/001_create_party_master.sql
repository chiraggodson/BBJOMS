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