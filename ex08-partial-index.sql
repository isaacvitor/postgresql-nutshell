-- Let's create a table to test indexing
DROP TABLE IF EXISTS partial_index;
CREATE TABLE partial_index (id serial, name TEXT);
-- Insert 2500000 data
INSERT INTO partial_index (name) SELECT 'João' FROM generate_series(1,2500000);

-- Add a little bit more
INSERT INTO partial_index (name) SELECT 'Maria' FROM generate_series(1,2500000);


-- Now, lets check the time expended to search for a name without index
EXPLAIN ANALYZE SELECT * FROM partial_index WHERE id = 2;

-- Now, let's create a partial index only for the name 'João'
CREATE INDEX idx_exclude_joao_maria ON partial_index (name) WHERE name NOT IN('João', 'Maria');
--DROP INDEX idx_exclude_joao_maria;

-- Now, let's check the time expended to search for a name with the partial index
EXPLAIN ANALYZE SELECT * FROM partial_index WHERE name = 'João1';

-- Finally, let's check the size of the index
SELECT pg_size_pretty(pg_total_relation_size('idx_exclude_joao_maria'));

-- Insert more data to see how the index performs
INSERT INTO partial_index (name) SELECT 'Pedro' FROM generate_series(1,1);

EXPLAIN ANALYZE SELECT * FROM partial_index WHERE name = 'Pedro';

-- The idea here is to create an index that excludes the most common values ('João' and 'Maria'),
-- which can help improve performance for queries that target less common values.
