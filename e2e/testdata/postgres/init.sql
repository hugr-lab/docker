-- Minimal test schema for E2E data source attachment tests
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO products (name, price) VALUES
    ('Widget', 9.99),
    ('Gadget', 24.99);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL DEFAULT 1,
    ordered_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO orders (product_id, quantity) VALUES
    (1, 3),
    (2, 1);
