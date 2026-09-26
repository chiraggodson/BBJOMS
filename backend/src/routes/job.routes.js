const express = require('express');
const { pool } = require('../db');
const router = express.Router();

const COMPANY_ID = '37c8cd03-c8ae-48cd-b8e4-cb3e864f042f';

function cleanString(v) { return v == null ? '' : String(v).trim(); }
function toNumber(v, fallback = 0) {
  if (v == null || v === '') return fallback;
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}
function uuid(v) { return String(v || ''); }

async function getJobById(client, id) {
  const result = await client.query(`
    SELECT
      j.id, j.job_no, j.job_date, j.party_id,
      COALESCE(p.name,'') AS party_name,
      j.fabric_id, COALESCE(f.name,'') AS fabric_name,
      j.design_no, f.gsm AS fabric_gsm, j.order_quantity_kg,
      j.status, j.notes, j.created_at, j.updated_at,
      COALESCE(prod.produced_quantity,0) AS produced_quantity,
      GREATEST(j.order_quantity_kg-COALESCE(prod.produced_quantity,0),0) AS remaining_quantity,
      COALESCE(ARRAY_AGG(DISTINCT jom.machine_id) FILTER (WHERE jom.machine_id IS NOT NULL), ARRAY[]::uuid[]) AS machine_ids
    FROM jobwork.job_orders j
    LEFT JOIN master.parties p ON p.id=j.party_id
    LEFT JOIN master.fabrics f ON f.id=j.fabric_id
    LEFT JOIN jobwork.job_order_machines jom ON jom.job_order_id=j.id
    LEFT JOIN (
      SELECT job_order_id, COALESCE(SUM(r.net_weight_kg),0) produced_quantity
      FROM production.fabric_production fp
      JOIN production.fabric_production_rolls r ON r.production_id=fp.id
      WHERE fp.status='POSTED'
      GROUP BY job_order_id
    ) prod ON prod.job_order_id=j.id
    WHERE (j.id::text=$1 OR j.job_no=$1) AND j.company_id=$2
    GROUP BY j.id,p.name,f.name,f.gsm,prod.produced_quantity
  `, [id, COMPANY_ID]);
  if (!result.rows.length) return null;
  const j = result.rows[0];

  const yarns = await client.query(`
    SELECT
      joy.id, joy.job_order_id, joy.yarn_id,
      COALESCE(y.name,'') AS yarn_name, COALESCE(y.count::text,'') AS yarn_count,
      joy.requirement_percent, joy.required_kg
    FROM jobwork.job_order_yarns joy
    JOIN master.yarns y ON y.id=joy.yarn_id
    WHERE joy.job_order_id=$1
    ORDER BY joy.id
  `, [id]);

  const production = await client.query(`
    SELECT
      fp.id, fp.job_order_id, fp.machine_id, fp.production_date,
      r.roll_no, r.net_weight_kg AS quantity_kg, r.meters, r.width_inches,
      r.gsm, r.remarks, fp.status, fp.created_at
    FROM production.fabric_production fp
    LEFT JOIN production.fabric_production_rolls r ON r.production_id=fp.id
    WHERE fp.job_order_id=$1
    ORDER BY fp.production_date DESC, fp.id DESC, r.roll_no
  `, [id]);

  const machineIds = (j.machine_ids || []).map(String);
  return {
    id: String(j.id), jobNo:j.job_no, jobDate:j.job_date,
    partyId: j.party_id ? String(j.party_id) : null, partyName:j.party_name,
    fabricId:j.fabric_id ? String(j.fabric_id) : null, fabricName:j.fabric_name,
    designNo:j.design_no || '', gsm: j.fabric_gsm == null ? 0 : Number(j.fabric_gsm),
    orderQuantity:Number(j.order_quantity_kg || 0), producedQuantity:Number(j.produced_quantity || 0),
    remainingQuantity:Number(j.remaining_quantity || 0), status:j.status, notes:j.notes || '',
    machineIds, machineNumbers: machineIds.join(', '),
    yarns:yarns.rows.map(y=>({
      id:String(y.id), yarnId:String(y.yarn_id), jobOrderId:String(y.job_order_id),
      yarnName:y.yarn_name, yarnCount:y.yarn_count, requirementPercent:y.requirement_percent == null ? null : Number(y.requirement_percent),
      requiredKg:Number(y.required_kg || 0), issuedKg:0, returnedKg:0, wasteKg:0
    })),
    production:production.rows.map(r=>({
      id:String(r.id), jobOrderId:String(r.job_order_id), machineId:r.machine_id ? String(r.machine_id):null,
      productionDate:r.production_date, rollNo:r.roll_no || '', quantityKg:Number(r.quantity_kg || 0),
      meters:r.meters == null ? 0:Number(r.meters), widthInches:r.width_inches == null ? null:Number(r.width_inches),
      gsm:r.gsm == null ? null:Number(r.gsm), remarks:r.remarks || '', status:r.status
    }))
  };
}

