const express = require('express');
const { pool } = require('../db');

const router = express.Router();

/*
 * BBJOMS JOB ORDERS API
 *
 * Current database tables:
 *
 *   job_orders
 *   job_order_machines
 *   job_order_yarns
 *   job_production
 *   parties
 *
 * This version DOES NOT depend on:
 *
 *   fabrics
 *   machines
 *   yarn_master
 *
 * because those tables are not currently present in the database.
 */

// ============================================================
// HELPERS
// ============================================================

function toNumber(value, fallback = 0) {
  if (value === null || value === undefined || value === '') {
    return fallback;
  }

  const number = Number(value);

  return Number.isFinite(number) ? number : fallback;
}

function cleanString(value) {
  if (value === null || value === undefined) {
    return '';
  }

  return String(value).trim();
}

function normaliseMachines(value) {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((item) => {
      if (typeof item === 'object' && item !== null) {
        return toNumber(
          item.machine_id ?? item.machineId ?? item.id,
          0,
        );
      }

      return toNumber(item, 0);
    })
    .filter((id) => id > 0);
}

function normaliseYarns(value) {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((item) => ({
      yarn_name: cleanString(
        item?.yarn_name ?? item?.yarnName,
      ),

      yarn_count: cleanString(
        item?.yarn_count ?? item?.yarnCount,
      ),

      required_kg: toNumber(
        item?.required_kg ?? item?.requiredKg,
      ),

      issued_kg: toNumber(
        item?.issued_kg ?? item?.issuedKg,
      ),

      returned_kg: toNumber(
        item?.returned_kg ?? item?.returnedKg,
      ),

      waste_kg: toNumber(
        item?.waste_kg ?? item?.wasteKg,
      ),
    }))
    .filter(
      (yarn) =>
        yarn.yarn_name ||
        yarn.yarn_count ||
        yarn.required_kg > 0,
    );
}

// ============================================================
// GET COMPLETE JOB BY ID
// ============================================================

async function getJobById(db, id) {
  const jobResult = await db.query(
    `
    SELECT
      j.id,
      j.job_no,
      j.job_date,
      j.party_id,
      COALESCE(p.name, '') AS party_name,
      j.fabric_name,
      j.design_no,
      j.gsm,
      j.order_quantity,
      COALESCE(j.status, 'Open') AS status,
      j.stitch_length,
      j.notes,
      j.created_at,
      j.updated_at,

      COALESCE(
        (
          SELECT SUM(jp.quantity_kg)
          FROM job_production jp
          WHERE jp.job_order_id = j.id
        ),
        0
      ) AS produced_quantity,

      GREATEST(
        j.order_quantity -
        COALESCE(
          (
            SELECT SUM(jp.quantity_kg)
            FROM job_production jp
            WHERE jp.job_order_id = j.id
          ),
          0
        ),
        0
      ) AS remaining_quantity

    FROM job_orders j

    LEFT JOIN parties p
      ON p.id = j.party_id

    WHERE j.id = $1

    LIMIT 1
    `,
    [id],
  );

  if (jobResult.rows.length === 0) {
    return null;
  }

  const job = jobResult.rows[0];

  const machineResult = await db.query(
    `
    SELECT
      machine_id
    FROM job_order_machines
    WHERE job_order_id = $1
    ORDER BY id
    `,
    [id],
  );

  const yarnResult = await db.query(
    `
    SELECT
      id,
      job_order_id,
      yarn_name,
      yarn_count,
      required_kg,
      issued_kg,
      returned_kg,
      waste_kg
    FROM job_order_yarns
    WHERE job_order_id = $1
    ORDER BY id
    `,
    [id],
  );

  const productionResult = await db.query(
    `
    SELECT
      id,
      job_order_id,
      machine_id,
      production_date,
      roll_no,
      quantity_kg,
      remarks,
      created_at
    FROM job_production
    WHERE job_order_id = $1
    ORDER BY
      production_date DESC NULLS LAST,
      id DESC
    `,
    [id],
  );

  const machineIds = machineResult.rows
    .map((row) => toNumber(row.machine_id, 0))
    .filter((id) => id > 0);

  return {
    id: Number(job.id),

    jobNo: job.job_no || '',

    jobDate: job.job_date,

    partyId:
      job.party_id === null
        ? null
        : Number(job.party_id),

    partyName: job.party_name || '',

    fabricName: job.fabric_name || '',

    designNo: job.design_no || '',

    gsm: toNumber(job.gsm),

    orderQuantity:
      toNumber(job.order_quantity),

    producedQuantity:
      toNumber(job.produced_quantity),

    remainingQuantity:
      toNumber(job.remaining_quantity),

    status: job.status || 'Open',

    stitchLength:
      toNumber(job.stitch_length),

    notes: job.notes || '',

    machineIds,

    machineNumbers:
      machineIds.length > 0
        ? machineIds.join(', ')
        : '',

    yarns: yarnResult.rows.map((yarn) => ({
      id: Number(yarn.id),

      jobOrderId:
        Number(yarn.job_order_id),

      yarnName:
        yarn.yarn_name || '',

      yarnCount:
        yarn.yarn_count || '',

      requiredKg:
        toNumber(yarn.required_kg),

      issuedKg:
        toNumber(yarn.issued_kg),

      returnedKg:
        toNumber(yarn.returned_kg),

      wasteKg:
        toNumber(yarn.waste_kg),
    })),

    production:
      productionResult.rows.map((item) => ({
        id: Number(item.id),

        jobOrderId:
          Number(item.job_order_id),

        machineId:
          item.machine_id === null
            ? null
            : Number(item.machine_id),

        productionDate:
          item.production_date,

        rollNo:
          item.roll_no || '',

        quantityKg:
          toNumber(item.quantity_kg),

        remarks:
          item.remarks || '',

        createdAt:
          item.created_at,
      })),
  };
}

