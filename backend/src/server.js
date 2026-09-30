
require('dotenv').config();

const app = require('./app');
const { pool } = require('./db');

const PORT = Number(process.env.PORT) || 4000;
const HOST = '0.0.0.0';

async function startServer() {
  try {
    // Verify DB connection
    await pool.query('SELECT NOW()');

    console.log('=================================');
    console.log('🚀 Starting BBJOMS');
    console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log('=================================');

    const server = app.listen(PORT, HOST, () => {
      console.log(`✅ Server running on port ${PORT}`);
      console.log(`🌐 Local: http://localhost:${PORT}`);
      console.log('=================================');
    });

    // Graceful shutdown
    const shutdown = async () => {
      console.log('\n🛑 Gracefully shutting down...');

      await pool.end();

      server.close(() => {
        console.log('✅ Server closed');
        process.exit(0);
      });
    };

    process.on('SIGINT', shutdown);
    process.on('SIGTERM', shutdown);

  } catch (error) {
    console.error('❌ Failed to start server');
    console.error(error.message);
    process.exit(1);
  }
}

startServer();