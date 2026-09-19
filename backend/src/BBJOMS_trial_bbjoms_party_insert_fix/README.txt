BBJOMS trial_bbjoms Party INSERT fix

Replace:
backend/src/routes/party.routes.js

Then run 001_party_contact_person.sql against trial_bbjoms if it has not already been run.

The immediate error was:
INSERT has more expressions than target columns

Cause:
The INSERT listed 16 target columns but supplied 17 values. The contact_person
value was present in the values array but contact_person was missing from the
target column list.

This version also fixes the malformed `party. party.phone` expression.
