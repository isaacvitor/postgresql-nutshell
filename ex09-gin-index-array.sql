-- GIN Indexes for Arrays in PostgreSQL
-- GIN (Generalized Inverted Index) indexes are perfect for array operations
-- They efficiently support containment operations and overlap checks

-- First, make sure we are in the correct database
SELECT current_database();
-- If not, use the command below in psql
\c exercises;

-- Create a test table for GIN array index demonstration
DROP TABLE IF EXISTS gin_array_test;
CREATE TABLE gin_array_test (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    tags TEXT[],
    skills TEXT[],
    numbers INTEGER[],
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert sample data with various array combinations
INSERT INTO gin_array_test (name, tags, skills, numbers) 
SELECT 
    'User ' || generate_series(1, 10000),
    ARRAY[
        CASE (random() * 3)::integer
            WHEN 0 THEN 'frontend'
            WHEN 1 THEN 'backend'
            WHEN 2 THEN 'fullstack'
            ELSE 'devops'
        END,
        CASE (random() * 2)::integer
            WHEN 0 THEN 'javascript'
            WHEN 1 THEN 'python'
            ELSE 'java'
        END
    ],
    ARRAY[
        'programming',
        CASE (random() * 3)::integer
            WHEN 0 THEN 'react'
            WHEN 1 THEN 'angular'
            WHEN 2 THEN 'vue'
            ELSE 'svelte'
        END,
        CASE (random() * 2)::integer
            WHEN 0 THEN 'docker'
            WHEN 1 THEN 'kubernetes'
            ELSE 'aws'
        END
    ],
    ARRAY[(random() * 100)::integer, (random() * 1000)::integer, (random() * 50)::integer];

-- Update table statistics
ANALYZE gin_array_test;

-- Check table size
SELECT pg_size_pretty(pg_total_relation_size('gin_array_test')) AS table_size;

-- Test array queries WITHOUT GIN index (will use sequential scan)
EXPLAIN ANALYZE SELECT * FROM gin_array_test WHERE tags @> ARRAY['frontend']; -- Checking if 'frontend' is in tags array

EXPLAIN ANALYZE SELECT * FROM gin_array_test WHERE skills && ARRAY['react', 'vue']; -- Checking if there is overlap with 'react' or 'vue' in skills array

EXPLAIN ANALYZE SELECT * FROM gin_array_test WHERE 42 = ANY(numbers); -- Checking is the number 42 is present in numbers array

-- Create GIN indexes on array columns
CREATE INDEX idx_gin_tags ON gin_array_test USING GIN (tags);
CREATE INDEX idx_gin_skills ON gin_array_test USING GIN (skills);
CREATE INDEX idx_gin_numbers ON gin_array_test USING GIN (numbers);

-- Check the indexes created
SELECT 
    indexname,
    indexdef,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes 
WHERE tablename = 'gin_array_test'
ORDER BY indexname;

-- Test the same queries WITH GIN indexes (should use Index Scan)
-- Contains operation (@>)
EXPLAIN ANALYZE SELECT * FROM gin_array_test WHERE tags @> ARRAY['frontend'];

-- Overlap operation (&&)
EXPLAIN ANALYZE SELECT * FROM gin_array_test WHERE skills && ARRAY['react', 'vue'];

-- ANY operation for finding specific values
-- If in the QUERY PLAN you see "Seq Scan", there is reasons for that:
-- The ANY operator is not supported optimally by GIN indexes.
EXPLAIN ANALYZE SELECT * FROM gin_array_test WHERE 42 = ANY(numbers); 
-- The alternative is to use the containment operator:
EXPLAIN ANALYZE SELECT * FROM gin_array_test WHERE numbers @> ARRAY[42];

-- Find users with both frontend and javascript tags
EXPLAIN ANALYZE SELECT * FROM gin_array_test WHERE tags @> ARRAY['frontend', 'javascript'];

-- Find users with programming skills but not docker
EXPLAIN ANALYZE SELECT * FROM gin_array_test 
WHERE skills @> ARRAY['programming'] AND NOT (skills && ARRAY['docker']);

-- Find users with numbers in a specific range using ANY
EXPLAIN ANALYZE SELECT * FROM gin_array_test 
WHERE EXISTS (SELECT 1 FROM unnest(numbers) AS num WHERE num BETWEEN 10 AND 50);

-- Show index usage statistics
SELECT 
    schemaname,
    relname,
    indexrelname,
    idx_scan AS index_scans,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes 
WHERE relname = 'gin_array_test'
ORDER BY idx_scan DESC;

-- Demonstrate array aggregation with indexes
SELECT 
    unnest(tags) AS tag,
    COUNT(*) AS frequency
FROM gin_array_test 
GROUP BY unnest(tags) 
ORDER BY frequency DESC;

-- Clean up - drop test indexes
DROP INDEX IF EXISTS idx_gin_tags;
DROP INDEX IF EXISTS idx_gin_skills;
DROP INDEX IF EXISTS idx_gin_numbers;