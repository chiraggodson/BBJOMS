const express = require('express');
const router = express.Router();
const { pool } = require('../db');

function clean(value) {
  if (value === undefined || value === null) return null;

  const v = String(value).trim();

  return v === '' ? null : v;
}

function isUuid(value) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
    String(value || '')
  );
}

// ============================================================
// COMPANIES
// GET /api/yarn-receipts/companies
//
// Returns B&B plus all active Customers from the existing
// Parties module. Customers are represented as core.companies
// because inventory.yarn_receipts.company_id is a UUID FK to
// core.companies.
// ============================================================

async function ensureCustomerCompanies() {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const customers = await client.query(`
      SELECT DISTINCT
        p.id,
        p.party_code,
        p.name,
        p.gstin,
        p.address_line1,
        p.address_line2,
        p.city,
        p.state,
        p.pin_code,
        p.country,
        p.phone,
        p.email
      FROM parties p
      JOIN party_roles pr
        ON pr.party_id = p.id
      WHERE COALESCE(p.is_active, true) = true
        AND LOWER(TRIM(pr.role)) = 'customer'
      ORDER BY p.name ASC
    `);

    const fyTemplate = await client.query(`
      SELECT code, name, start_date, end_date
      FROM core.financial_years
      WHERE is_current = true
        AND is_closed = false
      ORDER BY start_date DESC
      LIMIT 1
    `);

    let fyCode;
    let fyName;
    let fyStart;
    let fyEnd;

    if (fyTemplate.rows.length > 0) {
      const row = fyTemplate.rows[0];
      fyCode = row.code;
      fyName = row.name;
      fyStart = row.start_date;
      fyEnd = row.end_date;
    } else {
      const now = new Date();
      const year = now.getUTCMonth() >= 3
        ? now.getUTCFullYear()
        : now.getUTCFullYear() - 1;
      const nextYear = year + 1;

      fyCode = `${year}-${String(nextYear).slice(-2)}`;
      fyName = `FY ${fyCode}`;
      fyStart = `${year}-04-01`;
      fyEnd = `${nextYear}-03-31`;
    }

    for (const customer of customers.rows) {
      const companyCode = `CUST-${customer.id}`;

      const existing = await client.query(`
        SELECT id
        FROM core.companies
        WHERE code = $1
        LIMIT 1
      `, [companyCode]);

      let companyId;

      if (existing.rows.length > 0) {
        companyId = existing.rows[0].id;
      } else {
        const inserted = await client.query(`
          INSERT INTO core.companies (
            code, name, legal_name, gstin,
            address_line1, address_line2, city, state,
            pincode, country, phone, email, is_active
          )
          VALUES (
            $1, $2, $2, $3,
            $4, $5, $6, $7,
            $8, $9, $10, $11, true
          )
          ON CONFLICT (code) DO NOTHING
          RETURNING id
        `, [
          companyCode,
          customer.name,
          customer.gstin,
          customer.address_line1,
          customer.address_line2,
          customer.city,
          customer.state,
          customer.pin_code,
          customer.country || 'India',
          customer.phone,
          customer.email,
        ]);

        if (inserted.rows.length > 0) {
          companyId = inserted.rows[0].id;
        } else {
          const retry = await client.query(`
            SELECT id
            FROM core.companies
            WHERE code = $1
            LIMIT 1
          `, [companyCode]);
          companyId = retry.rows[0]?.id;
        }
      }

      if (!companyId) {
        throw new Error(
          `Could not create/find company for customer ${customer.name}.`
        );
      }

      const existingFy = await client.query(`
        SELECT id
        FROM core.financial_years
        WHERE company_id = $1
          AND code = $2
        LIMIT 1
      `, [companyId, fyCode]);

      if (existingFy.rows.length === 0) {
        await client.query(`
          INSERT INTO core.financial_years (
            company_id, code, name, start_date, end_date,
            is_current, is_closed
          )
          VALUES ($1, $2, $3, $4, $5, true, false)
          ON CONFLICT (company_id, code) DO NOTHING
        `, [companyId, fyCode, fyName, fyStart, fyEnd]);
      }
    }

    await client.query('COMMIT');
  } catch (error) {
    try { await client.query('ROLLBACK'); } catch (_) {}
    throw error;
  } finally {
    client.release();
  }
}

router.get('/companies', async (req, res) => {
  try {
    await ensureCustomerCompanies();

    const result = await pool.query(`
      SELECT id, code, name
      FROM core.companies
      WHERE COALESCE(is_active, true) = true
      ORDER BY
        CASE WHEN code LIKE 'CUST-%' THEN 1 ELSE 0 END,
        name ASC
    `);

    return res.json(result.rows);
  } catch (error) {
    console.error('Yarn receipt companies error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to load companies',
      details: error.message,
    });
  }
});