router.get('/', async (req,res)=>{
  try {
    const values=[COMPANY_ID], conditions=['j.company_id=$1'];
    const search=cleanString(req.query.search), status=cleanString(req.query.status);
    if(search){values.push(`%${search}%`); conditions.push(`(j.job_no ILIKE $${values.length} OR COALESCE(p.name,'') ILIKE $${values.length} OR COALESCE(f.name,'') ILIKE $${values.length})`);}
    if(status){values.push(status.toUpperCase()); conditions.push(`j.status=$${values.length}`);}
    const result=await pool.query(`
      SELECT j.id,j.job_no,j.job_date,j.party_id,COALESCE(p.name,'') party_name,
             j.fabric_id,COALESCE(f.name,'') fabric_name,f.gsm,j.order_quantity_kg,j.status,j.design_no,
             COALESCE(prod.produced_quantity,0) produced_quantity,
             GREATEST(j.order_quantity_kg-COALESCE(prod.produced_quantity,0),0) remaining_quantity,
             COALESCE(ARRAY_AGG(DISTINCT jom.machine_id) FILTER(WHERE jom.machine_id IS NOT NULL),ARRAY[]::uuid[]) machine_ids
      FROM jobwork.job_orders j
      LEFT JOIN master.parties p ON p.id=j.party_id
      LEFT JOIN master.fabrics f ON f.id=j.fabric_id
      LEFT JOIN jobwork.job_order_machines jom ON jom.job_order_id=j.id
      LEFT JOIN (SELECT fp.job_order_id,COALESCE(SUM(r.net_weight_kg),0) produced_quantity
                 FROM production.fabric_production fp JOIN production.fabric_production_rolls r ON r.production_id=fp.id
                 WHERE fp.status='POSTED' GROUP BY fp.job_order_id) prod ON prod.job_order_id=j.id
      WHERE ${conditions.join(' AND ')}
      GROUP BY j.id,p.name,f.name,f.gsm,prod.produced_quantity
      ORDER BY j.job_date DESC,j.created_at DESC
    `,values);
    res.json({success:true,jobs:result.rows.map(j=>({...j,id:String(j.id),partyId:j.party_id?String(j.party_id):null,
      fabricId:j.fabric_id?String(j.fabric_id):null,gsm:j.gsm==null?0:Number(j.gsm),
      orderQuantity:Number(j.order_quantity_kg||0),producedQuantity:Number(j.produced_quantity||0),
      remainingQuantity:Number(j.remaining_quantity||0),machineIds:(j.machine_ids||[]).map(String),
      machineNumbers:(j.machine_ids||[]).map(String).join(', ')}))});
  }catch(e){console.error('Get jobs failed:',e);res.status(500).json({success:false,error:e.message||'Failed to load job orders'});}
});

router.get('/:jobNo/yarn-history', async (req,res)=>{
  try{
    const result=await pool.query(`
      SELECT l.id,l.movement_date,l.created_at,l.quantity_out::float quantity,l.movement_type,l.reference_type,
             l.reference_id,l.remarks,l.location_id,COALESCE(loc.name,'') location_name,
             l.yarn_lot_id,yl.lot_no,y.id yarn_id,y.name yarn_name,y.count yarn_count,COALESCE(c.name,'') color_name
      FROM inventory.yarn_ledger l
      JOIN jobwork.job_orders jo ON jo.job_no=$1 AND l.reference_type='YARN_ISSUE' AND l.reference_id=(
        SELECT yi.id FROM jobwork.yarn_issues yi WHERE yi.job_order_id=jo.id LIMIT 1)
      JOIN master.yarn_lots yl ON yl.id=l.yarn_lot_id
      JOIN master.yarns y ON y.id=yl.yarn_id
      LEFT JOIN master.colors c ON c.id=yl.color_id
      LEFT JOIN master.locations loc ON loc.id=l.location_id
      WHERE l.quantity_out>0 ORDER BY l.movement_date DESC,l.id DESC
    `,[req.params.jobNo]);
    res.json({success:true,history:result.rows});
  }catch(e){console.error('Get yarn history failed:',e);res.status(500).json({success:false,error:e.message});}
});

