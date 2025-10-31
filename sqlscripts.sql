-- Course: Advanced databased technoloy
-- Topic: Parallel and Distributed Databases 
-- Use case: Smart Parking Management and Ticketing System (PostgreSQL)
-- Database name: parkingsystem
-- Author: Kabwali Masudi Dischon
-- Registration number: 223027551

-- Note: This assignment should have benn implemented on ORACLE developer but i met some issues when installing it on my computer


-- PRELUDE: Connect to the main database parkingticketingsystem and two logical branch databases (\c parkingticketingsystem)

-- Run these commands as a superuser/administrator (postgres)
-- Create three databases: central (optional) and two branch DBs
-- Run two branch DBs on the same PostgreSQL instance to simulate nodes,
-- or create actual separate instances for a stronger simulation.
-- Connect to the main database (optional: which isparkingticketingsystem; i'll use branch DBs as logical nodes)
CREATE DATABASE parkingsystem_branch_a;
CREATE DATABASE parkingsystem_branch_b;

-- SECTION A: Create base schemas on both BranchDB_A and BranchDB_B

-- Connect to parkingsystem_branch_a and run the following script
-- (postgres=# \c parkingsystem_branch_a)
-- Branch A schema (horizontal fragmentation example)
-- Parking lots with Location starting with 'A' will be stored here
CREATE SCHEMA IF NOT EXISTS parking;

-- Connect to Branch A database
-- \c parkingsystem_branch_a

-- Create schema for Parking Management
CREATE SCHEMA IF NOT EXISTS parking;

-- -- Table 1: ParkingLot (LotID, Name, Location, Capacity, Status)
CREATE TABLE parking.parkinglot (
  lotid      SERIAL PRIMARY KEY,
  name       TEXT NOT NULL,
  location   TEXT NOT NULL CHECK (location <> ''),  -- must not be empty . This is "ZoneA-Block1"
  capacity   INTEGER NOT NULL CHECK (capacity > 0), -- positive capacity
  status     TEXT NOT NULL CHECK (status IN ('OPEN', 'CLOSED')) -- constraint
);

-- Table 2: Space (SpaceID, LotID, SpaceNo, Status, Type)
CREATE TABLE parking.space (
  spaceid   SERIAL PRIMARY KEY,
  lotid     INTEGER NOT NULL REFERENCES parking.parkinglot(lotid) ON DELETE CASCADE, -- deleting a lot removes all its spaces
  spaceno   TEXT NOT NULL,
  status    TEXT NOT NULL CHECK (status IN ('FREE', 'OCCUPIED', 'RESERVED')),
  type      TEXT NOT NULL CHECK (type IN ('CAR', 'MOTORCYCLE', 'HANDICAP'))
);

-- Table 3: Vehicle (VehicleID, PlateNo, Type, OwnerName, Contact)
CREATE TABLE parking.vehicle (
  vehicleid SERIAL PRIMARY KEY,
  plateno   TEXT UNIQUE NOT NULL,
  type      TEXT NOT NULL CHECK (type IN ('CAR', 'MOTORCYCLE', 'TRUCK')),
  ownername TEXT NOT NULL,
  contact   TEXT
);

-- Table 4: Staff (StaffID, FullName, Role, Contact, Shift)
CREATE TABLE parking.staff (
  staffid  SERIAL PRIMARY KEY,
  fullname TEXT NOT NULL,
  role     TEXT NOT NULL CHECK (role IN ('ATTENDANT', 'SUPERVISOR', 'MANAGER')),
  contact  TEXT,
  shift    TEXT CHECK (shift IN ('DAY', 'NIGHT'))
);

-- Table 5: Ticket (TicketID, SpaceID, VehicleID, EntryTime, ExitTime, Status, staffid)
CREATE TABLE parking.ticket (
  ticketid  SERIAL PRIMARY KEY,
  spaceid   INTEGER NOT NULL REFERENCES parking.space(spaceid) ON DELETE RESTRICT,
  vehicleid INTEGER NOT NULL REFERENCES parking.vehicle(vehicleid) ON DELETE RESTRICT,
  entrytime TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
  exittime  TIMESTAMP WITHOUT TIME ZONE,
  status    TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'CLOSED')),
  staffid   INTEGER REFERENCES parking.staff(staffid)
);

