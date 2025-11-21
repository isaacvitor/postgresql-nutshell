-- OPERATORS SUPPORTED BY B-TREE INDEXES
-- B-tree indexes support the following operators:
=, <>, <, <=, >, >=, IS NULL, IS NOT NULL, BETWEEN, LIKE, ILIKE, SIMILAR TO, etc.
-- See: https://www.postgresql.org/docs/current/indexes-types.html#INDEXES-TYPES-BTREE

-- OPERATORS NOT SUPPORTED BY B-TREE INDEXES
-- B-tree indexes do not support the following operators:
-- NOT LIKE, NOT ILIKE, NOT SIMILAR TO, regular expressions (~, ~*, !~, !~*), IS DISTINCT FROM, etc.
-- For these operators, consider using a different index type, such as GIN or GiST

-- OPERATORS SUPPORTED BY GIN INDEXES
-- GIN indexes support operators for full-text search, array containment, JSONB containment, etc.
-- See: https://www.postgresql.org/docs/current/indexes-types.html#INDEXES-TYPES-GIN
-- GIN indexes support the following operators:
   Array operators: @>, <@, &&, =.
   JSONB operators: @>, <@, ?, ?|, ?&, etc.
   Full-text search operators: @@, @@@, etc.

-- OPERATORS NOT SUPPORTED BY GIN INDEXES
-- GIN indexes do not support the following operators (categorized by type):

-- COMPARISON OPERATORS
-- = (equals)
-- <> or != (not equals)
-- < (less than)
-- <= (less than or equal)
-- > (greater than)
-- >= (greater than or equal)

-- NULL TESTING OPERATORS
-- IS NULL (is null)
-- IS NOT NULL (is not null)
-- IS DISTINCT FROM (is distinct from)
-- IS NOT DISTINCT FROM (is not distinct from)

-- RANGE OPERATORS
-- BETWEEN (between range)
-- NOT BETWEEN (not between range)

-- PATTERN MATCHING OPERATORS
-- LIKE (pattern matching)
-- ILIKE (case-insensitive pattern matching)
-- NOT LIKE (negated pattern matching)
-- NOT ILIKE (negated case-insensitive pattern matching)
-- SIMILAR TO (SQL regular expression matching)
-- NOT SIMILAR TO (negated SQL regular expression matching)

-- REGULAR EXPRESSION OPERATORS
-- ~ (matches regular expression)
-- ~* (matches regular expression case-insensitive)
-- !~ (does not match regular expression)
-- !~* (does not match regular expression case-insensitive)

-- ARRAY QUANTIFIED COMPARISON OPERATORS
-- = ANY() (equals any element)
-- <> ANY() (not equals any element)
-- < ANY() (less than any element)
-- <= ANY() (less than or equal any element)
-- > ANY() (greater than any element)
-- >= ANY() (greater than or equal any element)
-- = ALL() (equals all elements)
-- <> ALL() (not equals all elements)
-- < ALL() (less than all elements)
-- <= ALL() (less than or equal all elements)
-- > ALL() (greater than all elements)
-- >= ALL() (greater than or equal all elements)

-- ARITHMETIC OPERATORS
-- + (addition)
-- - (subtraction)
-- * (multiplication)
-- / (division)
-- % (modulo)
-- ^ (exponentiation)
-- |/ (square root)
-- ||/ (cube root)
-- @ (absolute value)

-- BITWISE OPERATORS
-- & (bitwise AND)
-- | (bitwise OR)
-- # (bitwise XOR)
-- ~ (bitwise NOT)
-- << (bitwise left shift)
-- >> (bitwise right shift)

-- STRING CONCATENATION OPERATORS
-- || (string concatenation)

-- GEOMETRIC OPERATORS (for non-geometric GIN indexes)
-- << (is left of)
-- >> (is right of)
-- &< (does not extend to right of)
-- &> (does not extend to left of)
-- <<| (is below)
-- |>> (is above)
-- &<| (does not extend above)
-- |&> (does not extend below)
-- <-> (distance between)
-- ## (closest point)

-- NETWORK ADDRESS OPERATORS (for non-network GIN indexes)
-- << (is subnet of)
-- <<= (is subnet of or equals)
-- >> (contains subnet)
-- >>= (contains subnet or equals)

-- For these operators, consider using a different index type, such as B-tree

------------------------------------------------------------
-- EXAMPLES OF OPERATORS - ARRAY (ex09-gin-index-array.sql)
------------------------------------------------------------

