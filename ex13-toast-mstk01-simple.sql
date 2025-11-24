DROP TABLE IF EXISTS bad_small;
DROP TABLE IF EXISTS good_small;

CREATE TABLE bad_small (pk serial primary key, jb jsonb);
CREATE TABLE good_small (pk serial primary key, id int, jb jsonb);

-- Insert Small JSON (100 bytes), medium (5KB), large (200KB)
INSERT INTO bad_small (jb) VALUES
  (jsonb_build_object('id', 1, 'a', jsonb_build_array('small'))),
  (jsonb_build_object('id', 2, 'a', to_jsonb(repeat('X', 5000)::text))),
  (jsonb_build_object('id', 3, 'a', to_jsonb(repeat('X', 200000)::text)));

INSERT INTO good_small (id, jb) VALUES
  (1, (SELECT jsonb_build_object('id', 1, 'a', jsonb_build_array('small')) - 'id')),
  (2, (SELECT jsonb_build_object('id', 2, 'a', to_jsonb(repeat('X', 5000)::text)) - 'id')),
  (3, (SELECT jsonb_build_object('id', 3, 'a', to_jsonb(repeat('X', 200000)::text)) - 'id'));

ANALYZE bad_small;
ANALYZE good_small;

EXPLAIN (ANALYZE, BUFFERS) SELECT id FROM good_small;
EXPLAIN (ANALYZE, BUFFERS) SELECT (jb->>'id')::int FROM bad_small;
EXPLAIN (ANALYZE, BUFFERS) SELECT jb->'a' FROM good_small;
EXPLAIN (ANALYZE, BUFFERS) SELECT jb->'a' FROM bad_small;