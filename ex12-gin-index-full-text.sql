-- GIN Indexes for Full Text Search in PostgreSQL
-- GIN indexes are the standard choice for full text search operations
-- They efficiently support tsvector and tsquery operations

-- First, make sure we are in the correct database
SELECT current_database();
-- If not, use the command below in psql
\c exercises;

-- Create a test table for GIN full text search demonstration
DROP TABLE IF EXISTS gin_fulltext_test;
CREATE TABLE gin_fulltext_test (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200),
    content TEXT,
    author VARCHAR(100),
    category VARCHAR(50),
    search_vector tsvector,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert sample data with various text content
INSERT INTO gin_fulltext_test (title, content, author, category) 
SELECT 
    'Article ' || generate_series(1, 50000) || ': ' ||
    CASE (random() * 4)::integer
        WHEN 0 THEN 'PostgreSQL Database Performance'
        WHEN 1 THEN 'Advanced SQL Techniques'
        WHEN 2 THEN 'Index Optimization Strategies'
        WHEN 3 THEN 'Query Planning and Execution'
        ELSE 'Database Administration'
    END,
    'This is a comprehensive article about ' ||
    CASE (random() * 5)::integer
        WHEN 0 THEN 'database indexing, performance tuning, and query optimization techniques for PostgreSQL systems.'
        WHEN 1 THEN 'advanced SQL queries, joins, subqueries, and window functions in relational databases.'
        WHEN 2 THEN 'full text search capabilities, tsvector, tsquery, and GIN indexes in PostgreSQL.'
        WHEN 3 THEN 'database administration, backup strategies, and maintenance procedures for production systems.'
        WHEN 4 THEN 'PostgreSQL extensions, JSON processing, and advanced data types for modern applications.'
        ELSE 'database design patterns, normalization, and schema optimization for scalable applications.'
    END ||
    ' The article covers both theoretical concepts and practical examples with detailed explanations.',
    'Author ' || ((random() * 10)::integer + 1),
    CASE (random() * 3)::integer
        WHEN 0 THEN 'Technology'
        WHEN 1 THEN 'Database'
        WHEN 2 THEN 'Programming'
        ELSE 'Administration'
    END;

-- Show some random data samples before updating search_vector
SELECT id, title, left(content, 100) AS content_snippet, search_vector
FROM gin_fulltext_test
ORDER BY random()
LIMIT 5;

-- Update the search_vector column with tsvector data
UPDATE gin_fulltext_test SET search_vector = to_tsvector('english', title || ' ' || content);

-- Show some random data samples after updating search_vector
SELECT id, title, left(content, 100) AS content_snippet, search_vector
FROM gin_fulltext_test
ORDER BY random()
LIMIT 5;

-- Update table statistics
ANALYZE gin_fulltext_test;

-- Check table size
SELECT pg_size_pretty(pg_total_relation_size('gin_fulltext_test')) AS table_size;

-- Test full text search queries WITHOUT GIN index (will use sequential scan)
EXPLAIN ANALYZE SELECT * FROM gin_fulltext_test 
WHERE search_vector @@ to_tsquery('english', 'PostgreSQL');

EXPLAIN ANALYZE SELECT * FROM gin_fulltext_test 
WHERE search_vector @@ to_tsquery('english', 'database & performance');

EXPLAIN ANALYZE SELECT * FROM gin_fulltext_test 
WHERE to_tsvector('english', title || ' ' || content) @@ to_tsquery('english', 'optimization');

-- Create GIN index on the tsvector column
CREATE INDEX idx_gin_search_vector ON gin_fulltext_test USING GIN (search_vector);

-- Create GIN index on computed tsvector for title and content
CREATE INDEX idx_gin_title_content ON gin_fulltext_test 
USING GIN (to_tsvector('english', title || ' ' || content));

-- Check the indexes created
SELECT 
    indexname,
    indexdef,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes 
WHERE tablename = 'gin_fulltext_test'
ORDER BY indexname;

-- Test the same queries WITH GIN indexes (should use Index Scan)
-- Single term search
EXPLAIN ANALYZE SELECT * FROM gin_fulltext_test 
WHERE search_vector @@ to_tsquery('english', 'PostgreSQL');

-- AND operation
EXPLAIN ANALYZE SELECT * FROM gin_fulltext_test 
WHERE search_vector @@ to_tsquery('english', 'database & performance');

-- OR operation
SET enable_seqscan = off;
EXPLAIN ANALYZE SELECT * FROM gin_fulltext_test 
WHERE search_vector @@ to_tsquery('english', 'PostgreSQL | MySQL');
SET enable_seqscan = on;

-- NOT operation
EXPLAIN ANALYZE SELECT * FROM gin_fulltext_test 
WHERE search_vector @@ to_tsquery('english', 'database & !administration');

-- Phrase search (using <->)
EXPLAIN ANALYZE SELECT * FROM gin_fulltext_test 
WHERE search_vector @@ to_tsquery('english', 'query <-> optimization');

-- Advanced full text search features
-- Search with ranking
SELECT 
    title,
    ts_rank(search_vector, to_tsquery('english', 'PostgreSQL & performance')) AS rank
FROM gin_fulltext_test
WHERE search_vector @@ to_tsquery('english', 'PostgreSQL & performance')
ORDER BY rank DESC
LIMIT 10;

-- Search with headline (snippet)
SELECT 
    title,
    ts_headline('english', content, to_tsquery('english', 'PostgreSQL'), 
                'MaxWords=20, MinWords=10') AS snippet
FROM gin_fulltext_test
WHERE search_vector @@ to_tsquery('english', 'PostgreSQL')
LIMIT 5;

-- Complex search with multiple conditions
SELECT 
    title,
    author,
    category,
    ts_rank(search_vector, to_tsquery('english', 'database | index')) AS relevance
FROM gin_fulltext_test
WHERE search_vector @@ to_tsquery('english', 'database | index')
AND category = 'Technology'
ORDER BY relevance DESC
LIMIT 10;

-- Search statistics
SELECT 
    category,
    COUNT(*) AS total_articles,
    COUNT(*) FILTER (WHERE search_vector @@ to_tsquery('english', 'PostgreSQL')) AS postgresql_articles
FROM gin_fulltext_test
GROUP BY category
ORDER BY postgresql_articles DESC;

-- Show index usage statistics
SELECT 
    schemaname,
    relname AS table_name,
    indexrelname,
    idx_scan AS index_scans,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes 
WHERE relname = 'gin_fulltext_test'
ORDER BY idx_scan DESC;

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
WHERE relname = 'gin_fulltext_test';

-- Demonstrate different text search configurations
-- Create indexes for different languages
-- CREATE INDEX idx_gin_search_spanish ON gin_fulltext_test 
-- USING GIN (to_tsvector('spanish', title || ' ' || content));

-- Update search vector with triggers (for production use)
CREATE OR REPLACE FUNCTION gin_fulltext_test_trigger() RETURNS trigger AS $$
BEGIN
    NEW.search_vector := to_tsvector('english', NEW.title || ' ' || NEW.content);
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

-- Clean up - drop test indexes and trigger
DROP INDEX IF EXISTS idx_gin_search_vector;
DROP INDEX IF EXISTS idx_gin_title_content;
DROP FUNCTION IF EXISTS gin_fulltext_test_trigger();
