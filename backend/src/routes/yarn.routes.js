const express = require('express');

const router = express.Router();

const { pool } = require('../db');

// ============================================================
// GET ALL YARNS
// GET /api/yarns
// ============================================================

router.get('/', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        id,
        yarn_name,
        yarn_count,
        yarn_type,
        is_active,
        created_at,
        updated_at
      FROM yarns
      WHERE is_active = TRUE
      ORDER BY yarn_name ASC, yarn_count ASC
    `);

    const yarns = result.rows.map((yarn) => ({
      id: Number(yarn.id),
      yarn_name: yarn.yarn_name || '',
      yarn_count: yarn.yarn_count || '',
      yarn_type: yarn.yarn_type || '',
      is_active: yarn.is_active === true,
      created_at: yarn.created_at,
      updated_at: yarn.updated_at,
    }));

    return res.status(200).json(yarns);
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
        yarn_name,
        yarn_count,
        yarn_type,
        is_active,
        created_at,
        updated_at
      FROM yarns
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

    const yarn = result.rows[0];

    return res.status(200).json({
      id: Number(yarn.id),
      yarn_name: yarn.yarn_name || '',
      yarn_count: yarn.yarn_count || '',
      yarn_type: yarn.yarn_type || '',
      is_active: yarn.is_active === true,
      created_at: yarn.created_at,
      updated_at: yarn.updated_at,
    });
  } catch (error) {
    console.error('Get yarn failed:', error);

    return res.status(500).json({
      success: false,
      error: 'Failed to load yarn',
      details: error.message,
    });
  }
});

module.exports = router;