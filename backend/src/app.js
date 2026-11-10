const express = require('express');
const cors = require('cors');

const app = express();

const partyRoutes = require('./routes/party.routes');
const jobRoutes = require('./routes/job.routes');
const fabricRoutes = require('./routes/fabric.routes');
const machineRoutes = require('./routes/machine.routes');
const yarnRoutes = require('./routes/yarn.routes');
const yarnReceiptRoutes = require('./routes/yarn_receipt.routes');
const jobMaterialRoutes = require('./routes/job_material.routes');
const reportRoutes = require('./routes/reports.routes');

const allowedOrigins = new Set(
  (process.env.CORS_ORIGINS || 'http://localhost:3000,http://127.0.0.1:3000,http://192.168.1.69:3000')
    .split(',')
    .map(origin => origin.trim())
    .filter(Boolean)
);

app.use(cors({
  origin(origin, callback) {
    if (!origin || allowedOrigins.has(origin)) return callback(null, true);
    return callback(new Error('Origin is not allowed by CORS'));
  },
}));
app.use(express.json({ limit: '1mb' }));

app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    service: 'BBJOMS Backend',
    status: 'healthy',
  });
});

app.get('/api/health/database', async (req, res) => {
  try {
    const { testDatabaseConnection } = require('./db');

    const result = await testDatabaseConnection();

    res.json({
      success: true,
      database: 'connected',
      time: result.time,
    });
  } catch (error) {
    console.error(
      'Database health check failed:',
      error
    );

    res.status(500).json({
      success: false,
      database: 'disconnected',
      error: 'Database connection failed',
    });
  }
});

app.use('/api/parties', partyRoutes);
app.use('/api/jobs', jobRoutes);
app.use('/api/job-materials', jobMaterialRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/fabrics', fabricRoutes);
app.use('/api/machines', machineRoutes);
app.use('/api/yarns', yarnRoutes);
app.use('/api/yarn-receipts', yarnReceiptRoutes);

module.exports = app;