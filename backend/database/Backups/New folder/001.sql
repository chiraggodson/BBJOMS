BEGIN;

-- ============================================================
-- BBJOMS 2.0
-- MIGRATION 001 — CORE FOUNDATION
-- Database: trial_bbjoms
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- 1. CORE COMPANIES
-- ============================================================

CREATE TABLE core.companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    code VARCHAR(30) NOT NULL,
    name VARCHAR(200) NOT NULL,
    legal_name VARCHAR(200),

    gstin VARCHAR(20),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(20),
    country VARCHAR(100) NOT NULL DEFAULT 'India',

    phone VARCHAR(30),
    email CITEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT companies_code_unique
        UNIQUE (code),

    CONSTRAINT companies_name_unique
        UNIQUE (name)
);

-- ============================================================
-- 2. FINANCIAL YEARS
-- ============================================================

CREATE TABLE core.financial_years (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES core.companies(id)
        ON DELETE CASCADE,

    code VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,

    start_date DATE NOT NULL,
    end_date DATE NOT NULL,

    is_current BOOLEAN NOT NULL DEFAULT FALSE,
    is_closed BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT financial_years_dates_valid
        CHECK (end_date >= start_date),

    CONSTRAINT financial_years_code_unique
        UNIQUE (company_id, code)
);

-- Only one current financial year per company
CREATE UNIQUE INDEX financial_years_one_current
ON core.financial_years(company_id)
WHERE is_current = TRUE;

-- ============================================================
-- 3. USERS
-- ============================================================

CREATE TABLE core.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES core.companies(id)
        ON DELETE CASCADE,

    username CITEXT NOT NULL,
    display_name VARCHAR(150) NOT NULL,

    password_hash TEXT NOT NULL,

    email CITEXT,
    phone VARCHAR(30),

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    last_login_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT users_username_unique
        UNIQUE (company_id, username)
);

-- ============================================================
-- 4. ROLES
-- ============================================================

CREATE TABLE core.roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID
        REFERENCES core.companies(id)
        ON DELETE CASCADE,

    name VARCHAR(100) NOT NULL,
    description TEXT,

    is_system BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT roles_name_unique
        UNIQUE (company_id, name)
);

-- ============================================================
-- 5. PERMISSIONS
-- ============================================================

CREATE TABLE core.permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    code VARCHAR(100) NOT NULL,
    name VARCHAR(150) NOT NULL,

    module VARCHAR(100) NOT NULL,
    description TEXT,

    CONSTRAINT permissions_code_unique
        UNIQUE (code)
);

-- ============================================================
-- 6. ROLE PERMISSIONS
-- ============================================================

CREATE TABLE core.role_permissions (
    role_id UUID NOT NULL
        REFERENCES core.roles(id)
        ON DELETE CASCADE,

    permission_id UUID NOT NULL
        REFERENCES core.permissions(id)
        ON DELETE CASCADE,

    PRIMARY KEY (role_id, permission_id)
);

-- ============================================================
-- 7. USER ROLES
-- ============================================================

CREATE TABLE core.user_roles (
    user_id UUID NOT NULL
        REFERENCES core.users(id)
        ON DELETE CASCADE,

    role_id UUID NOT NULL
        REFERENCES core.roles(id)
        ON DELETE CASCADE,

    PRIMARY KEY (user_id, role_id)
);

-- ============================================================
-- 8. SETTINGS
-- ============================================================

CREATE TABLE core.settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    company_id UUID NOT NULL
        REFERENCES core.companies(id)
        ON DELETE CASCADE,

    setting_key VARCHAR(150) NOT NULL,
    setting_value JSONB NOT NULL DEFAULT '{}'::jsonb,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT settings_key_unique
        UNIQUE (company_id, setting_key)
);

-- ============================================================
-- 9. UPDATED_AT TRIGGER
-- ============================================================

CREATE OR REPLACE FUNCTION core.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER companies_updated_at
BEFORE UPDATE ON core.companies
FOR EACH ROW
EXECUTE FUNCTION core.set_updated_at();

CREATE TRIGGER users_updated_at
BEFORE UPDATE ON core.users
FOR EACH ROW
EXECUTE FUNCTION core.set_updated_at();

CREATE TRIGGER settings_updated_at
BEFORE UPDATE ON core.settings
FOR EACH ROW
EXECUTE FUNCTION core.set_updated_at();

-- ============================================================
-- 10. CREATE B&B KNITFAB
-- ============================================================

INSERT INTO core.companies (
    code,
    name,
    legal_name,
    country,
    is_active
)
VALUES (
    'BBKF',
    'B&B KnitFab',
    'B&B KnitFab',
    'India',
    TRUE
);

-- ============================================================
-- 11. CURRENT FINANCIAL YEAR
-- ============================================================

INSERT INTO core.financial_years (
    company_id,
    code,
    name,
    start_date,
    end_date,
    is_current,
    is_closed
)
SELECT
    id,
    '2026-27',
    'Financial Year 2026-27',
    DATE '2026-04-01',
    DATE '2027-03-31',
    TRUE,
    FALSE
FROM core.companies
WHERE code = 'BBKF';

-- ============================================================
-- 12. SYSTEM PERMISSIONS
-- ============================================================

INSERT INTO core.permissions (
    code,
    name,
    module,
    description
)
VALUES

('dashboard.view',
 'View Dashboard',
 'dashboard',
 'View dashboard'),

('master.view',
 'View Masters',
 'master',
 'View master data'),

('master.create',
 'Create Masters',
 'master',
 'Create master records'),

('master.update',
 'Update Masters',
 'master',
 'Update master records'),

('master.delete',
 'Delete Masters',
 'master',
 'Delete master records'),

('inventory.view',
 'View Inventory',
 'inventory',
 'View inventory'),

('inventory.create',
 'Create Inventory Transactions',
 'inventory',
 'Create inventory transactions'),

('inventory.adjust',
 'Adjust Inventory',
 'inventory',
 'Create stock adjustments'),

('jobwork.view',
 'View Jobwork',
 'jobwork',
 'View jobwork'),

('jobwork.create',
 'Create Jobwork',
 'jobwork',
 'Create job orders'),

('jobwork.update',
 'Update Jobwork',
 'jobwork',
 'Update job orders'),

('production.view',
 'View Production',
 'production',
 'View production'),

('production.create',
 'Create Production',
 'production',
 'Create production entries'),

('dispatch.view',
 'View Dispatch',
 'dispatch',
 'View dispatch'),

('dispatch.create',
 'Create Dispatch',
 'dispatch',
 'Create dispatch'),

('reports.view',
 'View Reports',
 'reports',
 'View reports'),

('admin.users',
 'Manage Users',
 'admin',
 'Manage users'),

('admin.roles',
 'Manage Roles',
 'admin',
 'Manage roles'),

('admin.settings',
 'Manage Settings',
 'admin',
 'Manage company settings');

-- ============================================================
-- 13. ADMIN ROLE
-- ============================================================

INSERT INTO core.roles (
    company_id,
    name,
    description,
    is_system
)
SELECT
    id,
    'Administrator',
    'Full access to BBJOMS',
    TRUE
FROM core.companies
WHERE code = 'BBKF';

-- ============================================================
-- 14. GIVE ADMIN ALL PERMISSIONS
-- ============================================================

INSERT INTO core.role_permissions (
    role_id,
    permission_id
)
SELECT
    r.id,
    p.id
FROM core.roles r
CROSS JOIN core.permissions p
WHERE r.name = 'Administrator'
  AND r.company_id = (
      SELECT id
      FROM core.companies
      WHERE code = 'BBKF'
  );

COMMIT;