// ============================================================
// SUPPLIERS
//
// The existing Parties module uses:
//   parties
//   party_roles
//
// Yarn Supplier is identified by:
//   party_roles.role = 'Yarn Supplier'
//
// The receipt transaction later maps this party into
// master.parties because inventory.yarn_receipts.party_id
// uses the UUID master party.
// ============================================================

router.get('/suppliers', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT DISTINCT
        p.id,
        p.party_code AS code,
        p.party_code,
        p.name
      FROM parties p
      JOIN party_roles pr
        ON pr.party_id = p.id
      WHERE COALESCE(p.is_active, true) = true
        AND LOWER(pr.role) = 'yarn supplier'
      ORDER BY p.name ASC
    `);

    return res.json(result.rows);
  } catch (error) {
    console.error('Yarn suppliers error:', error);

    return res.status(500).json({
      success: false,
      error: 'Failed to load yarn suppliers',
      details: error.message,
    });
  }
});

// ============================================================
// COLORS
// GET /api/yarn-receipts/colors
// ============================================================

router.get('/colors', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT id, code, name, description
      FROM master.colors
      WHERE COALESCE(is_active, true) = true
      ORDER BY name ASC
    `);
    return res.json(result.rows);
  } catch (error) {
    console.error('Yarn colors error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to load colors',
      details: error.message,
    });
  }
});

// ============================================================
// LOCATIONS
//
// Locations are physical storage points. They are shared by B&B and
// customer-owned yarn, so they must NOT be filtered by owner company.
// GET /api/yarn-receipts/locations
// ============================================================

router.get('/locations', async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT
        id,
        code,
        name,
        location_type
      FROM master.locations
      WHERE COALESCE(is_active, true) = true
      ORDER BY name ASC, code ASC
      `
    );

    return res.json(result.rows);
  } catch (error) {
    console.error('Yarn locations error:', error);

    return res.status(500).json({
      success: false,
      error: 'Failed to load locations',
      details: error.message,
    });
  }
});

// ============================================================
// RECEIPT LIST
//
// GET /api/yarn-receipts
// GET /api/yarn-receipts?company_id=UUID
// ============================================================

router.get('/', async (req, res) => {
  try {
    const companyId = clean(req.query.company_id);

    const params = [];
    let companyFilter = '';

    if (companyId) {
      if (!isUuid(companyId)) {
        return res.status(400).json({
          success: false,
          error: 'Invalid company ID.',
        });
      }

      params.push(companyId);

      companyFilter = `
        WHERE r.company_id = $${params.length}
      `;
    }

    const result = await pool.query(
      `
      SELECT
        r.id,
        r.company_id,

        c.code AS company_code,
        c.name AS company_name,

        r.receipt_no,
        r.receipt_date,
        r.challan_no,
        r.bill_no,

        r.party_id,
        p.name AS supplier_name,

        r.location_id,
        l.name AS location_name,

        r.status,

        COALESCE(SUM(rl.quantity), 0) AS total_quantity,
        COUNT(rl.id) AS line_count

      FROM inventory.yarn_receipts r

      LEFT JOIN core.companies c
        ON c.id = r.company_id

      LEFT JOIN master.parties p
        ON p.id = r.party_id

      LEFT JOIN master.locations l
        ON l.id = r.location_id

      LEFT JOIN inventory.yarn_receipt_lines rl
        ON rl.receipt_id = r.id

      ${companyFilter}

      GROUP BY
        r.id,
        r.company_id,
        c.code,
        c.name,
        r.receipt_no,
        r.receipt_date,
        r.challan_no,
        r.bill_no,
        r.party_id,
        p.name,
        r.location_id,
        l.name,
        r.status,
        r.created_at

      ORDER BY
        r.receipt_date DESC,
        r.created_at DESC

      LIMIT 100
      `,
      params
    );

    return res.json(result.rows);
  } catch (error) {
    console.error('Yarn receipt list error:', error);

    return res.status(500).json({
      success: false,
      error: 'Failed to load yarn receipts',
      details: error.message,
    });
  }
});


// ============================================================
// YARN STOCK FOR ISSUE
//
// GET /api/yarn-receipts/stock
// Returns positive-balance stock by lot + location.
// ============================================================
router.get('/stock', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        yl.id AS yarn_lot_id,
        yl.lot_no,
        yl.supplier_lot_no,
        yl.received_date,

        yl.company_id,
        COALESCE(owner.name, '') AS owner_name,

        yl.yarn_id,
        y.code AS yarn_code,
        y.name AS yarn_name,
        y.count AS yarn_count,
        y.composition,

        yl.color_id,
        COALESCE(ccol.code, '') AS color_code,
        COALESCE(ccol.name, '') AS color_name,

        yl.supplier_party_id,
        COALESCE(sp.name, '') AS supplier_name,

        yl_loc.location_id,
        COALESCE(loc.name, '') AS location_name,

        COALESCE(SUM(l.quantity_in), 0)::float AS quantity_in,
        COALESCE(SUM(l.quantity_out), 0)::float AS quantity_out,
        COALESCE(SUM(l.quantity_in - l.quantity_out), 0)::float AS balance
      FROM master.yarn_lots yl
      JOIN master.yarns y
        ON y.id = yl.yarn_id
      LEFT JOIN master.colors ccol
        ON ccol.id = yl.color_id
      LEFT JOIN master.parties sp
        ON sp.id = yl.supplier_party_id
      LEFT JOIN core.companies owner
        ON owner.id = yl.company_id
      JOIN (
        SELECT DISTINCT yarn_lot_id, location_id
        FROM inventory.yarn_ledger
        WHERE location_id IS NOT NULL
      ) yl_loc
        ON yl_loc.yarn_lot_id = yl.id
      LEFT JOIN master.locations loc
        ON loc.id = yl_loc.location_id
      LEFT JOIN inventory.yarn_ledger l
        ON l.yarn_lot_id = yl.id
       AND l.location_id = yl_loc.location_id
      GROUP BY
        yl.id,
        yl.lot_no,
        yl.supplier_lot_no,
        yl.received_date,
        yl.company_id,
        owner.name,
        yl.yarn_id,
        y.code,
        y.name,
        y.count,
        y.composition,
        yl.color_id,
        ccol.code,
        ccol.name,
        yl.supplier_party_id,
        sp.name,
        yl_loc.location_id,
        loc.name
      HAVING COALESCE(SUM(l.quantity_in - l.quantity_out), 0) > 0
      ORDER BY y.name ASC, ccol.name ASC, yl.lot_no ASC, loc.name ASC
    `);

    return res.json({
      success: true,
      stock: result.rows,
    });
  } catch (error) {
    console.error('Yarn issue stock error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to load yarn stock for issue.',
      details: error.message,
    });
  }
});