-- Table 6 : Payment (PaymentID, TicketID, Amount, PaymentDate, Method)
CREATE TABLE parking.payment (
  paymentid   SERIAL PRIMARY KEY,
  ticketid    INTEGER UNIQUE NOT NULL REFERENCES parking.ticket(ticketid)
               ON DELETE CASCADE, -- CASCADE DELETE between Ticket → Payment
  amount      NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
  paymentdate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
  method      TEXT NOT NULL CHECK (method IN ('CASH', 'CARD', 'MOBILE'))
);

-- Optional: add an INDEX useful for queries
CREATE INDEX idx_space_lotid ON parking.space(lotid);
CREATE INDEX idx_ticket_space ON parking.ticket(spaceid);
CREATE INDEX idx_ticket_vehicle ON parking.ticket(vehicleid);

-- Branch B schema (horizontal fragmentation example)

-- Connect to parkingsystem_branch_b and run the same schema definitions:
-- In psql: \c parkingsystem_branch_b (I can copy-paste the same block used for Branch A, to create identical schemas)
-- For brevity, repeat the same schema creation on Branch B:
-- Connect to Branch B database: \c parkingsystem_branch_b
-- Create schema for Parking Management
CREATE SCHEMA IF NOT EXISTS parking;

-- -- Table 1: ParkingLot (LotID, Name, Location, Capacity, Status)
CREATE TABLE parking.parkinglot (
  lotid      SERIAL PRIMARY KEY,
  name       TEXT NOT NULL,
  location   TEXT NOT NULL CHECK (location <> ''),  -- must not be empty . This is "ZoneA-Block1"
  capacity   INTEGER NOT NULL CHECK (capacity > 0), -- positive capacity
  status     TEXT NOT NULL CHECK (status IN ('OPEN', 'CLOSED')) -- constraint
);

-- Table 2: Space (SpaceID, LotID, SpaceNo, Status, Type)
CREATE TABLE parking.space (
  spaceid   SERIAL PRIMARY KEY,
  lotid     INTEGER NOT NULL REFERENCES parking.parkinglot(lotid) ON DELETE CASCADE, -- deleting a lot removes all its spaces
  spaceno   TEXT NOT NULL,
  status    TEXT NOT NULL CHECK (status IN ('FREE', 'OCCUPIED', 'RESERVED')),
  type      TEXT NOT NULL CHECK (type IN ('CAR', 'MOTORCYCLE', 'HANDICAP'))
);

-- Table 3: Vehicle (VehicleID, PlateNo, Type, OwnerName, Contact)
CREATE TABLE parking.vehicle (
  vehicleid SERIAL PRIMARY KEY,
  plateno   TEXT UNIQUE NOT NULL,
  type      TEXT NOT NULL CHECK (type IN ('CAR', 'MOTORCYCLE', 'TRUCK')),
  ownername TEXT NOT NULL,
  contact   TEXT
);

-- Table 4: Staff (StaffID, FullName, Role, Contact, Shift)
CREATE TABLE parking.staff (
  staffid  SERIAL PRIMARY KEY,
  fullname TEXT NOT NULL,
  role     TEXT NOT NULL CHECK (role IN ('ATTENDANT', 'SUPERVISOR', 'MANAGER')),
  contact  TEXT,
  shift    TEXT CHECK (shift IN ('DAY', 'NIGHT'))
);

