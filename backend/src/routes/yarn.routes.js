
const express = require('express');
const router = express.Router();
const { pool } = require('../db');

const COMPANY_ID = '63558a5c-3815-4d4f-9f0d-7edfdf5d3f11';

function clean(value) {
  return value == null ? '' : String(value).trim();
}

const YARN_SELECT = `
  SELECT
    y.id,
    y.company_id,
    y.code,
    y.name,
    y.yarn_type_id,
    COALESCE(yt.name, '') AS yarn_type_name,
    y.unit_id,
    y.description,
    y.is_active,
    y.created_at,
    y.updated_at
  FROM master.yarns y
  LEFT JOIN master.yarn_types yt ON yt.id=y.yarn_type_id
`;

function mapYarn(row) {
  return {
    id: row.id ? String(row.id) : null,
    company_id: row.company_id ? String(row.company_id) : null,
    code: row.code || '',
    name: row.name || '',
    yarn_name: row.name || '',
    // Compatibility fields for the current Flutter UI.
    count: '',
    yarn_count: '',
    composition: '',
    colour: '',
    yarn_type_id: row.yarn_type_id ? String(row.yarn_type_id) : null,
    yarn_type_name: row.yarn_type_name || '',
    unit_id: row.unit_id ? String(row.unit_id) : null,
    description: row.description || '',
    is_active: row.is_active === true,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

router.get('/', async (req, res) => {
  try {
    const search = clean(req.query.search);
    const values = [COMPANY_ID];
    let where = `(y.company_id=$1 OR y.company_id IS NULL) AND COALESCE(y.is_active,true)=true`;

    if (search) {
      values.push(`%${search}%`);
      const n = values.length;
      where += ` AND (
        y.code ILIKE $${n}
        OR y.name ILIKE $${n}
        OR COALESCE(yt.name,'') ILIKE $${n}
      )`;
    }

    const result = await pool.query(`
      ${YARN_SELECT}
      WHERE ${where}
      ORDER BY y.name ASC, y.code ASC
    `, values);

    res.json(result.rows.map(mapYarn));
  } catch (error) {
    console.error('Get yarns failed:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to load yarns',
      details: error.message,
    });
  }
});

router.get('/colors', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT id, code, name, description, is_active, created_at, updated_at
      FROM master.colors
      WHERE COALESCE(is_active,true)=true
      ORDER BY name ASC
    `);
    res.json(result.rows);
  } catch (error) {
    console.error('Get colors failed:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to load colors',
      details: error.message,
    });
  }
});

router.post('/colors', async (req, res) => {
  try {
    const name = clean(req.body?.name);
    const description = clean(req.body?.description) || null;

    if (!name) {
      return res.status(400).json({
        success: false,
        error: 'Color name is required',
      });
    }

    const duplicate = await pool.query(`
      SELECT id FROM master.colors
      WHERE LOWER(TRIM(name))=LOWER(TRIM($1))
      LIMIT 1
    `, [name]);

    if (duplicate.rows.length) {
      return res.status(409).json({
        success: false,
        error: 'Color already exists',
      });
    }

    const next = await pool.query(`
      SELECT COALESCE(MAX(
        CASE
          WHEN code ~ '^COL-[0-9]+$'
          THEN CAST(SUBSTRING(code FROM '[0-9]+$') AS INTEGER)
          ELSE 0
        END
      ),0)+1 AS next_no
      FROM master.colors
    `);

    const code = clean(req.body?.code) ||
      `COL-${String(Number(next.rows[0].next_no)).padStart(4,'0')}`;

    const result = await pool.query(`
      INSERT INTO master.colors(code,name,description,is_active)
      VALUES($1,$2,$3,true)
      RETURNING id,code,name,description,is_active,created_at,updated_at
    `, [code,name,description]);

    res.status(201).json({
      success: true,
      color: result.rows[0],
    });
  } catch (error) {
    console.error('Create color failed:', error);
    res.status(error.code === '23505' ? 409 : 500).json({
      success: false,
      error: error.code === '23505' ? 'Color code already exists' : 'Failed to create color',
      details: error.message,
    });
  }
});

router.put('/colors/:id', async (req, res) => {
  try {
    const name = clean(req.body?.name);
    const description = clean(req.body?.description) || null;
    if (!name) {
      return res.status(400).json({ success:false,error:'Color name is required' });
    }

    const result = await pool.query(`
      UPDATE master.colors
      SET name=$1, description=$2, is_active=$3, updated_at=NOW()
      WHERE id=$4
      RETURNING id,code,name,description,is_active,created_at,updated_at
    `, [name,description,req.body?.is_active !== false,req.params.id]);

    if (!result.rows.length) {
      return res.status(404).json({ success:false,error:'Color not found' });
    }

    res.json({ success:true,color:result.rows[0] });
  } catch (error) {
    console.error('Update color failed:', error);
    res.status(500).json({ success:false,error:'Failed to update color',details:error.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query(`
      ${YARN_SELECT}
      WHERE y.id=$1
        AND (y.company_id=$2 OR y.company_id IS NULL)
      LIMIT 1
    `, [req.params.id,COMPANY_ID]);

    if (!result.rows.length) {
      return res.status(404).json({ success:false,error:'Yarn not found' });
    }

    res.json(mapYarn(result.rows[0]));
  } catch (error) {
    console.error('Get yarn failed:', error);
    res.status(500).json({ success:false,error:'Failed to load yarn',details:error.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const code = clean(req.body?.code);
    const name = clean(req.body?.name);
    const yarnTypeId = clean(req.body?.yarn_type_id);
    const unitId = clean(req.body?.unit_id);
    const description = clean(req.body?.description) || null;

    if (!code || !name) {
      return res.status(400).json({
        success:false,
        error:'Yarn code and name are required',
      });
    }

    const result = await pool.query(`
      INSERT INTO master.yarns(
        company_id,code,name,yarn_type_id,unit_id,description,is_active
      )
      VALUES($1,$2,$3,$4,$5,$6,true)
      RETURNING id
    `, [COMPANY_ID,code,name,yarnTypeId || null,unitId || null,description]);

    const full = await pool.query(`
      ${YARN_SELECT}
      WHERE y.id=$1
    `, [result.rows[0].id]);

    res.status(201).json({
      success:true,
      yarn:mapYarn(full.rows[0]),
    });
  } catch (error) {
    console.error('Create yarn failed:', error);
    res.status(error.code === '23505' ? 409 : 500).json({
      success:false,
      error:error.code === '23505' ? 'Yarn code already exists' : 'Failed to create yarn',
      details:error.message,
    });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const code = clean(req.body?.code);
    const name = clean(req.body?.name);
    const yarnTypeId = clean(req.body?.yarn_type_id);
    const unitId = clean(req.body?.unit_id);
    const description = clean(req.body?.description) || null;

    if (!code || !name) {
      return res.status(400).json({
        success:false,
        error:'Yarn code and name are required',
      });
    }

    const result = await pool.query(`
      UPDATE master.yarns
      SET
        code=$1,
        name=$2,
        yarn_type_id=$3,
        unit_id=$4,
        description=$5,
        is_active=$6,
        updated_at=NOW()
      WHERE id=$7
        AND (company_id=$8 OR company_id IS NULL)
      RETURNING id
    `, [
      code,name,yarnTypeId || null,unitId || null,description,
      req.body?.is_active !== false,req.params.id,COMPANY_ID
    ]);

    if (!result.rows.length) {
      return res.status(404).json({ success:false,error:'Yarn not found' });
    }

    const full = await pool.query(`
      ${YARN_SELECT}
      WHERE y.id=$1
    `, [req.params.id]);

    res.json({ success:true,yarn:mapYarn(full.rows[0]) });
  } catch (error) {
    console.error('Update yarn failed:', error);
    res.status(error.code === '23505' ? 409 : 500).json({
      success:false,
      error:error.code === '23505' ? 'Yarn code already exists' : 'Failed to update yarn',
      details:error.message,
    });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const result = await pool.query(`
      UPDATE master.yarns
      SET is_active=false,updated_at=NOW()
      WHERE id=$1
        AND (company_id=$2 OR company_id IS NULL)
      RETURNING id,code,name,is_active
    `, [req.params.id,COMPANY_ID]);

    if (!result.rows.length) {
      return res.status(404).json({ success:false,error:'Yarn not found' });
    }

    res.json({
      success:true,
      message:'Yarn deactivated successfully',
      yarn:result.rows[0],
    });
  } catch (error) {
    console.error('Delete yarn failed:', error);
    res.status(500).json({
      success:false,
      error:'Failed to deactivate yarn',
      details:error.message,
    });
  }
});

module.exports = router;
