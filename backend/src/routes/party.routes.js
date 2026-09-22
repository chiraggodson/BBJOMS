const express = require('express');
const router = express.Router();
const { pool } = require('../db');

const COMPANY_ID = '37c8cd03-c8ae-48cd-b8e4-cb3e864f042f';

const ALLOWED_ROLES = [
  'Customer',
  'Yarn Supplier',
  'Job Worker',
  'Processor',
  'Fabric Buyer',
  'Other',
];

function normalizeRoles(roles) {
  if (!Array.isArray(roles)) return [];
  return [...new Set(roles.filter(r => typeof r === 'string').map(r => r.trim()).filter(Boolean))];
}

function validateRoles(roles) {
  return roles.every(role => ALLOWED_ROLES.includes(role));
}

function normalizeParty(data = {}) {
  return {
    code: typeof data.code === 'string' ? data.code.trim() : '',
    name: typeof data.name === 'string' ? data.name.trim() : '',
    alias: typeof data.alias === 'string' ? data.alias.trim() : null,
    gstin: typeof data.gstin === 'string' ? data.gstin.trim().toUpperCase() : null,
    pan: typeof data.pan === 'string' ? data.pan.trim().toUpperCase() : null,
    address_line1: typeof data.address_line1 === 'string' ? data.address_line1.trim() : null,
    address_line2: typeof data.address_line2 === 'string' ? data.address_line2.trim() : null,
    city: typeof data.city === 'string' ? data.city.trim() : null,
    state: typeof data.state === 'string' ? data.state.trim() : null,
    pin_code: typeof data.pin_code === 'string' ? data.pin_code.trim() : null,
    country: typeof data.country === 'string' && data.country.trim() ? data.country.trim() : 'India',
    contact_person: typeof data.contact_person === 'string' ? data.contact_person.trim() : null,
    phone: typeof data.phone === 'string' ? data.phone.trim() : null,
    email: typeof data.email === 'string' ? data.email.trim() : null,
    is_active: typeof data.is_active === 'boolean' ? data.is_active : true,
    notes: typeof data.notes === 'string' ? data.notes.trim() : null,
  };
}

async function ensureRole(client, roleName) {
  const code = roleName.toUpperCase().replace(/[^A-Z0-9]+/g, '_');
  const result = await client.query(`
    INSERT INTO master.party_roles (code, name)
    VALUES ($1, $2)
    ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name
    RETURNING id
  `, [code, roleName]);
  return result.rows[0].id;
}

async function fetchParty(client, id) {
  const result = await client.query(`
    SELECT
      p.id, p.code, p.name, p.alias, p.gstin, p.pan,
      p.address_line1, p.address_line2, p.city, p.state,
      p.pincode AS pin_code, p.country,
      p.contact_person, p.phone, p.email, p.is_active, p.notes,
      p.created_at, p.updated_at,
      COALESCE(
        ARRAY_AGG(pr.name ORDER BY pr.name)
        FILTER (WHERE pr.name IS NOT NULL),
        ARRAY[]::text[]
      ) AS roles
    FROM master.parties p
    LEFT JOIN master.party_role_assignments pra ON pra.party_id = p.id
    LEFT JOIN master.party_roles pr ON pr.id = pra.role_id
    WHERE p.id = $1 AND p.company_id = $2
    GROUP BY p.id
  `, [id, COMPANY_ID]);
  return result.rows[0] || null;
}

