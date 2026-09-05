const express = require('express');
const cors = require('cors');

const app = express();

const partyRoutes = require('./routes/party.routes');
const jobRoutes = require('./routes/job.routes');
const fabricRoutes = require('./routes/fabric.routes');
const machineRoutes = require('./routes/machine.routes');
const yarnRoutes = require('./routes/yarn.routes');
const yarnReceiptRoutes = require('./routes/yarn_receipt.routes');

app.use(cors());
app.use(express.json());

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
app.use('/api/fabrics', fabricRoutes);
app.use('/api/machines', machineRoutes);
app.use('/api/yarns', yarnRoutes);
app.use('/api/yarn-receipts', yarnReceiptRoutes);

module.exports = app;