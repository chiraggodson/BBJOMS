const express = require('express');
const router = express.Router();
const { pool } = require('../db');

// ============================================================
// GET ALL FABRICS
// GET /api/fabrics
// ============================================================

router.get('/', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        id,
        fabric_code,
        name,
        description,
        gsm,
        composition,
        width_inches,
        is_active,
        created_at,
        updated_at
      FROM fabrics
      WHERE is_active = TRUE
      ORDER BY name ASC
    `);

    const fabrics = result.rows.map((fabric) => ({
      id: Number(fabric.id),
      fabric_code: fabric.fabric_code || '',
      name: fabric.name || '',
      description: fabric.description || '',
      gsm: fabric.gsm == null ? null : Number(fabric.gsm),
      composition: fabric.composition || '',
      width_inches:
          fabric.width_inches == null
              ? null
              : Number(fabric.width_inches),
      is_active: fabric.is_active === true,
      created_at: fabric.created_at,
      updated_at: fabric.updated_at,
    }));

    res.status(200).json(fabrics);
  } catch (error) {
    console.error('Get fabrics failed:', error);

    res.status(500).json({
      success: false,
      error: 'Failed to load fabrics',
      details: error.message,
    });
  }
});

// ============================================================
// GET ONE FABRIC
// GET /api/fabrics/:id
// ============================================================

router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT
        id,
        fabric_code,
        name,
        description,
        gsm,
        composition,
        width_inches,
        is_active,
        created_at,
        updated_at
      FROM fabrics
      WHERE id = $1
      LIMIT 1
      `,
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Fabric not found',
      });
    }

    const fabric = result.rows[0];

    res.status(200).json({
      id: Number(fabric.id),
      fabric_code: fabric.fabric_code || '',
      name: fabric.name || '',
      description: fabric.description || '',
      gsm: fabric.gsm == null ? null : Number(fabric.gsm),
      composition: fabric.composition || '',
      width_inches:
          fabric.width_inches == null
              ? null
              : Number(fabric.width_inches),
      is_active: fabric.is_active === true,
      created_at: fabric.created_at,
      updated_at: fabric.updated_at,
    });
  } catch (error) {
    console.error('Get fabric failed:', error);

    res.status(500).json({
      success: false,
      error: 'Failed to load fabric',
      details: error.message,
    });
  }
});

// ============================================================
// CREATE FABRIC
// POST /api/fabrics
// ============================================================

router.post('/', async (req, res) => {
  try {
    const {
      fabric_code,
      name,
      description,
      gsm,
      composition,
      width_inches,
    } = req.body;

    if (!fabric_code || !fabric_code.toString().trim()) {
      return res.status(400).json({
        success: false,
        error: 'Fabric code is required',
      });
    }

    if (!name || !name.toString().trim()) {
      return res.status(400).json({
        success: false,
        error: 'Fabric name is required',
      });
    }

    const result = await pool.query(
      `
      INSERT INTO fabrics (
        fabric_code,
        name,
        description,
        gsm,
        composition,
        width_inches,
        is_active
      )
      VALUES ($1, $2, $3, $4, $5, $6, TRUE)
      RETURNING
        id,
        fabric_code,
        name,
        description,
        gsm,
        composition,
        width_inches,
        is_active,
        created_at,
        updated_at
      `,
      [
        fabric_code.toString().trim(),
        name.toString().trim(),
        description || null,
        gsm == null || gsm === '' ? null : Number(gsm),
        composition || null,
        width_inches == null || width_inches === ''
            ? null
            : Number(width_inches),
      ]
    );

    const fabric = result.rows[0];

    res.status(201).json({
      success: true,
      fabric: {
        id: Number(fabric.id),
        fabric_code: fabric.fabric_code,
        name: fabric.name,
        description: fabric.description || '',
        gsm: fabric.gsm == null ? null : Number(fabric.gsm),
        composition: fabric.composition || '',
        width_inches:
            fabric.width_inches == null
                ? null
                : Number(fabric.width_inches),
        is_active: fabric.is_active === true,
        created_at: fabric.created_at,
        updated_at: fabric.updated_at,
      },
    });
  } catch (error) {
    console.error('Create fabric failed:', error);

    if (error.code === '23505') {
      return res.status(409).json({
        success: false,
        error: 'Fabric code already exists',
      });
    }

    res.status(500).json({
      success: false,
      error: 'Failed to create fabric',
      details: error.message,
    });
  }
});

// ============================================================
// UPDATE FABRIC
// PUT /api/fabrics/:id
// ============================================================

router.put('/:id', async (req, res) => {
  try {
    const {
      fabric_code,
      name,
      description,
      gsm,
      composition,
      width_inches,
      is_active,
    } = req.body;

    if (!fabric_code || !fabric_code.toString().trim()) {
      return res.status(400).json({
        success: false,
        error: 'Fabric code is required',
      });
    }

    if (!name || !name.toString().trim()) {
      return res.status(400).json({
        success: false,
        error: 'Fabric name is required',
      });
    }

    const result = await pool.query(
      `
      UPDATE fabrics
      SET
        fabric_code = $1,
        name = $2,
        description = $3,
        gsm = $4,
        composition = $5,
        width_inches = $6,
        is_active = $7,
        updated_at = NOW()
      WHERE id = $8
      RETURNING
        id,
        fabric_code,
        name,
        description,
        gsm,
        composition,
        width_inches,
        is_active,
        created_at,
        updated_at
      `,
      [
        fabric_code.toString().trim(),
        name.toString().trim(),
        description || null,
        gsm == null || gsm === '' ? null : Number(gsm),
        composition || null,
        width_inches == null || width_inches === ''
            ? null
            : Number(width_inches),
        is_active !== false,
        req.params.id,
      ]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Fabric not found',
      });
    }

    const fabric = result.rows[0];

    res.status(200).json({
      success: true,
      fabric: {
        id: Number(fabric.id),
        fabric_code: fabric.fabric_code,
        name: fabric.name,
        description: fabric.description || '',
        gsm: fabric.gsm == null ? null : Number(fabric.gsm),
        composition: fabric.composition || '',
        width_inches:
            fabric.width_inches == null
                ? null
                : Number(fabric.width_inches),
        is_active: fabric.is_active === true,
        created_at: fabric.created_at,
        updated_at: fabric.updated_at,
      },
    });
  } catch (error) {
    console.error('Update fabric failed:', error);

    if (error.code === '23505') {
      return res.status(409).json({
        success: false,
        error: 'Fabric code already exists',
      });
    }

    res.status(500).json({
      success: false,
      error: 'Failed to update fabric',
      details: error.message,
    });
  }
});

// ============================================================
// DEACTIVATE FABRIC
// DELETE /api/fabrics/:id
// ============================================================

router.delete('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `
      UPDATE fabrics
      SET
        is_active = FALSE,
        updated_at = NOW()
      WHERE id = $1
      RETURNING id
      `,
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Fabric not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Fabric deactivated',
    });
  } catch (error) {
    console.error('Deactivate fabric failed:', error);

    res.status(500).json({
      success: false,
      error: 'Failed to deactivate fabric',
      details: error.message,
    });
  }
});

module.exports = router;