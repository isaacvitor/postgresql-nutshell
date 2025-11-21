-- Let'create a new database
CREATE DATABASE IF NOT EXISTS exercises;

-- Let's use the database
-- psql only
\c exercises;

-- Let's create a new table without any indexes
DROP TABLE IF EXISTS users;
CREATE TABLE users (
	id SERIAL,
	name VARCHAR(50)
);

-- Let's insert some data samples
INSERT INTO users(name) SELECT 'User' FROM generate_series(1, 1000000);

-- Now, check some a random rows from the table
SELECT * FROM users ORDER BY RANDOM() LIMIT 10;

-- Let's update the statistics for the table

-- Basic syntax:
-- ANALYZE [VERBOSE] [table_name [(column_name [, ...])]]

-- Examples:
ANALYZE;                                    -- All tables
ANALYZE users;                              -- A specific table
ANALYZE VERBOSE users;                      -- With detailed output
ANALYZE users (name);                       -- Specific columns
ANALYZE VERBOSE users (name);               -- Specific column with verbose

-- Table statistics

SELECT 
    relname,
    n_live_tup AS live_tuples, -- live tuples
    n_dead_tup AS dead_tuples, -- dead tuples
    n_tup_ins AS inserts, -- inserts
    n_tup_upd AS updates, -- updates
    n_tup_del AS deletes, -- deletes
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE relname = 'users';

-- Detail statistics for columns
SELECT 
    tablename,
    attname,           -- column name
    n_distinct,        -- estimated number of distinct values(negative value means a fraction of total rows)
    most_common_vals,  -- most common values
    most_common_freqs, -- frequencies of the most common values
    histogram_bounds   -- histogram bounds
FROM pg_stats 
WHERE tablename = 'users';

-- Cardinality (number of distinct rows)
SELECT n_distinct FROM pg_stats 
WHERE tablename = 'users' AND attname = 'name';

-- Value distribution (histogram)
SELECT histogram_bounds FROM pg_stats 
WHERE tablename = 'users' AND attname = 'name';

-- Physical correlation (order of data on disk)
SELECT correlation FROM pg_stats 
WHERE tablename = 'users' AND attname = 'name';

-- Check the last analyzed time
SELECT 
    schemaname,
    relname,
    last_analyze,
    last_autoanalyze,
    analyze_count,
    autoanalyze_count,
    *
FROM pg_stat_user_tables
WHERE relname = 'users';

-- Clean up
DROP TABLE IF EXISTS users;

