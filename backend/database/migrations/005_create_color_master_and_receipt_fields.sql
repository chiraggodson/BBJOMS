BEGIN;

-- ============================================================
-- COLOR MASTER + YARN RECEIPT COLOR / BOXES
-- ============================================================

CREATE TABLE IF NOT EXISTS master.colors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code varchar(30) NOT NULL UNIQUE,
  name varchar(100) NOT NULL,
  description text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Preserve colours that were previously stored on Yarn Master.
WITH legacy_colours AS (
  SELECT DISTINCT ON (LOWER(TRIM(colour)))
    LOWER(TRIM(colour)) AS colour_key,
    TRIM(colour) AS colour_name
  FROM master.yarns
  WHERE colour IS NOT NULL AND TRIM(colour) <> ''
  ORDER BY LOWER(TRIM(colour)), TRIM(colour)
), missing AS (
  SELECT l.*, ROW_NUMBER() OVER (ORDER BY l.colour_name) AS rn
  FROM legacy_colours l
  WHERE NOT EXISTS (
    SELECT 1 FROM master.colors c
    WHERE LOWER(TRIM(c.name)) = l.colour_key
  )
), base_no AS (
  SELECT COALESCE(
    MAX(CAST(NULLIF(SUBSTRING(code FROM '^CLR-([0-9]+)$'), '') AS INTEGER)),
    0
  ) AS n
  FROM master.colors
  WHERE code LIKE 'CLR-%'
)
INSERT INTO master.colors (code, name, description)
SELECT
  'CLR-' || LPAD((base_no.n + missing.rn)::text, 4, '0'),
  missing.colour_name,
  'Migrated from Yarn Master'
FROM missing CROSS JOIN base_no;

ALTER TABLE master.yarn_lots
  ADD COLUMN IF NOT EXISTS color_id uuid;

UPDATE master.yarn_lots yl
SET color_id = c.id
FROM master.yarns y
JOIN master.colors c
  ON LOWER(TRIM(c.name)) = LOWER(TRIM(y.colour))
WHERE yl.yarn_id = y.id
  AND yl.color_id IS NULL
  AND y.colour IS NOT NULL
  AND TRIM(y.colour) <> '';

ALTER TABLE master.yarn_lots
  DROP CONSTRAINT IF EXISTS yarn_lots_color_id_fkey;

ALTER TABLE master.yarn_lots
  ADD CONSTRAINT yarn_lots_color_id_fkey
  FOREIGN KEY (color_id) REFERENCES master.colors(id);

ALTER TABLE inventory.yarn_receipt_lines
  ADD COLUMN IF NOT EXISTS box_count integer;

ALTER TABLE inventory.yarn_receipt_lines
  DROP CONSTRAINT IF EXISTS yarn_receipt_lines_box_count_check;

ALTER TABLE inventory.yarn_receipt_lines
  ADD CONSTRAINT yarn_receipt_lines_box_count_check
  CHECK (box_count IS NULL OR box_count >= 0);

-- Colour now belongs to the received lot, not the generic Yarn Master.
ALTER TABLE master.yarns
  DROP COLUMN IF EXISTS colour;

COMMIT;
