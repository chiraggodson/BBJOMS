# Database setup

`setup_fresh_v2.psql` is the ordered schema setup for a **new, empty** BBJOMS 2.0 database. Run it with `psql -d YOUR_DATABASE -f setup_fresh_v2.psql` from `backend/database`. It uses the versioned core, master, factory, yarn, jobwork, return, and production SQL files.

Do not run the fresh setup against a database that already contains BBJOMS data. Back up an existing database and verify which schema scripts have already been applied before running any migration. The app does not apply migrations at startup.

The older `migrations/001` through `005` files create a legacy default-schema model and are not the bootstrap chain for the current backend, which uses `core`, `master`, `jobwork`, `inventory`, and `production` schemas. Migrations `006` and `007` add yarn returns/setting cloth and finished-fabric lots/dispatch to the BBJOMS 2.0 foundation. The fresh setup includes both. Migration `007` does not assume previously produced fabric is still physically on hand; reconcile existing rolls before making them dispatchable. For an existing database, back it up and apply each migration that has not already been run, after verifying its schema version and state. The app does not apply migrations at startup.
