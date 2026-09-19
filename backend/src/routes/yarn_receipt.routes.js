
const express = require('express');
const router = express.Router();
const { pool } = require('../db');

const COMPANY_ID = '63558a5c-3815-4d4f-9f0d-7edfdf5d3f11';

function clean(value) {
  return value == null ? '' : String(value).trim();
}

function isUuid(value) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(String(value || ''));
}

function number(value, fallback = 0) {
  if (value === null || value === undefined || value === '') return fallback;
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}

async function currentFinancialYear(client, companyId) {
  const result = await client.query(`
    SELECT id
    FROM core.financial_years
    WHERE company_id=$1
      AND is_current=true
      AND is_closed=false
    ORDER BY start_date DESC
    LIMIT 1
  `, [companyId]);

  if (!result.rows.length) {
    throw new Error('No open financial year exists for this company.');
  }

  return result.rows[0].id;
}

async function nextReceiptNo(client, companyId, financialYearId) {
  await client.query(
    `SELECT pg_advisory_xact_lock(hashtext($1))`,
    [`YARN_RECEIPT:${companyId}:${financialYearId}`]
  );

  const result = await client.query(`
    SELECT COALESCE(MAX(
      CASE
        WHEN receipt_no ~ '^YR-[0-9]+$'
        THEN CAST(SUBSTRING(receipt_no FROM '[0-9]+$') AS BIGINT)
        ELSE 0
      END
    ),0)+1 AS next_no
    FROM inventory.yarn_receipts
    WHERE company_id=$1 AND financial_year_id=$2
  `, [companyId,financialYearId]);

  return `YR-${String(Number(result.rows[0].next_no)).padStart(6,'0')}`;
}

async function nextIssueNo(client, companyId, financialYearId) {
  await client.query(
    `SELECT pg_advisory_xact_lock(hashtext($1))`,
    [`YARN_ISSUE:${companyId}:${financialYearId}`]
  );

  const result = await client.query(`
    SELECT COALESCE(MAX(
      CASE
        WHEN issue_no ~ '^YI-[0-9]+$'
        THEN CAST(SUBSTRING(issue_no FROM '[0-9]+$') AS BIGINT)
        ELSE 0
      END
    ),0)+1 AS next_no
    FROM jobwork.yarn_issues
    WHERE company_id=$1 AND financial_year_id=$2
  `, [companyId,financialYearId]);

  return `YI-${String(Number(result.rows[0].next_no)).padStart(6,'0')}`;
}

// ------------------------------------------------------------
// Companies
// ------------------------------------------------------------

router.get('/companies', async (req,res) => {
  try {
    const result = await pool.query(`
      SELECT id,code,name
      FROM core.companies
      WHERE COALESCE(is_active,true)=true
      ORDER BY name ASC
    `);
    res.json(result.rows);
  } catch (error) {
    console.error('Yarn receipt companies error:',error);
    res.status(500).json({success:false,error:'Failed to load companies',details:error.message});
  }
});

// ------------------------------------------------------------
// Suppliers
// ------------------------------------------------------------

router.get('/suppliers', async (req,res) => {
  try {
    const result = await pool.query(`
      SELECT DISTINCT
        p.id,
        p.code,
        p.code AS party_code,
        p.name,
        p.phone,
        p.email
      FROM master.parties p
      JOIN master.party_role_assignments pra ON pra.party_id=p.id
      JOIN master.party_roles pr ON pr.id=pra.role_id
      WHERE p.company_id=$1
        AND COALESCE(p.is_active,true)=true
        AND LOWER(pr.name)='yarn supplier'
      ORDER BY p.name ASC
    `,[COMPANY_ID]);

    res.json(result.rows);
  } catch (error) {
    console.error('Yarn suppliers error:',error);
    res.status(500).json({success:false,error:'Failed to load yarn suppliers',details:error.message});
  }
});

// ------------------------------------------------------------
// Colors
// ------------------------------------------------------------

router.get('/colors', async (req,res) => {
  try {
    const result = await pool.query(`
      SELECT id,code,name,description
      FROM master.colors
      WHERE COALESCE(is_active,true)=true
      ORDER BY name ASC
    `);
    res.json(result.rows);
  } catch (error) {
    console.error('Yarn colors error:',error);
    res.status(500).json({success:false,error:'Failed to load colors',details:error.message});
  }
});

