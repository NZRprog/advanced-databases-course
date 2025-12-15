USE ecommerce;

-- Таблица товаров
CREATE TABLE IF NOT EXISTS ecom_offers
(
    offer_id UInt64,
    price Float32,
    seller_id UInt32,
    category_id UInt32,
    vendor Nullable(String)
)
ENGINE = ReplacingMergeTree
ORDER BY (offer_id)
PRIMARY KEY (offer_id);

-- Таблица событий
CREATE TABLE IF NOT EXISTS raw_events
(
    hour UInt8,
    DeviceTypeName String,
    ApplicationName String,
    OSName String,
    ProvinceName String,
    ContentUnitID Nullable(UInt64)
)
ENGINE = MergeTree
PARTITION BY hour
ORDER BY (hour, DeviceTypeName, ApplicationName);