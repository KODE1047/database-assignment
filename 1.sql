-- Part 1

---
-- الف: List 'Ford' products with > 100 stock.
---
SELECT
    productcode,
    productname,
    msrp AS price
FROM
    products
WHERE
    productname ILIKE '%Ford%'
    AND quantityinstock > 100;


---
-- ب : List total payment amount and count by customer for 2003 and 2004.

---
SELECT
    c.customername,
    SUM(p.amount) AS total_amount_paid,
    COUNT(p.checknumber) AS total_payments_count
FROM
    payments p
JOIN
    customers c ON p.customernumber = c.customernumber
WHERE
    EXTRACT(YEAR FROM p.paymentdate) IN (2003, 2004)
GROUP BY
    c.customernumber, c.customername
ORDER BY
    total_amount_paid DESC;


---
-- پ: List details for 'Motorcycles' products.
---
SELECT
    p.productcode,
    p.productname,
    p.quantityinstock,
    p.buyprice,
    COALESCE(SUM(od.quantityordered), 0) AS total_quantity_sold,
    COUNT(DISTINCT od.ordernumber) AS invoices_issued_count,
    AVG(od.priceeach) AS average_sale_price,
    COALESCE(SUM(od.quantityordered * (od.priceeach - p.buyprice)), 0) AS total_profit
FROM
    products p
JOIN
    productlines pl ON p.productline = pl.productline
LEFT JOIN
    orderdetails od ON p.productcode = od.productcode
WHERE
    pl.productline = 'Motorcycles'
GROUP BY
    p.productcode
ORDER BY
    p.productcode;


---
-- ج: List order details for customers in 'Paris'.
---
SELECT
    c.customername,
    c.phone,
    COUNT(DISTINCT o.ordernumber) AS total_orders,
    SUM(od.quantityordered * od.priceeach) AS total_invoice_amount
FROM
    customers c
JOIN
    orders o ON c.customernumber = o.customernumber
JOIN
    orderdetails od ON o.ordernumber = od.ordernumber
WHERE
    c.city = 'Paris'
GROUP BY
    c.customernumber
ORDER BY
    total_invoice_amount DESC;


---
-- د: Delete records from 2003.
---
BEGIN;

-- Test 1: Payments
SELECT COUNT(*) AS payments_before_2003 FROM payments WHERE EXTRACT(YEAR FROM paymentdate) = 2003; -- Expect 1
DELETE FROM payments
WHERE EXTRACT(YEAR FROM paymentdate) = 2003;
SELECT COUNT(*) AS payments_after_2003 FROM payments WHERE EXTRACT(YEAR FROM paymentdate) = 2003; -- Expect 0

-- Test 2: Office Buys
SELECT COUNT(*) AS office_buys_before_2003 FROM office_buys WHERE EXTRACT(YEAR FROM buy_date) = 2003; -- Expect 1
DELETE FROM office_buys
WHERE EXTRACT(YEAR FROM buy_date) = 2003;
SELECT COUNT(*) AS office_buys_after_2003 FROM office_buys WHERE EXTRACT(YEAR FROM buy_date) = 2003; -- Expect 0

-- Test 3: Order Details
SELECT COUNT(*) AS orderdetails_before_2003 FROM orderdetails WHERE ordernumber IN (SELECT ordernumber FROM orders WHERE EXTRACT(YEAR FROM orderdate) = 2003); -- Expect 1
DELETE FROM orderdetails
WHERE ordernumber IN (
    SELECT ordernumber
    FROM orders
    WHERE EXTRACT(YEAR FROM orderdate) = 2003
);
SELECT COUNT(*) AS orderdetails_after_2003 FROM orderdetails WHERE ordernumber IN (SELECT ordernumber FROM orders WHERE EXTRACT(YEAR FROM orderdate) = 2003); -- Expect 0

RAISE NOTICE 'Query (E) DELETE test complete. Rolling back...';
ROLLBACK;


---
-- و : Add a new 'In Process' order for today.
---
BEGIN;

-- Run the INSERT query
WITH new_order_data AS (
    SELECT
        MAX(ordernumber) + 1 AS new_id,
        (SELECT customernumber FROM customers WHERE city = 'Paris' LIMIT 1) AS cust_id
    FROM orders
)
INSERT INTO orders (ordernumber, orderdate, requireddate, status, customernumber)
SELECT new_id, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 day', 'In Process', cust_id
FROM new_order_data;

INSERT INTO orderdetails (ordernumber, productcode, quantityordered, priceeach, orderlinenumber)
SELECT (SELECT MAX(ordernumber) FROM orders), 'S19', 2, 1000.00, 1;

INSERT INTO orderdetails (ordernumber, productcode, quantityordered, priceeach, orderlinenumber)
SELECT (SELECT MAX(ordernumber) FROM orders), 'S20', 3, 1500.00, 2;

-- Test 1: Verify the new order header
-- (Note: MAX(ordernumber) will be 20001)
SELECT * FROM orders WHERE ordernumber = (SELECT MAX(ordernumber) FROM orders);

-- Test 2: Verify the new order details
SELECT * FROM orderdetails WHERE ordernumber = (SELECT MAX(ordernumber) FROM orders);

RAISE NOTICE 'Query (F) INSERT test complete. Rolling back...';
ROLLBACK;
