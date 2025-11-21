-- Let's create two tables to exemplify a JOIN operation, 
-- and then see the performance before and after create a foreign key index
-- Create the first table 'orders'
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    order_id INT PRIMARY KEY,  
    order_date DATE
);
-- Create the second table 'order_items' with a foreign key reference to 'orders'
CREATE TABLE order_items (
    item_id SERIAL NOT NULL,
    order_id INT,
    product_name VARCHAR(100),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    constraint fk_itens_orders foreign key (order_id) references orders(order_id)
    match simple on update cascade on delete cascade);

-- Now, let's insert some sample data into both tables
WITH orders_rws as (
    INSERT INTO orders (order_id, order_date)
    SELECT generate_series(1, 100000) AS order_id,
           CURRENT_DATE - (random() * 365)::int AS order_date
    RETURNING order_id
)
INSERT INTO order_items (item_id, order_id, product_name, description)
SELECT generate_series(1, 4) item_id, order_id,
       'Product ' || (random() * 1000)::int AS product_name,
       'Description for product ' || (random() * 1000)::int AS description
FROM orders_rws;

-- Let's analyze the performance of a JOIN operation without an index on the foreign key
EXPLAIN ANALYZE
SELECT oi.item_id, oi.product_name, o.order_date
FROM order_items oi 
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id = 50000;

--After check the performance above, let's create an index on the foreign key column
CREATE INDEX idx_order_items_order_id ON order_items (order_id);

-- And check the performance of the same JOIN operation again
EXPLAIN ANALYZE
SELECT oi.item_id, oi.product_name, o.order_date
FROM order_items oi 
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id = 50000;