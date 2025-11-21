-- B-Tree Index Only Scan in PostgreSQL
-- This exercise demonstrates how to create a B-Tree index that enables Index Only Scan

-- Check the current database
SELECT current_database();
-- If needed, connect to the correct database
\c exercises;

-- Create a test table
DROP TABLE IF EXISTS index_only_test;
CREATE TABLE index_only_test (id serial primary KEY, name varchar(50));
-- Insert 1000000 rows
INSERT INTO index_only_test (name)
SELECT 'Name ' || generate_series(1, 1000000);

--Now, let's see how an index scan works
EXPLAIN ANALYZE
SELECT name FROM index_only_test WHERE id = 500000;

-- Check existing indexes
SELECT 
    indexname,
    indexdef,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes 
WHERE tablename = 'index_only_test';

-- When we run the above query, PostgreSQL uses an index scan to find the row with id = 500000.
-- To gives us the complete row, Postgres needs to access the table itself after locating the index entry.
-- This is known as a "heap fetch".
-- Probably, in the explain result you will have something like this:
--Index Scan using index_only_test_pkey on index_only_test  (cost=0.43..8.45 rows=1 width=16) (actual time=0.253..0.255 rows=1 loops=1)
--   Index Cond: (id = 5000000)
-- Planning Time: 1.062 ms
-- Execution Time: 0.373 ms

-- Now, let's get only the indexed column
EXPLAIN ANALYZE
SELECT id FROM index_only_test WHERE id = 500000;

-- In the query above, probably PostgreSQL will use an "Index Only Scan".
-- This is because all the data needed (the id column) is available in the index itself, so it doesn't need to access the table.
-- In the explain result you will have something like this:
--Index Only Scan using index_only_test_pkey on index_only_test  (cost=0.43..4.45 rows=1 width=4) (actual time=0.236..0.239 rows=1 loops=1)
--   Index Cond: (id = 5000000)
--   Heap Fetches: 0
-- Planning Time: 0.584 ms
-- Execution Time: 0.342 ms
--(5 rows)

-- Now, let's create a covering index
CREATE INDEX idx_name_covering ON index_only_test (id) INCLUDE (name);

-- Check existing indexes
SELECT 
    indexname,
    indexdef,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes 
WHERE tablename = 'index_only_test';

-- Now, let's run the original query again
EXPLAIN ANALYZE
SELECT name FROM index_only_test WHERE id = 500000;
-- Now, with the covering index, PostgreSQL can perform an Index Only Scan for this query as well.
-- The explain result should show "Index Only Scan" and "Heap Fetches: 0"