// ============================================================
// GET /api/jobs
// JOB ORDER REGISTER
// ============================================================

router.get('/', async (req, res) => {
  try {
    const search =
      cleanString(req.query.search);

    const status =
      cleanString(req.query.status);

    const partyId =
      toNumber(req.query.party_id, 0);

    const values = [];
    const conditions = [];

    if (search) {
      values.push(`%${search}%`);

      const parameter =
        `$${values.length}`;

      conditions.push(`
        (
          j.job_no ILIKE ${parameter}
          OR COALESCE(p.name, '') ILIKE ${parameter}
          OR COALESCE(j.fabric_name, '') ILIKE ${parameter}
          OR COALESCE(j.status, '') ILIKE ${parameter}
          OR COALESCE(j.design_no, '') ILIKE ${parameter}
        )
      `);
    }

    if (status && status.toLowerCase() !== 'all') {
      values.push(status);

      conditions.push(
        `j.status = $${values.length}`,
      );
    }

    if (partyId > 0) {
      values.push(partyId);

      conditions.push(
        `j.party_id = $${values.length}`,
      );
    }

    const where =
      conditions.length > 0
        ? `WHERE ${conditions.join(' AND ')}`
        : '';

    const result = await pool.query(
      `
      SELECT
        j.id,
        j.job_no,
        j.job_date,
        j.party_id,

        COALESCE(
          p.name,
          ''
        ) AS party_name,

        j.fabric_name,
        j.design_no,
        j.gsm,
        j.order_quantity,

        COALESCE(
          j.status,
          'Open'
        ) AS status,

        j.stitch_length,
        j.notes,
        j.created_at,
        j.updated_at,

        COALESCE(
          (
            SELECT SUM(
              jp.quantity_kg
            )
            FROM job_production jp
            WHERE jp.job_order_id = j.id
          ),
          0
        ) AS produced_quantity,

        GREATEST(
          j.order_quantity -
          COALESCE(
            (
              SELECT SUM(
                jp.quantity_kg
              )
              FROM job_production jp
              WHERE jp.job_order_id = j.id
            ),
            0
          ),
          0
        ) AS remaining_quantity,

        COALESCE(
          (
            SELECT ARRAY_AGG(
              DISTINCT jom.machine_id
            )
            FROM job_order_machines jom
            WHERE jom.job_order_id = j.id
              AND jom.machine_id IS NOT NULL
          ),
          ARRAY[]::bigint[]
        ) AS machine_ids

      FROM job_orders j

      LEFT JOIN parties p
        ON p.id = j.party_id

      ${where}

      ORDER BY
        j.job_date DESC NULLS LAST,
        j.id DESC
      `,
      values,
    );

    const jobs = result.rows.map((job) => {
      const machineIds =
        Array.isArray(job.machine_ids)
          ? job.machine_ids
              .map((id) => Number(id))
              .filter((id) => id > 0)
          : [];

      return {
        id: Number(job.id),

        jobNo:
          job.job_no || '',

        jobDate:
          job.job_date,

        partyId:
          job.party_id === null
            ? null
            : Number(job.party_id),

        partyName:
          job.party_name || '',

        fabricName:
          job.fabric_name || '',

        designNo:
          job.design_no || '',

        gsm:
          toNumber(job.gsm),

        orderQuantity:
          toNumber(job.order_quantity),

        producedQuantity:
          toNumber(job.produced_quantity),

        remainingQuantity:
          toNumber(job.remaining_quantity),

        status:
          job.status || 'Open',

        stitchLength:
          toNumber(job.stitch_length),

        notes:
          job.notes || '',

        machineIds,

        machineNumbers:
          machineIds.length > 0
            ? machineIds.join(', ')
            : '',

        createdAt:
          job.created_at,

        updatedAt:
          job.updated_at,
      };
    });

    res.json({
      success: true,
      jobs,
    });
  } catch (error) {
    console.error(
      'Get jobs failed:',
      error,
    );

    res.status(500).json({
      success: false,
      error:
        error.message ||
        'Failed to load job orders',
    });
  }
});

