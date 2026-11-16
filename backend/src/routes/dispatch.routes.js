const express = require('express');
const { pool } = require('../db');
const { COMPANY_ID } = require('../config');

const router = express.Router();
const clean = value => value == null ? '' : String(value).trim();
const number = value => Number.isFinite(Number(value)) ? Number(value) : 0;
const roundKg = value => Math.round((value + Number.EPSILON) * 1000) / 1000;

router.get('/lots', async (req, res) => {
  try {
    const values = [COMPANY_ID];
    const conditions = ['l.company_id=$1'];
    if (req.query.status !== 'all') conditions.push("l.status='AVAILABLE'");
    if (req.query.party_id) { values.push(req.query.party_id); conditions.push(`j.party_id=$${values.length}`); }
    if (req.query.job_id) { values.push(req.query.job_id); conditions.push(`j.id=$${values.length}`); }
    const result = await pool.query(`
      SELECT l.id, l.lot_no, l.quantity_kg::float, l.status, l.parent_lot_id,
        l.created_at, j.id job_id, j.job_no, j.party_id, p.name party_name,
        f.name fabric_name, r.roll_no, r.net_weight_kg::float original_roll_kg,
        fp.production_date
      FROM jobwork.fabric_lots l
      JOIN jobwork.job_orders j ON j.id=l.job_order_id
      JOIN master.parties p ON p.id=j.party_id
      JOIN production.fabric_production_rolls r ON r.id=l.origin_roll_id
      JOIN production.fabric_production fp ON fp.id=r.production_id AND fp.status='POSTED'
      LEFT JOIN master.fabrics f ON f.id=j.fabric_id
      WHERE ${conditions.join(' AND ')}
      ORDER BY j.job_no, r.roll_no, l.created_at, l.lot_no
    `, values);
    res.json({ success: true, lots: result.rows });
  } catch (error) {
    // The origin-roll relationship is direct; no separate lookup table is needed.
    console.error('List dispatch lots failed:', error);
    res.status(500).json({ success: false, error: 'Failed to load fabric lots' });
  }
});

router.get('/unreconciled-rolls', async (_req, res) => {
  try {
    const result = await pool.query(`
      SELECT r.id,r.roll_no,r.net_weight_kg::float AS quantity_kg,
        fp.production_no,fp.production_date,j.job_no,j.id AS job_id,
        j.party_id,p.name AS party_name,f.name AS fabric_name
      FROM production.fabric_production_rolls r
      JOIN production.fabric_production fp ON fp.id=r.production_id AND fp.status='POSTED'
      JOIN jobwork.job_orders j ON j.id=fp.job_order_id
      JOIN master.parties p ON p.id=j.party_id
      LEFT JOIN master.fabrics f ON f.id=j.fabric_id
      WHERE fp.company_id=$1
        AND NOT EXISTS (
          SELECT 1 FROM jobwork.fabric_lots l WHERE l.origin_roll_id=r.id
        )
      ORDER BY fp.production_date DESC,j.job_no,r.roll_no
    `, [COMPANY_ID]);
    res.json({ success: true, rolls: result.rows });
  } catch (error) {
    console.error('List unreconciled production rolls failed:', error);
    res.status(500).json({ success: false, error: 'Failed to load unreconciled production rolls' });
  }
});

