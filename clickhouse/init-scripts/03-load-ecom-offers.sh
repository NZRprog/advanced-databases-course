#!/bin/bash

echo "Загрузка данных из Parquet файла..."

# Ждем, пока ClickHouse будет готов
until clickhouse-client --host localhost --query "SELECT 1" &>/dev/null; do
    echo "Ожидание запуска ClickHouse..."
    sleep 2
done

echo "ClickHouse запущен, начинаю загрузку данных..."

# Загружаем данные через HTTP API
curl -X POST "http://localhost:8123/?query=INSERT%20INTO%20ecommerce.ecom_offers%20FORMAT%20Parquet" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @/var/lib/clickhouse/user_files/part-00000-fe025c1f-5ca7-4f31-8143-5b648fcc9879-c000.snappy.parquet \
  && echo "Parquet данные успешно загружены!" \
  || echo "Загрузка Parquet данных не удалась"

# Добавляем небольшую задержку между запросами
sleep 2