// ============================================================
// GET /api/jobs/:id
// COMPLETE JOB DETAILS
// ============================================================

router.get('/:id', async (req, res) => {
  const id =
    Number(req.params.id);

  if (
    !Number.isInteger(id) ||
    id <= 0
  ) {
    return res.status(400).json({
      success: false,
      error: 'Invalid job ID',
    });
  }

  try {
    const job =
      await getJobById(
        pool,
        id,
      );

    if (!job) {
      return res.status(404).json({
        success: false,
        error:
          'Job order not found',
      });
    }

    res.json({
      success: true,
      job,
    });
  } catch (error) {
    console.error(
      'Get job details failed:',
      error,
    );

    res.status(500).json({
      success: false,
      error:
        error.message ||
        'Failed to load job details',
    });
  }
});

// ============================================================
// GET /api/jobs/details/:id
// COMPATIBILITY ENDPOINT FOR FLUTTER
// ============================================================

router.get(
  '/details/:id',
  async (req, res) => {
    const id =
      Number(req.params.id);

    if (
      !Number.isInteger(id) ||
      id <= 0
    ) {
      return res.status(400).json({
        success: false,
        error: 'Invalid job ID',
      });
    }

    try {
      const job =
        await getJobById(
          pool,
          id,
        );

      if (!job) {
        return res.status(404).json({
          success: false,
          error:
            'Job order not found',
        });
      }

      res.json({
        success: true,

        ...job,
      });
    } catch (error) {
      console.error(
        'Get job details failed:',
        error,
      );

      res.status(500).json({
        success: false,
        error:
          error.message ||
          'Failed to load job details',
      });
    }
  },
);

// ============================================================
// POST /api/jobs
// CREATE JOB
// ============================================================

