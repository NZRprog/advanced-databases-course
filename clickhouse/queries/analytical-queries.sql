-- 1. Топ-20 категорий по количеству товаров
SELECT
    category_id,
    product_count
FROM ecommerce.catalog_by_category_mv
ORDER BY product_count DESC
LIMIT 20;

-- 2. Топ-30 брендов по количеству товаров
SELECT
    vendor,
    product_count
FROM ecommerce.catalog_by_brand_mv
WHERE vendor IS NOT NULL
ORDER BY product_count DESC
LIMIT 30;

-- 3. Среднее количество товаров по брендам в категориях
SELECT
    category_id,
    avg(product_count) AS avg_products_per_brand,
    count(DISTINCT vendor) AS brand_count
FROM (
    SELECT
        category_id,
        vendor,
        count() AS product_count
    FROM ecommerce.ecom_offers
    WHERE vendor IS NOT NULL
    GROUP BY category_id, vendor
) AS brand_stats
GROUP BY category_id
ORDER BY avg_products_per_brand DESC;

-- 4. Анализ товаров без пользовательских событий
SELECT
    e.offer_id,
    e.price,
    e.category_id,
    e.vendor
FROM ecommerce.ecom_offers e
LEFT JOIN ecommerce.raw_events r ON e.offer_id = r.ContentUnitID
WHERE r.ContentUnitID IS NULL
LIMIT 100;

-- 5. Анализ покрытия каталога
SELECT
    avg(coverage_ratio) * 100 as avg_coverage_percent,
    countIf(coverage_ratio > 0.5) as well_covered_categories,
    count() as total_categories
FROM ecommerce.catalog_coverage_mv;