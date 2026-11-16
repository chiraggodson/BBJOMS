const express = require('express');
const { pool } = require('../db');
const router = express.Router();
const { COMPANY_ID } = require('../config');

function dateRange(req) {
  const valid = value => /^\d{4}-\d{2}-\d{2}$/.test(String(value || ''));
  const from = valid(req.query.from) ? req.query.from : null;
  const to = valid(req.query.to) ? req.query.to : null;
  return [from, to];
}

router.get('/overview', async (_req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        COALESCE(SUM(r.net_weight_kg) FILTER (WHERE fp.production_date=CURRENT_DATE),0)::float AS production_today_kg,
        COALESCE(SUM(r.net_weight_kg),0)::float AS production_month_kg
      FROM production.fabric_production fp
      JOIN production.fabric_production_rolls r ON r.production_id=fp.id
      WHERE fp.company_id=$1 AND fp.status='POSTED'
        AND fp.production_date >= date_trunc('month',CURRENT_DATE)::date
        AND fp.production_date < (date_trunc('month',CURRENT_DATE)+INTERVAL '1 month')::date
    `, [COMPANY_ID]);
    const ops = await pool.query(`
      SELECT
        (SELECT COUNT(*)::int FROM jobwork.job_orders WHERE company_id=$1 AND status IN ('OPEN','RUNNING','PAUSED')) AS open_jobs,
        (SELECT COALESCE(SUM(quantity_kg),0)::float FROM jobwork.fabric_lots WHERE company_id=$1 AND status='AVAILABLE') AS available_fabric_kg
    `, [COMPANY_ID]);
    res.json({success:true,summary:{...result.rows[0],...ops.rows[0]}});
  } catch (error) {
    console.error('Load report overview failed:',error);
    res.status(500).json({success:false,error:'Failed to load report summary'});
  }
});

router.get('/production', async (req, res) => {
  try {
    const [from,to] = dateRange(req);
    const result = await pool.query(`
      SELECT fp.production_date,fp.production_no,j.job_no,p.name party_name,
        f.name fabric_name,m.machine_no,COUNT(r.id)::int roll_count,
        COALESCE(SUM(r.net_weight_kg),0)::float quantity_kg,
        COALESCE(SUM(r.meters),0)::float meters
      FROM production.fabric_production fp
      JOIN production.fabric_production_rolls r ON r.production_id=fp.id
      LEFT JOIN jobwork.job_orders j ON j.id=fp.job_order_id
      LEFT JOIN master.parties p ON p.id=j.party_id
      LEFT JOIN master.fabrics f ON f.id=j.fabric_id
      LEFT JOIN master.machines m ON m.id=fp.machine_id
      WHERE fp.company_id=$1 AND fp.status='POSTED'
        AND ($2::date IS NULL OR fp.production_date >= $2::date)
        AND ($3::date IS NULL OR fp.production_date <= $3::date)
      GROUP BY fp.id,fp.production_date,fp.production_no,j.job_no,p.name,f.name,m.machine_no
      ORDER BY fp.production_date DESC,fp.production_no DESC
      LIMIT 1000
    `,[COMPANY_ID,from,to]);
    res.json({success:true,rows:result.rows});
  } catch (error) {
    console.error('Load production report failed:',error);
    res.status(500).json({success:false,error:'Failed to load production report'});
  }
});

router.get('/jobs', async (_req,res) => {
  try {
    const result=await pool.query(`
      SELECT j.job_no,j.job_date,p.name party_name,f.name fabric_name,j.status,
        j.order_quantity_kg::float target_kg,COALESCE(prod.produced_kg,0)::float produced_kg,
        GREATEST(j.order_quantity_kg-COALESCE(prod.produced_kg,0),0)::float remaining_kg
      FROM jobwork.job_orders j
      LEFT JOIN master.parties p ON p.id=j.party_id
      LEFT JOIN master.fabrics f ON f.id=j.fabric_id
      LEFT JOIN (SELECT fp.job_order_id,SUM(r.net_weight_kg) produced_kg
        FROM production.fabric_production fp JOIN production.fabric_production_rolls r ON r.production_id=fp.id
        WHERE fp.company_id=$1 AND fp.status='POSTED' GROUP BY fp.job_order_id) prod ON prod.job_order_id=j.id
      WHERE j.company_id=$1
      ORDER BY j.job_date DESC,j.job_no DESC LIMIT 1000
    `,[COMPANY_ID]);
    res.json({success:true,rows:result.rows});
  } catch(error) {
    console.error('Load job report failed:',error);
    res.status(500).json({success:false,error:'Failed to load job report'});
  }
});

router.get('/fabric-stock', async (_req,res) => {
  try {
    const result=await pool.query(`
      SELECT l.lot_no,j.job_no,p.name party_name,f.name fabric_name,
        l.quantity_kg::float quantity_kg,l.status,l.created_at::date received_date
      FROM jobwork.fabric_lots l
      JOIN jobwork.job_orders j ON j.id=l.job_order_id
      JOIN master.parties p ON p.id=j.party_id
      LEFT JOIN master.fabrics f ON f.id=j.fabric_id
      WHERE l.company_id=$1 AND l.status='AVAILABLE'
      ORDER BY l.created_at DESC,l.lot_no LIMIT 2000
    `,[COMPANY_ID]);
    res.json({success:true,rows:result.rows});
  } catch(error) {
    console.error('Load fabric stock report failed:',error);
    res.status(500).json({success:false,error:'Failed to load fabric stock report'});
  }
});

module.exports=router;