-- Table 5: Ticket (TicketID, SpaceID, VehicleID, EntryTime, ExitTime, Status, staffid)
CREATE TABLE parking.ticket (
  ticketid  SERIAL PRIMARY KEY,
  spaceid   INTEGER NOT NULL REFERENCES parking.space(spaceid) ON DELETE RESTRICT,
  vehicleid INTEGER NOT NULL REFERENCES parking.vehicle(vehicleid) ON DELETE RESTRICT,
  entrytime TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
  exittime  TIMESTAMP WITHOUT TIME ZONE,
  status    TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'CLOSED')),
  staffid   INTEGER REFERENCES parking.staff(staffid)
);
-- Table 6 : Payment (PaymentID, TicketID, Amount, PaymentDate, Method)
CREATE TABLE parking.payment (
  paymentid   SERIAL PRIMARY KEY,
  ticketid    INTEGER UNIQUE NOT NULL REFERENCES parking.ticket(ticketid)
               ON DELETE CASCADE, -- CASCADE DELETE between Ticket → Payment
  amount      NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
  paymentdate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
  method      TEXT NOT NULL CHECK (method IN ('CASH', 'CARD', 'MOBILE'))
);

-- Optional: add an INDEX useful for queries
CREATE INDEX idx_space_lotid ON parking.space(lotid);
CREATE INDEX idx_ticket_space ON parking.ticket(spaceid);
CREATE INDEX idx_ticket_vehicle ON parking.ticket(vehicleid);

-- SECTION B (Question 1): Distributed schema design and fragmentation strategy

-- Explanation:
-- Horizontal fragmentation: we partition records by ParkingLot.location.
-- Example policy:
--  - Branch A stores parking lots where location LIKE 'A%' (Zone A)
--  - Branch B stores parking lots where location LIKE 'B%' (Zone B)
-- We'll enforce this at application level or with check constraints.

-- Add CHECK constraints to enforce fragmentation (example)
-- On Branch A (connect to parkingsystem_branch_a):
ALTER TABLE parking.parkinglot
  ADD COLUMN IF NOT EXISTS fragment_tag TEXT DEFAULT 'A';
-- Enforce: only rows with 'A' allowed in Branch A (application-level or trigger)
-- Example CHECK:
ALTER TABLE parking.parkinglot
  ADD CONSTRAINT chk_fragment_a CHECK (left(location,1) = 'A');

-- On Branch B (connect to parkingsystem_branch_b):
ALTER TABLE parking.parkinglot
  ADD COLUMN IF NOT EXISTS fragment_tag TEXT DEFAULT 'B';
ALTER TABLE parking.parkinglot
  ADD CONSTRAINT chk_fragment_b CHECK (left(location,1) = 'B');

-- Entity Relation Diagram (ERD): Use draw.io (or Graphviz dot)


-- SECTION C: Populate demo data (small sample + larger for perfect tests)

-- Run on each branch with appropriate sample locations
-- Branch A sample inserts (connect to branch_a)
INSERT INTO parking.parkinglot (name, location, capacity, status) VALUES
  ('Main A1', 'A-01', 100, 'OPEN'),
  ('A MultiStorey', 'A-02', 200, 'OPEN');

INSERT INTO parking.space (lotid, spaceno, status, type)
SELECT p.lotid, 'S' || s, 'FREE', 'CAR'
FROM parking.parkinglot p CROSS JOIN generate_series(1,50) s
WHERE left(p.location,1) = 'A';

-- Add vehicles
INSERT INTO parking.vehicle (plateno, type, ownername, contact) VALUES
 ('RWA-1001', 'CAR', 'Alice', '250-xxx'),
 ('RWA-1002', 'MOTORCYCLE', 'Bob', '250-yyy');

-- Branch B sample inserts (connect to branch_b)
INSERT INTO parking.parkinglot (name, location, capacity, status) VALUES
  ('Main B1', 'B-01', 80, 'OPEN'),
  ('B East', 'B-02', 120, 'OPEN');

INSERT INTO parking.space (lotid, spaceno, status, type)
SELECT p.lotid, 'S' || s, 'FREE', 'CAR'
FROM parking.parkinglot p CROSS JOIN generate_series(1,40) s
WHERE left(p.location,1) = 'B';