router.get('/:jobNo/production-history', async(req,res)=>{
  try{
    const result=await pool.query(`
      SELECT fp.id,fp.job_order_id,fp.machine_id,fp.production_date,r.roll_no,r.net_weight_kg quantity_kg,r.remarks,r.created_at
      FROM production.fabric_production fp
      LEFT JOIN production.fabric_production_rolls r ON r.production_id=fp.id
      JOIN jobwork.job_orders jo ON jo.id=fp.job_order_id
      WHERE jo.job_no=$1 ORDER BY fp.production_date DESC,fp.id DESC
    `,[req.params.jobNo]);
    res.json({success:true,history:result.rows});
  }catch(e){console.error('Get production history failed:',e);res.status(500).json({success:false,error:e.message});}
});

router.get('/:id',async(req,res)=>{
  try{const job=await getJobById(pool,req.params.id);if(!job)return res.status(404).json({success:false,error:'Job order not found'});res.json({success:true,job});}
  catch(e){console.error('Get job failed:',e);res.status(500).json({success:false,error:e.message});}
});

router.post('/',async(req,res)=>{
  const b=req.body||{};
  const partyId=uuid(b.party_id??b.partyId), fabricId=uuid(b.fabric_id??b.fabricId);
  const qty=toNumber(b.order_quantity??b.orderQuantity);
  if(!partyId||!fabricId||qty<=0)return res.status(400).json({success:false,error:'Party, fabric and order quantity are required'});
  const machines=Array.isArray(b.machines??b.machine_ids??b.machineIds)?(b.machines??b.machine_ids??b.machineIds):[];
  const yarns=Array.isArray(b.yarns)?b.yarns:[];
  const client=await pool.connect();
  try{
    await client.query('BEGIN');
    const fy=await client.query(`SELECT id FROM core.financial_years WHERE company_id=$1 AND is_current AND NOT is_closed LIMIT 1`,[COMPANY_ID]);
    if(!fy.rows.length)throw new Error('No open financial year for company');
    const party=await client.query(`SELECT id FROM master.parties WHERE id=$1 AND company_id=$2 AND is_active`,[partyId,COMPANY_ID]);
    if(!party.rows.length)throw new Error('Selected party does not exist');
    const fabric=await client.query(`SELECT id FROM master.fabrics WHERE id=$1 AND company_id=$2 AND is_active`,[fabricId,COMPANY_ID]);
    if(!fabric.rows.length)throw new Error('Selected fabric does not exist');
    const number=await client.query(`SELECT COALESCE(MAX(CAST(NULLIF(SUBSTRING(job_no FROM '^BBJO-([0-9]+)$'),'') AS INTEGER)),0)+1 next_no FROM jobwork.job_orders WHERE company_id=$1`,[COMPANY_ID]);
    const jobNo=`BBJO-${String(Number(number.rows[0].next_no)).padStart(5,'0')}`;
    const inserted=await client.query(`
      INSERT INTO jobwork.job_orders(company_id,financial_year_id,job_no,job_date,party_id,fabric_id,design_no,order_quantity_kg,status,notes)
      VALUES($1,$2,$3,COALESCE($4::date,CURRENT_DATE),$5,$6,$7,$8,$9,$10) RETURNING id
    `,[COMPANY_ID,fy.rows[0].id,jobNo,b.job_date??b.jobDate??null,partyId,fabricId,cleanString(b.design_no??b.designNo)||null,qty,cleanString(b.status).toUpperCase()||'OPEN',cleanString(b.notes)||null]);
    const jobId=inserted.rows[0].id;
    for(const m of machines){
      const mid=typeof m==='object'?(m.machine_id??m.id):m;
      if(!mid)continue;
    const check=await client.query(`
  SELECT id
  FROM master.machines
  WHERE company_id=$1
    AND is_active
    AND (id::text=$2 OR machine_no=$2)
  LIMIT 1
`,[COMPANY_ID,String(mid)]);

if(!check.rows.length)throw new Error(`Machine ${mid} does not exist`);

await client.query(
  `INSERT INTO jobwork.job_order_machines(job_order_id,machine_id,is_primary)
   VALUES($1,$2,$3) ON CONFLICT DO NOTHING`,
  [jobId,check.rows[0].id,0]
);  
      
    }
    for(const y of yarns){
      const yarnId=uuid(y.yarn_id??y.yarnId);
      const required=toNumber(y.required_kg??y.requiredKg);
      if(!yarnId||required<=0)throw new Error('Each yarn requirement needs a yarn and required kg');
      const check=await client.query(`SELECT id FROM master.yarns WHERE id=$1 AND is_active`,[yarnId]);
      if(!check.rows.length)throw new Error(`Yarn ${yarnId} does not exist`);
      const percent=y.requirement_percent??y.requirementPercent;
      await client.query(`INSERT INTO jobwork.job_order_yarns(job_order_id,yarn_id,requirement_percent,required_kg) VALUES($1,$2,$3,$4)`,[jobId,yarnId,percent===''||percent==null?null:Number(percent),required]);
    }
    await client.query('COMMIT');
    res.status(201).json({success:true,job:await getJobById(pool,jobId)});
  }catch(e){await client.query('ROLLBACK');console.error('Create job failed:',e);res.status(500).json({success:false,error:e.message});}
  finally{client.release();}
});

