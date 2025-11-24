-- Check current database
SELECT current_database();

-- Block Size
SHOW block_size;

-- Table file path
SELECT pg_relation_filepath('table_name');

-- See the indexes on the table
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'table_name';

-- Alternative way to see constraints/indexes
SELECT
    conname AS constraint_name,
    contype AS constraint_type
FROM pg_constraint
WHERE conrelid = 'table_name'::regclass;

-- Check all indexes in current database
SELECT schemaname, tablename, indexname, indexdef 
FROM pg_indexes 
WHERE schemaname = 'public';

-- Check table definition more detailed
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'table_name' AND table_schema = 'public';

-- Check if there are any indexes at all on this table
SELECT 
    i.relname AS index_name,
    t.relname AS table_name,
    a.attname AS column_name
FROM pg_class i
JOIN pg_index ix ON i.oid = ix.indexrelid
JOIN pg_class t ON t.oid = ix.indrelid
JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(ix.indkey)
WHERE t.relname = 'table_name';

-- Multiple ways to check table statistics
-- 1. Using pg_stats
SELECT
	schemaname, -- Schema name
	tablename, -- Table name
	attname, -- Column name
    null_frac, -- Fraction of NULL values
	avg_width as bytes_per_row, -- Average width in bytes
    n_distinct, -- Number of disinct values (negative means a percentage of total rows, positive means exact count, e.g., -0.5 means 50% of total rows, 100 means exactly 100 distinct values) Cardinality
    most_common_vals, -- Most common values in the column
    most_common_freqs, -- Frequencies of the most common values
    histogram_bounds, -- Histogram bounds for the column
	correlation -- Correlation coefficient between physical order and logical order (Values close to 1 or -1 indicate good correlation, values close to 0 indicate poor correlation)
FROM pg_stats
WHERE tablename = 'table_name' AND schemaname = 'public';

-- 2. Using pg_stat_all_tables
SELECT
    relname AS table_name,
    seq_scan, -- Sesquential scans
    seq_tup_read, -- Sesquential tuples read
    idx_scan, -- Index scan
    idx_tup_fetch, -- Index tuples fetched
    n_live_tup, -- Live tuples
    n_dead_tup, -- Dead tuples
    last_vacuum, -- Last manual vacuum
    last_autovacuum, -- Last autovacuum
    last_analyze, -- Last manual analyze
    last_autoanalyze -- Last autoanalyze
FROM pg_stat_all_tables
WHERE relname = 'table_name';

-- 3. Using pg_class
SELECT
    relname AS table_name,
    relpages AS pages,
    reltuples AS estimated_rows,
    pg_size_pretty(pg_table_size(relname::regclass)) AS table_size,
    pg_size_pretty(pg_total_relation_size(relname::regclass)) AS total_size
FROM pg_class
WHERE relname = 'table_name';

-- 4. Using pg_stat_user_tables
SELECT
    relname AS table_name,
    seq_scan, -- Sequential scans
    seq_tup_read, -- Tuples read by sequential scans
    seq_tup_read / seq_scan as avg, -- Average tuples read per sequential scan
    idx_scan, -- Index scans
    idx_tup_fetch, -- Tuples fetched by index scans
    n_live_tup, -- Live tuples
    n_dead_tup, -- Dead tuples
    last_vacuum, -- Last manual vacuum
    last_autovacuum, -- Last autovacuum
    last_analyze, -- Last manual analyze
    last_autoanalyze -- Last autoanalyze
FROM pg_stat_user_tables
WHERE relname = 'table_name';

-- Table owner
SELECT
	schemaname,
	tablename,
	tableowner
FROM
	pg_tables
WHERE
	tablename = 'table_name';

-- Index usage statistics for all indexes
SELECT
	schemaname,
	relname,
	indexrelname,
	idx_scan, -- How many times index was scanned
    idx_tup_read, -- How many tuples were read by index scans
    idx_tup_fetch, -- How many tuples were fetched by index scans
	pg_size_pretty(pg_relation_size(indexrelid)) as idx_size -- Index size
FROM
	pg_stat_user_indexes;

---------------------------------
-- JSONB 
---------------------------------
-- Check the real storage size of JSONB data
SELECT
	pg_column_size(column_name) AS real_bytes,
	length(column_name::text) AS json_text_length
FROM
	table_name
ORDER BY
	pg_column_size(column_name) DESC
LIMIT 10;