INSERT INTO parking.vehicle (plateno, type, ownername, contact) VALUES
 ('RWA-2001', 'CAR', 'Charlie', '250-aaa'),
 ('RWA-2002', 'CAR', 'Diana', '250-bbb');

-- SECTION D (Question 2): Create FDW (Create and use database links) between Branch A and Branch B

-- I'll create postgres_fdw in Branch A to access Branch B (simulate a db link).
-- On Branch A: connect to parkingsystem_branch_a

-- 1) Enable extension (superuser required)
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- 2) Create foreign server pointing to branch_b (adjust host/port/user as needed)
-- If branch_b is on same instance, use 'localhost' and same port.
-- Replace host/port/user/password with actual values if remote.
CREATE SERVER branch_b_srv
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'localhost', dbname 'parkingsystem_branch_b', port '5432');

-- 3) Create user mapping for current user (use password if needed)
CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER
  SERVER branch_b_srv
  OPTIONS (user 'postgres', password 'your_password_here'); -- your_password_here

-- 4) Import or create foreign tables
-- Import foreign table definitions for parking.parkinglot and parking.space
-- I'll create foreign tables in schema parking_fdw on Branch A
CREATE SCHEMA IF NOT EXISTS parking_fdw;

IMPORT FOREIGN SCHEMA parking
  LIMIT TO (parkinglot, space, vehicle, ticket, staff, payment)
  FROM SERVER branch_b_srv
  INTO parking_fdw;
-- The IMPORT will create foreign tables named parkinglot, space, etc, under parking_fdw.

-- 5) Example remote SELECT (run on Branch A)
-- Select all lots from Branch B via FDW
SELECT * FROM parking_fdw.parkinglot LIMIT 5;

-- 6) Example distributed join: join local space with remote parkinglot
-- Suppose i want to list spaces in Branch B with local branch_a vehicles (just demo)
SELECT s.spaceid, s.spaceno, p.name AS lot_name, p.location
FROM parking.space s
JOIN parking_fdw.parkinglot p ON s.lotid = p.lotid
LIMIT 10;
-- This executes a join that may fetch rows from remote server.

-- SECTION E (Question 3): Parallel query execution

-- Steps to enable:
--  1. Ensure the PostgreSQL server has multiple worker slots:
--     ALTER SYSTEM SET max_parallel_workers = 8;
--     ALTER SYSTEM SET max_worker_processes = 8;
--     ALTER SYSTEM SET max_parallel_workers_per_gather = 4;
--  2. Restart the server if necessary. Or set at session:
SET max_parallel_workers_per_gather = 4; -- Run inside each branch database (A and B) where i want to test or allow parallel execution
SET max_parallel_workers = 8;  -- Run inside each branch database (A and B) where i want to test or allow parallel execution
-- Enable timing output in psql:
-- In psql: \timing on

-- Create a large transactions-like table to test parallelism
-- Connect to a single branch: Branch A and run:
CREATE TABLE IF NOT EXISTS parking.txn AS
SELECT
  gs AS txn_id,
  (now() - (random() * interval '365 days'))::timestamp AS txn_time,
  (1 + (random()*10))::int AS amount,
  (array['PAYMENT','REFUND','CHARGE'])[1 + floor(random()*3)::int] as txn_type,
  (1 + floor(random()*1000))::int AS lotid
FROM generate_series(1,2000000) gs; -- 2 million rows

-- Add index to support queries
CREATE INDEX IF NOT EXISTS idx_txn_lotid ON parking.txn(lotid);
VACUUM ANALYZE parking.txn;

-- Compare serial vs parallel:
-- Run EXPLAIN ANALYZE (buffers) on a large aggregation:
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT lotid, count(*) AS cnt, sum(amount) AS total
FROM parking.txn
GROUP BY lotid
ORDER BY total DESC
LIMIT 10;