// ============================================================
// RECENT YARN MOVEMENTS
//
// GET /api/yarn-receipts/movements?limit=50
// ============================================================
router.get('/movements', async (req, res) => {
  try {
    const requestedLimit = Number(req.query.limit);
    const limit = Number.isInteger(requestedLimit)
      ? Math.min(Math.max(requestedLimit, 1), 200)
      : 50;

    const result = await pool.query(`
      SELECT
        l.id,
        l.movement_date,
        l.created_at,
        l.movement_type,
        l.quantity_in::float AS quantity_in,
        l.quantity_out::float AS quantity_out,
        l.reference_type,
        l.reference_id,
        l.remarks,

        l.company_id,
        COALESCE(owner.name, '') AS owner_name,

        l.location_id,
        COALESCE(loc.name, '') AS location_name,

        yl.id AS yarn_lot_id,
        yl.lot_no,
        yl.supplier_lot_no,

        y.id AS yarn_id,
        y.code AS yarn_code,
        y.name AS yarn_name,
        y.count AS yarn_count,
        y.composition,

        yl.color_id,
        COALESCE(ccol.code, '') AS color_code,
        COALESCE(ccol.name, '') AS color_name,

        COALESCE(j.job_no, '') AS job_no
      FROM inventory.yarn_ledger l
      JOIN master.yarn_lots yl
        ON yl.id = l.yarn_lot_id
      JOIN master.yarns y
        ON y.id = yl.yarn_id
      LEFT JOIN master.colors ccol
        ON ccol.id = yl.color_id
      LEFT JOIN core.companies owner
        ON owner.id = l.company_id
      LEFT JOIN master.locations loc
        ON loc.id = l.location_id
      LEFT JOIN job_orders j
        ON l.reference_type = 'YARN_ISSUE'
       AND l.reference_id = md5('job:' || j.id::text)::uuid
      ORDER BY l.created_at DESC NULLS LAST, l.movement_date DESC, l.id DESC
      LIMIT $1
    `, [limit]);

    return res.json({
      success: true,
      movements: result.rows,
    });
  } catch (error) {
    console.error('Yarn movements error:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to load yarn movements.',
      details: error.message,
    });
  }
});

