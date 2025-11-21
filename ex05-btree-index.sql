-- B-Tree Indexes in PostgreSQL
-- B-Tree indexes are the most common type of index in PostgreSQL
-- They are efficient for equality and range queries

-- First, make sure we are in the correct database
SELECT current_database();
-- If not, use the command below in psql
\c exercises;

-- Create a test table for index demonstration
DROP TABLE IF EXISTS btree_test;
CREATE TABLE btree_test (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    age INTEGER,
    salary DECIMAL(10,2),
    department VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert sample data to demonstrate index performance
INSERT INTO btree_test (name, age, salary, department) 
SELECT 
    'Employee ' || generate_series(1, 100000),
    (random() * 40 + 20)::integer, -- Age between 20-60
    (random() * 50000 + 30000)::decimal(10,2), -- Salary between 30k-80k
    CASE (random() * 4)::integer
        WHEN 0 THEN 'Engineering'
        WHEN 1 THEN 'Sales'
        WHEN 2 THEN 'Marketing'
        WHEN 3 THEN 'HR'
        ELSE 'Finance'
    END;

-- Update table statistics
ANALYZE btree_test;

-- Check table size and current indexes
SELECT pg_size_pretty(pg_total_relation_size('btree_test')) AS table_size;

-- Show existing indexes (should only have the primary key)
SELECT 
    indexname,
    indexdef,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes 
WHERE tablename = 'btree_test';

-- Test query performance WITHOUT indexes
-- This will perform a sequential scan
EXPLAIN ANALYZE SELECT * FROM btree_test WHERE age = 30;

EXPLAIN ANALYZE SELECT * FROM btree_test WHERE age BETWEEN 25 AND 35;

EXPLAIN (ANALYZE, FORMAT TEXT) SELECT * FROM btree_test WHERE salary > 50000;

-- Create B-Tree indexes
-- Single column index
CREATE INDEX idx_btree_age ON btree_test (age);

-- Index with expression
CREATE INDEX idx_btree_upper_name ON btree_test (UPPER(name));

-- Composite index (multiple columns)
CREATE INDEX idx_btree_dept_salary ON btree_test (department, salary);

-- Partial index (with WHERE condition)
CREATE INDEX idx_btree_high_salary ON btree_test (salary) WHERE salary > 60000;

-- Check all indexes now
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes 
WHERE tablename = 'btree_test'
ORDER BY indexname;

-- Test the same queries WITH indexes
-- This should now use Index Scan
EXPLAIN ANALYZE SELECT * FROM btree_test WHERE age = 30;

-- Range query - B-tree is perfect for this
EXPLAIN ANALYZE SELECT * FROM btree_test WHERE age BETWEEN 25 AND 35;

-- Test composite index usage
EXPLAIN ANALYZE SELECT * FROM btree_test WHERE department = 'Engineering' AND salary > 50000;

-- Test partial index usage
EXPLAIN ANALYZE SELECT * FROM btree_test WHERE salary = 65000;

-- Test expression index
EXPLAIN ANALYZE SELECT * FROM btree_test WHERE UPPER(name) = 'EMPLOYEE 50000';

-- Show index usage statistics
SELECT 
    schemaname,
    relname AS table_name,
    idx_scan AS index_scans,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes 
WHERE relname = 'btree_test'
ORDER BY idx_scan DESC;

-- Demonstrate ORDER BY with indexes
-- This can use the index for sorting
EXPLAIN ANALYZE SELECT * FROM btree_test ORDER BY age LIMIT 10;

-- Demonstrate LIKE operations
-- B-tree can optimize prefix searches
EXPLAIN ANALYZE SELECT * FROM btree_test WHERE name LIKE 'Employee 1%';

-- But not suffix searches
EXPLAIN ANALYZE SELECT * FROM btree_test WHERE name LIKE '%1000';

-- Show index maintenance overhead
-- Let's see how indexes affect INSERT performance
EXPLAIN ANALYZE INSERT INTO btree_test (name, age, salary, department) 
VALUES ('New Employee', 25, 45000, 'IT');

-- Check index bloat (simplified query)
SELECT 
    i.schemaname,
    i.tablename,
    i.indexname,
    pg_size_pretty(pg_relation_size(i.indexname::regclass)) AS index_size,
    pg_size_pretty(pg_total_relation_size(i.tablename::regclass)) AS table_size
FROM pg_indexes i
WHERE i.tablename = 'btree_test';


-- Index maintenance commands
-- Rebuild an index
REINDEX INDEX idx_btree_age;

-- Rebuild all indexes on table
REINDEX TABLE btree_test;

-- Check if indexes are being used effectively
-- Look for unused indexes
SELECT 
    schemaname,
    relname AS table_name,
    indexrelname AS index_name,
    idx_scan,
    pg_size_pretty(pg_relation_size(indexrelname::regclass)) AS index_size
FROM pg_stat_user_indexes 
WHERE relname = 'btree_test' AND idx_scan = 0;


-- Clean up - drop test indexes (keep primary key)
DROP INDEX IF EXISTS idx_btree_age;
DROP INDEX IF EXISTS idx_btree_upper_name;
DROP INDEX IF EXISTS idx_btree_dept_salary;
DROP INDEX IF EXISTS idx_btree_high_salary;