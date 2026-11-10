const DEFAULT_COMPANY_ID = '37c8cd03-c8ae-48cd-b8e4-cb3e864f042f';
const COMPANY_ID = String(process.env.COMPANY_ID || DEFAULT_COMPANY_ID).trim();

if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(COMPANY_ID)) {
  throw new Error('COMPANY_ID must be a valid UUID.');
}

module.exports = { COMPANY_ID };