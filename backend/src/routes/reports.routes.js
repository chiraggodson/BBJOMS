const express = require('express');
const { pool } = require('../db');
const router = express.Router();
const { COMPANY_ID } = require('../config');

router.get('/overview', async (_req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        COALESCE(SUM(r.net_weight_kg) FILTER (WHERE fp.production_date=CURRENT_DATE),0)::float AS production_today_kg,
        COALESCE(SUM(r.net_weight_kg),0)::float AS production_month_kg
      FROM production.fabric_production fp
      JOIN production.fabric_production_rolls r ON r.production_id=fp.id
      WHERE fp.company_id=$1
        AND fp.status='POSTED'
        AND fp.production_date >= date_trunc('month',CURRENT_DATE)::date
        AND fp.production_date < (date_trunc('month',CURRENT_DATE)+INTERVAL '1 month')::date
    `, [COMPANY_ID]);
    res.json({success:true,summary:result.rows[0]});
  } catch (error) {
    console.error('Load report overview failed:',error);
    res.status(500).json({success:false,error:'Failed to load production summary'});
  }
});

module.exports = router;