-- Overlap operation (&&) - Checks if two arrays have at least one element in common
-- Example: find users who have 'react' OR 'vue' in their skills
SELECT * FROM gin_array_test WHERE skills && ARRAY['react', 'vue'];

-- Practical cases:
ARRAY['a', 'b'] && ARRAY['b', 'c'] → true --(share 'b')
ARRAY['a', 'b'] && ARRAY['c', 'd'] → false --(no common elements)

-- Contains operation (@>) - Checks if left array contains all elements from right array
-- Example: find users who have both 'programming' AND 'javascript' skills
SELECT * FROM gin_array_test WHERE skills @> ARRAY['programming', 'javascript'];

-- Practical cases:
ARRAY['a', 'b', 'c'] @> ARRAY['a', 'b'] → true (contains all elements)
ARRAY['a', 'b'] @> ARRAY['a', 'c'] → false --(doesn't contain 'c')

-- Is contained by (<@) - Checks if left array is contained in right array
-- Example: find users whose tags are subset of given tags
SELECT * FROM gin_array_test WHERE tags <@ ARRAY['frontend', 'backend', 'fullstack'];

-- Practical cases:
ARRAY['a', 'b'] <@ ARRAY['a', 'b', 'c'] → true --(is subset)
ARRAY['a', 'd'] <@ ARRAY['a', 'b', 'c'] → false --(contains 'd' which is not in right)

-- NOTE: Equality (=) is NOT supported by GIN indexes for arrays
-- This query will use sequential scan even with GIN index
-- Example: find users with exact tag combination (NOT OPTIMIZED)
SELECT * FROM gin_array_test WHERE tags = ARRAY['frontend', 'javascript'];

-- Practical cases:
ARRAY['a', 'b'] = ARRAY['a', 'b'] → true --(exactly equal)
ARRAY['a', 'b'] = ARRAY['b', 'a'] → false --(different order)

-- For exact array matching, consider using B-tree index or hash index

-- NOTE: ANY operation (= ANY) is NOT supported by GIN indexes
-- This query will use sequential scan even with GIN index
-- Example: find users with specific number in their array (NOT OPTIMIZED)
SELECT * FROM gin_array_test WHERE 42 = ANY(numbers);

-- GIN-OPTIMIZED ALTERNATIVES:
-- Use containment operator (@>) instead of = ANY()
SELECT * FROM gin_array_test WHERE numbers @> ARRAY[42];

-- Practical cases:
-- WRONG (not GIN-optimized): SELECT * FROM table WHERE 'value' = ANY(array_column);
-- CORRECT (GIN-optimized): SELECT * FROM table WHERE array_column @> ARRAY['value'];

-----------------------------------------------------------
-- EXAMPLES OF OPERATORS - JSONB (ex10-gin-index-jsonb.sql)
-----------------------------------------------------------

-- Contains (@>) - Checks if left JSONB contains right JSONB
-- Example: find users who are active
SELECT * FROM gin_jsonb_test WHERE profile @> '{"active": true}';

-- Practical cases:
'{"a": 1, "b": 2}' @> '{"a": 1}' → true --(contains key-value pair)
'{"a": 1}' @> '{"a": 1, "b": 2}' → false --(doesn't contain all pairs)

-- Is contained by (<@) - Checks if left JSONB is contained in right JSONB
-- Example: check if profile subset matches
SELECT * FROM gin_jsonb_test WHERE '{"active": true}' <@ profile;

-- Key exists (?) - Checks if top-level key exists in JSONB
-- Example: find users who have 'salary' field
SELECT * FROM gin_jsonb_test WHERE profile ? 'salary';

-- Practical cases:
'{"a": 1, "b": 2}' ? 'a' → true --(key 'a' exists)
'{"a": 1}' ? 'b' → false --(key 'b' doesn't exist)

-- Any key exists (?|) - Checks if any of the keys exist
-- Example: find users who have either 'salary' or 'bonus' field
SELECT * FROM gin_jsonb_test WHERE profile ?| ARRAY['salary', 'bonus'];

-- Practical cases:
'{"a": 1, "b": 2}' ?| ARRAY['a', 'c'] → true --(key 'a' exists)
'{"a": 1}' ?| ARRAY['c', 'd'] → false --(none of the keys exist)

-- All keys exist (?&) - Checks if all specified keys exist
-- Example: find users who have both 'age' and 'city' fields
SELECT * FROM gin_jsonb_test WHERE profile ?& ARRAY['age', 'city'];

-- Practical cases:
'{"a": 1, "b": 2}' ?& ARRAY['a', 'b'] → true --(all keys exist)
'{"a": 1}' ?& ARRAY['a', 'b'] → false --(key 'b' doesn't exist)

-- Path operations with JSONB
-- Example: find users with specific nested values (GIN-optimized)
SELECT * FROM gin_jsonb_test WHERE profile->'skills' @> '["programming"]';

-- NOTE: The ->> operator with = is NOT supported by GIN indexes
-- This query will use sequential scan even with GIN index
-- WRONG (not GIN-optimized): SELECT * FROM gin_jsonb_test WHERE profile->>'city' = 'New York';
-- CORRECT (GIN-optimized): SELECT * FROM gin_jsonb_test WHERE profile @> '{"city": "New York"}';
SELECT * FROM gin_jsonb_test WHERE profile @> '{"city": "New York"}';

---------------------------------------------------------------------------
-- EXAMPLES OF OPERATORS - FULL TEXT SEARCH (ex11-gin-index-full-text.sql)
---------------------------------------------------------------------------

-- Text search match (@@) - Matches tsvector against tsquery
-- Example: find articles containing 'PostgreSQL'
SELECT * FROM gin_fulltext_test WHERE search_vector @@ to_tsquery('english', 'PostgreSQL');

-- Practical cases:
to_tsvector('PostgreSQL is great') @@ to_tsquery('PostgreSQL') → true
to_tsvector('MySQL database') @@ to_tsquery('PostgreSQL') → false

-- AND operation in text search
-- Example: find articles containing both 'database' AND 'performance'
SELECT * FROM gin_fulltext_test WHERE search_vector @@ to_tsquery('english', 'database & performance');

-- OR operation in text search  
-- Example: find articles containing 'PostgreSQL' OR 'MySQL'
SELECT * FROM gin_fulltext_test WHERE search_vector @@ to_tsquery('english', 'PostgreSQL | MySQL');

-- NOT operation in text search
-- Example: find articles containing 'database' but NOT 'administration'
SELECT * FROM gin_fulltext_test WHERE search_vector @@ to_tsquery('english', 'database & !administration');

-- Phrase search with distance operators
-- Example: find 'query' followed by 'optimization' (adjacent words)
SELECT * FROM gin_fulltext_test WHERE search_vector @@ to_tsquery('english', 'query <-> optimization');

-- Example: find 'query' within 3 words of 'optimization'
SELECT * FROM gin_fulltext_test WHERE search_vector @@ to_tsquery('english', 'query <3> optimization');

-- Prefix matching in text search
-- Example: find words starting with 'optim'
SELECT * FROM gin_fulltext_test WHERE search_vector @@ to_tsquery('english', 'optim:*');

-- Weight-based text search (A, B, C, D weights)
-- Example: search with different weights for title vs content
SELECT * FROM gin_fulltext_test 
WHERE setweight(to_tsvector('english', title), 'A') || 
      setweight(to_tsvector('english', content), 'B') @@ to_tsquery('english', 'PostgreSQL');

-- Text search ranking
-- Example: rank results by relevance
SELECT title, ts_rank(search_vector, to_tsquery('english', 'PostgreSQL')) as rank
FROM gin_fulltext_test 
WHERE search_vector @@ to_tsquery('english', 'PostgreSQL')
ORDER BY rank DESC;



-- OPERATORS SUPPORTED BY GiST INDEXES
-- GiST indexes support operators for geometric data types, full-text search, etc.
-- See: https://www.postgresql.org/docs/current/indexes-types.html#INDEXES-TYPES-GIST

-- GiST indexes support the following operators:
-- Geometric operators: <<, &<, &>, >>, <<|, &<|, |&>, |>>, &&, @>, <@, ~=, etc.
-- Full-text search operators: @@
-- Range type operators: &&, @>, <@, -|-, etc.
-- Network address operators: <<, <<=, >>, >>=, &&, etc.

-- EXAMPLES OF OPERATORS - GEOMETRIC (GiST indexes)
-- Note: These examples would require a table with geometric columns

-- Overlap (&&) - for geometric types
-- SELECT * FROM geometric_table WHERE box_column && box '((1,1),(2,2))';

-- Contains (@>) - for geometric types  
-- SELECT * FROM geometric_table WHERE circle_column @> point '(1,1)';

-- Contained by (<@) - for geometric types
-- SELECT * FROM geometric_table WHERE point_column <@ circle '((0,0),5)';

-- Summary:
-- B-tree: Best for equality, range queries, and ordering
-- GIN: Best for array containment, JSONB queries, and full-text search
-- GiST: Best for geometric data, range types, and specialized search operations