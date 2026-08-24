const express = require('express');

const router = express.Router();

const { pool } = require('../db');

// ============================================================
// HELPERS
// ============================================================

function mapYarn(row) {
  return {
    id: row.id,
    company_id: row.company_id,
    code: row.code || '',
    name: row.name || '',
    count: row.count || '',
    yarn_type_id: row.yarn_type_id,
    composition: row.composition || '',
    colour: row.colour || '',
    unit_id: row.unit_id,
    description: row.description || '',
    is_active: row.is_active === true,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

// ============================================================
// GET ALL YARNS
// GET /api/yarns
// ============================================================

router.get('/', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        id,
        company_id,
        code,
        name,
        count,
        yarn_type_id,
        composition,
        colour,
        unit_id,
        description,
        is_active,
        created_at,
        updated_at
      FROM master.yarns
      WHERE is_active = TRUE
      ORDER BY name ASC, count ASC
    `);

    return res.status(200).json(
      result.rows.map(mapYarn)
    );
  } catch (error) {
    console.error('Get yarns failed:', error);

    return res.status(500).json({
      success: false,
      error: 'Failed to load yarns',
      details: error.message,
    });
  }
});

// ============================================================
// GET ONE YARN
// GET /api/yarns/:id
// ============================================================

router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT
        id,
        company_id,
        code,
        name,
        count,
        yarn_type_id,
        composition,
        colour,
        unit_id,
        description,
        is_active,
        created_at,
        updated_at
      FROM master.yarns
      WHERE id = $1
      LIMIT 1
      `,
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Yarn not found',
      });
    }

    return res.status(200).json(
      mapYarn(result.rows[0])
    );
  } catch (error) {
    console.error('Get yarn failed:', error);

    return res.status(500).json({
      success: false,
      error: 'Failed to load yarn',
      details: error.message,
    });
  }
});

// ============================================================
// CREATE YARN
// POST /api/yarns
// ============================================================

router.post('/', async (req, res) => {
  try {
    const {
      company_id,
      code,
      name,
      count,
      yarn_type_id,
      composition,
      colour,
      unit_id,
      description,
    } = req.body;

    if (!code || !code.toString().trim()) {
      return res.status(400).json({
        success: false,
        error: 'Yarn code is required',
      });
    }

    if (!name || !name.toString().trim()) {
      return res.status(400).json({
        success: false,
        error: 'Yarn name is required',
      });
    }

    if (!company_id) {
      return res.status(400).json({
        success: false,
        error: 'Company ID is required',
      });
    }

    const result = await pool.query(
      `
      INSERT INTO master.yarns (
        company_id,
        code,
        name,
        count,
        yarn_type_id,
        composition,
        colour,
        unit_id,
        description,
        is_active
      )
      VALUES (
        $1, $2, $3, $4, $5,
        $6, $7, $8, $9, TRUE
      )
      RETURNING
        id,
        company_id,
        code,
        name,
        count,
        yarn_type_id,
        composition,
        colour,
        unit_id,
        description,
        is_active,
        created_at,
        updated_at
      `,
      [
        company_id,
        code.toString().trim(),
        name.toString().trim(),
        count || null,
        yarn_type_id || null,
        composition || null,
        colour || null,
        unit_id || null,
        description || null,
      ]
    );

    return res.status(201).json({
      success: true,
      yarn: mapYarn(result.rows[0]),
    });
  } catch (error) {
    console.error('Create yarn failed:', error);

    if (error.code === '23505') {
      return res.status(409).json({
        success: false,
        error: 'Yarn code already exists',
      });
    }

    return res.status(500).json({
      success: false,
      error: 'Failed to create yarn',
      details: error.message,
    });
  }
});

// ============================================================
// UPDATE YARN
// PUT /api/yarns/:id
// ============================================================

router.put('/:id', async (req, res) => {
  try {
    const {
      company_id,
      code,
      name,
      count,
      yarn_type_id,
      composition,
      colour,
      unit_id,
      description,
      is_active,
    } = req.body;

    if (!code || !code.toString().trim()) {
      return res.status(400).json({
        success: false,
        error: 'Yarn code is required',
      });
    }

    if (!name || !name.toString().trim()) {
      return res.status(400).json({
        success: false,
        error: 'Yarn name is required',
      });
    }

    if (!company_id) {
      return res.status(400).json({
        success: false,
        error: 'Company ID is required',
      });
    }

    const result = await pool.query(
      `
      UPDATE master.yarns
      SET
        company_id = $1,
        code = $2,
        name = $3,
        count = $4,
        yarn_type_id = $5,
        composition = $6,
        colour = $7,
        unit_id = $8,
        description = $9,
        is_active = $10,
        updated_at = NOW()
      WHERE id = $11
      RETURNING
        id,
        company_id,
        code,
        name,
        count,
        yarn_type_id,
        composition,
        colour,
        unit_id,
        description,
        is_active,
        created_at,
        updated_at
      `,
      [
        company_id,
        code.toString().trim(),
        name.toString().trim(),
        count || null,
        yarn_type_id || null,
        composition || null,
        colour || null,
        unit_id || null,
        description || null,
        is_active !== false,
        req.params.id,
      ]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Yarn not found',
      });
    }

    return res.status(200).json({
      success: true,
      yarn: mapYarn(result.rows[0]),
    });
  } catch (error) {
    console.error('Update yarn failed:', error);

    if (error.code === '23505') {
      return res.status(409).json({
        success: false,
        error: 'Yarn code already exists',
      });
    }

    return res.status(500).json({
      success: false,
      error: 'Failed to update yarn',
      details: error.message,
    });
  }
});

// ============================================================
// DEACTIVATE YARN
// DELETE /api/yarns/:id
// ============================================================

router.delete('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `
      UPDATE master.yarns
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
        error: 'Yarn not found',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Yarn deactivated',
    });
  } catch (error) {
    console.error('Deactivate yarn failed:', error);

    return res.status(500).json({
      success: false,
      error: 'Failed to deactivate yarn',
      details: error.message,
    });
  }
});

module.exports = router;