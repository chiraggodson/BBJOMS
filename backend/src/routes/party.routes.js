const express = require('express');
const router = express.Router();

const { pool } = require('../db');

const ALLOWED_ROLES = [
  'Customer',
  'Yarn Supplier',
  'Job Worker',
  'Processor',
  'Fabric Buyer',
  'Other',
];

function normalizeRoles(roles) {
  if (!Array.isArray(roles)) {
    return [];
  }

  return [
    ...new Set(
      roles
        .filter((role) => typeof role === 'string')
        .map((role) => role.trim())
        .filter(Boolean),
    ),
  ];
}

function validateRoles(roles) {
  return roles.every((role) => ALLOWED_ROLES.includes(role));
}

function normalizeParty(data) {
  return {
    name: typeof data.name === 'string' ? data.name.trim() : '',
    alias: typeof data.alias === 'string' ? data.alias.trim() : null,
    gstin: typeof data.gstin === 'string' ? data.gstin.trim().toUpperCase() : null,
    pan: typeof data.pan === 'string' ? data.pan.trim().toUpperCase() : null,
    address_line1:
      typeof data.address_line1 === 'string'
        ? data.address_line1.trim()
        : null,
    address_line2:
      typeof data.address_line2 === 'string'
        ? data.address_line2.trim()
        : null,
    city: typeof data.city === 'string' ? data.city.trim() : null,
    state: typeof data.state === 'string' ? data.state.trim() : null,
    pin_code:
      typeof data.pin_code === 'string' ? data.pin_code.trim() : null,
    country:
      typeof data.country === 'string' && data.country.trim()
        ? data.country.trim()
        : 'India',
    contact_person:
      typeof data.contact_person === 'string'
        ? data.contact_person.trim()
        : null,
    phone: typeof data.phone === 'string' ? data.phone.trim() : null,
    email: typeof data.email === 'string' ? data.email.trim() : null,
    is_active:
      typeof data.is_active === 'boolean' ? data.is_active : true,
    notes: typeof data.notes === 'string' ? data.notes.trim() : null,
  };
}

function generatePartyCode(id) {
  return `PTY${String(id).padStart(5, '0')}`;
}

/**
 * GET /api/parties
 *
 * Optional query parameters:
 * ?search=abc
 * ?role=Customer
 * ?active=true
 */
router.get('/', async (req, res) => {
  try {
    const search =
      typeof req.query.search === 'string'
        ? req.query.search.trim()
        : '';

    const role =
      typeof req.query.role === 'string'
        ? req.query.role.trim()
        : '';

    const active =
      typeof req.query.active === 'string'
        ? req.query.active.trim().toLowerCase()
        : '';

    const conditions = [];
    const values = [];

    if (search) {
      values.push(`%${search}%`);

      conditions.push(`
        (
          p.name ILIKE $${values.length}
          OR p.alias ILIKE $${values.length}
          OR p.party_code ILIKE $${values.length}
          OR p.city ILIKE $${values.length}
          OR p.gstin ILIKE $${values.length}
          OR p.phone ILIKE $${values.length}
        )
      `);
    }

    if (role) {
      values.push(role);
      conditions.push(`
        EXISTS (
          SELECT 1
          FROM party_roles pr_filter
          WHERE pr_filter.party_id = p.id
            AND pr_filter.role = $${values.length}
        )
      `);
    }

    if (active === 'true' || active === 'false') {
      values.push(active === 'true');
      conditions.push(`p.is_active = $${values.length}`);
    }

    const whereClause =
      conditions.length > 0
        ? `WHERE ${conditions.join(' AND ')}`
        : '';

    const query = `
      SELECT
        p.id,
        p.party_code,
        p.name,
        p.alias,
        p.gstin,
        p.pan,
        p.address_line1,
        p.address_line2,
        p.city,
        p.state,
        p.pin_code,
        p.country,
        p.contact_person,
        p.phone,
        p.email,
        p.is_active,
        p.notes,
        p.created_at,
        p.updated_at,
        COALESCE(
          ARRAY_AGG(pr.role ORDER BY pr.role)
          FILTER (WHERE pr.role IS NOT NULL),
          ARRAY[]::VARCHAR[]
        ) AS roles
      FROM parties p
      LEFT JOIN party_roles pr
        ON pr.party_id = p.id
      ${whereClause}
      GROUP BY p.id
      ORDER BY p.name ASC;
    `;

    const result = await pool.query(query, values);

    res.json({
      success: true,
      count: result.rows.length,
      parties: result.rows,
    });
  } catch (error) {
    console.error('Get parties failed:', error);

    res.status(500).json({
      success: false,
      error: 'Failed to fetch parties',
    });
  }
});

/**
 * GET /api/parties/stats
 */
