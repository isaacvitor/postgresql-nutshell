-- GIN Indexes for JSONB in PostgreSQL
-- GIN indexes are excellent for JSONB data queries
-- They support various JSONB operators and path operations

-- First, make sure we are in the correct database
SELECT current_database();
-- If not, use the command below in psql
\c exercises;

-- Create a test table for GIN JSONB index demonstration
DROP TABLE IF EXISTS gin_jsonb_test;
CREATE TABLE gin_jsonb_test (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    profile JSONB,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert sample data with various JSONB structures
INSERT INTO gin_jsonb_test (name, profile, metadata) 
SELECT 
    'User ' || generate_series(1, 10000),
    jsonb_build_object(
        'age', (random() * 40 + 20)::integer,
        'city', CASE (random() * 4)::integer
            WHEN 0 THEN 'New York'
            WHEN 1 THEN 'Los Angeles'
            WHEN 2 THEN 'Chicago'
            WHEN 3 THEN 'Houston'
            ELSE 'Phoenix'
        END,
        'skills', jsonb_build_array(
            'programming',
            CASE (random() * 3)::integer
                WHEN 0 THEN 'javascript'
                WHEN 1 THEN 'python'
                WHEN 2 THEN 'java'
                ELSE 'go'
            END
        ),
        'active', (random() > 0.3),
        'salary', (random() * 50000 + 40000)::integer
    ),
    jsonb_build_object(
        'department', CASE (random() * 3)::integer
            WHEN 0 THEN 'Engineering'
            WHEN 1 THEN 'Sales'
            WHEN 2 THEN 'Marketing'
            ELSE 'HR'
        END,
        'remote', (random() > 0.5),
        'projects', (random() * 10)::integer,
        'tags', jsonb_build_array('employee', 'active')
    );

-- Get some random data samples
SELECT * FROM gin_jsonb_test ORDER BY random() LIMIT 5;

-- Update table statistics
ANALYZE gin_jsonb_test;

-- Check table size
SELECT pg_size_pretty(pg_total_relation_size('gin_jsonb_test')) AS table_size;

-- Test JSONB queries WITHOUT GIN index (will use sequential scan)
EXPLAIN ANALYZE SELECT * FROM gin_jsonb_test WHERE profile @> '{"active": true}';

EXPLAIN ANALYZE SELECT * FROM gin_jsonb_test WHERE profile ? 'city';

EXPLAIN ANALYZE SELECT * FROM gin_jsonb_test WHERE profile->'age' @> '25';

-- Create GIN indexes on JSONB columns
CREATE INDEX idx_gin_profile ON gin_jsonb_test USING GIN (profile);
CREATE INDEX idx_gin_metadata ON gin_jsonb_test USING GIN (metadata);

-- Create a GIN index on a specific JSONB path
CREATE INDEX idx_gin_profile_skills ON gin_jsonb_test USING GIN ((profile->'skills'));

-- Check the indexes created
SELECT 
    indexname,
    indexdef,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes 
WHERE tablename = 'gin_jsonb_test'
ORDER BY indexname;

-- Test the same queries WITH GIN indexes (should use Index Scan)
-- Contains operation (@>)
EXPLAIN ANALYZE SELECT * FROM gin_jsonb_test WHERE profile @> '{"active": true}';

-- Key existence (?)
EXPLAIN ANALYZE SELECT * FROM gin_jsonb_test WHERE profile ? 'city';

-- Multiple key existence (?&)
EXPLAIN ANALYZE SELECT * FROM gin_jsonb_test WHERE profile ?& ARRAY['age', 'city'];

-- Any key existence (?|)
EXPLAIN ANALYZE SELECT * FROM gin_jsonb_test WHERE profile ?| ARRAY['salary', 'bonus'];

-- Path queries
EXPLAIN ANALYZE SELECT * FROM gin_jsonb_test WHERE profile->'skills' @> '["programming"]';

-- Complex JSONB queries
-- Find users in specific cities with programming skills
EXPLAIN ANALYZE SELECT * FROM gin_jsonb_test 
WHERE profile @> '{"city": "New York"}' 
AND profile->'skills' @> '["programming"]';

-- Find active users with high salary
EXPLAIN ANALYZE SELECT * FROM gin_jsonb_test 
WHERE profile @> '{"active": true}' 
AND (profile->'salary')::integer > 60000;

-- Find users by department using metadata
EXPLAIN ANALYZE SELECT * FROM gin_jsonb_test 
WHERE metadata @> '{"department": "Engineering"}';

-- JSONB aggregation queries
SELECT 
    profile->>'city' AS city,
    COUNT(*) AS user_count,
    AVG((profile->>'salary')::integer) AS avg_salary
FROM gin_jsonb_test 
WHERE profile ? 'salary'
GROUP BY profile->>'city'
ORDER BY user_count DESC;

-- Extract unique skills
SELECT DISTINCT 
    jsonb_array_elements_text(profile->'skills') AS skill
FROM gin_jsonb_test
WHERE profile ? 'skills';

-- Show index usage statistics
SELECT 
    schemaname,
    relname,
    indexrelname,
    idx_scan AS index_scans,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes 
WHERE relname = 'gin_jsonb_test'
ORDER BY idx_scan DESC;


-- Clean up - drop test indexes
DROP INDEX IF EXISTS idx_gin_profile;
DROP INDEX IF EXISTS idx_gin_metadata;
DROP INDEX IF EXISTS idx_gin_profile_skills;
DROP TABLE IF EXISTS gin_jsonb_test;