router.post('/', async (req, res) => {
  const {
    job_date,
    jobDate,

    party_id,
    partyId,

    fabric_name,
    fabricName,

    design_no,
    designNo,

    gsm,

    order_quantity,
    orderQuantity,

    status,

    stitch_length,
    stitchLength,

    notes,

    machines,
    machine_ids,
    machineIds,

    yarns,
  } = req.body || {};

  const resolvedPartyId =
    toNumber(
      party_id ?? partyId,
      0,
    );

  const resolvedFabricName =
    cleanString(
      fabric_name ?? fabricName,
    );

  const resolvedOrderQuantity =
    toNumber(
      order_quantity ??
        orderQuantity,
      0,
    );

  if (resolvedPartyId <= 0) {
    return res.status(400).json({
      success: false,
      error:
        'party_id is required',
    });
  }

  if (!resolvedFabricName) {
    return res.status(400).json({
      success: false,
      error:
        'fabric_name is required',
    });
  }

  if (resolvedOrderQuantity <= 0) {
    return res.status(400).json({
      success: false,
      error:
        'order_quantity must be greater than 0',
    });
  }

  const machineList =
    normaliseMachines(
      machines ??
        machine_ids ??
        machineIds ??
        [],
    );

  const yarnList =
    normaliseYarns(yarns);

  const client =
    await pool.connect();

  try {
    await client.query(
      'BEGIN',
    );

    const partyCheck =
      await client.query(
        `
        SELECT id
        FROM parties
        WHERE id = $1
        `,
        [resolvedPartyId],
      );

    if (
      partyCheck.rows.length === 0
    ) {
      throw new Error(
        'Selected party does not exist',
      );
    }

    const sequenceResult =
      await client.query(`
        SELECT COALESCE(
          MAX(
            CASE
              WHEN job_no ~ '[0-9]+$'
              THEN CAST(
                substring(
                  job_no
                  FROM '[0-9]+$'
                )
                AS BIGINT
              )
              ELSE 0
            END
          ),
          0
        ) + 1 AS next_no
        FROM job_orders
      `);

    const nextNo =
      Number(
        sequenceResult.rows[0]
          .next_no,
      );

    const jobNo =
      `BBJO-${String(nextNo)
        .padStart(5, '0')}`;

    const jobResult =
      await client.query(
        `
        INSERT INTO job_orders (
          job_no,
          job_date,
          party_id,
          fabric_name,
          design_no,
          gsm,
          order_quantity,
          status,
          stitch_length,
          notes
        )
        VALUES (
          $1,
          COALESCE(
            $2::date,
            CURRENT_DATE
          ),
          $3,
          $4,
          $5,
          $6,
          $7,
          COALESCE(
            NULLIF($8, ''),
            'Open'
          ),
          $9,
          $10
        )
        RETURNING id
        `,
        [
          jobNo,

          job_date ??
            jobDate ??
            null,

          resolvedPartyId,

          resolvedFabricName,

          cleanString(
            design_no ??
              designNo,
          ) || null,

          toNumber(gsm, 0),

          resolvedOrderQuantity,

          cleanString(status),

          toNumber(
            stitch_length ??
              stitchLength,
            0,
          ),

          cleanString(notes) ||
            null,
        ],
      );

    const jobId =
      Number(
        jobResult.rows[0].id,
      );

    // ========================================================
    // MACHINES
    // ========================================================

    for (
      const machineId
      of machineList
    ) {
      await client.query(
        `
        INSERT INTO
          job_order_machines (
            job_order_id,
            machine_id
          )
        VALUES ($1, $2)
        `,
        [
          jobId,
          machineId,
        ],
      );
    }

    // ========================================================
    // YARNS
    // ========================================================

    for (
      const yarn
      of yarnList
    ) {
      await client.query(
        `
        INSERT INTO
          job_order_yarns (
            job_order_id,
            yarn_name,
            yarn_count,
            required_kg,
            issued_kg,
            returned_kg,
            waste_kg
          )
        VALUES (
          $1,
          $2,
          $3,
          $4,
          $5,
          $6,
          $7
        )
        `,
        [
          jobId,

          yarn.yarn_name ||
            null,

          yarn.yarn_count ||
            null,

          yarn.required_kg,

          yarn.issued_kg,

          yarn.returned_kg,

          yarn.waste_kg,
        ],
      );
    }

    await client.query(
      'COMMIT',
    );

    const createdJob =
      await getJobById(
        pool,
        jobId,
      );

    res.status(201).json({
      success: true,
      job: createdJob,
    });
  } catch (error) {
    await client.query(
      'ROLLBACK',
    );

    console.error(
      'Create job failed:',
      error,
    );

    res.status(500).json({
      success: false,
      error:
        error.message ||
        'Failed to create job order',
    });
  } finally {
    client.release();
  }
});

