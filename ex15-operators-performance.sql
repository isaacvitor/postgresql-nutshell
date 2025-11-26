
-- How JSONB operators perform with varying levels of nesting and size
-- This script creates a test table with JSONB data of varying sizes and nesting levels
-- to analyze the performance of JSONB operators in PostgreSQL.
DROP TABLE IF EXISTS test_jsonb_nesting;


CREATE TABLE test_jsonb_nesting AS
SELECT
  id,
  (id / 10) AS size,
  (id % 10) AS level,
  (
    repeat('{"obj": ', id % 10)
    || jsonb_build_object(
         'key', id,
         'long_str', repeat('a', (pow(10, id::float / 200.0))::int)
       )::text
    || repeat('}', id % 10)
  )::jsonb AS jb
FROM generate_series(0, 1200) AS id;



-- Let's see some random samples
SELECT * FROM test_jsonb_nesting
WHERE size IN (0, 50, 100, 200, 400, 800)
AND level IN (0, 2, 4, 6, 8)
ORDER BY size, level;


SELECT *
FROM test_jsonb_nesting
WHERE size = 0 AND level = 9;

SELECT * FROM test_jsonb_nesting
WHERE level = 9;

SELECT count(*) FROM test_jsonb_nesting
WHERE size = 5 AND level = 4;

SELECT count(*) FROM test_jsonb_nesting
WHERE level = 9;

-- Check the query plan for different JSONB operators
-- -> Containment operator (@>)
-- -> Nested containment operator (@>)

-- Simple key lookup (->)
EXPLAIN (ANALYZE, BUFFERS)
SELECT jb -> 'obj' -> 'obj' -> 'obj' -> 'obj' -> 'key'
FROM test_jsonb_nesting
WHERE size = 5 AND level = 4;

-- Nested key lookup (#>>)
EXPLAIN (ANALYZE, BUFFERS)
SELECT jb #> '{obj,obj,obj,obj,key}'
FROM test_jsonb_nesting
WHERE size = 5 AND level = 4;

-- -JSONB field access using indexing ([]) - subscripting
EXPLAIN (ANALYZE, BUFFERS)
SELECT jb['obj']['obj']['obj']['obj']['key']
FROM test_jsonb_nesting
WHERE size = 5 AND level = 4;

-- Jsonpath operator ($)
EXPLAIN (ANALYZE, BUFFERS)
SELECT jsonb_path_query_first(jb, '$.obj.obj.obj.obj.key')
FROM test_jsonb_nesting
WHERE size = 5 AND level = 4;



-- EXPLAIN ANALYZE
-- SELECT * FROM test_jsonb_nesting
-- WHERE jb->>'key' = '100'; -- Simple key lookup  

-- EXPLAIN ANALYZE
-- SELECT * FROM test_jsonb_nesting
-- WHERE jb @> '{"key": 100}'; -- Containment operator   

-- EXPLAIN ANALYZE
-- SELECT * FROM test_jsonb_nesting
-- WHERE jb #>> '{obj,obj,key}' = '100'; -- Nested key lookup  

-- EXPLAIN ANALYZE
-- SELECT * FROM test_jsonb_nesting
-- WHERE jb @> '{"obj": {"obj": {"key": 100}}}'; -- Nested containment operator
