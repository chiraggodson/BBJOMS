const express = require('express');

const router = express.Router();

const { pool } = require('../db');

// ============================================================
// CURRENT COMPANY
// ============================================================

const COMPANY_ID =
  '63558a5c-3815-4d4f-9f0d-7edfdf5d3f11';

// ============================================================
// HELPERS
// ============================================================

function mapFabric(row) {
  return {
    id: row.id,
    company_id: row.company_id,
    code: row.code || '',
    name: row.name || '',
    product_id: row.product_id,
    design_no: row.design_no || '',
    gsm: row.gsm == null ? null : Number(row.gsm),
    width_inches:
      row.width_inches == null
        ? null
        : Number(row.width_inches),
    composition: row.composition || '',
    stitch_length:
      row.stitch_length == null
        ? null
        : Number(row.stitch_length),
    gauge: row.gauge || '',
    construction: row.construction || '',
    unit_id: row.unit_id,
    is_active: row.is_active === true,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

// ============================================================
// GET ALL FABRICS
// GET /api/fabrics
// ============================================================

router.get('/', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        id,
        company_id,
        code,
        name,
        product_id,
        design_no,
        gsm,
        width_inches,
        composition,
        stitch_length,
        gauge,
        construction,
        unit_id,
        is_active,
        created_at,
        updated_at
      FROM master.fabrics
      WHERE company_id = $1
        AND is_active = TRUE
      ORDER BY name ASC
    `, [COMPANY_ID]);

    return res.status(200).json(
      result.rows.map(mapFabric)
    );
  } catch (error) {
    console.error('Get fabrics failed:', error);

    return res.status(500).json({
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
        company_id,
        code,
        name,
        product_id,
        design_no,
        gsm,
        width_inches,
        composition,
        stitch_length,
        gauge,
        construction,
        unit_id,
        is_active,
        created_at,
        updated_at
      FROM master.fabrics
      WHERE id = $1
        AND company_id = $2
      LIMIT 1
      `,
      [req.params.id, COMPANY_ID]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Fabric not found',
      });
    }

    return res.status(200).json(
      mapFabric(result.rows[0])
    );
  } catch (error) {
    console.error('Get fabric failed:', error);

    return res.status(500).json({
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
      code,
      name,
      product_id,
      design_no,
      gsm,
      width_inches,
      composition,
      stitch_length,
      gauge,
      construction,
      unit_id,
    } = req.body;

    if (!code || !code.toString().trim()) {
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
      INSERT INTO master.fabrics (
        company_id,
        code,
        name,
        product_id,
        design_no,
        gsm,
        width_inches,
        composition,
        stitch_length,
        gauge,
        construction,
        unit_id,
        is_active
      )
      VALUES (
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        $9,
        $10,
        $11,
        $12,
        TRUE
      )
      RETURNING
        id,
        company_id,
        code,
        name,
        product_id,
        design_no,
        gsm,
        width_inches,
        composition,
        stitch_length,
        gauge,
        construction,
        unit_id,
        is_active,
        created_at,
        updated_at
      `,
      [
        COMPANY_ID,
        code.toString().trim(),
        name.toString().trim(),
        product_id || null,
        design_no || null,
        gsm === '' || gsm == null
          ? null
          : Number(gsm),
        width_inches === '' || width_inches == null
          ? null
          : Number(width_inches),
        composition || null,
        stitch_length === '' || stitch_length == null
          ? null
          : Number(stitch_length),
        gauge || null,
        construction || null,
        unit_id || null,
      ]
    );

    return res.status(201).json({
      success: true,
      fabric: mapFabric(result.rows[0]),
    });
  } catch (error) {
    console.error('Create fabric failed:', error);

    if (error.code === '23505') {
      return res.status(409).json({
        success: false,
        error: 'Fabric code already exists',
      });
    }

    return res.status(500).json({
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
      code,
      name,
      product_id,
      design_no,
      gsm,
      width_inches,
      composition,
      stitch_length,
      gauge,
      construction,
      unit_id,
      is_active,
    } = req.body;

    if (!code || !code.toString().trim()) {
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
      UPDATE master.fabrics
      SET
        code = $1,
        name = $2,
        product_id = $3,
        design_no = $4,
        gsm = $5,
        width_inches = $6,
        composition = $7,
        stitch_length = $8,
        gauge = $9,
        construction = $10,
        unit_id = $11,
        is_active = $12,
        updated_at = NOW()
      WHERE id = $13
        AND company_id = $14
      RETURNING
        id,
        company_id,
        code,
        name,
        product_id,
        design_no,
        gsm,
        width_inches,
        composition,
        stitch_length,
        gauge,
        construction,
        unit_id,
        is_active,
        created_at,
        updated_at
      `,
      [
        code.toString().trim(),
        name.toString().trim(),
        product_id || null,
        design_no || null,
        gsm === '' || gsm == null
          ? null
          : Number(gsm),
        width_inches === '' || width_inches == null
          ? null
          : Number(width_inches),
        composition || null,
        stitch_length === '' || stitch_length == null
          ? null
          : Number(stitch_length),
        gauge || null,
        construction || null,
        unit_id || null,
        is_active !== false,
        req.params.id,
        COMPANY_ID,
      ]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Fabric not found',
      });
    }

    return res.status(200).json({
      success: true,
      fabric: mapFabric(result.rows[0]),
    });
  } catch (error) {
    console.error('Update fabric failed:', error);

    if (error.code === '23505') {
      return res.status(409).json({
        success: false,
        error: 'Fabric code already exists',
      });
    }

    return res.status(500).json({
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
      UPDATE master.fabrics
      SET
        is_active = FALSE,
        updated_at = NOW()
      WHERE id = $1
        AND company_id = $2
      RETURNING id
      `,
      [req.params.id, COMPANY_ID]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Fabric not found',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Fabric deactivated',
    });
  } catch (error) {
    console.error('Deactivate fabric failed:', error);

    return res.status(500).json({
      success: false,
      error: 'Failed to deactivate fabric',
      details: error.message,
    });
  }
});

module.exports = router;