-- Toggle parallelism off and repeat to compare:
SET max_parallel_workers_per_gather = 0;
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT lotid, count(*) AS cnt, sum(amount) AS total
FROM parking.txn
GROUP BY lotid
ORDER BY total DESC
LIMIT 10;

-- Re-enable default after testing:
SET max_parallel_workers_per_gather = 4; -- Run inside each branch database (A and B) where i want to test or allow parallel execution

-- Save the two EXPLAIN outputs and their "Execution Time" / "actual time" lines for report.

-- SECTION F (Question 4): Two-phase commit simulation

-- I'll simulate a distributed transaction that updates Branch A and Branch B in one atomic operation.
-- Steps (requires two separate sessions or two psql windows):

-- Session 1 (on Branch A) begin distributed tx:
-- BEGIN;
-- Example: insert a ticket in local (Branch A) and in remote (Branch B) via FDW
-- For the remote insert to participate in 2PC, remote must be accessed with a FOREIGN DATA WRAPPER that supports two-phase commit.
-- postgres_fdw supports two-phase commit when prepared transactions are used and the remote is on same major version.

-- Example sequence (Session 1, Branch A):
BEGIN;
INSERT INTO parking.ticket (spaceid, vehicleid, entrytime, status) VALUES (1,1, now(), 'ACTIVE');
-- Insert into remote server via an explicit dblink or via FDW + execute remote INSERT (fdw will send remote commands)
-- Option A: Use dblink extension to execute statements on Branch B (recommended for explicit 2PC):
CREATE EXTENSION IF NOT EXISTS dblink;

-- Perform remote insert using dblink (this runs on Branch B in the context of Branch B session)

SELECT dblink_connect('connB', 'host=localhost dbname=parkingsystem_branch_b user=postgres password=mas098');
SELECT dblink_exec('connB',
  $$INSERT INTO parking.ticket (spaceid, vehicleid, entrytime, status) VALUES (1, 2, now(), 'ACTIVE')$$
);

-- Establish a secure connection to Branch B
SELECT dblink_connect(
  'connB',
  'host=localhost port=5432 dbname=parkingsystem_branch_b user=postgres password=correct_password_here'
);

-- Now i prepare the local transaction:
-- Note: PostgreSQL's 2PC uses PREPARE TRANSACTION '<gid>'
PREPARE TRANSACTION 'dist_tx_001';
-- At this point, the transaction is prepared on Branch A. The remote dblink action has executed a statement on 
-- Branch B in its own session; to achieve true 2PC across servers you would use two-phase commit drivers or 
-- application-coordinator that issues PREPARE on both sides. For simulation, we prepare the local and then simulate
--  remote prepare by running PREPARE on Branch B manually (see below).

-- On Branch B: connect and find the session that did dblink_exec (you may need to control remote session)
-- For simulation, on Branch B open a transaction and PREPARE TRANSACTION 'dist_tx_001_remote' then COMMIT PREPARED later.

-- To inspect prepared transactions (DBA_2PC_PENDING analogue):
SELECT * FROM pg_prepared_xacts;

-- Commit prepared:
COMMIT PREPARED 'dist_tx_001';
-- If something went wrong i can:
-- ROLLBACK PREPARED 'dist_tx_001'; 

-- Note: In practice, to coordinate 2PC you need a transaction coordinator (application code) that issues PREPARE 
-- TRANSACTION on each involved node; this script shows how to PREPARE and COMMIT PREPARED in Postgres.

-- SECTION G (Question 5): Distributed rollback and recovery, simulate network failure and recovery

-- Steps to simulate network failure during a distributed transaction:
-- 1) Start distributed work and PREPARE TRANSACTION on one node.
-- 2) Kill the other node's session (or disconnect the network).
-- 3) Use pg_prepared_xacts to see unresolved prepared transactions.
-- 4) Use ROLLBACK PREPARED or COMMIT PREPARED from a DBA session to resolve.

