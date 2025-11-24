-- Let's see how vacuuming works in PostgreSQL
-- Make sure we are in the correct database 
SELECT current_database();
-- If not, use the command below in psql
\c exercises;

-- Drop the table if it exists
DROP TABLE IF EXISTS vacuum_test;
-- Create the table
CREATE TABLE vacuum_test (
    id SERIAL,
    name VARCHAR(50),
    age INT
);
-- Disable autovacuum for this table to see the effects manually
ALTER TABLE vacuum_test SET (autovacuum_enabled = false);
-- Check Autovacuum settings for the table
SELECT 
    n.nspname AS schema_name,
    c.relname AS table_name,
    c.reloptions
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relname = 'vacuum_test';


-- Let's see some statistics about the table
-- But first, what is the block size:
SHOW block_size;  
-- Block Sise is the size of a single page in PostgreSQL, typically 8 KB (8192 bytes).
-- Sometimes it is called a page size, page.

-- Now, check the table statistics
SELECT pg_size_pretty(pg_total_relation_size('vacuum_test')); -- Total size including indexes, toast, etc.
SELECT pg_size_pretty(pg_relation_size('vacuum_test')); -- Size of the main table data only

-- Insert some data
INSERT INTO vacuum_test (name, age) VALUES ('User', 25);

SELECT pg_size_pretty(pg_relation_size('vacuum_test'));

-- Lets see the file path of the table
SELECT pg_relation_filepath('vacuum_test');

-- Go to the file system and check the size of the file
-- If you are using the preentation repo, a vilume is mounted at ./postgres/data
-- So you can check the file size with the command below
-- ls -lh ./postgres/data/base/[database_oid]/[file_name]
-- e.g ls -lh ./postgres/data/base/16399/16452
-- or access the container and check the file size there
-- docker exec -it [container_name] bash
-- e.g. docker exec -it postgres_14_5 bash
-- Then navigate to /var/lib/postgresql/data/base/[database_oid]/ and check the file size with ls -lh


SELECT 
    relname AS table_name,
    n_live_tup AS row_count,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    pg_size_pretty(pg_relation_size(relid)) AS table_size,
    pg_size_pretty(pg_indexes_size(relid)) AS index_size
FROM pg_stat_user_tables
WHERE relname = 'vacuum_test';


-- Let's insert more data
INSERT INTO vacuum_test (name, age) SELECT 'User', 30 FROM generate_series(1, 1000000);


SELECT pg_size_pretty(pg_total_relation_size('vacuum_test'));
SELECT pg_size_pretty(pg_relation_size('vacuum_test'));

-- Let's see random rows from the table
SELECT * FROM vacuum_test ORDER BY RANDOM() LIMIT 10;

-- Let's update some rows
UPDATE vacuum_test SET age = 35 WHERE id > 500000;

-- And then check the table statistics again
SELECT pg_size_pretty(pg_total_relation_size('vacuum_test'));
SELECT pg_size_pretty(pg_relation_size('vacuum_test'));

SELECT 
    relname,
    n_live_tup AS live_tuples,
    n_dead_tup AS dead_tuples,
    n_tup_ins AS inserts,
    n_tup_upd AS updates,
    n_tup_del AS deletes,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
WHERE relname = 'vacuum_test';

-- Let's run vacuum manually
VACUUM VERBOSE vacuum_test;

-- Check the table statistics again
SELECT pg_size_pretty(pg_relation_size('vacuum_test'));
-- Probably, the table size will be the same as before
-- Why? Because vacuum reclaims space for reuse but does not reduce the file size on disk

-- THERE IS A NAME FOR THIS PROBLEM: TABLE BLOAT

-- Now, let's see the VACUUM FULL


-- Functions bellow shoe more about table
-- Sizes in bytes
-- SELECT 
--     relname AS table_name,
--     n_live_tup AS row_count,
--     pg_total_relation_size(relid) AS total_size_bytes,
--     pg_relation_size(relid) AS table_size_bytes,
--     pg_indexes_size(relid) AS index_size_bytes
-- FROM pg_stat_user_tables
-- WHERE relname = 'vacuum_test';

-- -- Calculate pages and records per page
-- SELECT 
--     pg_relation_size('vacuum_test') / 8192 AS total_pages,
--     COUNT(*) AS total_records,
--     COUNT(*) / (pg_relation_size('vacuum_test') / 8192.0) AS records_per_page
-- FROM vacuum_test;
