const express = require('express');
const router = express.Router();
const { pool } = require('../db');

// ============================================================
// GET ALL MACHINES
// GET /api/machines
// ============================================================

router.get('/', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        id,
        machine_no,
        machine_type,
        floor,
        status,
        rpm,
        counter,
        roll_size,
        is_active,
        created_at,
        updated_at
      FROM machines
      WHERE is_active = TRUE
      ORDER BY machine_no ASC
    `);

    const machines = result.rows.map((machine) => {
      const rpm = Number(machine.rpm) || 0;
      const counter = Number(machine.counter) || 0;
      const rollSize = Number(machine.roll_size) || 0;

      // Production calculation:
      // kg/hour = (24 × RPM × 60) / counter
      let kgPerHour = 0;

      if (counter > 0) {
        kgPerHour = (24 * (rpm * 60)) / counter;
      }

      const kg24h = kgPerHour * 24;

      let estimatedRolls24h = 0;

      if (rollSize > 0) {
        estimatedRolls24h = Math.floor(kg24h / rollSize);
      }

      return {
        id: Number(machine.id),
        machine_no: machine.machine_no,
        machine_type: machine.machine_type,
        floor: machine.floor,
        status: machine.status,
        rpm,
        counter,
        roll_size: rollSize,
        kg_per_hour: Number(kgPerHour.toFixed(2)),
        kg_24h: Number(kg24h.toFixed(2)),
        estimated_rolls_24h: estimatedRolls24h,
        is_active: machine.is_active,
        created_at: machine.created_at,
        updated_at: machine.updated_at,
      };
    });

    res.status(200).json(machines);
  } catch (error) {
    console.error('Get machines failed:', error);

    res.status(500).json({
      success: false,
      error: 'Failed to load machines',
    });
  }
});

// ============================================================
// GET ONE MACHINE
// GET /api/machines/:id
// ============================================================

router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT
        id,
        machine_no,
        machine_type,
        floor,
        status,
        rpm,
        counter,
        roll_size,
        is_active,
        created_at,
        updated_at
      FROM machines
      WHERE id = $1
      LIMIT 1
      `,
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Machine not found',
      });
    }

    const machine = result.rows[0];

    const rpm = Number(machine.rpm) || 0;
    const counter = Number(machine.counter) || 0;
    const rollSize = Number(machine.roll_size) || 0;

    let kgPerHour = 0;

    if (counter > 0) {
      kgPerHour = (24 * (rpm * 60)) / counter;
    }

    const kg24h = kgPerHour * 24;

    let estimatedRolls24h = 0;

    if (rollSize > 0) {
      estimatedRolls24h = Math.floor(kg24h / rollSize);
    }

    res.status(200).json({
      ...machine,
      id: Number(machine.id),
      rpm,
      counter,
      roll_size: rollSize,
      kg_per_hour: Number(kgPerHour.toFixed(2)),
      kg_24h: Number(kg24h.toFixed(2)),
      estimated_rolls_24h: estimatedRolls24h,
    });
  } catch (error) {
    console.error('Get machine failed:', error);

    res.status(500).json({
      success: false,
      error: 'Failed to load machine',
    });
  }
});

module.exports = router;