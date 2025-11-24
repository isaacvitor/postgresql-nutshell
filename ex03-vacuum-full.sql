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


-- Now, check the table statistics
SELECT pg_size_pretty(pg_relation_size('vacuum_test'));

-- Insert some data
INSERT INTO vacuum_test (name, age) SELECT 'User', 30 FROM generate_series(1, 1000000);

SELECT pg_size_pretty(pg_relation_size('vacuum_test'));

-- Check table statistics
SELECT 
    relname AS table_name,
    n_live_tup AS row_count,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    pg_size_pretty(pg_relation_size(relid)) AS table_size,
    pg_size_pretty(pg_indexes_size(relid)) AS index_size
FROM pg_stat_user_tables
WHERE relname = 'vacuum_test';


-- Let's see random rows from the table
SELECT * FROM vacuum_test ORDER BY RANDOM() LIMIT 10;

-- Let's update some rows
UPDATE vacuum_test SET age = 35 WHERE id > 500000;

-- And then check the table statistics again
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

SELECT pg_size_pretty(pg_relation_size('vacuum_test'));

-- Let's run vacuum manually
VACUUM FULL VERBOSE vacuum_test;

-- Check the table statistics again
SELECT pg_size_pretty(pg_relation_size('vacuum_test'));
-- Now, let's see the vacuum full effect
-- The table size should be reduced after VACUUM FULL
-- Probably, the table size will be the same as before the update
-- Why? Because VACUUM FULL reclaims space by rewriting the entire table