-- What is tsvector and tsvector functions
-- tsvector is a data type in PostgreSQL used for full-text search.
-- It stores lexemes (normalized words) along with their positions in the document. 
-- This allows for efficient searching and ranking of text data.

-- What is tsvector?
-- tsvector is a data type in PostgreSQL used for full-text search.
-- It stores lexemes (normalized words) along with their positions in the document.
-- This allows for efficient searching and ranking of text data.

-- What are tsvector functions?
-- tsvector functions are used to manipulate and analyze tsvector data.
-- Common tsvector functions include:
-- to_tsvector: Converts text to tsvector
-- to_tsquery: Converts query text to tsquery
-- plainto_tsquery: Converts plain text to tsquery
-- phraseto_tsquery: Converts phrase text to tsquery
-- websearch_to_tsquery: Converts web search style text to tsquery
-- ts_rank: Ranks documents based on relevance to the query
-- ts_headline: Generates a snippet of text with highlighted search terms

-- WHat is to_tsvector function?
-- The to_tsvector function converts a given text document into a tsvector.
-- It tokenizes the text, normalizes the words (removes stop words, stems words, creates lexemes, and lowercases them and includes their positions),
-- and stores them in a format suitable for full-text search.
-- to_tsvector syntax:
-- to_tsvector([config regconfig,] document text) → tsvector
    -- config: Specifies the text search configuration to use (optional) - such as 'english', 'portuguese', etc.
    -- document: The text to be converted to tsvector

SELECT to_tsvector('The quick brown Fox jumps over the lazy Dog.') AS tsvector_example;
-- output: 'brown':3 'dog':9 'fox':4 'jump':5 'lazi':8 'quick':2
-- The output shows that the words 'brown', 'dog', 'fox', 'jump', 'lazi', and 'quick' are present in the document,
-- and their positions are indicated by the numbers following the colon.

SELECT to_tsvector('portuguese', 'Os gatos estão correndo rapidamente') AS tsvector_portuguese;

SELECT * FROM (
    VALUES 
        (to_tsvector('english', 'PostgreSQL is a powerful, open source object-relational database system.')),
        (to_tsvector('english', 'MySQL is another popular relational database management system.'))
) AS t(tsvector_english)
WHERE tsvector_english @@ to_tsquery('english', 'PostgreSQL | database');

SELECT to_tsquery('english', 'PostgreSQL | MySQL');        -- OR
SELECT to_tsquery('english', 'database & !Oracle');        -- NOT
SELECT to_tsquery('english', 'open <-> source');           -- FOLLOWED BY
SELECT to_tsquery('english', 'PostgreSQL <2> database');   -- DISTANCE <N>

-- Common tsvector functions
-- to_tsvector: Converts text to tsvector
SELECT to_tsvector('english', 'PostgreSQL is a powerful, open source object-relational database system.') AS tsvector_english;
-- to_tsquery: Converts query text to tsquery
SELECT to_tsquery('english', 'PostgreSQL & database') AS tsquery_example;
-- plainto_tsquery: Converts plain text to tsquery
SELECT plainto_tsquery('english', 'PostgreSQL database performance') AS plainto_tsquery_example;
-- phraseto_tsquery: Converts phrase text to tsquery
SELECT phraseto_tsquery('english', 'full text search') AS phraseto_tsquery_example;
-- websearch_to_tsquery: Converts web search style text to tsquery
SELECT websearch_to_tsquery('english', 'PostgreSQL OR MySQL -Oracle') AS websearch_tsquery_example;
-- ts_rank: Ranks documents based on relevance to the query
SELECT 
    ts_rank(to_tsvector('english', 'PostgreSQL is a powerful database system.'), to_tsquery('english', 'PostgreSQL & database')) AS rank_example;
-- ts_headline: Generates a snippet of text with highlighted search terms
SELECT 
    ts_headline('english', 'PostgreSQL is a powerful open source database system.', to_tsquery('english', 'PostgreSQL & database & open & source')) AS headline_example;

-- Reference:
-- https://www.postgresql.org/docs/current/textsearch.html
-- https://www.postgresql.org/docs/current/functions-textsearch.html