-- Example:
-- On Branch B: start a transaction, insert, and PREPARE TRANSACTION 'tx_for_recovery'
-- In a different session: simulate failure by terminating the session (pg_terminate_backend(pid)) or kill process.
-- Then as superuser:
SELECT * FROM pg_prepared_xacts;  -- shows prepared transactions waiting
-- Force rollback:
ROLLBACK PREPARED 'tx_for_recovery';
-- Or force commit (if safe):
COMMIT PREPARED 'tx_for_recovery';

-- SECTION H (Question 6): Distributed concurrency control

-- Demonstrate locking conflict between two sessions updating same record.

-- Step A (Session 1 on Branch A):
BEGIN;
-- Acquire exclusive lock on a specific parking.space row:
UPDATE parking.space SET status = 'OCCUPIED' WHERE spaceid = 1;
-- Do NOT commit yet. This transaction holds the lock.

-- Step B (Session 2 on Branch A or Branch B using FDW/remote update):
-- Attempt to update the same space:
BEGIN;
UPDATE parking.space SET status = 'MAINTENANCE' WHERE spaceid = 1;
-- This will block until session 1 commits/rollbacks.

-- In a separate session, inspect locks:
SELECT pid, locktype, relation::regclass AS relation, page, tuple, virtualtransaction, mode, granted
FROM pg_locks pl
LEFT JOIN pg_class pc ON pl.relation = pc.oid
WHERE relation::text LIKE '%space%';

-- Or more complete:
SELECT a.pid, a.usename, a.query, l.mode, l.granted
FROM pg_stat_activity a
JOIN pg_locks l ON a.pid = l.pid
WHERE l.relation = 'parking.space'::regclass;

-- After testing, roll back both sessions:
ROLLBACK; -- in both sessions

-- SECTION I (Question 7): Parallel data loading / ETL simulation

-- Approach: Partition the target table, and run multiple COPY/INSERT workers in parallel
-- Example: Partition parking.txn by lotid to allow parallel insertion per partition.

-- 1) Create partitioned table (example): on Branch A
DROP TABLE IF EXISTS parking.txn_part;
CREATE TABLE parking.txn_part (
  txn_id bigint,
  txn_time timestamp,
  amount integer,
  txn_type text,
  lotid int
) PARTITION BY HASH (lotid);

-- Create 4 partitions
CREATE TABLE parking.txn_p0 PARTITION OF parking.txn_part FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE parking.txn_p1 PARTITION OF parking.txn_part FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE parking.txn_p2 PARTITION OF parking.txn_part FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE parking.txn_p3 PARTITION OF parking.txn_part FOR VALUES WITH (MODULUS 4, REMAINDER 3);

-- 2) Use multiple client processes to COPY data into different partitions concurrently:
-- From shell, run (example):
-- psql -d parkingsystem_branch_a -c "COPY parking.txn_p0 FROM STDIN WITH (FORMAT csv)" < data_p0.csv &
-- psql -d parkingsystem_branch_a -c "COPY parking.txn_p1 FROM STDIN WITH (FORMAT csv)" < data_p1.csv &
-- 
-- Using 4 parallel COPY processes improves load throughput.

-- Alternatively, use pg_restore -j N when restoring a dump created with directory format.

-- After loads, run ANALYZE and compare runtimes (capture EXPLAIN ANALYZE where needed).

-- SECTION J (Question 8): Three-Tier client - server architecture design (using Python Django codes)

-- Provided separately as draw.io snippet in the pdf document (or Graphviz dot snippet)
-- The three tiers are as follows:
--  - Presentation Tier: Web/Mobile UI
--  - Application Tier: API server with Python Django code (Node/Java) that implements business rules, fragmentation 
-- logic and coordinates 2PC
--  - Database Tier: Branch A and Branch B (postgres instances), FDW / dblink for distribution

-- SECTION K (Question 9): Distributed query optimization

