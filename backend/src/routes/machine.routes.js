const express = require('express');
const router = express.Router();
const { pool } = require('../db');

const COMPANY_ID = '37c8cd03-c8ae-48cd-b8e4-cb3e864f042f';

function mapMachine(row) {
  const rpm = Number(row.rpm) || 0;
  const counter = Number(row.counter) || 0;
  const rollSize = Number(row.roll_size) || 0;
  const kgPerHour = counter > 0 ? (24 * (rpm * 60)) / counter : 0;
  const kg24h = kgPerHour * 24;
  return {
    id: row.id,
    machine_no: row.machine_no,
    machine_type: row.machine_type || row.machine_group_name || '',
    floor: row.floor || row.floor_name || '',
    status: row.status,
    rpm, counter, roll_size: rollSize,
    kg_per_hour: Number(kgPerHour.toFixed(2)),
    kg_24h: Number(kg24h.toFixed(2)),
    estimated_rolls_24h: rollSize > 0 ? Math.floor(kg24h / rollSize) : 0,
    is_active: row.is_active,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

const selectSql = `
  SELECT
    m.id, m.machine_no, m.status, m.rpm, m.counter, m.roll_size, m.is_active,
    m.created_at, m.updated_at,
    COALESCE(mg.name, '') AS machine_group_name,
    COALESCE(f.name, '') AS floor_name
  FROM master.machines m
  LEFT JOIN master.machine_groups mg ON mg.id = m.machine_group_id
  LEFT JOIN master.floors f ON f.id = m.floor_id
`;

router.get('/', async (req, res) => {
  try {
    const result = await pool.query(`
      ${selectSql}
      WHERE m.company_id = $1 AND m.is_active = TRUE
      ORDER BY CASE WHEN TRIM(m.machine_no) ~ '^\\d+$' THEN CAST(TRIM(m.machine_no) AS INTEGER) ELSE NULL END ASC NULLS LAST, m.machine_no ASC
    `, [COMPANY_ID]);
    return res.status(200).json(result.rows.map(mapMachine));
  } catch (error) {
    console.error('Get machines failed:', error);
    return res.status(500).json({ success: false, error: 'Failed to load machines', details: error.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query(`
      ${selectSql}
      WHERE m.id = $1 AND m.company_id = $2
      LIMIT 1
    `, [req.params.id, COMPANY_ID]);
    if (!result.rows.length) return res.status(404).json({ success: false, error: 'Machine not found' });
    return res.json(mapMachine(result.rows[0]));
  } catch (error) {
    console.error('Get machine failed:', error);
    return res.status(500).json({ success: false, error: 'Failed to load machine', details: error.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const machineNo = String(req.body?.machine_no ?? '').trim();
    if (!machineNo) return res.status(400).json({ success: false, error: 'Machine number is required' });

    const rpm = Number(req.body?.rpm) || 0;
    const counter = Number(req.body?.counter) || 0;
    const rollSize = Number(req.body?.roll_size) || 0;
    if (rpm < 0 || counter < 0 || rollSize < 0) {
      return res.status(400).json({ success: false, error: 'RPM, counter and roll size cannot be negative' });
    }

    const duplicate = await pool.query(`
      SELECT id FROM master.machines
      WHERE company_id = $1 AND machine_no = $2 LIMIT 1
    `, [COMPANY_ID, machineNo]);
    if (duplicate.rows.length) return res.status(409).json({ success: false, error: `Machine "${machineNo}" already exists` });

    let groupId = null;
    let floorId = null;

    if (req.body?.machine_group_id) {
      const r = await pool.query(`SELECT id FROM master.machine_groups WHERE id=$1 AND company_id=$2`, [req.body.machine_group_id, COMPANY_ID]);
      if (!r.rows.length) return res.status(400).json({ success: false, error: 'Invalid machine group' });
      groupId = req.body.machine_group_id;
    }

    if (req.body?.floor_id) {
      const r = await pool.query(`SELECT id FROM master.floors WHERE id=$1 AND company_id=$2`, [req.body.floor_id, COMPANY_ID]);
      if (!r.rows.length) return res.status(400).json({ success: false, error: 'Invalid floor' });
      floorId = req.body.floor_id;
    }

    const result = await pool.query(`
      INSERT INTO master.machines (
        company_id, machine_no, machine_group_id, floor_id,
        status, rpm, counter, roll_size, is_active
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
      RETURNING id, machine_no, status, rpm, counter, roll_size, is_active, created_at, updated_at
    `, [
      COMPANY_ID, machineNo, groupId, floorId,
      String(req.body?.status || 'IDLE').toUpperCase(),
      rpm, counter, rollSize, req.body?.is_active !== false
    ]);

    const full = await pool.query(`${selectSql} WHERE m.id=$1`, [result.rows[0].id]);
    return res.status(201).json({ success: true, message: 'Machine added successfully', machine: mapMachine(full.rows[0]) });
  } catch (error) {
    console.error('Add machine failed:', error);
    return res.status(error.code === '23505' ? 409 : 500).json({
      success: false,
      error: error.code === '23505' ? 'A machine with this machine number already exists' : 'Failed to add machine',
      details: error.message
    });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const machineNo = String(req.body?.machine_no ?? '').trim();
    if (!machineNo) return res.status(400).json({ success: false, error: 'Machine number is required' });

    const rpm = Number(req.body?.rpm) || 0;
    const counter = Number(req.body?.counter) || 0;
    const rollSize = Number(req.body?.roll_size) || 0;
    if (rpm < 0 || counter < 0 || rollSize < 0) return res.status(400).json({ success: false, error: 'RPM, counter and roll size cannot be negative' });

    const result = await pool.query(`
      UPDATE master.machines
      SET machine_no=$1, status=$2, rpm=$3, counter=$4, roll_size=$5, updated_at=NOW()
      WHERE id=$6 AND company_id=$7
      RETURNING id
    `, [
      machineNo, String(req.body?.status || 'IDLE').toUpperCase(),
      rpm, counter, rollSize, req.params.id, COMPANY_ID
    ]);

    if (!result.rows.length) return res.status(404).json({ success: false, error: 'Machine not found' });
    const full = await pool.query(`${selectSql} WHERE m.id=$1`, [req.params.id]);
    return res.json({ success: true, message: 'Machine updated successfully', machine: mapMachine(full.rows[0]) });
  } catch (error) {
    console.error('Update machine failed:', error);
    return res.status(error.code === '23505' ? 409 : 500).json({
      success: false,
      error: error.code === '23505' ? 'A machine with this machine number already exists' : 'Failed to update machine',
      details: error.message
    });
  }
});

module.exports = router;