// ============================================================
// PUT /api/jobs/:id
// UPDATE JOB
// ============================================================

router.put('/:id', async (req, res) => {
  const id =
    Number(req.params.id);

  if (
    !Number.isInteger(id) ||
    id <= 0
  ) {
    return res.status(400).json({
      success: false,
      error: 'Invalid job ID',
    });
  }

  const {
    job_date,
    jobDate,

    party_id,
    partyId,

    fabric_name,
    fabricName,

    design_no,
    designNo,

    gsm,

    order_quantity,
    orderQuantity,

    status,

    stitch_length,
    stitchLength,

    notes,

    machines,
    machine_ids,
    machineIds,

    yarns,
  } = req.body || {};

  const client =
    await pool.connect();

  try {
    await client.query(
      'BEGIN',
    );

    const existing =
      await client.query(
        `
        SELECT id
        FROM job_orders
        WHERE id = $1
        FOR UPDATE
        `,
        [id],
      );

    if (
      existing.rows.length === 0
    ) {
      await client.query(
        'ROLLBACK',
      );

      return res.status(404).json({
        success: false,
        error:
          'Job order not found',
      });
    }

    await client.query(
      `
      UPDATE job_orders

      SET
        job_date =
          COALESCE(
            $1::date,
            job_date
          ),

        party_id =
          COALESCE(
            $2,
            party_id
          ),

        fabric_name =
          COALESCE(
            NULLIF($3, ''),
            fabric_name
          ),

        design_no =
          COALESCE(
            NULLIF($4, ''),
            design_no
          ),

        gsm =
          COALESCE(
            $5,
            gsm
          ),

        order_quantity =
          COALESCE(
            $6,
            order_quantity
          ),

        status =
          COALESCE(
            NULLIF($7, ''),
            status
          ),

        stitch_length =
          COALESCE(
            $8,
            stitch_length
          ),

        notes =
          COALESCE(
            NULLIF($9, ''),
            notes
          ),

        updated_at = NOW()

      WHERE id = $10
      `,
      [
        job_date ??
          jobDate ??
          null,

        toNumber(
          party_id ??
            partyId,
          0,
        ) || null,

        cleanString(
          fabric_name ??
            fabricName,
        ),

        cleanString(
          design_no ??
            designNo,
        ),

        toNumber(gsm, 0) ||
          null,

        toNumber(
          order_quantity ??
            orderQuantity,
          0,
        ) || null,

        cleanString(status),

        toNumber(
          stitch_length ??
            stitchLength,
          0,
        ) || null,

        cleanString(notes),

        id,
      ],
    );

    // ========================================================
    // MACHINES
    // ========================================================

    const machinesProvided =
      machines !== undefined ||
      machine_ids !== undefined ||
      machineIds !== undefined;

    if (machinesProvided) {
      const machineList =
        normaliseMachines(
          machines ??
            machine_ids ??
            machineIds ??
            [],
        );

      await client.query(
        `
        DELETE FROM
          job_order_machines
        WHERE job_order_id = $1
        `,
        [id],
      );

      for (
        const machineId
        of machineList
      ) {
        await client.query(
          `
          INSERT INTO
            job_order_machines (
              job_order_id,
              machine_id
            )
          VALUES ($1, $2)
          `,
          [
            id,
            machineId,
          ],
        );
      }
    }

    // ========================================================
    // YARNS
    // ========================================================

    if (yarns !== undefined) {
      const yarnList =
        normaliseYarns(yarns);

      await client.query(
        `
        DELETE FROM
          job_order_yarns
        WHERE job_order_id = $1
        `,
        [id],
      );

      for (
        const yarn
        of yarnList
      ) {
        await client.query(
          `
          INSERT INTO
            job_order_yarns (
              job_order_id,
              yarn_name,
              yarn_count,
              required_kg,
              issued_kg,
              returned_kg,
              waste_kg
            )
          VALUES (
            $1,
            $2,
            $3,
            $4,
            $5,
            $6,
            $7
          )
          `,
          [
            id,

            yarn.yarn_name ||
              null,

            yarn.yarn_count ||
              null,

            yarn.required_kg,

            yarn.issued_kg,

            yarn.returned_kg,

            yarn.waste_kg,
          ],
        );
      }
    }

    await client.query(
      'COMMIT',
    );

    const updatedJob =
      await getJobById(
        pool,
        id,
      );

    res.json({
      success: true,
      job: updatedJob,
    });
  } catch (error) {
    await client.query(
      'ROLLBACK',
    );

    console.error(
      'Update job failed:',
      error,
    );

    res.status(500).json({
      success: false,
      error:
        error.message ||
        'Failed to update job order',
    });
  } finally {
    client.release();
  }
});

