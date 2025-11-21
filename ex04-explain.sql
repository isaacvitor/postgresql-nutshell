-- Now let's see the EXPLAIN command
-- But, before, don't forget to check the current database
SELECT current_database();


-- First, create table and insert some data
CREATE TABLE explain_test (
    id SERIAL,
    name VARCHAR(50));
INSERT INTO explain_test (name) SELECT 'Name' || generate_series(1, 1000000);

-- Now, let's see the EXPLAIN command
EXPLAIN SELECT * FROM explain_test WHERE id = 500000;

-- Probably we'll get something like this:
--  Gather  (cost=1000.00..11614.43 rows=1 width=14)
--    Workers Planned: 2
--    ->  Parallel Seq Scan on explain_test  (cost=0.00..10614.33 rows=1 width=14)
--          Filter: (id = 500000)
-- (4 rows)

-- What the result means:
-- Gather – Coordinator node that collects results from parallel workers
-- cost=1000.00..11614.43 – (startup cost .. total cost)
-- rows=1 – Estimated to return 1 row
-- width=14 – 14 bytes per row on average
-- Workers Planned: 2 – PostgreSQL will use 2 parallel worker processes
-- Parallel Seq Scan – Parallel sequential scan on the table
-- cost=0.00..10614.33 – Cost of the parallel scan
-- Filter: (id = 500000) – Condition applied during the scan
-- (4 rows) - Quantity of rows in the output

-- Now, let's see the EXPLAIN command with ANALYZE
EXPLAIN ANALYZE SELECT * FROM explain_test WHERE id = 500000;

-- The output will be similar to the previous one, but with actual execution times and row counts
--  Gather  (cost=1000.00..11614.43 rows=1 width=14) (actual time=19.918..28.678 rows=1 loops=1)
--    Workers Planned: 2
--    Workers Launched: 2
--    ->  Parallel Seq Scan on explain_test  (cost=0.00..10614.33 rows=1 width=14) (actual time=14.986..17.417 rows=0 loops=3)
--          Filter: (id = 500000)
--          Rows Removed by Filter: 333333
--  Planning Time: 0.190 ms
--  Execution Time: 28.752 ms
-- (8 rows)

-- Explanation of additional fields:
-- actual time=19.918..28.678 – Actual time taken (start..end)
-- rows=1 – Actual number of rows returned
-- loops=1 – Number of times this node was executed
-- Workers Launched: 2 – Number of parallel workers actually launched
-- Rows Removed by Filter: 333333 – Number of rows that did not meet the filter condition(Just one process shows this info)
-- Planning Time: 0.190 ms – Time taken to plan the query
-- Execution Time: 28.752 ms – Total time taken to execute the query

-- We can combine multiple options
EXPLAIN (ANALYZE, VERBOSE, BUFFERS) SELECT * FROM explain_test WHERE id = 500000;

-- Lets see whar we get:
-- Gather  (cost=1000.00..11614.43 rows=1 width=14) (actual time=23.534..25.177 rows=1 loops=1)
--    Output: id, name
--    Workers Planned: 2
--    Workers Launched: 2
--    Buffers: shared hit=5406
--    ->  Parallel Seq Scan on public.explain_test  (cost=0.00..10614.33 rows=1 width=14) (actual time=13.636..15.887 rows=0 loops=3)
--          Output: id, name
--          Filter: (explain_test.id = 500000)
--          Rows Removed by Filter: 333333
--          Buffers: shared hit=5406
--          Worker 0:  actual time=6.384..13.138 rows=1 loops=1
--            Buffers: shared hit=1529
--          Worker 1:  actual time=11.456..11.456 rows=0 loops=1
--            Buffers: shared hit=1365
--  Planning Time: 0.135 ms
--  Execution Time: 25.207 ms
-- (16 rows)

-- What's new here:
-- Output: id, name – Columns output by this node
-- Buffers: shared hit=5406 – Number of buffer hits (pages found in memory)
-- Worker 0/1: actual time=.. – Actual time taken by each worker
-- Buffers: shared hit=1529/1365 – Buffer hits for each worker