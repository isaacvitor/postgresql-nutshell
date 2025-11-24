-- Lets's compare performance of querying JSONB with id inside the JSON vs id in separate column

-- 2) DROP tables if they exist
DROP TABLE IF EXISTS bad_table;
DROP TABLE IF EXISTS good_table;

-- CLENUP DATA
TRUNCATE TABLE bad_table;
TRUNCATE TABLE good_table;

-- 3) "Bad" table: id inside the jsonb
CREATE TABLE bad_table (
  pk serial primary key,
  jb jsonb
);

-- 4) "Good" table: id in separate column + jsonb with only the document
CREATE TABLE good_table (
  pk serial primary key,
  id int,         -- separate column for filter/lookup
  jb jsonb
);

-- 5) Helper function to generate a jsonb with 'id' field and a growing array 'a'
-- The idea: the array 'a' will have many elements each of size ~N, thus increasing the total size.
CREATE OR REPLACE FUNCTION make_big_json(id_val int, repeat_count int)
RETURNS jsonb LANGUAGE sql IMMUTABLE AS $$
  SELECT jsonb_build_object(
    'id', id_val,
    'meta', jsonb_build_object('ts', now()::text),
    'a', (SELECT jsonb_agg(elem)
            FROM (
              SELECT repeat(md5(random()::text), 1) || repeat('x', 0) as elem -- basic small string
              FROM generate_series(1, repeat_count)
            ) s)
  );
$$;

-- 6) Populate tables with JSONs of increasing sizes.
-- Adjust the parameters (series & repeat_count) to reach sizes:
--   repeat_count ~ 1..10000 to cover from a few KBs to megabytes.
-- We will insert groups with increasing repeat_count to simulate documents of various sizes.

-- WARNING: this may insert A LOT of data. Run in a test database.
INSERT INTO bad_table (jb)
SELECT make_big_json(g, pow(2, s)::int)
FROM generate_series(1,200) g, generate_series(3,15) s
LIMIT 50000;

-- For good_table we will insert the same content, but separating id
INSERT INTO good_table (id, jb)
SELECT g, make_big_json(g, pow(2, s)::int) - 'id'
FROM generate_series(1,200) g, generate_series(3,15) s
LIMIT 50000;


-- 7) Let's check the performance of queries filtering by id
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT * FROM good_table WHERE id = 42;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT * FROM bad_table WHERE (jb->>'id')::int = 42;

-- 8) Let's create indexes to speed up the queries
CREATE INDEX idx_good_table_id ON good_table (id);
CREATE INDEX idx_bad_table_jb_id ON bad_table (((jb->>'id')::int));

-- 9) Re-run the queries to see the performance improvement with indexes
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT * FROM good_table WHERE id = 42;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT * FROM bad_table WHERE (jb->>'id')::int = 42;


VACUUM VERBOSE ANALYZE bad_table;
VACUUM VERBOSE ANALYZE good_table;