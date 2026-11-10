const express = require('express');
const { pool } = require('../db');
const router = express.Router();
const COMPANY_ID = '37c8cd03-c8ae-48cd-b8e4-cb3e864f042f';

function clean(v) { return v == null ? '' : String(v).trim(); }
function num(v) { const n = Number(v); return Number.isFinite(n) ? n : 0; }

router.get('/:jobId/returnable-yarn', async (req,res) => {
  try {
    const result = await pool.query(`
      SELECT il.id AS issue_line_id, il.yarn_id, COALESCE(y.name,'') AS yarn_name,
        COALESCE(yl.lot_no,'') AS lot_no, il.location_id, COALESCE(loc.name,'') AS location_name,
        il.quantity_kg::float AS issued_kg,
        GREATEST(il.quantity_kg-COALESCE(SUM(CASE WHEN ret.status='POSTED' THEN rl.quantity_kg ELSE 0 END),0),0)::float AS available_kg
      FROM jobwork.yarn_issues yi
      JOIN jobwork.yarn_issue_lines il ON il.issue_id=yi.id
      JOIN master.yarn_lots yl ON yl.id=il.yarn_lot_id
      LEFT JOIN master.yarns y ON y.id=il.yarn_id
      LEFT JOIN master.locations loc ON loc.id=il.location_id
      LEFT JOIN jobwork.yarn_return_lines rl ON rl.issue_line_id=il.id
      LEFT JOIN jobwork.yarn_returns ret ON ret.id=rl.return_id
      WHERE yi.job_order_id=$1 AND yi.company_id=$2 AND yi.status='POSTED'
      GROUP BY il.id, y.name, yl.lot_no, loc.name
      HAVING il.quantity_kg-COALESCE(SUM(CASE WHEN ret.status='POSTED' THEN rl.quantity_kg ELSE 0 END),0)>0
      ORDER BY y.name, yl.lot_no, il.id
    `, [req.params.jobId, COMPANY_ID]);
    res.json({success:true,lines:result.rows});
  } catch (e) {
    console.error('Load returnable yarn failed:',e);
    res.status(500).json({success:false,error:e.message || 'Failed to load returnable yarn'});
  }
});

router.post('/:jobId/yarn-return', async (req,res) => {
  const client = await pool.connect();
  try {
    const entries = Array.isArray(req.body?.lines) ? req.body.lines : [];
    if (!entries.length) return res.status(400).json({success:false,error:'Add at least one yarn return line.'});
    await client.query('BEGIN');
    const job = await client.query('SELECT id FROM jobwork.job_orders WHERE id=$1 AND company_id=$2 FOR UPDATE', [req.params.jobId, COMPANY_ID]);
    if (!job.rows.length) throw new Error('Job order not found.');
    const fy = await client.query(`SELECT id FROM core.financial_years WHERE company_id=$1 AND is_current=true AND is_closed=false ORDER BY start_date DESC LIMIT 1`, [COMPANY_ID]);
    if (!fy.rows.length) throw new Error('No open financial year exists.');
    const header = await client.query(`INSERT INTO jobwork.yarn_returns(company_id,financial_year_id,job_order_id,status,notes) VALUES($1,$2,$3,'DRAFT',$4) RETURNING id,return_no`, [COMPANY_ID,fy.rows[0].id,req.params.jobId,clean(req.body?.notes)||null]);
    for (const line of entries) {
      const issue = await client.query(`
        SELECT il.id, il.quantity_kg, il.location_id, yi.job_order_id,
          COALESCE((SELECT SUM(rl.quantity_kg) FROM jobwork.yarn_return_lines rl JOIN jobwork.yarn_returns rr ON rr.id=rl.return_id WHERE rl.issue_line_id=il.id AND rr.status='POSTED'),0) returned
        FROM jobwork.yarn_issue_lines il JOIN jobwork.yarn_issues yi ON yi.id=il.issue_id
        WHERE il.id=$1 AND yi.job_order_id=$2 AND yi.company_id=$3 AND yi.status='POSTED'
        FOR UPDATE OF il
      `, [line.issue_line_id,req.params.jobId,COMPANY_ID]);
      const qty = num(line.quantity_kg);
      if (!issue.rows.length || qty <= 0 || qty > Number(issue.rows[0].quantity_kg)-Number(issue.rows[0].returned)+0.0001) throw new Error('Return quantity exceeds the available issued quantity.');
      await client.query(`INSERT INTO jobwork.yarn_return_lines(return_id,issue_line_id,location_id,quantity_kg) VALUES($1,$2,$3,$4)`, [header.rows[0].id,line.issue_line_id,issue.rows[0].location_id,qty]);
    }
    await client.query(`UPDATE jobwork.yarn_returns SET status='POSTED' WHERE id=$1`, [header.rows[0].id]);
    await client.query('COMMIT');
    res.status(201).json({success:true,return_no:header.rows[0].return_no,message:'Yarn return posted.'});
  } catch (e) {
    await client.query('ROLLBACK');
    console.error('Post yarn return failed:',e);
    res.status(400).json({success:false,error:e.message || 'Failed to post yarn return'});
  } finally { client.release(); }
});

router.post('/:jobId/setting-cloth', async (req,res) => {
  const client = await pool.connect();
  try {
    const quantity = num(req.body?.quantity_kg);
    if (quantity <= 0) return res.status(400).json({success:false,error:'Setting cloth weight must be greater than zero.'});
    await client.query('BEGIN');
    const job = await client.query(`
      SELECT j.id,j.order_quantity_kg FROM jobwork.job_orders j WHERE j.id=$1 AND j.company_id=$2 FOR UPDATE
    `, [req.params.jobId,COMPANY_ID]);
    if (!job.rows.length) throw new Error('Job order not found.');
    const fy = await client.query(`SELECT id FROM core.financial_years WHERE company_id=$1 AND is_current=true AND is_closed=false ORDER BY start_date DESC LIMIT 1`, [COMPANY_ID]);
    if (!fy.rows.length) throw new Error('No open financial year exists.');
    const recipe = await client.query(`SELECT yarn_id,requirement_percent FROM jobwork.job_order_yarns WHERE job_order_id=$1 ORDER BY created_at,id`, [req.params.jobId]);
    if (!recipe.rows.length) throw new Error('This job order has no yarn percentages to calculate setting cloth consumption.');
    const entry = await client.query(`INSERT INTO jobwork.setting_cloth_entries(company_id,financial_year_id,job_order_id,quantity_kg,notes) VALUES($1,$2,$3,$4,$5) RETURNING id`, [COMPANY_ID,fy.rows[0].id,req.params.jobId,quantity,clean(req.body?.notes)||null]);
    for (const yarn of recipe.rows) {
      const percent = num(yarn.requirement_percent);
      const used = Math.round((quantity * percent / 100) * 1000) / 1000;
      await client.query(`INSERT INTO jobwork.setting_cloth_yarn_lines(setting_cloth_id,yarn_id,quantity_kg,requirement_percent) VALUES($1,$2,$3,$4)`, [entry.rows[0].id,yarn.yarn_id,used,percent]);
    }
    await client.query('COMMIT');
    res.status(201).json({success:true,message:'Setting cloth recorded. Yarn use was allocated by the job recipe; production and knitting charges are unchanged.'});
  } catch (e) {
    await client.query('ROLLBACK');
    console.error('Record setting cloth failed:',e);
    res.status(400).json({success:false,error:e.message || 'Failed to record setting cloth'});
  } finally { client.release(); }
});

module.exports = router;