router.get('/stats', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        COUNT(*)::INTEGER AS total_parties,
        COUNT(*) FILTER (WHERE is_active = TRUE)::INTEGER AS active_parties,
        COUNT(*) FILTER (WHERE is_active = FALSE)::INTEGER AS inactive_parties,
        (
          SELECT COUNT(DISTINCT party_id)::INTEGER
          FROM party_roles
          WHERE role = 'Customer'
        ) AS customers,
        (
          SELECT COUNT(DISTINCT party_id)::INTEGER
          FROM party_roles
          WHERE role = 'Yarn Supplier'
        ) AS yarn_suppliers,
        (
          SELECT COUNT(DISTINCT party_id)::INTEGER
          FROM party_roles
          WHERE role = 'Job Worker'
        ) AS job_workers,
        (
          SELECT COUNT(DISTINCT party_id)::INTEGER
          FROM party_roles
          WHERE role = 'Fabric Buyer'
        ) AS fabric_buyers
      FROM parties;
    `);

    res.json({
      success: true,
      stats: result.rows[0],
    });
  } catch (error) {
    console.error('Get party stats failed:', error);

    res.status(500).json({
      success: false,
      error: 'Failed to fetch party statistics',
    });
  }
});

/**
 * GET /api/parties/:id
 */
router.get('/:id', async (req, res) => {
  try {
    const id = Number(req.params.id);

    if (!Number.isInteger(id) || id <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Invalid party ID',
      });
    }

    const result = await pool.query(
      `
        SELECT
          p.id,
          p.party_code,
          p.name,
          p.alias,
          p.gstin,
          p.pan,
          p.address_line1,
          p.address_line2,
          p.city,
          p.state,
          p.pin_code,
          p.country,
          p.contact_person,
          p.phone,
          p.email,
          p.is_active,
          p.notes,
          p.created_at,
          p.updated_at,
          COALESCE(
            ARRAY_AGG(pr.role ORDER BY pr.role)
            FILTER (WHERE pr.role IS NOT NULL),
            ARRAY[]::VARCHAR[]
          ) AS roles
        FROM parties p
        LEFT JOIN party_roles pr
          ON pr.party_id = p.id
        WHERE p.id = $1
        GROUP BY p.id;
      `,
      [id],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Party not found',
      });
    }

    res.json({
      success: true,
      party: result.rows[0],
    });
  } catch (error) {
    console.error('Get party failed:', error);

    res.status(500).json({
      success: false,
      error: 'Failed to fetch party',
    });
  }
});

/**
 * POST /api/parties
 */
router.post('/', async (req, res) => {
  const client = await pool.connect();

  try {
    const party = normalizeParty(req.body);
    const roles = normalizeRoles(req.body.roles);

    if (!party.name) {
      return res.status(400).json({
        success: false,
        error: 'Party name is required',
      });
    }

    if (roles.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'At least one party role is required',
      });
    }

    if (!validateRoles(roles)) {
      return res.status(400).json({
        success: false,
        error: 'One or more party roles are invalid',
        allowed_roles: ALLOWED_ROLES,
      });
    }

    await client.query('BEGIN');

    const insertParty = await client.query(
      `
        INSERT INTO parties (
          party_code,
          name,
          alias,
          gstin,
          pan,
          address_line1,
          address_line2,
          city,
          state,
          pin_code,
          country,
          contact_person,
          phone,
          email,
          is_active,
          notes
        )
        VALUES (
          'TEMP',
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
          $11, $12, $13, $14, $15

          
        )
        RETURNING id;
      `,
      [
        party.name,
        party.alias,
        party.gstin,
        party.pan,
        party.address_line1,
        party.address_line2,
        party.city,
        party.state,
        party.pin_code,
        party.country,
        party.contact_person,
        party.phone,
        party.email,
        party.is_active,
        party.notes,
      ],
    );

    const partyId = insertParty.rows[0].id;
    const partyCode = generatePartyCode(partyId);

    await client.query(
      `
        UPDATE parties
        SET party_code = $1,
            updated_at = NOW()
        WHERE id = $2;
      `,
      [partyCode, partyId],
    );

    for (const partyRole of roles) {
      await client.query(
        `
          INSERT INTO party_roles (party_id, role)
          VALUES ($1, $2);
        `,
        [partyId, partyRole],
      );
    }

    const result = await client.query(
      `
        SELECT
          p.id,
          p.party_code,
          p.name,
          p.alias,
          p.gstin,
          p.pan,
          p.address_line1,
          p.address_line2,
          p.city,
          p.state,
          p.pin_code,
          p.country,
          p.contact_person,
          p.phone,
          p.email,
          p.is_active,
          p.notes,
          p.created_at,
          p.updated_at,
          COALESCE(
            ARRAY_AGG(pr.role ORDER BY pr.role)
            FILTER (WHERE pr.role IS NOT NULL),
            ARRAY[]::VARCHAR[]
          ) AS roles
        FROM parties p
        LEFT JOIN party_roles pr
          ON pr.party_id = p.id
        WHERE p.id = $1
        GROUP BY p.id;
      `,
      [partyId],
    );

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      message: 'Party created successfully',
      party: result.rows[0],
    });
  } catch (error) {
    await client.query('ROLLBACK');

    console.error('Create party failed:', error);

    res.status(500).json({
      success: false,
      error: 'Failed to create party',
    });
  } finally {
    client.release();
  }
});

/**
 * PUT /api/parties/:id
 */
router.put('/:id', async (req, res) => {
  const client = await pool.connect();

  try {
    const id = Number(req.params.id);

    if (!Number.isInteger(id) || id <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Invalid party ID',
      });
    }

    const party = normalizeParty(req.body);
    const roles = normalizeRoles(req.body.roles);

    if (!party.name) {
      return res.status(400).json({
        success: false,
        error: 'Party name is required',
      });
    }

    if (roles.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'At least one party role is required',
      });
    }

    if (!validateRoles(roles)) {
      return res.status(400).json({
        success: false,
        error: 'One or more party roles are invalid',
        allowed_roles: ALLOWED_ROLES,
      });
    }

    await client.query('BEGIN');

    const existing = await client.query(
      `SELECT id FROM parties WHERE id = $1 FOR UPDATE;`,
      [id],
    );

    if (existing.rows.length === 0) {
      await client.query('ROLLBACK');

      return res.status(404).json({
        success: false,
        error: 'Party not found',
      });
    }

    await client.query(
      `
        UPDATE parties
        SET
          name = $1,
          alias = $2,
          gstin = $3,
          pan = $4,
          address_line1 = $5,
          address_line2 = $6,
          city = $7,
          state = $8,
          pin_code = $9,
          country = $10,
          contact_person = $11,
          phone = $12,
          email = $13,
          is_active = $14,
          notes = $15,
          updated_at = NOW()
        WHERE id = $16;
      `,
      [
        party.name,
        party.alias,
        party.gstin,
        party.pan,
        party.address_line1,
        party.address_line2,
        party.city,
        party.state,
        party.pin_code,
        party.country,
        party.contact_person,
        party.phone,
        party.email,
        party.is_active,
        party.notes,
        id,
      ],
    );

    await client.query(
      `DELETE FROM party_roles WHERE party_id = $1;`,
      [id],
    );

    for (const partyRole of roles) {
      await client.query(
        `
          INSERT INTO party_roles (party_id, role)
          VALUES ($1, $2);
        `,
        [id, partyRole],
      );
    }

    const result = await client.query(
      `
        SELECT
          p.id,
          p.party_code,
          p.name,
          p.alias,
          p.gstin,
          p.pan,
          p.address_line1,
          p.address_line2,
          p.city,
          p.state,
          p.pin_code,
          p.country,
          p.contact_person,
          p.phone,
          p.email,
          p.is_active,
          p.notes,
          p.created_at,
          p.updated_at,
          COALESCE(
            ARRAY_AGG(pr.role ORDER BY pr.role)
            FILTER (WHERE pr.role IS NOT NULL),
            ARRAY[]::VARCHAR[]
          ) AS roles
        FROM parties p
        LEFT JOIN party_roles pr
          ON pr.party_id = p.id
        WHERE p.id = $1
        GROUP BY p.id;
      `,
      [id],
    );

    await client.query('COMMIT');

    res.json({
      success: true,
      message: 'Party updated successfully',
      party: result.rows[0],
    });
  } catch (error) {
    await client.query('ROLLBACK');

    console.error('Update party failed:', error);

    res.status(500).json({
      success: false,
      error: 'Failed to update party',
    });
  } finally {
    client.release();
  }
});

/**
 * DELETE /api/parties/:id
 *
 * For now this performs a soft delete by setting is_active=false.
 * We do not physically delete parties because future transactions
 * will depend on their historical identity.
 */
router.delete('/:id', async (req, res) => {
  try {
    const id = Number(req.params.id);

    if (!Number.isInteger(id) || id <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Invalid party ID',
      });
    }

    const result = await pool.query(
      `
        UPDATE parties
        SET
          is_active = FALSE,
          updated_at = NOW()
        WHERE id = $1
        RETURNING id, party_code, name, is_active;
      `,
      [id],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Party not found',
      });
    }

    res.json({
      success: true,
      message: 'Party deactivated successfully',
      party: result.rows[0],
    });
  } catch (error) {
    console.error('Delete party failed:', error);

    res.status(500).json({
      success: false,
      error: 'Failed to deactivate party',
    });
  }
});

module.exports = router;