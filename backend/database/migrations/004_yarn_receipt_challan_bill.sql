-- 004_yarn_receipt_challan_bill.sql
-- Yarn receipts use one header with multiple yarn lines.
-- Challan and Bill are separate references because one document can contain
-- multiple yarn items.

BEGIN;

ALTER TABLE inventory.yarn_receipts
  ADD COLUMN IF NOT EXISTS challan_no VARCHAR(100),
  ADD COLUMN IF NOT EXISTS bill_no VARCHAR(100);

COMMIT;