router.put('/:id',async(req,res)=>{
  const client=await pool.connect();
  try{
    await client.query('BEGIN');
    const id=req.params.id;
    const exists=await client.query(`SELECT id FROM jobwork.job_orders WHERE id=$1 AND company_id=$2 FOR UPDATE`,[id,COMPANY_ID]);
    if(!exists.rows.length){await client.query('ROLLBACK');return res.status(404).json({success:false,error:'Job order not found'});}
    const b=req.body||{};
    await client.query(`
      UPDATE jobwork.job_orders SET job_date=COALESCE($1::date,job_date),party_id=COALESCE($2,party_id),
      fabric_id=COALESCE($3,fabric_id),design_no=COALESCE(NULLIF($4,''),design_no),
      order_quantity_kg=COALESCE($5,order_quantity_kg),status=COALESCE(NULLIF($6,''),status),
      notes=COALESCE(NULLIF($7,''),notes),updated_at=NOW() WHERE id=$8 AND company_id=$9
    `,[b.job_date??b.jobDate??null,b.party_id??b.partyId??null,b.fabric_id??b.fabricId??null,
      cleanString(b.design_no??b.designNo),toNumber(b.order_quantity??b.orderQuantity)||null,
      cleanString(b.status).toUpperCase(),cleanString(b.notes),id,COMPANY_ID]);
    if(b.machines!==undefined||b.machine_ids!==undefined||b.machineIds!==undefined){
      const list=b.machines??b.machine_ids??b.machineIds??[];
      await client.query(`DELETE FROM jobwork.job_order_machines WHERE job_order_id=$1`,[id]);
      for(const m of list){const mid=typeof m==='object'?(m.machine_id??m.id):m; if(mid)await client.query(`INSERT INTO jobwork.job_order_machines(job_order_id,machine_id,is_primary) VALUES($1,$2,false) ON CONFLICT DO NOTHING`,[id,mid]);}
    }
    if(b.yarns!==undefined){
      await client.query(`DELETE FROM jobwork.job_order_yarns WHERE job_order_id=$1`,[id]);
      for(const y of b.yarns){const yarnId=uuid(y.yarn_id??y.yarnId);const required=toNumber(y.required_kg??y.requiredKg);if(yarnId&&required>0)await client.query(`INSERT INTO jobwork.job_order_yarns(job_order_id,yarn_id,requirement_percent,required_kg) VALUES($1,$2,$3,$4)`,[id,yarnId,y.requirement_percent??y.requirementPercent??null,required]);}
    }
    await client.query('COMMIT');res.json({success:true,job:await getJobById(pool,id)});
  }catch(e){await client.query('ROLLBACK');console.error('Update job failed:',e);res.status(500).json({success:false,error:e.message});}
  finally{client.release();}
});

router.delete('/:id',async(req,res)=>{
  const client=await pool.connect();
  try{
    await client.query('BEGIN');
    const id=req.params.id;
    const j=await client.query(`SELECT id,job_no FROM jobwork.job_orders WHERE id=$1 AND company_id=$2 FOR UPDATE`,[id,COMPANY_ID]);
    if(!j.rows.length){await client.query('ROLLBACK');return res.status(404).json({success:false,error:'Job order not found'});}
    const posted=await client.query(`SELECT 1 FROM jobwork.yarn_issues WHERE job_order_id=$1 AND status='POSTED' LIMIT 1`,[id]);
    const prod=await client.query(`SELECT 1 FROM production.fabric_production WHERE job_order_id=$1 AND status='POSTED' LIMIT 1`,[id]);
    if(posted.rows.length||prod.rows.length){await client.query('ROLLBACK');return res.status(409).json({success:false,error:`${j.rows[0].job_no} cannot be deleted after posted yarn issue or production.`});}
    await client.query(`DELETE FROM jobwork.job_order_machines WHERE job_order_id=$1`,[id]);
    await client.query(`DELETE FROM jobwork.job_order_yarns WHERE job_order_id=$1`,[id]);
    await client.query(`DELETE FROM jobwork.job_orders WHERE id=$1`,[id]);
    await client.query('COMMIT');res.json({success:true,message:`${j.rows[0].job_no} deleted successfully`,id});
  }catch(e){await client.query('ROLLBACK');console.error('Delete job failed:',e);res.status(500).json({success:false,error:e.message});}
  finally{client.release();}
});