// ------------------------------------------------------------
// Locations
// ------------------------------------------------------------

router.get('/locations', async (req,res) => {
  try {
    const result = await pool.query(`
      SELECT id,code,name,floor_id,location_type
      FROM master.locations
      WHERE company_id=$1
        AND COALESCE(is_active,true)=true
      ORDER BY name ASC,code ASC
    `,[COMPANY_ID]);

    res.json(result.rows);
  } catch (error) {
    console.error('Yarn locations error:',error);
    res.status(500).json({success:false,error:'Failed to load locations',details:error.message});
  }
});

// ------------------------------------------------------------
// Receipt list
// ------------------------------------------------------------

router.get('/', async (req,res) => {
  try {
    const companyId = clean(req.query.company_id) || COMPANY_ID;

    if (!isUuid(companyId)) {
      return res.status(400).json({success:false,error:'Invalid company ID.'});
    }

    const result = await pool.query(`
      SELECT
        r.id,
        r.company_id,
        c.code AS company_code,
        c.name AS company_name,
        r.financial_year_id,
        r.receipt_no,
        r.receipt_date,
        r.reference_no,
        r.challan_no,
        r.bill_no,
        r.party_id,
        COALESCE(p.name,'') AS supplier_name,
        r.location_id,
        COALESCE(l.name,'') AS location_name,
        r.status,
        r.notes,
        COALESCE(SUM(rl.quantity),0)::float AS total_quantity,
        COUNT(rl.id)::integer AS line_count
      FROM inventory.yarn_receipts r
      LEFT JOIN core.companies c ON c.id=r.company_id
      LEFT JOIN master.parties p ON p.id=r.party_id
      LEFT JOIN master.locations l ON l.id=r.location_id
      LEFT JOIN inventory.yarn_receipt_lines rl ON rl.receipt_id=r.id
      WHERE r.company_id=$1
      GROUP BY
        r.id,c.code,c.name,r.financial_year_id,r.receipt_no,
        r.receipt_date,r.reference_no,r.challan_no,r.bill_no,
        r.party_id,p.name,r.location_id,l.name,r.status,r.notes,r.created_at
      ORDER BY r.receipt_date DESC,r.created_at DESC
      LIMIT 100
    `,[companyId]);

    res.json(result.rows);
  } catch (error) {
    console.error('Yarn receipt list error:',error);
    res.status(500).json({success:false,error:'Failed to load yarn receipts',details:error.message});
  }
});

// ------------------------------------------------------------
// Stock
// ------------------------------------------------------------

router.get('/stock', async (req,res) => {
  try {
    const result = await pool.query(`
      SELECT
        yl.id AS yarn_lot_id,
        yl.lot_no,
        yl.supplier_lot_no,
        yl.received_date,
        yl.company_id,
        yl.yarn_id,
        y.code AS yarn_code,
        y.name AS yarn_name,
        '' AS yarn_count,
        '' AS composition,
        yl.color_id,
        COALESCE(c.name,'') AS color_name,
        yl.supplier_party_id,
        COALESCE(sp.name,'') AS supplier_name,
        led.location_id,
        COALESCE(loc.name,'') AS location_name,
        COALESCE(SUM(led.quantity_in-led.quantity_out),0)::float AS balance,
        COALESCE(SUM(led.quantity_in),0)::float AS quantity_in,
        COALESCE(SUM(led.quantity_out),0)::float AS quantity_out
      FROM master.yarn_lots yl
      JOIN master.yarns y ON y.id=yl.yarn_id
      LEFT JOIN master.colors c ON c.id=yl.color_id
      LEFT JOIN master.parties sp ON sp.id=yl.supplier_party_id
      JOIN inventory.yarn_ledger led ON led.yarn_lot_id=yl.id
      LEFT JOIN master.locations loc ON loc.id=led.location_id
      WHERE yl.company_id=$1
        AND led.location_id IS NOT NULL
      GROUP BY
        yl.id,yl.lot_no,yl.supplier_lot_no,yl.received_date,
        yl.company_id,yl.yarn_id,y.code,y.name,yl.color_id,c.name,
        yl.supplier_party_id,sp.name,led.location_id,loc.name
      HAVING COALESCE(SUM(led.quantity_in-led.quantity_out),0)>0
      ORDER BY y.name ASC,c.name ASC,yl.lot_no ASC,loc.name ASC
    `,[COMPANY_ID]);

    res.json({success:true,stock:result.rows});
  } catch (error) {
    console.error('Yarn issue stock error:',error);
    res.status(500).json({success:false,error:'Failed to load yarn stock for issue.',details:error.message});
  }
});