// ============================================================
// POST /api/jobs/:id/production
// ADD PRODUCTION
// ============================================================

router.post(
  '/:id/production',
  async (req, res) => {
    const jobId =
      Number(req.params.id);

    if (
      !Number.isInteger(jobId) ||
      jobId <= 0
    ) {
      return res.status(400).json({
        success: false,
        error: 'Invalid job ID',
      });
    }

    const {
      machine_id,
      machineId,

      production_date,
      productionDate,

      roll_no,
      rollNo,

      quantity_kg,
      quantityKg,

      remarks,
    } = req.body || {};

    const quantity =
      toNumber(
        quantity_kg ??
          quantityKg,
        0,
      );

    if (quantity <= 0) {
      return res.status(400).json({
        success: false,
        error:
          'quantity_kg must be greater than 0',
      });
    }

    try {
      const jobCheck =
        await pool.query(
          `
          SELECT id
          FROM job_orders
          WHERE id = $1
          `,
          [jobId],
        );

      if (
        jobCheck.rows.length === 0
      ) {
        return res.status(404).json({
          success: false,
          error:
            'Job order not found',
        });
      }

      const result =
        await pool.query(
          `
          INSERT INTO job_production (
            job_order_id,
            machine_id,
            production_date,
            roll_no,
            quantity_kg,
            remarks
          )
          VALUES (
            $1,
            $2,
            COALESCE(
              $3::date,
              CURRENT_DATE
            ),
            $4,
            $5,
            $6
          )
          RETURNING
            id,
            job_order_id,
            machine_id,
            production_date,
            roll_no,
            quantity_kg,
            remarks,
            created_at
          `,
          [
            jobId,

            toNumber(
              machine_id ??
                machineId,
              0,
            ) || null,

            production_date ??
              productionDate ??
              null,

            cleanString(
              roll_no ??
                rollNo,
            ) || null,

            quantity,

            cleanString(
              remarks,
            ) || null,
          ],
        );

      res.status(201).json({
        success: true,
        production:
          result.rows[0],
      });
    } catch (error) {
      console.error(
        'Add job production failed:',
        error,
      );

      res.status(500).json({
        success: false,
        error:
          error.message ||
          'Failed to add production',
      });
    }
  },
);

// ============================================================
// GET YARN HISTORY
// ============================================================
//
// NOTE:
// The current database schema does not contain a dedicated
// yarn transaction/history table for jobs.
// Therefore this returns the yarn requirements recorded
// against the job.
//

router.get(
  '/:jobNo/yarn-history',
  async (req, res) => {
    const jobNo =
      cleanString(req.params.jobNo);

    try {
      const result =
        await pool.query(
          `
          SELECT
            joy.id,
            'Requirement' AS transaction_type,
            joy.required_kg AS quantity,
            joy.created_at,
            '' AS lot_no,
            joy.yarn_name,
            '' AS remarks
          FROM job_order_yarns joy
          INNER JOIN job_orders jo
            ON jo.id =
              joy.job_order_id
          WHERE jo.job_no = $1
          ORDER BY joy.id DESC
          `,
          [jobNo],
        );

      res.json(
        result.rows.map((row) => ({
          transaction_type:
            row.transaction_type,

          quantity:
            toNumber(row.quantity),

          created_at:
            row.created_at,

          lot_no:
            row.lot_no || '',

          yarn_name:
            row.yarn_name || '',

          remarks:
            row.remarks || '',
        })),
      );
    } catch (error) {
      console.error(
        'Get yarn history failed:',
        error,
      );

      res.status(500).json({
        success: false,
        error:
          error.message ||
          'Failed to load yarn history',
      });
    }
  },
);