router.get('/', async (req, res) => {
  try {
    const search = typeof req.query.search === 'string' ? req.query.search.trim() : '';
    const role = typeof req.query.role === 'string' ? req.query.role.trim() : '';
    const active = typeof req.query.active === 'string' ? req.query.active.trim().toLowerCase() : '';

    const values = [COMPANY_ID];
    const conditions = ['p.company_id = $1'];

    if (search) {
      values.push(`%${search}%`);
      conditions.push(`(
        p.name ILIKE $${values.length}
        OR COALESCE(p.alias, '') ILIKE $${values.length}
        OR COALESCE(p.code, '') ILIKE $${values.length}
        OR COALESCE(p.city, '') ILIKE $${values.length}
        OR COALESCE(p.gstin, '') ILIKE $${values.length}
        OR COALESCE(p.phone, '') ILIKE $${values.length}
      )`);
    }

    if (role) {
      values.push(role);
      conditions.push(`EXISTS (
        SELECT 1
        FROM master.party_role_assignments pra2
        JOIN master.party_roles pr2 ON pr2.id = pra2.role_id
        WHERE pra2.party_id = p.id
          AND LOWER(pr2.name) = LOWER($${values.length})
      )`);
    }

    if (active === 'true' || active === 'false') {
      values.push(active === 'true');
      conditions.push(`p.is_active = $${values.length}`);
    }

    const result = await pool.query(`
      SELECT
        p.id, p.code AS party_code, p.name, p.alias, p.gstin, p.pan,
        p.address_line1, p.address_line2, p.city, p.state,
        p.pincode AS pin_code, p.country,
        p.contact_person, p.phone, p.email, p.is_active, p.notes,
        p.created_at, p.updated_at,
        COALESCE(
          ARRAY_AGG(pr.name ORDER BY pr.name)
          FILTER (WHERE pr.name IS NOT NULL),
          ARRAY[]::text[]
        ) AS roles
      FROM master.parties p
      LEFT JOIN master.party_role_assignments pra ON pra.party_id = p.id
      LEFT JOIN master.party_roles pr ON pr.id = pra.role_id
      WHERE ${conditions.join(' AND ')}
      GROUP BY p.id
      ORDER BY p.name ASC
    `, values);

    return res.json({ success: true, count: result.rows.length, parties: result.rows });
  } catch (error) {
    console.error('Get parties failed:', error);
    return res.status(500).json({ success: false, error: 'Failed to fetch parties', details: error.message });
  }
});

