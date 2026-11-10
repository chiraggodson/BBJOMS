# Database setup

`setup_fresh_v2.psql` is the ordered schema setup for a **new, empty** BBJOMS 2.0 database. Run it with `psql -d YOUR_DATABASE -f setup_fresh_v2.psql` from `backend/database`. It uses the versioned core, master, factory, yarn, jobwork, return, and production SQL files.

Do not run the fresh setup against a database that already contains BBJOMS data. Back up an existing database and verify which schema scripts have already been applied before running any migration. The app does not apply migrations at startup.

The older `migrations/001` through `005` files create a legacy default-schema model and are not the bootstrap chain for the current backend, which uses `core`, `master`, `jobwork`, `inventory`, and `production` schemas. The standalone `migrations/006` file adds yarn returns and setting-cloth records to a database that already has the BBJOMS 2.0 foundation.