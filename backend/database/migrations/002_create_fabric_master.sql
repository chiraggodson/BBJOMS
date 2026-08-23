-- ============================================================
-- BBJOMS
-- FABRIC MASTER
-- Migration: 002_create_fabric_master.sql
-- ============================================================

CREATE TABLE IF NOT EXISTS fabrics (
    id BIGSERIAL PRIMARY KEY,

    fabric_code VARCHAR(50) NOT NULL UNIQUE,

    name VARCHAR(255) NOT NULL,

    description TEXT,

    gsm NUMERIC(10,2),

    composition VARCHAR(255),

    width_inches NUMERIC(10,2),

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fabrics_code
    ON fabrics(fabric_code);

CREATE INDEX IF NOT EXISTS idx_fabrics_name
    ON fabrics(name);

CREATE INDEX IF NOT EXISTS idx_fabrics_active
    ON fabrics(is_active);