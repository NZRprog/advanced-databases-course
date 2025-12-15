#!/bin/bash

set -e  # Прерывать выполнение при ошибках

# Определяем пути к CSV файлу
USER_FILES_CSV="/var/lib/clickhouse/user_files/10ozon.csv"
IMPORT_CSV="/var/lib/clickhouse/import/10ozon.csv"

# Выбираем доступный файл
if [ -f "$USER_FILES_CSV" ]; then
    CSV_FILE="$USER_FILES_CSV"
    echo "Использую файл из user_files"
elif [ -f "$IMPORT_CSV" ]; then
    # Копируем файл в user_files
    echo "Копирую файл в user_files..."
    cp "$IMPORT_CSV" "$USER_FILES_CSV"
    chown clickhouse:clickhouse "$USER_FILES_CSV"
    CSV_FILE="$USER_FILES_CSV"
else
    echo "ОШИБКА: CSV файл не найден!"
    echo "Искал в: $USER_FILES_CSV"
    echo "Искал в: $IMPORT_CSV"
    exit 1
fi

echo "Начинаю импорт CSV в $(date)"
echo "Файл: $CSV_FILE"
echo "Размер: $(ls -lh "$CSV_FILE" | awk '{print $5}')"
echo "Строк: $(wc -l < "$CSV_FILE")"

# Проверяем первые 5 строк
echo "Первые 5 строк файла:"
head -5 "$CSV_FILE"

# Ждем ClickHouse
echo "Ожидание запуска ClickHouse..."
until clickhouse-client --host localhost --query "SELECT 1" &>/dev/null; do
    sleep 2
done

echo "ClickHouse доступен, начинаю импорт..."

# Очищаем таблицу перед импортом
echo "Очищаю таблицу ecom_offers от старых данных..."
clickhouse-client --host localhost --query "TRUNCATE TABLE ecommerce.ecom_offers"

# Тестовый запрос - используем c1, c2 и т.д.
echo "Тестовый запрос - первые 3 строки:"
clickhouse-client --host localhost --query "
SELECT 
    c1 as row_num,
    c2 as offer_id,
    c3 as price,
    c4 as seller_id,
    c5 as category_id,
    c6 as vendor
FROM file('$CSV_FILE', 'CSV')
LIMIT 3"

# Импорт с исправленной настройкой
echo "Начинаю основной импорт..."
start_time=$(date +%s)

# Используем правильную настройку: input_format_csv_skip_first_lines вместо format_csv_skip_first_lines
clickhouse-client --host localhost --query "
INSERT INTO ecommerce.ecom_offers (offer_id, price, seller_id, category_id, vendor)
SELECT 
    toUInt64(c2) as offer_id,
    toFloat32(c3) as price,
    toUInt32(c4) as seller_id,
    toUInt32(c5) as category_id,
    nullIf(c6, '') as vendor
FROM file('$CSV_FILE', 'CSV')
SETTINGS input_format_csv_skip_first_lines = 1"

end_time=$(date +%s)
duration=$((end_time - start_time))

echo "Импорт завершен в $(date)"
echo "Время импорта: $duration секунд (~$(echo "scale=2; $duration / 60" | bc) минут)"

echo "Проверяем результат:"
clickhouse-client --host localhost --query "
SELECT 
    count() as total_rows,
    formatReadableQuantity(count()) as readable_rows,
    uniq(offer_id) as unique_offers,
    avg(price) as avg_price,
    min(price) as min_price,
    max(price) as max_price
FROM ecommerce.ecom_offers"

# Добавляем тестовые события
echo "Добавляю тестовые события в raw_events..."
clickhouse-client --host localhost --query "
INSERT INTO ecommerce.raw_events VALUES
(22, 'PC', 'Chrome', 'UNKNOWN', 'Московская область', 1878722550),
(22, 'ANDROID', 'Ozon', 'android 13', 'Свердловская область', NULL),
(22, 'IOS', 'Ozon', 'ios 18.5', 'Санкт-Петербург', NULL),
(22, 'ANDROID', 'Ozon', 'android 12', 'Санкт-Петербург', NULL),
(22, 'IOS', 'Ozon', 'ios 17.1.1', 'Липецкая область', 3002010749);"

echo "CSV импорт завершен!"