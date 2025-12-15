USE ecommerce;

-- Удаляем существующие представления (если есть)
DROP VIEW IF EXISTS catalog_by_category_mv;
DROP VIEW IF EXISTS catalog_by_brand_mv;
DROP VIEW IF EXISTS catalog_coverage_mv;

-- Материализованное представление: агрегаты по категориям
CREATE MATERIALIZED VIEW catalog_by_category_mv
ENGINE = SummingMergeTree
ORDER BY (category_id)
POPULATE
AS
SELECT
    category_id,
    count() AS product_count,
    avg(price) AS avg_price,
    min(price) AS min_price,
    max(price) AS max_price,
    sum(price) AS total_revenue
FROM ecom_offers
GROUP BY category_id;

-- Материализованное представление: агрегаты по брендам
-- Используем настройку allow_nullable_key для поддержки NULL в vendor
CREATE MATERIALIZED VIEW catalog_by_brand_mv
ENGINE = SummingMergeTree
ORDER BY (vendor)
SETTINGS allow_nullable_key = 1
POPULATE
AS
SELECT
    vendor,
    count() AS product_count,
    avg(price) AS avg_price,
    min(price) AS min_price,
    max(price) AS max_price
FROM ecom_offers
WHERE vendor IS NOT NULL
GROUP BY vendor;

-- Анализ покрытия каталога событиями
-- Используем AggregatingMergeTree, но без POPULATE, так как запрос с JOIN может быть тяжелым
CREATE MATERIALIZED VIEW catalog_coverage_mv
ENGINE = AggregatingMergeTree
ORDER BY (category_id)
AS
SELECT
    e.category_id,
    count(DISTINCT e.offer_id) AS total_products,
    count(DISTINCT r.ContentUnitID) AS products_with_events,
    products_with_events / total_products AS coverage_ratio
FROM ecom_offers e
LEFT JOIN raw_events r ON e.offer_id = r.ContentUnitID
GROUP BY e.category_id;

-- Заполняем представление catalog_coverage_mv вручную
INSERT INTO catalog_coverage_mv
SELECT
    e.category_id,
    count(DISTINCT e.offer_id) AS total_products,
    count(DISTINCT r.ContentUnitID) AS products_with_events,
    products_with_events / total_products AS coverage_ratio
FROM ecom_offers e
LEFT JOIN raw_events r ON e.offer_id = r.ContentUnitID
GROUP BY e.category_id;