-- Part 2

-- Find the average price and total number of in-stock offers for each seller, but only for books within the 'Technology' category.

SELECT
    s.name AS seller_name,
    COUNT(so.id) AS in_stock_offers,
    -- Format the average price to two decimal places
    TO_CHAR(AVG(so.price), '999D99') AS average_price
FROM
    public.seller s
JOIN
    public.seller_offer so ON s.id = so.seller_id
JOIN
    public.book b ON so.book_id = b.id
JOIN
    public.book_category bc ON b.id = bc.book_id
JOIN
    public.category c ON bc.category_id = c.id
WHERE
    c.name = 'Technology'
    AND so.is_in_stock = TRUE
GROUP BY
    s.id, s.name  -- Group by both ID and name
ORDER BY
    seller_name;

-- For the publisher 'O'Reilly Media', find the total number of offers (both in-stock and out-of-stock) grouped by author and category.

SELECT
    p.name AS publisher_name,
    a.name AS author_name,
    c.name AS category_name,
    COUNT(so.id) AS total_offers
FROM
    public.publisher p
JOIN
    public.book b ON p.id = b.publisher_id
JOIN
    public.book_author ba ON b.id = ba.book_id
JOIN
    public.author a ON ba.author_id = a.id
JOIN
    public.book_category bc ON b.id = bc.book_id
JOIN
    public.category c ON bc.category_id = c.id
JOIN
    public.seller_offer so ON b.id = so.book_id
WHERE
    p.name = 'O''Reilly Media' -- Note the double-quote for escaping
GROUP BY
    p.name, a.name, c.name -- Grouping by three columns
ORDER BY
    author_name, category_name;

-- Find the minimum and maximum price for any book with over 300 pages, grouped by its publisher and category.

SELECT
    p.name AS publisher_name,
    c.name AS category_name,
    MIN(so.price) AS min_price,
    MAX(so.price) AS max_price
FROM
    public.book b
JOIN
    public.publisher p ON b.publisher_id = p.id
JOIN
    public.book_category bc ON b.id = bc.book_id
JOIN
    public.category c ON bc.category_id = c.id
JOIN
    public.seller_offer so ON b.id = so.book_id
WHERE
    b.page_count > 300
GROUP BY
    p.name, c.name -- Group by our two main entities
ORDER BY
    publisher_name, min_price;

-- List how many different categories and different authors each seller offers, but only for sellers who have at least one offer under $20.00.

SELECT
    s.name AS seller_name,
    COUNT(DISTINCT c.id) AS distinct_categories_offered,
    COUNT(DISTINCT a.id) AS distinct_authors_offered
FROM
    public.seller s
JOIN
    public.seller_offer so ON s.id = so.seller_id
JOIN
    public.book b ON so.book_id = b.id
JOIN
    public.book_category bc ON b.id = bc.book_id
JOIN
    public.category c ON bc.category_id = c.id
JOIN
    public.book_author ba ON b.id = ba.book_id
JOIN
    public.author a ON ba.author_id = a.id
WHERE
    s.id IN (
        -- Subquery to find "budget" sellers
        SELECT DISTINCT seller_id
        FROM public.seller_offer
        WHERE price < 20.00
    )
GROUP BY
    s.id, s.name -- Group by seller ID and name
ORDER BY
    seller_name;
