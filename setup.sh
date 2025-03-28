docker-compose up -d
docker ps
docker exec -it citus_coordinator psql -U postgres -p 5432
or 
psql -U postgres -h localhost -p 5435

CREATE EXTENSION citus;

SELECT citus_add_node('citus_worker_1', 5432);
SELECT citus_add_node('citus_worker_2', 5432);
SELECT * FROM master_get_active_worker_nodes();


CREATE TABLE account_transactions (
    transaction_id SERIAL,
    account_id INT NOT NULL,
    branch_code VARCHAR(10),
    amount DECIMAL(15, 2),
    transaction_time TIMESTAMP NOT NULL,
    last_modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (account_id, transaction_id)
);

INSERT INTO account_transactions (account_id, branch_code, amount, transaction_time, last_modified)
SELECT 
    (RANDOM() * 100000)::INT AS account_id,  -- Random account IDs (1 to 100,000)
    'BR' || LPAD((s % 100)::text, 3, '0') AS branch_code,  -- BR000 to BR099
    (RANDOM() * 1000)::DECIMAL(15, 2) AS amount,  -- Random amount between 0 and 1000
    NOW() - (s % 365) * INTERVAL '1 day' AS transaction_time,  -- Random date in the last year
    NOW() - (RANDOM() * 365) * INTERVAL '1 day' AS last_modified  -- Random last modified date
FROM generate_series(1, 1000000) s;


EXPLAIN ANALYZE
SELECT 
    account_id,
    SUM(amount) AS total_amount,
    COUNT(*) AS transaction_count
FROM account_transactions
WHERE account_id = 500000
AND transaction_time >= NOW() - INTERVAL '100 days'
GROUP BY account_id;


EXPLAIN ANALYZE
SELECT 
    branch_code,
    SUM(amount) AS total_amount,
    COUNT(*) AS transaction_count
FROM account_transactions
WHERE transaction_time >= NOW() - INTERVAL '30 days'
GROUP BY branch_code
ORDER BY total_amount DESC
LIMIT 10;


EXPLAIN VERBOSE
SELECT SUM(amount)
FROM account_transactions    
WHERE account_id BETWEEN 2000 AND 6000;