-- More detailed statistics on JSONB column storage - TAKE CARE WITH LARGE TABLES
SELECT
	min(pg_column_size(column_name)) as min_bytes,
	max(pg_column_size(column_name)) as max_bytes,
	avg(pg_column_size(column_name)) as avg_bytes,
	percentile_cont(0.5) within group (
	ORDER BY pg_column_size(column_name)) as median_bytes
FROM
	table_name;

-- TOAST table size breakdown - TAKE CARE WITH LARGE TABLES
SELECT
	pg_size_pretty(pg_total_relation_size('table_name')) as total_size,
	pg_size_pretty(pg_relation_size('table_name')) as main_table,
	pg_size_pretty(pg_total_relation_size('table_name') - pg_relation_size('table_name')) as toast_size;


-- ANALYZE
-- Basic syntax:
-- ANALYZE [VERBOSE] [table_name [(column_name [, ...])]]

-- Examples:
ANALYZE;                                    -- All tables
ANALYZE users;                              -- A specific table
ANALYZE VERBOSE users;                      -- With detailed output
ANALYZE users (name);                       -- Specific columns
ANALYZE VERBOSE users (name);               -- Specific column with verbose

-- EXPLAIN
-- Basic syntax:
--EXPLAIN [ANALYZE] [VERBOSE] [COSTS] [SETTINGS] [BUFFERS] [WAL] [TIMING] [SUMMARY] [FORMAT format] query

-- Main parameters:
EXPLAIN query;                              -- Basic plan
EXPLAIN ANALYZE query;                      -- Executes and shows actual times
EXPLAIN VERBOSE query;                      -- Detailed information
EXPLAIN (ANALYZE, BUFFERS) query;           -- With buffer information
EXPLAIN (ANALYZE, VERBOSE, BUFFERS) query;  -- Complete information
EXPLAIN (ANALYZE true, TIMING false) query;  -- Disable timing for faster queries

-- Output formats:
EXPLAIN (FORMAT TEXT) query;                -- Default text format
EXPLAIN (FORMAT JSON) query;                -- JSON
EXPLAIN (FORMAT XML) query;                 -- XML
EXPLAIN (FORMAT YAML) query;                -- YAML

-- Useful combinations:
EXPLAIN (ANALYZE true, BUFFERS true, TIMING true, COSTS true) query;

-- REINDEX
-- Basic syntax:
--REINDEX { INDEX | TABLE | SCHEMA | DATABASE } name
-- Examples:
REINDEX INDEX index_name;                   -- Rebuild a specific index, witthout CONCURRENTLY, the operation locks the index
REINDEX TABLE table_name;                   -- Rebuild all indexes on a table
REINDEX SCHEMA schema_name;                 -- Rebuild all indexes in a schema
REINDEX DATABASE database_name;             -- Rebuild all indexes in a database
-- With options:
REINDEX (VERBOSE) INDEX index_name;          -- Verbose output
REINDEX CONCURRENTLY INDEX index_name;      -- Concurrent reindexing, allowing reads/writes during operation

-- Autovacuum settings
SHOW autovacuum;
SHOW autovacuum_vacuum_threshold;
SHOW autovacuum_vacuum_scale_factor;

---------------------------------
-- SCANS
---------------------------------
-- Scans básicos
SHOW enable_seqscan;        -- Sequencial scan
SHOW enable_indexscan;      -- Index scan (inclui GIN, GiST, B-tree, etc.)
SHOW enable_indexonlyscan;  -- Index-only scan
SHOW enable_bitmapscan;     -- Bitmap scan (usado com GIN)
SHOW enable_tidscan;        -- TID scan

-- Joins
SHOW enable_hashjoin;       -- Hash join
SHOW enable_mergejoin;      -- Merge join  
SHOW enable_nestloop;       -- Nested loop join

-- Agregações
SHOW enable_hashagg;        -- Hash aggregation
SHOW enable_sort;           -- Ordenação
SHOW enable_material;       -- Materialização


-------------------------------
-- JSONB
-------------------------------
-- JSONB
-- Basic syntax:
-- jsonb_column @> jsonb_value
-- Examples:
SELECT * FROM table_name WHERE jsonb_column @> '{"key": "value"}';


SHOW default_toast_compression;
SELECT name, setting, enumvals 
FROM pg_settings 
WHERE name = 'default_toast_compression';

--- PSQL
-- docker exec -it [container_name] psql -U postgres
-- e.g. 
-- docker exec -it postgres_14_5 psql -U postgres 
-- \c -- Chek current DB
-- \dt -- List tables
-- \d+ table_name -- Detailed table info
-- \di -- List indexes
-- \di+ index_name -- Detailed index info