// ============================================================
// ISSUE YARN - MULTIPLE JOBS / MULTIPLE YARNS
//
// POST /api/yarn-receipts/issue-batch
//
// Each entry:
//   job_id
//   yarn_lot_id
//   location_id
//   quantity
//   remarks (optional)
//
// Every entry is written to the same inventory yarn ledger used
// by receipts, so stock remains fully traceable.
// ============================================================
router.post('/issue-batch', async (req, res) => {
  const entries = Array.isArray(req.body?.entries)
    ? req.body.entries
    : [];
  const issueDate = clean(req.body?.issue_date ?? req.body?.issueDate);

  if (entries.length === 0) {
    return res.status(400).json({
      success: false,
      error: 'At least one yarn issue line is required.',
    });
  }

  if (issueDate && !/^\d{4}-\d{2}-\d{2}$/.test(issueDate)) {
    return res.status(400).json({
      success: false,
      error: 'Issue date must be in YYYY-MM-DD format.',
    });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const saved = [];

    for (const raw of entries) {
      const jobId = Number(raw?.job_id ?? raw?.jobId);
      const yarnLotId = clean(raw?.yarn_lot_id ?? raw?.yarnLotId);
      const locationId = clean(raw?.location_id ?? raw?.locationId);
      const quantity = Number(raw?.quantity);
      const remarks = clean(raw?.remarks);

      if (!Number.isInteger(jobId) || jobId <= 0) {
        throw new Error('Invalid job ID in yarn issue batch.');
      }

      if (!yarnLotId || !isUuid(yarnLotId)) {
        throw new Error('Invalid yarn lot ID in yarn issue batch.');
      }

      if (!locationId || !isUuid(locationId)) {
        throw new Error('A valid stock location is required for every issue line.');
      }

      if (!Number.isFinite(quantity) || quantity <= 0) {
        throw new Error('Yarn issue quantity must be greater than zero.');
      }

      const job = await client.query(`
        SELECT id, job_no, party_id
        FROM job_orders
        WHERE id = $1
        LIMIT 1
      `, [jobId]);

      if (job.rows.length === 0) {
        throw new Error(`Job order ${jobId} was not found.`);
      }

      const lot = await client.query(`
        SELECT
          yl.id,
          yl.company_id,
          yl.yarn_id,
          yl.lot_no,
          yl.color_id,
          y.name AS yarn_name,
          COALESCE(ccol.name, '') AS color_name
        FROM master.yarn_lots yl
        JOIN master.yarns y
          ON y.id = yl.yarn_id
        LEFT JOIN master.colors ccol
          ON ccol.id = yl.color_id
        WHERE yl.id = $1
        LIMIT 1
      `, [yarnLotId]);

      if (lot.rows.length === 0) {
        throw new Error(`Yarn lot ${yarnLotId} was not found.`);
      }

      const lotRow = lot.rows[0];

      const location = await client.query(`
        SELECT id, name
        FROM master.locations
        WHERE id = $1
          AND COALESCE(is_active, true) = true
        LIMIT 1
      `, [locationId]);

      if (location.rows.length === 0) {
        throw new Error('Selected yarn stock location was not found or is inactive.');
      }

      const balanceResult = await client.query(`
        SELECT COALESCE(SUM(quantity_in - quantity_out), 0)::float AS balance
        FROM inventory.yarn_ledger
        WHERE yarn_lot_id = $1
          AND location_id = $2
      `, [yarnLotId, locationId]);

      const balance = Number(balanceResult.rows[0].balance || 0);

      if (balance + 0.000001 < quantity) {
        throw new Error(
          `Insufficient stock for ${lotRow.yarn_name} / ${lotRow.lot_no}. Available: ${balance.toFixed(2)} kg.`
        );
      }

      // If this job has yarn requirements, ensure the selected yarn is one
      // of the requested yarns. Jobs without a requirement remain issuable.
      const requirement = await client.query(`
        SELECT joy.id
        FROM job_order_yarns joy
        JOIN master.yarns jy
          ON LOWER(TRIM(jy.name)) = LOWER(TRIM(joy.yarn_name))
         AND (
           joy.yarn_count IS NULL
           OR TRIM(joy.yarn_count) = ''
           OR LOWER(TRIM(jy.count)) = LOWER(TRIM(joy.yarn_count))
         )
        WHERE joy.job_order_id = $1
          AND jy.id = $2
        ORDER BY joy.id
        LIMIT 1
        FOR UPDATE OF joy
      `, [jobId, lotRow.yarn_id]);

      const anyRequirements = await client.query(`
        SELECT 1
        FROM job_order_yarns
        WHERE job_order_id = $1
        LIMIT 1
      `, [jobId]);

      if (anyRequirements.rows.length > 0 && requirement.rows.length === 0) {
        throw new Error(
          `${lotRow.yarn_name} is not one of the yarns required for job ${job.rows[0].job_no}.`
        );
      }

      const result = await client.query(`
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
          remarks
        )
        SELECT
          $1,
          fy.id,
          $2,
          $3,
          COALESCE($6::date, CURRENT_DATE),
          'ISSUE',
          0,
          $4,
          'YARN_ISSUE',
          md5('job:' || $5::text)::uuid,
          $7
        FROM core.financial_years fy
        WHERE fy.company_id = $1
          AND fy.is_current = true
          AND fy.is_closed = false
        ORDER BY fy.start_date DESC
        LIMIT 1
        RETURNING
          id,
          movement_date,
          movement_type,
          quantity_out,
          reference_id,
          remarks
      `, [
        lotRow.company_id,
        yarnLotId,
        locationId,
        quantity,
        jobId,
        remarks,
        issueDate,
      ]);

      if (result.rows.length === 0) {
        throw new Error(
          `No open financial year exists for yarn stock owner of ${lotRow.yarn_name}.`
        );
      }

      // Keep the job's yarn requirement in sync with the actual issue.
      // The ledger remains the source of truth; this field is maintained
      // for the Job Order UI and existing workflows.
      if (requirement.rows.length > 0) {
        await client.query(`
          UPDATE job_order_yarns
          SET issued_kg = COALESCE(issued_kg, 0) + $1,
              updated_at = NOW()
          WHERE id = $2
        `, [quantity, requirement.rows[0].id]);
      }

      saved.push({
        ...result.rows[0],
        job_id: jobId,
        job_no: job.rows[0].job_no,
        yarn_lot_id: yarnLotId,
        yarn_id: lotRow.yarn_id,
        yarn_name: lotRow.yarn_name,
        color_name: lotRow.color_name,
        location_id: locationId,
        location_name: location.rows[0].name,
        quantity: quantity,
      });
    }

    await client.query('COMMIT');

    return res.status(201).json({
      success: true,
      count: saved.length,
      message: `Yarn issue posted successfully. ${saved.length} line(s) saved.`,
      issues: saved,
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Yarn issue batch failed:', error);

    return res.status(500).json({
      success: false,
      error: error.message || 'Failed to post yarn issue batch.',
    });
  } finally {
    client.release();
  }
});

// ============================================================
// RECEIPT DETAIL
//
// GET /api/yarn-receipts/:id
// ============================================================

router.get('/:id', async (req, res) => {
  try {
    const receipt = await pool.query(
      `
      SELECT
        r.*,

        c.code AS company_code,
        c.name AS company_name,

        p.name AS supplier_name,

        l.name AS location_name

      FROM inventory.yarn_receipts r

      LEFT JOIN core.companies c
        ON c.id = r.company_id

      LEFT JOIN master.parties p
        ON p.id = r.party_id

      LEFT JOIN master.locations l
        ON l.id = r.location_id

      WHERE r.id = $1
      `,
      [req.params.id]
    );

    if (receipt.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Yarn receipt not found.',
      });
    }

    const lines = await pool.query(
      `
      SELECT
        rl.id,
        rl.yarn_lot_id,
        rl.quantity,
        rl.unit_rate,
        rl.notes,

        yl.lot_no,
        yl.supplier_lot_no,
        yl.color_id,
        ccol.code AS color_code,
        ccol.name AS color_name,

        y.id AS yarn_id,
        y.code AS yarn_code,
        y.name AS yarn_name,
        y.count AS yarn_count,
        y.composition,
        y.colour

      FROM inventory.yarn_receipt_lines rl

      JOIN master.yarn_lots yl
        ON yl.id = rl.yarn_lot_id

      JOIN master.yarns y
        ON y.id = yl.yarn_id

      LEFT JOIN master.colors ccol
        ON ccol.id = yl.color_id

      WHERE rl.receipt_id = $1

      ORDER BY rl.id
      `,
      [req.params.id]
    );

    return res.json({
      success: true,
      receipt: receipt.rows[0],
      lines: lines.rows,
    });
  } catch (error) {
    console.error('Yarn receipt detail error:', error);

    return res.status(500).json({
      success: false,
      error: 'Failed to load yarn receipt',
      details: error.message,
    });
  }
});

