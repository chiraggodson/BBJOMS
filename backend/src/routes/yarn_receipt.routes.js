const express = require('express');
const router = express.Router();
const { pool } = require('../db');

const COMPANY_ID = '63558a5c-3815-4d4f-9f0d-7edfdf5d3f11';

function clean(value) {
  if (value === undefined || value === null) return null;
  const v = String(value).trim();
  return v === '' ? null : v;
}

/* ============================================================
   SUPPLIERS
   ============================================================ */

router.get('/suppliers', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT DISTINCT
        p.id,
        p.code,
        p.name
      FROM master.parties p
      JOIN master.party_role_assignments pra
        ON pra.party_id = p.id
      JOIN master.party_roles pr
        ON pr.id = pra.role_id
      WHERE p.company_id = $1
        AND COALESCE(p.is_active, true) = true
        AND (
          UPPER(pr.code) = 'YARN_SUPPLIER'
          OR LOWER(pr.name) = 'yarn supplier'
        )
      ORDER BY p.name
    `, [COMPANY_ID]);

    res.json(result.rows);
  } catch (error) {
    console.error('Yarn suppliers error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/* ============================================================
   LOCATIONS
   ============================================================ */

router.get('/locations', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        id,
        code,
        name,
        location_type
      FROM master.locations
      WHERE company_id = $1
        AND COALESCE(is_active, true) = true
      ORDER BY name
    `, [COMPANY_ID]);

    res.json(result.rows);
  } catch (error) {
    console.error('Yarn locations error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/* ============================================================
   RECEIPT LIST
   ============================================================ */

router.get('/', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        r.id,
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
      LEFT JOIN master.parties p
        ON p.id = r.party_id
      LEFT JOIN master.locations l
        ON l.id = r.location_id
      LEFT JOIN inventory.yarn_receipt_lines rl
        ON rl.receipt_id = r.id
      WHERE r.company_id = $1
      GROUP BY
        r.id,
        r.receipt_no,
        r.receipt_date,
        r.challan_no,
        r.bill_no,
        r.party_id,
        p.name,
        r.location_id,
        l.name,
        r.status
      ORDER BY r.receipt_date DESC, r.created_at DESC
      LIMIT 100
    `, [COMPANY_ID]);

    res.json(result.rows);
  } catch (error) {
    console.error('Yarn receipt list error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/* ============================================================
   RECEIPT DETAIL
   ============================================================ */

router.get('/:id', async (req, res) => {
  try {
    const receipt = await pool.query(`
      SELECT
        r.*,
        p.name AS supplier_name,
        l.name AS location_name
      FROM inventory.yarn_receipts r
      LEFT JOIN master.parties p
        ON p.id = r.party_id
      LEFT JOIN master.locations l
        ON l.id = r.location_id
      WHERE r.id = $1
        AND r.company_id = $2
    `, [req.params.id, COMPANY_ID]);

    if (receipt.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Yarn receipt not found.',
      });
    }

    const lines = await pool.query(`
      SELECT
        rl.id,
        rl.yarn_lot_id,
        rl.quantity,
        rl.unit_rate,
        rl.notes,
        yl.lot_no,
        yl.supplier_lot_no,
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
      WHERE rl.receipt_id = $1
      ORDER BY rl.id
    `, [req.params.id]);

    res.json({
      success: true,
      receipt: receipt.rows[0],
      lines: lines.rows,
    });
  } catch (error) {
    console.error('Yarn receipt detail error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/* ============================================================
   CREATE RECEIPT
   ============================================================ */

router.post('/', async (req, res) => {
  const client = await pool.connect();

  try {
    const {
      receipt_date,
      challan_no,
      bill_no,
      party_id,
      location_id,
      notes,
      lines,
    } = req.body;

    const receiptDate = clean(receipt_date);
    const challanNo = clean(challan_no);
    const billNo = clean(bill_no);
    const partyId = clean(party_id);
    const locationId = clean(location_id);
    const receiptNotes = clean(notes);

    if (!receiptDate) {
      return res.status(400).json({
        success: false,
        error: 'Receipt date is required.',
      });
    }

    if (!partyId) {
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

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];

      if (!clean(line.yarn_id)) {
        return res.status(400).json({
          success: false,
          error: `Yarn is required on line ${i + 1}.`,
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

    /* --------------------------------------------------------
       FINANCIAL YEAR
       -------------------------------------------------------- */

    let financialYearId = clean(req.body.financial_year_id);

    if (!financialYearId) {
      financialYearId = clean(process.env.FINANCIAL_YEAR_ID);
    }

    if (!financialYearId) {
      financialYearId = clean(
        process.env.BBJOMS_FINANCIAL_YEAR_ID
      );
    }

    if (!financialYearId) {
      throw new Error(
        'Financial year is not configured. Set FINANCIAL_YEAR_ID in the backend environment.'
      );
    }

    /* --------------------------------------------------------
       VALIDATE SUPPLIER
       -------------------------------------------------------- */

    const supplierCheck = await client.query(`
      SELECT p.id
      FROM master.parties p
      JOIN master.party_role_assignments pra
        ON pra.party_id = p.id
      JOIN master.party_roles pr
        ON pr.id = pra.role_id
      WHERE p.id = $1
        AND p.company_id = $2
        AND COALESCE(p.is_active, true) = true
        AND (
          UPPER(pr.code) = 'YARN_SUPPLIER'
          OR LOWER(pr.name) = 'yarn supplier'
        )
      LIMIT 1
    `, [partyId, COMPANY_ID]);

    if (supplierCheck.rows.length === 0) {
      throw new Error(
        'Selected supplier is not an active Yarn Supplier.'
      );
    }

    /* --------------------------------------------------------
       VALIDATE LOCATION
       -------------------------------------------------------- */

    if (locationId) {
      const locationCheck = await client.query(`
        SELECT id
        FROM master.locations
        WHERE id = $1
          AND company_id = $2
          AND COALESCE(is_active, true) = true
      `, [locationId, COMPANY_ID]);

      if (locationCheck.rows.length === 0) {
        throw new Error('Selected location is invalid.');
      }
    }

    /* --------------------------------------------------------
       RECEIPT NUMBER
       -------------------------------------------------------- */

    const receiptNumberResult = await client.query(`
      SELECT COALESCE(
        MAX(
          CAST(
            SUBSTRING(receipt_no FROM 'YR-([0-9]+)')
            AS INTEGER
          )
        ),
        0
      ) + 1 AS next_no
      FROM inventory.yarn_receipts
      WHERE company_id = $1
        AND receipt_no LIKE 'YR-%'
    `, [COMPANY_ID]);

    const nextReceiptNo =
      Number(receiptNumberResult.rows[0].next_no);

    const receiptNo =
      `YR-${String(nextReceiptNo).padStart(6, '0')}`;

    /* --------------------------------------------------------
       CREATE RECEIPT HEADER
       -------------------------------------------------------- */

    const receiptResult = await client.query(`
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
        $1, $2, $3, $4, $5,
        $6, $7, $8, $9, 'POSTED'
      )
      RETURNING
        id,
        receipt_no,
        receipt_date,
        challan_no,
        bill_no,
        status
    `, [
      COMPANY_ID,
      financialYearId,
      receiptNo,
      receiptDate,
      partyId,
      locationId,
      challanNo,
      billNo,
      receiptNotes,
    ]);

    const receipt = receiptResult.rows[0];

    const createdLines = [];

    /* --------------------------------------------------------
       CREATE LINES + LOTS + LEDGER
       -------------------------------------------------------- */

    for (const line of lines) {
      const yarnId = clean(line.yarn_id);
      const supplierLotNo = clean(line.supplier_lot_no);
      const quantity = Number(line.quantity);
      const unitRate =
        line.unit_rate === null ||
        line.unit_rate === undefined ||
        line.unit_rate === ''
          ? null
          : Number(line.unit_rate);

      const lineNotes = clean(line.notes);

      /* Validate generic Yarn Master */

      const yarnCheck = await client.query(`
        SELECT id
        FROM master.yarns
        WHERE id = $1
          AND COALESCE(is_active, true) = true
        LIMIT 1
      `, [yarnId]);

      if (yarnCheck.rows.length === 0) {
        throw new Error(
          `Yarn ${yarnId} does not exist or is inactive.`
        );
      }

      let yarnLotId;

      /* ------------------------------------------------------
         Reuse supplier lot when possible
         ------------------------------------------------------ */

      if (supplierLotNo) {
        const existingLot = await client.query(`
          SELECT id
          FROM master.yarn_lots
          WHERE company_id = $1
            AND yarn_id = $2
            AND supplier_party_id = $3
            AND supplier_lot_no = $4
          LIMIT 1
        `, [
          COMPANY_ID,
          yarnId,
          partyId,
          supplierLotNo,
        ]);

        if (existingLot.rows.length > 0) {
          yarnLotId = existingLot.rows[0].id;
        }
      }

      /* ------------------------------------------------------
         Create internal lot if required
         ------------------------------------------------------ */

      if (!yarnLotId) {
        const lotNumberResult = await client.query(`
          SELECT COALESCE(
            MAX(
              CAST(
                SUBSTRING(lot_no FROM 'YL-([0-9]+)')
                AS INTEGER
              )
            ),
            0
          ) + 1 AS next_no
          FROM master.yarn_lots
          WHERE company_id = $1
            AND lot_no LIKE 'YL-%'
        `, [COMPANY_ID]);

        const nextLotNo =
          Number(lotNumberResult.rows[0].next_no);

        const lotNo =
          `YL-${String(nextLotNo).padStart(6, '0')}`;

        const lotResult = await client.query(`
          INSERT INTO master.yarn_lots (
            company_id,
            yarn_id,
            lot_no,
            supplier_party_id,
            supplier_lot_no,
            received_date,
            notes
          )
          VALUES (
            $1, $2, $3, $4, $5, $6, $7
          )
          RETURNING id, lot_no
        `, [
          COMPANY_ID,
          yarnId,
          lotNo,
          partyId,
          supplierLotNo,
          receiptDate,
          lineNotes,
        ]);

        yarnLotId = lotResult.rows[0].id;
      }

      /* ------------------------------------------------------
         Receipt Line
         ------------------------------------------------------ */

      await client.query(`
        INSERT INTO inventory.yarn_receipt_lines (
          receipt_id,
          yarn_lot_id,
          quantity,
          unit_rate,
          notes
        )
        VALUES ($1, $2, $3, $4, $5)
      `, [
        receipt.id,
        yarnLotId,
        quantity,
        unitRate,
        lineNotes,
      ]);

      /* ------------------------------------------------------
         Stock Ledger
         ------------------------------------------------------ */

      await client.query(`
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
          $1, $2, $3, $4, $5,
          'RECEIPT',
          $6, 0,
          'YARN_RECEIPT',
          $7,
          $8
        )
      `, [
        COMPANY_ID,
        financialYearId,
        yarnLotId,
        locationId,
        new Date(),
        quantity,
        receipt.id,
        lineNotes,
      ]);

      createdLines.push({
        yarn_id: yarnId,
        yarn_lot_id: yarnLotId,
        quantity,
        unit_rate: unitRate,
        supplier_lot_no: supplierLotNo,
      });
    }

    await client.query('COMMIT');

    return res.status(201).json({
      success: true,
      message: 'Yarn receipt posted successfully.',
      receipt: {
        id: receipt.id,
        receipt_no: receipt.receipt_no,
        receipt_date: receipt.receipt_date,
        challan_no: receipt.challan_no,
        bill_no: receipt.bill_no,
        status: receipt.status,
      },
      lines: createdLines,
    });

  } catch (error) {
    await client.query('ROLLBACK');

    console.error('Yarn receipt creation error:', error);

    return res.status(500).json({
      success: false,
      error: error.message,
    });
  } finally {
    client.release();
  }
});

module.exports = router;