router.get('/stats', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        COUNT(*)::integer AS total_parties,
        COUNT(*) FILTER (WHERE p.is_active)::integer AS active_parties,
        COUNT(*) FILTER (WHERE NOT p.is_active)::integer AS inactive_parties,
        COUNT(DISTINCT p.id) FILTER (WHERE LOWER(pr.name) = 'customer')::integer AS customers,
        COUNT(DISTINCT p.id) FILTER (WHERE LOWER(pr.name) = 'yarn supplier')::integer AS yarn_suppliers,
        COUNT(DISTINCT p.id) FILTER (WHERE LOWER(pr.name) = 'job worker')::integer AS job_workers,
        COUNT(DISTINCT p.id) FILTER (WHERE LOWER(pr.name) = 'fabric buyer')::integer AS fabric_buyers
      FROM master.parties p
      LEFT JOIN master.party_role_assignments pra ON pra.party_id = p.id
      LEFT JOIN master.party_roles pr ON pr.id = pra.role_id
      WHERE p.company_id = $1
    `, [COMPANY_ID]);
    return res.json({ success: true, stats: result.rows[0] });
  } catch (error) {
    console.error('Get party stats failed:', error);
    return res.status(500).json({ success: false, error: 'Failed to fetch party statistics', details: error.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const party = await fetchParty(pool, req.params.id);
    if (!party) return res.status(404).json({ success: false, error: 'Party not found' });
    return res.json({ success: true, party });
  } catch (error) {
    console.error('Get party failed:', error);
    return res.status(500).json({ success: false, error: 'Failed to fetch party', details: error.message });
  }
});

router.post('/', async (req, res) => {
  const client = await pool.connect();
  try {
    const party = normalizeParty(req.body);
    const roles = normalizeRoles(req.body.roles);

    if (!party.name) return res.status(400).json({ success: false, error: 'Party name is required' });
    if (!roles.length) return res.status(400).json({ success: false, error: 'At least one party role is required' });
    if (!validateRoles(roles)) return res.status(400).json({ success: false, error: 'One or more party roles are invalid', allowed_roles: ALLOWED_ROLES });

    await client.query('BEGIN');

    let code = party.code;
    if (!code) {
      const next = await client.query(`
        SELECT COALESCE(MAX(
          CASE WHEN code ~ '^PTY[0-9]+$'
          THEN CAST(SUBSTRING(code FROM '[0-9]+$') AS BIGINT) ELSE 0 END
        ), 0) + 1 AS next_no
        FROM master.parties
        WHERE company_id = $1
      `, [COMPANY_ID]);
      code = `PTY${String(Number(next.rows[0].next_no)).padStart(5, '0')}`;
    }

    const inserted = await client.query(`
      INSERT INTO master.parties (
        company_id, code, name, alias, gstin, pan,
        address_line1, address_line2, city, state, pincode,
        country, contact_person, phone, email, is_active, notes
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17)
      RETURNING id
    `, [
      COMPANY_ID, code, party.name, party.alias, party.gstin, party.pan,
      party.address_line1, party.address_line2, party.city, party.state,
      party.pin_code, party.country, party.contact_person,
      party.phone, party.email, party.is_active, party.notes
    ]);

    const partyId = inserted.rows[0].id;

    for (const role of roles) {
      const roleId = await ensureRole(client, role);
      await client.query(`
        INSERT INTO master.party_role_assignments (party_id, role_id)
        VALUES ($1, $2)
        ON CONFLICT DO NOTHING
      `, [partyId, roleId]);
    }

    await client.query('COMMIT');
    const created = await fetchParty(pool, partyId);
    return res.status(201).json({ success: true, message: 'Party created successfully', party: created });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Create party failed:', error);
    return res.status(error.code === '23505' ? 409 : 500).json({
      success: false,
      error: error.code === '23505' ? 'Party code already exists' : 'Failed to create party',
      details: error.message
    });
  } finally {
    client.release();
  }
});

router.put('/:id', async (req, res) => {
  const client = await pool.connect();
  try {
    const party = normalizeParty(req.body);
    const roles = normalizeRoles(req.body.roles);

    if (!party.name) return res.status(400).json({ success: false, error: 'Party name is required' });
    if (!roles.length) return res.status(400).json({ success: false, error: 'At least one party role is required' });
    if (!validateRoles(roles)) return res.status(400).json({ success: false, error: 'One or more party roles are invalid', allowed_roles: ALLOWED_ROLES });

    await client.query('BEGIN');

    const existing = await client.query(`
      SELECT id FROM master.parties
      WHERE id = $1 AND company_id = $2
      FOR UPDATE
    `, [req.params.id, COMPANY_ID]);

    if (!existing.rows.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ success: false, error: 'Party not found' });
    }

    await client.query(`
      UPDATE master.parties SET
        name=$1, alias=$2, gstin=$3, pan=$4,
        address_line1=$5, address_line2=$6, city=$7, state=$8,
        pincode=$9, country=$10, contact_person=$11, phone=$12,
        email=$13, is_active=$14, notes=$15, updated_at=NOW()
      WHERE id=$16 AND company_id=$17
    `, [
      party.name, party.alias, party.gstin, party.pan,
      party.address_line1, party.address_line2, party.city, party.state,
      party.pin_code, party.country, party.contact_person,
      party.phone, party.email, party.is_active, party.notes, req.params.id, COMPANY_ID
    ]);

    await client.query(`DELETE FROM master.party_role_assignments WHERE party_id = $1`, [req.params.id]);
    for (const role of roles) {
      const roleId = await ensureRole(client, role);
      await client.query(`
        INSERT INTO master.party_role_assignments (party_id, role_id)
        VALUES ($1,$2) ON CONFLICT DO NOTHING
      `, [req.params.id, roleId]);
    }

    await client.query('COMMIT');
    const updated = await fetchParty(pool, req.params.id);
    return res.json({ success: true, message: 'Party updated successfully', party: updated });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Update party failed:', error);
    return res.status(500).json({ success: false, error: 'Failed to update party', details: error.message });
  } finally {
    client.release();
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const result = await pool.query(`
      UPDATE master.parties
      SET is_active = FALSE, updated_at = NOW()
      WHERE id = $1 AND company_id = $2
      RETURNING id, code AS party_code, name, is_active
    `, [req.params.id, COMPANY_ID]);

    if (!result.rows.length) return res.status(404).json({ success: false, error: 'Party not found' });
    return res.json({ success: true, message: 'Party deactivated successfully', party: result.rows[0] });
  } catch (error) {
    console.error('Delete party failed:', error);
    return res.status(500).json({ success: false, error: 'Failed to deactivate party', details: error.message });
  }
});

module.exports = router;