// ============================================================
// CREATE / POST RECEIPT
//
// POST /api/yarn-receipts
//
// Creates:
//
// 1. Receipt header
// 2. Supplier mapping
// 3. Yarn lot(s)
// 4. Receipt line(s)
// 5. Stock ledger movement(s)
//
// Multiple yarns can be posted under ONE receipt.
// ============================================================

router.post('/', async (req, res) => {
  const client = await pool.connect();

  try {
    const companyId = clean(req.body.company_id);
    const receiptDate = clean(req.body.receipt_date);
    const challanNo = clean(req.body.challan_no);
    const billNo = clean(req.body.bill_no);

    const supplierId = clean(req.body.party_id);
    const locationId = clean(req.body.location_id);

    const notes = clean(req.body.notes);
    const lines = req.body.lines;

    // ========================================================
    // BASIC VALIDATION
    // ========================================================

    if (!companyId || !isUuid(companyId)) {
      return res.status(400).json({
        success: false,
        error: 'Company is required.',
      });
    }

    if (!receiptDate) {
      return res.status(400).json({
        success: false,
        error: 'Receipt date is required.',
      });
    }

    if (!supplierId) {
      return res.status(400).json({
        success: false,
        error: 'Supplier is required.',
      });
    }

    if (!Array.isArray(lines) || lines.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'At least one yarn line is required.',
      });
    }

    // ========================================================
    // VALIDATE LINES
    // ========================================================

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i] || {};

      if (!clean(line.yarn_id)) {
        return res.status(400).json({
          success: false,
          error: `Yarn is required on line ${i + 1}.`,
        });
      }

      const colorId = clean(line.color_id);

      if (!colorId || !isUuid(colorId)) {
        return res.status(400).json({
          success: false,
          error: `Color is required on line ${i + 1}.`,
        });
      }

      const boxCount = line.box_count === null || line.box_count === undefined || line.box_count === ''
        ? null
        : Number(line.box_count);

      if (boxCount !== null && (!Number.isInteger(boxCount) || boxCount < 0)) {
        return res.status(400).json({
          success: false,
          error: `No. of boxes must be a whole number of zero or more on line ${i + 1}.`,
        });
      }

      const qty = Number(line.quantity);

      if (!Number.isFinite(qty) || qty <= 0) {
        return res.status(400).json({
          success: false,
          error: `Quantity must be greater than zero on line ${i + 1}.`,
        });
      }

      if (
        line.unit_rate !== null &&
        line.unit_rate !== undefined &&
        line.unit_rate !== ''
      ) {
        const rate = Number(line.unit_rate);

        if (!Number.isFinite(rate) || rate < 0) {
          return res.status(400).json({
            success: false,
            error: `Invalid rate on line ${i + 1}.`,
          });
        }
      }
    }

    await client.query('BEGIN');
    
    // ========================================================
    // COMPANY
    // ========================================================

    const company = await client.query(`
      SELECT id, code, name
      FROM core.companies
      WHERE id = $1
        AND COALESCE(is_active, true) = true
      LIMIT 1
    `, [companyId]);

    if (company.rows.length === 0) {
      throw new Error('Selected company is invalid or inactive.');
    }

    // ========================================================
    // CURRENT FINANCIAL YEAR
    // ========================================================

    const fy = await client.query(`
      SELECT id
      FROM core.financial_years
      WHERE company_id = $1
        AND is_current = true
        AND is_closed = false
      ORDER BY start_date DESC
      LIMIT 1
    `, [companyId]);

    if (fy.rows.length === 0) {
      throw new Error(
        'No open current financial year exists for the selected company.'
      );
    }

    const financialYearId = fy.rows[0].id;


    
    // ========================================================
    // SUPPLIER
    //
    // Existing Parties module:
    //   parties.id
    //   party_roles.party_id
    //   party_roles.role
    //
    // We find the selected Yarn Supplier here.
    // ========================================================

    const supplier = await client.query(
      `
      SELECT DISTINCT
        p.id,
        p.party_code,
        p.name,
        p.gstin,
        p.pan,
        p.address_line1,
        p.address_line2,
        p.city,
        p.state,
        p.pin_code,
        p.country,
        p.phone,
        p.email,
        p.notes

      FROM parties p

      JOIN party_roles pr
        ON pr.party_id = p.id

      WHERE p.id = $1
        AND COALESCE(p.is_active, true) = true
        AND LOWER(pr.role) = 'yarn supplier'

      LIMIT 1
      `,
      [supplierId]
    );

    if (supplier.rows.length === 0) {
      throw new Error(
        'Selected supplier is not an active Yarn Supplier.'
      );
    }

    const legacySupplier = supplier.rows[0];

    // ========================================================
    // MASTER PARTY BRIDGE
    //
    // Inventory uses UUID master.parties.
    //
    // Existing Parties module uses the legacy parties table.
    //
    // We create/reuse the corresponding master party.
    // ========================================================

    let masterParty = await client.query(
      `
      SELECT id

      FROM master.parties

      WHERE company_id = $1
        AND code = $2

      LIMIT 1
      `,
      [
        companyId,
        legacySupplier.party_code,
      ]
    );

    let masterPartyId;

    if (masterParty.rows.length > 0) {
      masterPartyId = masterParty.rows[0].id;
    } else {
      const insertedParty = await client.query(
        `
        INSERT INTO master.parties (
          company_id,
          code,
          name,
          legal_name,
          gstin,
          pan,
          address_line1,
          address_line2,
          city,
          state,
          pincode,
          country,
          phone,
          email,
          is_active,
          notes
        )

        VALUES (
          $1,
          $2,
          $3,
          $3,
          $4,
          $5,
          $6,
          $7,
          $8,
          $9,
          $10,
          COALESCE($11, 'India'),
          $12,
          $13,
          true,
          $14
        )

        RETURNING id
        `,
        [
          companyId,
          legacySupplier.party_code,
          legacySupplier.name,
          legacySupplier.gstin,
          legacySupplier.pan,
          legacySupplier.address_line1,
          legacySupplier.address_line2,
          legacySupplier.city,
          legacySupplier.state,
          legacySupplier.pin_code,
          legacySupplier.country,
          legacySupplier.phone,
          legacySupplier.email,
          legacySupplier.notes,
        ]
      );

      masterPartyId = insertedParty.rows[0].id;
    }

    // ========================================================
    // ENSURE YARN SUPPLIER ROLE EXISTS
    // ========================================================

    const role = await client.query(`
      SELECT id

      FROM master.party_roles

      WHERE UPPER(code) = 'YARN_SUPPLIER'
         OR LOWER(name) = 'yarn supplier'

      LIMIT 1
    `);

    let roleId;

    if (role.rows.length > 0) {
      roleId = role.rows[0].id;
    } else {
      const insertedRole = await client.query(`
        INSERT INTO master.party_roles (
          code,
          name
        )

        VALUES (
          'YARN_SUPPLIER',
          'Yarn Supplier'
        )

        ON CONFLICT (code)
        DO UPDATE SET name = EXCLUDED.name

        RETURNING id
      `);

      roleId = insertedRole.rows[0].id;
    }

    await client.query(
      `
      INSERT INTO master.party_role_assignments (
        party_id,
        role_id
      )

      VALUES ($1, $2)

      ON CONFLICT DO NOTHING
      `,
      [
        masterPartyId,
        roleId,
      ]
    );

    // ========================================================
    // LOCATION
    // ========================================================

    if (locationId) {
      const location = await client.query(
        `
        SELECT id
        FROM master.locations
        WHERE id = $1
          AND COALESCE(is_active, true) = true
        LIMIT 1
        `,
        [locationId]
      );

      if (location.rows.length === 0) {
        throw new Error(
          'Selected location does not exist or is inactive.'
        );
      }
    }

    // ========================================================
    // RECEIPT NUMBER
    // ========================================================

    const receiptNumberResult = await client.query(
      `
      SELECT
        COALESCE(
          MAX(
            CAST(
              NULLIF(
                SUBSTRING(
                  receipt_no
                  FROM '^YR-([0-9]+)$'
                ),
                ''
              )
              AS INTEGER
            )
          ),
          0
        ) + 1 AS next_no

      FROM inventory.yarn_receipts

      WHERE company_id = $1
        AND receipt_no LIKE 'YR-%'
      `,
      [companyId]
    );

    const nextReceiptNumber = Number(
      receiptNumberResult.rows[0].next_no
    );

    const receiptNo =
      `YR-${String(nextReceiptNumber).padStart(6, '0')}`;

    // ========================================================
    // RECEIPT HEADER
    // ========================================================

    const receiptResult = await client.query(
      `
      INSERT INTO inventory.yarn_receipts (
        company_id,
        financial_year_id,
        receipt_no,
        receipt_date,
        party_id,
        location_id,
        challan_no,
        bill_no,
        notes,
        status
      )

      VALUES (
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        $9,
        'POSTED'
      )

      RETURNING
        id,
        company_id,
        receipt_no,
        receipt_date,
        challan_no,
        bill_no,
        status
      `,
      [
        companyId,
        financialYearId,
        receiptNo,
        receiptDate,
        masterPartyId,
        locationId,
        challanNo,
        billNo,
        notes,
      ]
    );

    const receipt = receiptResult.rows[0];

    const createdLines = [];

    // ========================================================
    // PROCESS EACH YARN LINE
    // ========================================================

    for (const line of lines) {
      const yarnId = clean(line.yarn_id);
      const colorId = clean(line.color_id);

      const supplierLotNo =
        clean(line.supplier_lot_no);

      const quantity =
        Number(line.quantity);

      const boxCount = line.box_count === null || line.box_count === undefined || line.box_count === ''
        ? null
        : Number(line.box_count);

      const unitRate =
        line.unit_rate === null ||
        line.unit_rate === undefined ||
        line.unit_rate === ''
          ? null
          : Number(line.unit_rate);

      const lineNotes =
        clean(line.notes);

      // ======================================================
      // VALIDATE YARN MASTER
      // ======================================================

      const yarn = await client.query(
        `
        SELECT id

        FROM master.yarns

        WHERE id = $1
          AND COALESCE(is_active, true) = true

        LIMIT 1
        `,
        [yarnId]
      );

      if (yarn.rows.length === 0) {
        throw new Error(
          `Yarn ${yarnId} does not exist or is inactive.`
        );
      }

      let yarnLotId;

      // ======================================================
      // REUSE EXISTING SUPPLIER LOT
      // ======================================================

      if (supplierLotNo) {
        const existingLot = await client.query(
          `
          SELECT id

          FROM master.yarn_lots

          WHERE company_id = $1
            AND yarn_id = $2
            AND supplier_party_id = $3
            AND supplier_lot_no = $4
            AND color_id = $5

          LIMIT 1
          `,
          [
            companyId,
            yarnId,
            masterPartyId,
            supplierLotNo,
            colorId,
          ]
        );

        if (existingLot.rows.length > 0) {
          yarnLotId =
            existingLot.rows[0].id;
        }
      }

      // ======================================================
      // CREATE NEW INTERNAL LOT
      // ======================================================

      if (!yarnLotId) {
        const lotNumberResult = await client.query(
          `
          SELECT
            COALESCE(
              MAX(
                CAST(
                  NULLIF(
                    SUBSTRING(
                      lot_no
                      FROM '^YL-([0-9]+)$'
                    ),
                    ''
                  )
                  AS INTEGER
                )
              ),
              0
            ) + 1 AS next_no

          FROM master.yarn_lots

          WHERE company_id = $1
            AND lot_no LIKE 'YL-%'
          `,
          [companyId]
        );

        const nextLotNumber =
          Number(
            lotNumberResult.rows[0].next_no
          );

        const lotNo =
          `YL-${String(nextLotNumber).padStart(6, '0')}`;

        const lotResult = await client.query(
          `
          INSERT INTO master.yarn_lots (
            company_id,
            yarn_id,
            lot_no,
            supplier_party_id,
            supplier_lot_no,
            color_id,
            received_date,
            notes
          )

          VALUES (
            $1,
            $2,
            $3,
            $4,
            $5,
            $6,
            $7,
            $8
          )

          RETURNING
            id,
            lot_no
          `,
          [
            companyId,
            yarnId,
            lotNo,
            masterPartyId,
            supplierLotNo,
            colorId,
            receiptDate,
            lineNotes,
          ]
        );

        yarnLotId =
          lotResult.rows[0].id;
      }

      // ======================================================
      // RECEIPT LINE
      // ======================================================

      await client.query(
        `
        INSERT INTO inventory.yarn_receipt_lines (
          receipt_id,
          yarn_lot_id,
          quantity,
          box_count,
          unit_rate,
          notes
        )

        VALUES (
          $1,
          $2,
          $3,
          $4,
          $5,
          $6
        )
        `,
        [
          receipt.id,
          yarnLotId,
          quantity,
          boxCount,
          unitRate,
          lineNotes,
        ]
      );

      // ======================================================
      // STOCK LEDGER
      // ======================================================

      await client.query(
        `
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
          remarks
        )

        VALUES (
          $1,
          $2,
          $3,
          $4,
          $5,
          'RECEIPT',
          $6,
          0,
          'YARN_RECEIPT',
          $7,
          $8
        )
        `,
        [
          companyId,
          financialYearId,
          yarnLotId,
          locationId,
          receiptDate,
          quantity,
          receipt.id,
          lineNotes,
        ]
      );

      createdLines.push({
        yarn_id: yarnId,
        yarn_lot_id: yarnLotId,
        quantity: quantity,
        box_count: boxCount,
        unit_rate: unitRate,
        supplier_lot_no: supplierLotNo,
      });
    }

    // ========================================================
    // COMMIT
    // ========================================================

    await client.query('COMMIT');

    return res.status(201).json({
      success: true,
      message: 'Yarn receipt posted successfully.',
      receipt: receipt,
      lines: createdLines,
    });

  } catch (error) {
    try {
      await client.query('ROLLBACK');
    } catch (_) {
      // Ignore rollback errors
    }

    console.error(
      'Create yarn receipt failed:',
      error
    );

    return res.status(500).json({
      success: false,
      error:
        error.message ||
        'Failed to post yarn receipt.',
    });

  } finally {
    client.release();
  }
});

// ============================================================
// EXPORT
// ============================================================

module.exports = router;