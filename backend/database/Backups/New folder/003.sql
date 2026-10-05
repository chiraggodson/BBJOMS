BEGIN;

-- ============================================================
-- BBJOMS 2.0
-- MIGRATION 003 — FACTORY MASTER DATA
-- Database: trial_bbjoms
-- ============================================================

-- ============================================================
-- 1. PARTIES
-- ============================================================

INSERT INTO master.parties (
    company_id,
    code,
    name,
    alias,
    country,
    is_active
)
SELECT
    c.id,
    p.code,
    p.name,
    p.alias,
    'India',
    TRUE
FROM core.companies c
CROSS JOIN (
    VALUES
        ('PTY00001', 'Lakshay Knit India', 'Lakshay Knit India'),
        ('PTY00002', 'Prime Fashion',      'Prime Fashion'),
        ('PTY00003', 'Bharti Fabrics',     'Bharti Fabrics'),
        ('PTY00004', 'Parasram Apparels',  'Parasram Apparels'),
        ('PTY00005', 'Ansh Fabrics',       'A.F'),
        ('PTY00006', 'Bhavya Fabrics',      'Bhavya Fabrics'),
        ('PTY00007', 'Hitesh Yarn',        'Hitesh Yarn'),
        ('PTY00008', 'Bhagwati',            'Bhagwati')
) AS p(code, name, alias)
WHERE c.code = 'BBKF';


-- ============================================================
-- 2. PARTY ROLE ASSIGNMENTS
-- ============================================================

-- Customers
INSERT INTO master.party_role_assignments (
    party_id,
    role_id
)
SELECT
    p.id,
    r.id
FROM master.parties p
JOIN master.party_roles r
    ON r.code = 'CUSTOMER'
WHERE p.code IN (
    'PTY00001',
    'PTY00002',
    'PTY00003',
    'PTY00004',
    'PTY00005',
    'PTY00006'
);

-- Suppliers
INSERT INTO master.party_role_assignments (
    party_id,
    role_id
)
SELECT
    p.id,
    r.id
FROM master.parties p
JOIN master.party_roles r
    ON r.code = 'SUPPLIER'
WHERE p.code IN (
    'PTY00007',
    'PTY00008'
);


-- ============================================================
-- 3. COLORS
-- ============================================================

INSERT INTO master.colors (
    code,
    name,
    is_active
)
VALUES
    ('CLR-0001', 'White', TRUE),
    ('CLR-0002', 'Kora',  TRUE);


-- ============================================================
-- 4. YARN MASTER
--
-- yarn_type_id intentionally populated only where the
-- classification is explicitly clear from the yarn name.
-- We can refine classifications later.
-- ============================================================

INSERT INTO master.yarns (
    company_id,
    code,
    name,
    yarn_type_id,
    unit_id,
    is_active
)
SELECT
    c.id,
    y.code,
    y.name,
    yt.id,
    u.id,
    TRUE
FROM core.companies c
JOIN master.units u
    ON u.company_id = c.id
   AND u.code = 'KG'
LEFT JOIN (
    VALUES
        ('YRN-0001', '40''S Viscose',           'VISCOSE'),
        ('YRN-0002', '80/72/S',                 NULL),
        ('YRN-0003', '75/36',                   NULL),
        ('YRN-0004', '20 D Lycra',              'LYCRA'),
        ('YRN-0005', '32''S Fake Cotton',       NULL),
        ('YRN-0006', '30''S Cotton',            'COTTON'),
        ('YRN-0007', '150/144',                 NULL),
        ('YRN-0008', '15 NM Chenille',          'CHENILLE'),
        ('YRN-0009', '120 D Polyester',         'POLYESTER'),
        ('YRN-0010', '80/20 Covered Lycra',     'LYCRA'),
        ('YRN-0011', '150/108 Polyester',       'POLYESTER'),
        ('YRN-0012', '40''S PC (48/52)',        'PC'),
        ('YRN-0013', '40 D Lycra',              'LYCRA'),
        ('YRN-0014', '50 D Polyester',          'POLYESTER')
) AS y(code, name, type_code)
    ON TRUE
LEFT JOIN master.yarn_types yt
    ON yt.code = y.type_code
WHERE c.code = 'BBKF';


-- ============================================================
-- 5. FABRICS
--
-- GSM / width / composition are intentionally NULL here.
-- These are product specifications and should not be guessed.
-- ============================================================

INSERT INTO master.fabrics (
    company_id,
    code,
    name,
    category_id,
    unit_id,
    is_active
)
SELECT
    c.id,
    f.code,
    f.name,
    fc.id,
    u.id,
    TRUE
FROM core.companies c
JOIN master.units u
    ON u.company_id = c.id
   AND u.code = 'KG'
LEFT JOIN (
    VALUES
        ('12G-01', 'Sinker Jacquard Lycra', 'SINKER_JACQUARD'),
        ('IJ-01',  'Chennille',             'INTERLOCK_JACQUARD'),
        ('IP-01',  'Crush Knit',            'INTERLOCK'),
        ('IP-02',  'Russian Fleece',        'INTERLOCK'),
        ('IS-01',  'Scuba',                 'INTERLOCK'),
        ('OKJ-01', 'OverKnit Jacquard',     'INTERLOCK_JACQUARD'),
        ('SSK-01', 'Sweater Knit',          'SINKER')
) AS f(code, name, category_code)
    ON TRUE
LEFT JOIN master.fabric_categories fc
    ON fc.company_id = c.id
   AND fc.code = f.category_code
WHERE c.code = 'BBKF';


COMMIT;