const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

pool.on('error', (error) => {
  console.error('Unexpected PostgreSQL error:', error);
});

async function testDatabaseConnection() {
  const result = await pool.query('SELECT NOW() AS time');
  return result.rows[0];
}

module.exports = {
  pool,
  testDatabaseConnection,
};