const express = require('express');
const router = express.Router();
const { pool } = require('../db');


// ============================================================
// GET ALL MACHINES
// GET /api/machines
// ============================================================

router.get("/", async (req, res) => {
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

    // IMPORTANT:
    // Flutter expects a raw JSON List here.
    res.status(200).json(machines);
  } catch (error) {
    console.error("Get machines failed:", error);

    res.status(500).json({
      success: false,
      error: "Failed to load machines",
      details: error.message,
    });
  }
});

// ============================================================
// ADD MACHINE
// POST /api/machines
// ============================================================

router.post("/", async (req, res) => {
  try {
    const {
      machine_no,
      machine_type = "",
      floor = "",
      status = "idle",
      rpm = 0,
      counter = 0,
      roll_size = 0,
      is_active = true,
    } = req.body || {};

    const machineNo = String(machine_no ?? "").trim();

    if (!machineNo) {
      return res.status(400).json({
        success: false,
        error: "Machine number is required",
      });
    }

    const machineType = String(machine_type ?? "").trim();
    const machineFloor = String(floor ?? "").trim();
    const machineStatus =
      String(status ?? "idle").trim() || "idle";

    const machineRpm = Number(rpm) || 0;
    const machineCounter = Number(counter) || 0;
    const machineRollSize = Number(roll_size) || 0;
    const active = is_active !== false;

    if (
      machineRpm < 0 ||
      machineCounter < 0 ||
      machineRollSize < 0
    ) {
      return res.status(400).json({
        success: false,
        error: "RPM, counter and roll size cannot be negative",
      });
    }

    // Check for duplicate machine number.
    const existing = await pool.query(
      `
      SELECT id
      FROM machines
      WHERE machine_no = $1
      LIMIT 1
      `,
      [machineNo]
    );

    if (existing.rows.length > 0) {
      return res.status(409).json({
        success: false,
        error: `Machine "${machineNo}" already exists`,
      });
    }

    const result = await pool.query(
      `
      INSERT INTO machines (
        machine_no,
        machine_type,
        floor,
        status,
        rpm,
        counter,
        roll_size,
        is_active
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING
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
      `,
      [
        machineNo,
        machineType,
        machineFloor,
        machineStatus,
        machineRpm,
        machineCounter,
        machineRollSize,
        active,
      ]
    );

    const machine = result.rows[0];

    return res.status(201).json({
      success: true,
      message: "Machine added successfully",
      machine: {
        ...machine,
        id: Number(machine.id),
        rpm: Number(machine.rpm) || 0,
        counter: Number(machine.counter) || 0,
        roll_size: Number(machine.roll_size) || 0,
      },
    });
  } catch (error) {
    console.error("Add machine failed:", error);

    if (error.code === "23505") {
      return res.status(409).json({
        success: false,
        error: "A machine with this machine number already exists",
      });
    }

    if (error.code === "23502") {
      return res.status(400).json({
        success: false,
        error: `Database requires the field "${error.column}"`,
        details: error.message,
      });
    }

    return res.status(500).json({
      success: false,
      error: "Failed to add machine",
      details: error.message,
    });
  }
});

// ============================================================
// GET ONE MACHINE
// GET /api/machines/:id
// ============================================================

router.get("/:id", async (req, res) => {
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
        error: "Machine not found",
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

    return res.status(200).json({
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
    console.error("Get machine failed:", error);

    return res.status(500).json({
      success: false,
      error: "Failed to load machine",
      details: error.message,
    });
  }
});


module.exports = router;