// ------------------------------------------------------------
// Movements
// ------------------------------------------------------------

router.get('/movements', async (req,res) => {
  try {
    const requestedLimit = Number(req.query.limit);
    const limit = Number.isInteger(requestedLimit)
      ? Math.min(Math.max(requestedLimit,1),200)
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
        l.location_id,
        COALESCE(loc.name,'') AS location_name,
        yl.id AS yarn_lot_id,
        yl.lot_no,
        yl.supplier_lot_no,
        y.id AS yarn_id,
        y.code AS yarn_code,
        y.name AS yarn_name,
        '' AS yarn_count,
        '' AS composition,
        yl.color_id,
        COALESCE(c.name,'') AS color_name,
        COALESCE(jo.job_no,'') AS job_no
      FROM inventory.yarn_ledger l
      JOIN master.yarn_lots yl ON yl.id=l.yarn_lot_id
      JOIN master.yarns y ON y.id=yl.yarn_id
      LEFT JOIN master.colors c ON c.id=yl.color_id
      LEFT JOIN master.locations loc ON loc.id=l.location_id
      LEFT JOIN jobwork.yarn_issues yi
        ON yi.id=l.reference_id
       AND l.reference_type='YARN_ISSUE'
      LEFT JOIN jobwork.job_orders jo
        ON jo.id=yi.job_order_id
      WHERE l.company_id=$1
      ORDER BY l.created_at DESC NULLS LAST,l.movement_date DESC,l.id DESC
      LIMIT $2
    `,[COMPANY_ID,limit]);

    res.json({success:true,movements:result.rows});
  } catch (error) {
    console.error('Yarn movements error:',error);
    res.status(500).json({success:false,error:'Failed to load yarn movements.',details:error.message});
  }
});

// ------------------------------------------------------------
// Issue batch
// ------------------------------------------------------------

router.post('/issue-batch', async (req,res) => {
  const entries = Array.isArray(req.body?.entries) ? req.body.entries : [];
  const issueDate = clean(req.body?.issue_date ?? req.body?.issueDate) ||
    new Date().toISOString().slice(0,10);

  if (!entries.length) {
    return res.status(400).json({
      success:false,
      error:'At least one yarn issue line is required.'
    });
  }

  if (!/^\d{4}-\d{2}-\d{2}$/.test(issueDate)) {
    return res.status(400).json({
      success:false,
      error:'Issue date must be in YYYY-MM-DD format.'
    });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const grouped = new Map();

    for (const raw of entries) {
      const jobId = clean(raw?.job_id ?? raw?.jobId);
      const yarnLotId = clean(raw?.yarn_lot_id ?? raw?.yarnLotId);
      const locationId = clean(raw?.location_id ?? raw?.locationId);
      const machineId = clean(raw?.machine_id ?? raw?.machineId);
      const quantity = number(raw?.quantity ?? raw?.quantity_kg);
      const remarks = clean(raw?.remarks) || null;

      if (!isUuid(jobId)) throw new Error('Invalid job ID in yarn issue batch.');
      if (!isUuid(yarnLotId)) throw new Error('Invalid yarn lot ID in yarn issue batch.');
      if (!isUuid(locationId)) throw new Error('A valid stock location is required for every issue line.');
      if (machineId && !isUuid(machineId)) throw new Error('Invalid machine ID in yarn issue batch.');
      if (quantity <= 0) throw new Error('Yarn issue quantity must be greater than zero.');

      if (!grouped.has(jobId)) grouped.set(jobId, []);
      grouped.get(jobId).push({
        yarnLotId, locationId, machineId: machineId || null, quantity, remarks
      });
    }

    const saved = [];

    for (const [jobId, lines] of grouped.entries()) {
      const job = await client.query(`
        SELECT id,job_no,company_id
        FROM jobwork.job_orders
        WHERE id=$1 AND company_id=$2
        FOR SHARE
      `,[jobId,COMPANY_ID]);

      if (!job.rows.length) {
        throw new Error(`Job order ${jobId} was not found.`);
      }

      const financialYearId = await currentFinancialYear(client,COMPANY_ID);
      const issueNo = await nextIssueNo(client,COMPANY_ID,financialYearId);

      const issue = await client.query(`
        INSERT INTO jobwork.yarn_issues(
          company_id,financial_year_id,issue_no,issue_date,
          job_order_id,status,notes
        )
        VALUES($1,$2,$3,$4,$5,'DRAFT',$6)
        RETURNING id,issue_no,issue_date,job_order_id
      `,[
        COMPANY_ID,
        financialYearId,
        issueNo,
        issueDate,
        jobId,
        lines.map((x)=>x.remarks).filter(Boolean).join('; ') || null
      ]);

      for (const line of lines) {
        const lot = await client.query(`
          SELECT
            yl.id,yl.company_id,yl.yarn_id,yl.lot_no,
            COALESCE(y.name,'') AS yarn_name,
            COALESCE(c.name,'') AS color_name
          FROM master.yarn_lots yl
          JOIN master.yarns y ON y.id=yl.yarn_id
          LEFT JOIN master.colors c ON c.id=yl.color_id
          WHERE yl.id=$1
            AND yl.company_id=$2
            AND COALESCE(yl.is_active,true)=true
          FOR SHARE
        `,[line.yarnLotId,COMPANY_ID]);

        if (!lot.rows.length) {
          throw new Error(`Yarn lot ${line.yarnLotId} was not found.`);
        }

        const location = await client.query(`
          SELECT id,name
          FROM master.locations
          WHERE id=$1
            AND company_id=$2
            AND COALESCE(is_active,true)=true
        `,[line.locationId,COMPANY_ID]);

        if (!location.rows.length) {
          throw new Error(`Stock location ${line.locationId} was not found or is inactive.`);
        }

        if (line.machineId) {
          const machine = await client.query(`
            SELECT id
            FROM master.machines
            WHERE id=$1 AND company_id=$2 AND COALESCE(is_active,true)=true
          `,[line.machineId,COMPANY_ID]);

          if (!machine.rows.length) {
            throw new Error(`Machine ${line.machineId} was not found or is inactive.`);
          }
        }

        await client.query(`
          INSERT INTO jobwork.yarn_issue_lines(
            issue_id,yarn_lot_id,location_id,yarn_id,machine_id,quantity_kg,remarks
          )
          VALUES($1,$2,$3,$4,$5,$6,$7)
        `,[
          issue.rows[0].id,
          line.yarnLotId,
          line.locationId,
          lot.rows[0].yarn_id,
          line.machineId,
          line.quantity,
          line.remarks
        ]);

        saved.push({
          issue_id:issue.rows[0].id,
          issue_no:issue.rows[0].issue_no,
          job_id:jobId,
          job_no:job.rows[0].job_no,
          yarn_lot_id:line.yarnLotId,
          yarn_id:lot.rows[0].yarn_id,
          yarn_name:lot.rows[0].yarn_name,
          color_name:lot.rows[0].color_name,
          location_id:line.locationId,
          location_name:location.rows[0].name,
          quantity:line.quantity
        });
      }

      await client.query(`SELECT jobwork.post_yarn_issue($1)`,[issue.rows[0].id]);
    }

    await client.query('COMMIT');

    res.status(201).json({
      success:true,
      count:saved.length,
      message:`Yarn issue posted successfully. ${saved.length} line(s) saved.`,
      issues:saved
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Yarn issue batch failed:',error);

    res.status(500).json({
      success:false,
      error:error.message || 'Failed to post yarn issue batch.'
    });
  } finally {
    client.release();
  }
});

// ------------------------------------------------------------
// Receipt detail
// ------------------------------------------------------------

router.get('/:id', async (req,res) => {
  try {
    const receipt = await pool.query(`
      SELECT
        r.*,
        c.code AS company_code,
        c.name AS company_name,
        p.name AS supplier_name,
        l.name AS location_name
      FROM inventory.yarn_receipts r
      LEFT JOIN core.companies c ON c.id=r.company_id
      LEFT JOIN master.parties p ON p.id=r.party_id
      LEFT JOIN master.locations l ON l.id=r.location_id
      WHERE r.id=$1
    `,[req.params.id]);

    if (!receipt.rows.length) {
      return res.status(404).json({success:false,error:'Yarn receipt not found.'});
    }

    const lines = await pool.query(`
      SELECT
        rl.id,
        rl.yarn_lot_id,
        rl.quantity,
        rl.unit_rate,
        rl.box_count,
        rl.notes,
        yl.lot_no,
        yl.supplier_lot_no,
        yl.color_id,
        c.code AS color_code,
        c.name AS color_name,
        y.id AS yarn_id,
        y.code AS yarn_code,
        y.name AS yarn_name,
        '' AS yarn_count,
        '' AS composition
      FROM inventory.yarn_receipt_lines rl
      JOIN master.yarn_lots yl ON yl.id=rl.yarn_lot_id
      JOIN master.yarns y ON y.id=yl.yarn_id
      LEFT JOIN master.colors c ON c.id=yl.color_id
      WHERE rl.receipt_id=$1
      ORDER BY rl.id
    `,[req.params.id]);

    res.json({
      success:true,
      receipt:receipt.rows[0],
      lines:lines.rows
    });
  } catch (error) {
    console.error('Yarn receipt detail error:',error);
    res.status(500).json({success:false,error:'Failed to load yarn receipt',details:error.message});
  }
});

// ------------------------------------------------------------
// Create receipt
// ------------------------------------------------------------

router.post('/', async (req,res) => {
  const client = await pool.connect();

  try {
    const companyId = clean(req.body?.company_id) || COMPANY_ID;
    const receiptDate = clean(req.body?.receipt_date) || new Date().toISOString().slice(0,10);
    const challanNo = clean(req.body?.challan_no) || null;
    const billNo = clean(req.body?.bill_no) || null;
    const referenceNo = clean(req.body?.reference_no) || null;
    const supplierId = clean(req.body?.party_id);
    const locationId = clean(req.body?.location_id);
    const notes = clean(req.body?.notes) || null;
    const lines = Array.isArray(req.body?.lines) ? req.body.lines : [];

    if (!isUuid(companyId)) return res.status(400).json({success:false,error:'Company is required.'});
    if (!/^\d{4}-\d{2}-\d{2}$/.test(receiptDate)) return res.status(400).json({success:false,error:'Receipt date must be YYYY-MM-DD.'});
    if (!isUuid(supplierId)) return res.status(400).json({success:false,error:'A valid supplier is required.'});
    if (!isUuid(locationId)) return res.status(400).json({success:false,error:'A valid yarn storage location is required.'});
    if (!lines.length) return res.status(400).json({success:false,error:'At least one yarn line is required.'});

    await client.query('BEGIN');

    const company = await client.query(`
      SELECT id FROM core.companies
      WHERE id=$1 AND COALESCE(is_active,true)=true
    `,[companyId]);

    if (!company.rows.length) throw new Error('Company not found or inactive.');

    const supplier = await client.query(`
      SELECT p.id
      FROM master.parties p
      JOIN master.party_role_assignments pra ON pra.party_id=p.id
      JOIN master.party_roles pr ON pr.id=pra.role_id
      WHERE p.id=$1
        AND p.company_id=$2
        AND COALESCE(p.is_active,true)=true
        AND LOWER(pr.name)='yarn supplier'
      LIMIT 1
    `,[supplierId,companyId]);

    if (!supplier.rows.length) {
      throw new Error('Selected supplier is not an active Yarn Supplier.');
    }

    const location = await client.query(`
      SELECT id FROM master.locations
      WHERE id=$1 AND company_id=$2 AND COALESCE(is_active,true)=true
    `,[locationId,companyId]);

    if (!location.rows.length) throw new Error('Selected location was not found or is inactive.');

    const financialYearId = await currentFinancialYear(client,companyId);
    const receiptNo = await nextReceiptNo(client,companyId,financialYearId);

    const receipt = await client.query(`
      INSERT INTO inventory.yarn_receipts(
        company_id,financial_year_id,receipt_no,receipt_date,
        party_id,location_id,reference_no,challan_no,bill_no,
        status,notes
      )
      VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,'POSTED',$10)
      RETURNING id,receipt_no,receipt_date,status
    `,[
      companyId,financialYearId,receiptNo,receiptDate,
      supplierId,locationId,referenceNo,challanNo,billNo,notes
    ]);

    const createdLines = [];

    for (let i=0;i<lines.length;i++) {
      const line = lines[i] || {};
      const yarnId = clean(line.yarn_id);
      const colorId = clean(line.color_id);
      const quantity = number(line.quantity);
      const boxCount = line.box_count == null || line.box_count === ''
        ? null : Number(line.box_count);
      const unitRate = line.unit_rate == null || line.unit_rate === ''
        ? null : Number(line.unit_rate);
      const supplierLotNo = clean(line.supplier_lot_no) || null;
      const lotNo = clean(line.lot_no) || `${receiptNo}-${String(i+1).padStart(2,'0')}`;
      const lineNotes = clean(line.notes) || null;

      if (!isUuid(yarnId)) throw new Error(`Valid yarn is required on line ${i+1}.`);
      if (!isUuid(colorId)) throw new Error(`Valid color is required on line ${i+1}.`);
      if (quantity <= 0) throw new Error(`Quantity must be greater than zero on line ${i+1}.`);
      if (boxCount != null && (!Number.isInteger(boxCount) || boxCount < 0)) throw new Error(`Invalid box count on line ${i+1}.`);
      if (unitRate != null && (!Number.isFinite(unitRate) || unitRate < 0)) throw new Error(`Invalid unit rate on line ${i+1}.`);

      const yarn = await client.query(`
        SELECT id FROM master.yarns
        WHERE id=$1
          AND (company_id=$2 OR company_id IS NULL)
          AND COALESCE(is_active,true)=true
      `,[yarnId,companyId]);

      if (!yarn.rows.length) throw new Error(`Yarn ${yarnId} was not found or is inactive.`);

      const color = await client.query(`
        SELECT id FROM master.colors
        WHERE id=$1 AND COALESCE(is_active,true)=true
      `,[colorId]);

      if (!color.rows.length) throw new Error(`Color ${colorId} was not found or is inactive.`);

      const lot = await client.query(`
        INSERT INTO master.yarn_lots(
          company_id,lot_no,yarn_id,color_id,supplier_party_id,
          supplier_lot_no,received_date,remarks,is_active
        )
        VALUES($1,$2,$3,$4,$5,$6,$7,$8,true)
        ON CONFLICT (company_id,yarn_id,lot_no)
        DO UPDATE SET
          color_id=EXCLUDED.color_id,
          supplier_party_id=EXCLUDED.supplier_party_id,
          supplier_lot_no=EXCLUDED.supplier_lot_no,
          received_date=EXCLUDED.received_date,
          remarks=EXCLUDED.remarks,
          is_active=true,
          updated_at=NOW()
        RETURNING id
      `,[
        companyId,lotNo,yarnId,colorId,supplierId,
        supplierLotNo,receiptDate,lineNotes
      ]);

      const yarnLotId = lot.rows[0].id;

      await client.query(`
        INSERT INTO inventory.yarn_receipt_lines(
          receipt_id,yarn_lot_id,quantity,unit_rate,box_count,notes
        )
        VALUES($1,$2,$3,$4,$5,$6)
      `,[
        receipt.rows[0].id,yarnLotId,quantity,unitRate,boxCount,lineNotes
      ]);

      await client.query(`
        INSERT INTO inventory.yarn_ledger(
          company_id,financial_year_id,yarn_lot_id,location_id,
          movement_date,movement_type,quantity_in,quantity_out,
          reference_type,reference_id,remarks
        )
        VALUES($1,$2,$3,$4,$5,'RECEIPT',$6,0,'YARN_RECEIPT',$7,$8)
      `,[
        companyId,financialYearId,yarnLotId,locationId,
        receiptDate,quantity,receipt.rows[0].id,lineNotes
      ]);

      createdLines.push({
        yarn_id:yarnId,
        yarn_lot_id:yarnLotId,
        lot_no:lotNo,
        quantity,
        box_count:boxCount,
        unit_rate:unitRate,
        supplier_lot_no:supplierLotNo
      });
    }

    await client.query('COMMIT');

    res.status(201).json({
      success:true,
      message:'Yarn receipt posted successfully.',
      receipt:receipt.rows[0],
      lines:createdLines
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Create yarn receipt failed:',error);

    res.status(error.code === '23505' ? 409 : 500).json({
      success:false,
      error:error.message || 'Failed to post yarn receipt.'
    });
  } finally {
    client.release();
  }
});

module.exports = router;