router.post('/:id/production',async(req,res)=>{
  try{
    const b=req.body||{}, jobId=req.params.id;
    const machineId=b.machine_id??b.machineId, qty=toNumber(b.quantity_kg??b.quantityKg);
    if(!machineId||qty<=0)return res.status(400).json({success:false,error:'Machine and quantity_kg are required'});
    const job=await pool.query(`SELECT id FROM jobwork.job_orders WHERE id=$1 AND company_id=$2`,[jobId,COMPANY_ID]);
    if(!job.rows.length)return res.status(404).json({success:false,error:'Job order not found'});
    const prod=await pool.query(`
      INSERT INTO production.fabric_production(company_id,financial_year_id,job_order_id,machine_id,production_date,status,notes)
      SELECT $1,fy.id,$2,$3,COALESCE($4::date,CURRENT_DATE),'POSTED',$5
      FROM core.financial_years fy WHERE fy.company_id=$1 AND fy.is_current AND NOT fy.is_closed
      RETURNING id
    `,[COMPANY_ID,jobId,machineId,b.production_date??b.productionDate??null,cleanString(b.remarks)]);
    if(!prod.rows.length)return res.status(400).json({success:false,error:'No open financial year'});
    const roll=await pool.query(`
      INSERT INTO production.fabric_production_rolls(production_id,roll_no,gross_weight_kg,tare_weight_kg,net_weight_kg,meters,width_inches,gsm,remarks)
      VALUES($1,$2,$3,0,$3,$4,$5,$6,$7)
      RETURNING id,roll_no,net_weight_kg
    `,[prod.rows[0].id,cleanString(b.roll_no??b.rollNo)||null,qty,toNumber(b.meters),b.width_inches??b.widthInches??null,b.gsm??null,cleanString(b.remarks)||null]);
    res.status(201).json({success:true,production:roll.rows[0]});
  }catch(e){console.error('Add production failed:',e);res.status(500).json({success:false,error:e.message});}
});

router.post('/production-batch',async(req,res)=>{
  const entries=Array.isArray(req.body?.entries)?req.body.entries:[];
  if(!entries.length)return res.status(400).json({success:false,error:'At least one production roll is required'});
  const client=await pool.connect();
  try{
    await client.query('BEGIN');const saved=[];
    for(const b of entries){
      const jobId=b.job_id??b.jobId,machineId=b.machine_id??b.machineId,qty=toNumber(b.quantity_kg??b.quantityKg);
      if(!jobId||!machineId||qty<=0)throw new Error('Each production line needs job, machine and quantity');
      const prod=await client.query(`
        INSERT INTO production.fabric_production(company_id,financial_year_id,job_order_id,machine_id,production_date,status,notes)
        SELECT $1,fy.id,$2,$3,COALESCE($4::date,CURRENT_DATE),'POSTED',$5
        FROM core.financial_years fy WHERE fy.company_id=$1 AND fy.is_current AND NOT fy.is_closed
        RETURNING id
      `,[COMPANY_ID,jobId,machineId,b.production_date??b.productionDate??null,cleanString(b.remarks)]);
      if(!prod.rows.length)throw new Error('No open financial year');
      const roll=await client.query(`
        INSERT INTO production.fabric_production_rolls(production_id,roll_no,gross_weight_kg,tare_weight_kg,net_weight_kg,meters,width_inches,gsm,remarks)
        VALUES($1,$2,$3,0,$3,$4,$5,$6,$7)
        RETURNING id,roll_no,net_weight_kg
      `,[prod.rows[0].id,cleanString(b.roll_no??b.rollNo)||null,qty,toNumber(b.meters),b.width_inches??b.widthInches??null,b.gsm??null,cleanString(b.remarks)||null]);
      saved.push(roll.rows[0]);
    }
    await client.query('COMMIT');res.status(201).json({success:true,count:saved.length,production:saved});
  }catch(e){await client.query('ROLLBACK');console.error('Production batch failed:',e);res.status(500).json({success:false,error:e.message});}
  finally{client.release();}
});

module.exports=router;