router.get('/', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT d.id,d.dispatch_no,d.challan_date,d.transporter,d.vehicle_no,d.notes,d.status,
        p.name party_name,COALESCE(SUM(dl.quantity_kg),0)::float quantity_kg,
        COUNT(dl.id)::int lot_count,
        STRING_AGG(DISTINCT j.job_no, ', ' ORDER BY j.job_no) job_numbers
      FROM jobwork.fabric_dispatches d
      JOIN master.parties p ON p.id=d.party_id
      LEFT JOIN jobwork.fabric_dispatch_lines dl ON dl.dispatch_id=d.id
      LEFT JOIN jobwork.fabric_lots l ON l.id=dl.lot_id
      LEFT JOIN jobwork.job_orders j ON j.id=l.job_order_id
      WHERE d.company_id=$1
      GROUP BY d.id,p.name
      ORDER BY d.challan_date DESC,d.created_at DESC
      LIMIT 300
    `, [COMPANY_ID]);
    res.json({ success: true, dispatches: result.rows });
  } catch (error) {
    console.error('List dispatches failed:', error);
    res.status(500).json({ success: false, error: 'Failed to load dispatches' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const header = await pool.query(`
      SELECT d.id,d.dispatch_no,d.challan_date,d.transporter,d.vehicle_no,d.notes,d.status,
        p.name party_name,p.address_line1,p.address_line2,p.city,p.state,p.pincode AS pin_code,p.gstin
      FROM jobwork.fabric_dispatches d
      JOIN master.parties p ON p.id=d.party_id
      WHERE d.id=$1 AND d.company_id=$2
    `, [req.params.id, COMPANY_ID]);
    if (!header.rows.length) return res.status(404).json({ success: false, error: 'Dispatch challan not found.' });
    const lines = await pool.query(`
      SELECT dl.quantity_kg::float,l.lot_no,r.roll_no,j.job_no,f.name fabric_name,j.design_no,j.gsm
      FROM jobwork.fabric_dispatch_lines dl
      JOIN jobwork.fabric_dispatches d ON d.id=dl.dispatch_id
      JOIN jobwork.fabric_lots l ON l.id=dl.lot_id
      JOIN production.fabric_production_rolls r ON r.id=l.origin_roll_id
      JOIN jobwork.job_orders j ON j.id=l.job_order_id
      LEFT JOIN master.fabrics f ON f.id=j.fabric_id
      WHERE d.id=$1 AND d.company_id=$2
      ORDER BY j.job_no,r.roll_no,l.lot_no
    `, [req.params.id, COMPANY_ID]);
    res.json({ success: true, dispatch: header.rows[0], lines: lines.rows });
  } catch (error) {
    console.error('Load dispatch details failed:', error);
    res.status(500).json({ success: false, error: 'Failed to load dispatch details' });
  }
});

router.post('/lots/:id/split', async (req, res) => {
  const client = await pool.connect();
  try {
    const childQuantities = Array.isArray(req.body?.child_quantities_kg)
      ? req.body.child_quantities_kg.map(value => roundKg(number(value))) : [];
    const loss = roundKg(number(req.body?.cutting_loss_kg));
    if (childQuantities.length < 2 || childQuantities.some(q => q <= 0) || loss < 0) {
      return res.status(400).json({ success: false, error: 'Enter at least two positive lot quantities and a non-negative cutting loss.' });
    }
    await client.query('BEGIN');
    const source = await client.query(`
      SELECT l.*,j.party_id FROM jobwork.fabric_lots l
      JOIN jobwork.job_orders j ON j.id=l.job_order_id
      WHERE l.id=$1 AND l.company_id=$2 AND l.status='AVAILABLE' FOR UPDATE OF l
    `, [req.params.id, COMPANY_ID]);
    if (!source.rows.length) throw new Error('Available fabric lot not found.');
    const lot = source.rows[0];
    const sourceQty = number(lot.quantity_kg);
    const childTotal = childQuantities.reduce((sum, q) => sum + q, 0);
    if (Math.abs(childTotal + loss - sourceQty) > 0.00001) {
      throw new Error(`Child lots and cutting loss must total ${sourceQty.toFixed(3)} kg.`);
    }
    const splitSeq = await client.query("SELECT nextval('jobwork.fabric_split_no_seq') AS n");
    const splitNo = `SPL-${String(new Date().getFullYear()).slice(-2)}-${String(splitSeq.rows[0].n).padStart(6, '0')}`;
    const split = await client.query(`
      INSERT INTO jobwork.fabric_lot_splits(company_id,split_no,source_lot_id,source_quantity_kg,cutting_loss_kg,notes)
      VALUES($1,$2,$3,$4,$5,$6) RETURNING id,split_no
    `, [COMPANY_ID, splitNo, lot.id, sourceQty, loss, clean(req.body?.notes) || null]);
    await client.query(`UPDATE jobwork.fabric_lots SET status='SPLIT',split_id=$1 WHERE id=$2`, [split.rows[0].id, lot.id]);
    const children = [];
    for (let index = 0; index < childQuantities.length; index++) {
      const child = await client.query(`
        INSERT INTO jobwork.fabric_lots(company_id,job_order_id,origin_roll_id,parent_lot_id,split_id,lot_no,quantity_kg)
        VALUES($1,$2,$3,$4,$5,'LOT-' || lpad(nextval('jobwork.fabric_lot_no_seq')::text,7,'0'),$6)
        RETURNING id,lot_no,quantity_kg::float
      `, [COMPANY_ID, lot.job_order_id, lot.origin_roll_id, lot.id, split.rows[0].id, childQuantities[index]]);
      children.push(child.rows[0]);
    }
    await client.query('COMMIT');
    res.status(201).json({ success: true, split_no: split.rows[0].split_no, children, cutting_loss_kg: loss });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Split fabric lot failed:', error);
    res.status(400).json({ success: false, error: error.message || 'Failed to split fabric lot' });
  } finally { client.release(); }
});

router.post('/opening-stock', async (req, res) => {
  const client = await pool.connect();
  try {
    const rollIds = Array.isArray(req.body?.roll_ids)
      ? [...new Set(req.body.roll_ids.map(clean).filter(Boolean))]
      : [];
    if (!rollIds.length || rollIds.some(id => !/^[0-9a-f-]{36}$/i.test(id))) {
      return res.status(400).json({ success: false, error: 'Select at least one valid production roll.' });
    }
    await client.query('BEGIN');
    const rolls = await client.query(`
      SELECT r.id,r.net_weight_kg,fp.job_order_id,fp.company_id
      FROM production.fabric_production_rolls r
      JOIN production.fabric_production fp ON fp.id=r.production_id AND fp.status='POSTED'
      WHERE r.id=ANY($1::uuid[]) AND fp.company_id=$2
        AND NOT EXISTS (SELECT 1 FROM jobwork.fabric_lots l WHERE l.origin_roll_id=r.id)
      ORDER BY r.id FOR UPDATE OF r
    `, [rollIds, COMPANY_ID]);
    if (rolls.rows.length !== rollIds.length) {
      throw new Error('One or more rolls are no longer available for reconciliation. Refresh and try again.');
    }
    const saved = [];
    for (const roll of rolls.rows) {
      const lot = await client.query(`
        INSERT INTO jobwork.fabric_lots(company_id,job_order_id,origin_roll_id,lot_no,quantity_kg)
        VALUES($1,$2,$3,'LOT-' || lpad(nextval('jobwork.fabric_lot_no_seq')::text,7,'0'),$4)
        RETURNING id,lot_no,quantity_kg::float
      `, [COMPANY_ID, roll.job_order_id, roll.id, roll.net_weight_kg]);
      saved.push(lot.rows[0]);
    }
    await client.query('COMMIT');
    res.status(201).json({ success: true, count: saved.length, lots: saved });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Reconcile opening fabric stock failed:', error);
    res.status(400).json({ success: false, error: error.message || 'Failed to reconcile opening stock' });
  } finally { client.release(); }
});

router.post('/', async (req, res) => {
  const client = await pool.connect();
  try {
    const partyId = clean(req.body?.party_id);
    const lotIds = Array.isArray(req.body?.lot_ids) ? [...new Set(req.body.lot_ids.map(clean).filter(Boolean))] : [];
    if (!partyId || !lotIds.length) return res.status(400).json({ success: false, error: 'Select a party and at least one available roll or lot.' });
    await client.query('BEGIN');
    const lots = await client.query(`
      SELECT l.id,l.job_order_id,l.quantity_kg,j.party_id
      FROM jobwork.fabric_lots l JOIN jobwork.job_orders j ON j.id=l.job_order_id
      JOIN production.fabric_production_rolls r ON r.id=l.origin_roll_id
      JOIN production.fabric_production fp ON fp.id=r.production_id AND fp.status='POSTED'
      WHERE l.id=ANY($1::uuid[]) AND l.company_id=$2 AND l.status='AVAILABLE'
      ORDER BY l.id FOR UPDATE OF l
    `, [lotIds, COMPANY_ID]);
    if (lots.rows.length !== lotIds.length) throw new Error('One or more selected lots are no longer available. Refresh and try again.');
    if (lots.rows.some(lot => String(lot.party_id) !== partyId)) throw new Error('All selected lots must belong to the selected party.');
    const fy = await client.query(`SELECT id FROM core.financial_years WHERE company_id=$1 AND is_current AND NOT is_closed LIMIT 1`, [COMPANY_ID]);
    if (!fy.rows.length) throw new Error('No open financial year exists.');
    const inserted = await client.query(`
      INSERT INTO jobwork.fabric_dispatches(company_id,financial_year_id,party_id,dispatch_no,challan_date,transporter,vehicle_no,notes)
      VALUES($1,$2,$3,'DC-' || to_char(CURRENT_DATE,'YY') || '-' || lpad(nextval('jobwork.fabric_dispatch_no_seq')::text,6,'0'),
        COALESCE($4::date,CURRENT_DATE),$5,$6,$7)
      RETURNING id,dispatch_no,challan_date
    `, [COMPANY_ID, fy.rows[0].id, partyId, req.body?.challan_date || null, clean(req.body?.transporter) || null, clean(req.body?.vehicle_no) || null, clean(req.body?.notes) || null]);
    for (const lot of lots.rows) {
      await client.query(`INSERT INTO jobwork.fabric_dispatch_lines(dispatch_id,lot_id,quantity_kg) VALUES($1,$2,$3)`, [inserted.rows[0].id, lot.id, lot.quantity_kg]);
      await client.query(`UPDATE jobwork.fabric_lots SET status='DISPATCHED' WHERE id=$1`, [lot.id]);
    }
    await client.query('COMMIT');
    res.status(201).json({ success: true, dispatch: inserted.rows[0], lot_count: lots.rows.length });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Post fabric dispatch failed:', error);
    res.status(400).json({ success: false, error: error.message || 'Failed to post dispatch' });
  } finally { client.release(); }
});

module.exports = router;