// ============================================================
// GET PRODUCTION HISTORY
// ============================================================

router.get(
  '/:jobNo/production-history',
  async (req, res) => {
    const jobNo =
      cleanString(req.params.jobNo);

    try {
      const result =
        await pool.query(
          `
          SELECT
            jp.roll_no,
            jp.quantity_kg,
            jp.created_at
          FROM job_production jp
          INNER JOIN job_orders jo
            ON jo.id =
              jp.job_order_id
          WHERE jo.job_no = $1
          ORDER BY
            jp.production_date DESC NULLS LAST,
            jp.id DESC
          `,
          [jobNo],
        );

      res.json(
        result.rows.map((row) => ({
          roll_no:
            row.roll_no || '',

          quantity:
            toNumber(row.quantity_kg),

          created_at:
            row.created_at,
        })),
      );
    } catch (error) {
      console.error(
        'Get production history failed:',
        error,
      );

      res.status(500).json({
        success: false,
        error:
          error.message ||
          'Failed to load production history',
      });
    }
  },
);

// ============================================================
// PUT /api/jobs/close/:jobNo
// CLOSE JOB
// ============================================================

router.put(
  '/close/:jobNo',
  async (req, res) => {
    const jobNo =
      cleanString(req.params.jobNo);

    if (!jobNo) {
      return res.status(400).json({
        success: false,
        error:
          'Job number is required',
      });
    }

    try {
      const result =
        await pool.query(
          `
          UPDATE job_orders

          SET
            status = 'Closed',
            updated_at = NOW()

          WHERE job_no = $1

          RETURNING id
          `,
          [jobNo],
        );

      if (
        result.rows.length === 0
      ) {
        return res.status(404).json({
          success: false,
          error:
            'Job order not found',
        });
      }

      res.json({
        success: true,
        message:
          'Job closed successfully',
      });
    } catch (error) {
      console.error(
        'Close job failed:',
        error,
      );

      res.status(500).json({
        success: false,
        error:
          error.message ||
          'Failed to close job',
      });
    }
  },
);

// ============================================================
// PUT /api/jobs/change-machine/:jobId
// CHANGE MACHINE
// ============================================================

router.put(
  '/change-machine/:jobId',
  async (req, res) => {
    const jobId =
      Number(req.params.jobId);

    const newMachineId =
      toNumber(
        req.body?.new_machine_id ??
          req.body?.newMachineId,
        0,
      );

    if (
      !Number.isInteger(jobId) ||
      jobId <= 0
    ) {
      return res.status(400).json({
        success: false,
        error:
          'Invalid job ID',
      });
    }

    if (newMachineId <= 0) {
      return res.status(400).json({
        success: false,
        error:
          'new_machine_id is required',
      });
    }

    const client =
      await pool.connect();

    try {
      await client.query(
        'BEGIN',
      );

      const jobCheck =
        await client.query(
          `
          SELECT id
          FROM job_orders
          WHERE id = $1
          `,
          [jobId],
        );

      if (
        jobCheck.rows.length === 0
      ) {
        await client.query(
          'ROLLBACK',
        );

        return res.status(404).json({
          success: false,
          error:
            'Job order not found',
        });
      }

      await client.query(
        `
        DELETE FROM
          job_order_machines
        WHERE job_order_id = $1
        `,
        [jobId],
      );

      await client.query(
        `
        INSERT INTO
          job_order_machines (
            job_order_id,
            machine_id
          )
        VALUES ($1, $2)
        `,
        [
          jobId,
          newMachineId,
        ],
      );

      await client.query(
        'COMMIT',
      );

      res.json({
        success: true,
        message:
          'Job machine changed successfully',
      });
    } catch (error) {
      await client.query(
        'ROLLBACK',
      );

      console.error(
        'Change job machine failed:',
        error,
      );

      res.status(500).json({
        success: false,
        error:
          error.message ||
          'Failed to change job machine',
      });
    } finally {
      client.release();
    }
  },
);

// ============================================================
// EXPORT
// ============================================================

module.exports = router; 