-- Use EXPLAIN (ANALYZE, BUFFERS, VERBOSE) to inspect distributed joins.
-- Example: On Branch A, run a join between local and remote table:
EXPLAIN (ANALYZE, BUFFERS)
SELECT s.spaceid, s.spaceno, p.name, p.location
FROM parking.space s
JOIN parking_fdw.parkinglot p ON s.lotid = p.lotid
WHERE p.location LIKE 'B%';

-- Tips to tune postgres_fdw:
--  - Set option use_remote_estimate = on in the foreign server or foreign table to let planner use remote planner.
--  - Adjust fetch_size to control row fetch batches: ALTER FOREIGN TABLE ... OPTIONS (SET fetch_size '1000');
-- Example:
ALTER SERVER branch_b_srv OPTIONS (SET use_remote_estimate 'on');

-- SECTION L (Question 10): Performance benchmark and report

-- Run one complex query three ways:
--  1) Centralized: Run query on a single DB with all data.
--  2) Parallel: Use large table and enable parallel workers (settings above).
--  3) Distributed: Use FDW join across branch_a and branch_b.

-- Example complex query:

-- (a) Centralized (centralized data in parkingticketingsystem with no schema created)
-- Connect to parkingsystem_main and run:

EXPLAIN (ANALYZE, BUFFERS)
SELECT pl.location, COUNT(t.ticketid) AS open_tickets, SUM(p.amount) AS revenue
FROM parkinglot pl
JOIN space s ON s.lotid = pl.lotid
LEFT JOIN ticket t ON t.spaceid = s.spaceid AND t.status = 'ACTIVE'
LEFT JOIN payment p ON p.ticketid = t.ticketid
GROUP BY pl.location
ORDER BY revenue DESC
LIMIT 20;

-- (b) Parallel: same query on large tables in branch_a with parallel workers enabled
SET max_parallel_workers_per_gather = 4;
EXPLAIN (ANALYZE, BUFFERS)
SELECT pl.location, COUNT(t.ticketid) AS open_tickets, SUM(p.amount) AS revenue
FROM parking.parkinglot pl
JOIN parking.space s ON s.lotid = pl.lotid
LEFT JOIN parking.ticket t ON t.spaceid = s.spaceid AND t.status = 'ACTIVE'
LEFT JOIN parking.txn p ON p.txn_id = t.ticketid
GROUP BY pl.location
ORDER BY revenue DESC
LIMIT 20;

-- (c) Distributed: on branch_a join to branch_b via FDW
EXPLAIN (ANALYZE, BUFFERS)
SELECT pl.location, COUNT(t.ticketid) AS open_tickets, SUM(p.amount) AS revenue
FROM parking.parkinglot pl
JOIN parking.space s ON s.lotid = pl.lotid
LEFT JOIN parking.ticket t ON t.spaceid = s.spaceid AND t.status = 'ACTIVE'
LEFT JOIN parking_fdw.payment p ON p.ticketid = t.ticketid  -- remote payments via FDW
GROUP BY pl.location
ORDER BY revenue DESC
LIMIT 20;

EXPLAIN (ANALYZE, BUFFERS)
SELECT pl.location, COUNT(t.ticketid) AS open_tickets, SUM(p.amount) AS revenue
FROM parking.parkinglot pl
JOIN parking.space s ON s.lotid = pl.lotid
LEFT JOIN parking.ticket t ON t.spaceid = s.spaceid AND t.status = 'ACTIVE'
LEFT JOIN parking_fdw.payment p ON p.ticketid = t.ticketid  -- remote payments via FDW
GROUP BY pl.location
ORDER BY revenue DESC
LIMIT 20;
-- Record "Execution Time" lines and Buffers read/written. Put them into a performance comparison table.

-- CLEANUP / NOTES

-- If i used dblink connections, close them:
SELECT dblink_disconnect('connB');

-- When i finish test runs, remove prepared transactions if any remain:
-- SELECT * FROM pg_prepared_xacts;
-- ROLLBACK PREPARED '<gid>' OR COMMIT PREPARED '<gid>';

-- End of SQL script
