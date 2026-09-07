const express = require('express');

const router = express.Router();

const { pool } = require('../db');

// ============================================================
// HELPERS
// ============================================================

function mapYarn(row) {
  return {
    id: row.id,
    code: row.code || '',
    name: row.name || '',
    count: row.count || '',
    yarn_type_id: row.yarn_type_id,
    composition: row.composition || '',
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
        code,
        name,
        count,
        yarn_type_id,
        composition,
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

// ============================================================
// COLOR MASTER
// GET /api/yarns/colors
// POST /api/yarns/colors
// PUT /api/yarns/colors/:id
// ============================================================

router.get('/colors', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT id, code, name, description, is_active, created_at, updated_at
      FROM master.colors
      WHERE COALESCE(is_active, true) = true
      ORDER BY name ASC
    `);
    return res.json(result.rows);
  } catch (error) {
    console.error('Get colors failed:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to load colors',
      details: error.message,
    });
  }
});

router.post('/colors', async (req, res) => {
  try {
    const name = String(req.body.name || '').trim();
    const description = req.body.description == null
      ? null
      : String(req.body.description).trim() || null;

    if (!name) {
      return res.status(400).json({
        success: false,
        error: 'Color name is required',
      });
    }

    const duplicate = await pool.query(`
      SELECT id
      FROM master.colors
      WHERE LOWER(TRIM(name)) = LOWER(TRIM($1))
      LIMIT 1
    `, [name]);

    if (duplicate.rows.length > 0) {
      return res.status(409).json({
        success: false,
        error: 'Color already exists',
      });
    }

    const next = await pool.query(`
      SELECT COALESCE(
        MAX(CAST(NULLIF(SUBSTRING(code FROM '^CLR-([0-9]+)$'), '') AS INTEGER)),
        0
      ) + 1 AS next_no
      FROM master.colors
      WHERE code LIKE 'CLR-%'
    `);

    const code = `CLR-${String(Number(next.rows[0].next_no)).padStart(4, '0')}`;

    const result = await pool.query(`
      INSERT INTO master.colors (code, name, description, is_active)
      VALUES ($1, $2, $3, true)
      RETURNING id, code, name, description, is_active, created_at, updated_at
    `, [code, name, description]);

    return res.status(201).json({
      success: true,
      color: result.rows[0],
    });
  } catch (error) {
    console.error('Create color failed:', error);

    if (error.code === '23505') {
      return res.status(409).json({
        success: false,
        error: 'Color already exists',
      });
    }

    return res.status(500).json({
      success: false,
      error: 'Failed to create color',
      details: error.message,
    });
  }
});

router.put('/colors/:id', async (req, res) => {
  try {
    const name = String(req.body.name || '').trim();
    const description = req.body.description == null
      ? null
      : String(req.body.description).trim() || null;
    const isActive = req.body.is_active !== false;

    if (!name) {
      return res.status(400).json({
        success: false,
        error: 'Color name is required',
      });
    }

    const result = await pool.query(`
      UPDATE master.colors
      SET
        name = $1,
        description = $2,
        is_active = $3,
        updated_at = NOW()
      WHERE id = $4
      RETURNING id, code, name, description, is_active, created_at, updated_at
    `, [name, description, isActive, req.params.id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Color not found',
      });
    }

    return res.json({
      success: true,
      color: result.rows[0],
    });
  } catch (error) {
    console.error('Update color failed:', error);
    return res.status(500).json({
      success: false,
      error: 'Failed to update color',
      details: error.message,
    });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT
        id,
        code,
        name,
        count,
        yarn_type_id,
        composition,
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
      code,
      name,
      count,
      yarn_type_id,
      composition,
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

    const result = await pool.query(
      `
      INSERT INTO master.yarns (
        code,
        name,
        count,
        yarn_type_id,
        composition,
        unit_id,
        description,
        is_active
      )
      VALUES (
        $1, $2, $3, $4, $5,
        $6, $7, TRUE
      )
      RETURNING
        id,
        code,
        name,
        count,
        yarn_type_id,
        composition,
        unit_id,
        description,
        is_active,
        created_at,
        updated_at
      `,
      [
        code.toString().trim(),
        name.toString().trim(),
        count || null,
        yarn_type_id || null,
        composition || null,
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
      code,
      name,
      count,
      yarn_type_id,
      composition,
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

    const result = await pool.query(
      `
      UPDATE master.yarns
      SET
        code = $1,
        name = $2,
        count = $3,
        yarn_type_id = $4,
        composition = $5,
        unit_id = $6,
        description = $7,
        is_active = $8,
        updated_at = NOW()
      WHERE id = $9
      RETURNING
        id,
        code,
        name,
        count,
        yarn_type_id,
        composition,
        unit_id,
        description,
        is_active,
        created_at,
        updated_at
      `,
      [
        code.toString().trim(),
        name.toString().trim(),
        count || null,
        yarn_type_id || null,
        composition || null,
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