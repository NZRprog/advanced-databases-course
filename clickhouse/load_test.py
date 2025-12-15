import time
import requests
import pandas as pd
from datetime import datetime

def execute_query(query, name="Query"):
    start = time.time()
    try:
        response = requests.post('http://localhost:8123', data=query, timeout=30)
        response.raise_for_status()
        elapsed = time.time() - start
        print(f"{name}: {elapsed:.3f} секунд")
        return elapsed, response.text
    except Exception as e:
        print(f"Ошибка в {name}: {e}")
        return None, None

def main():
    results = []
    
    # Запрос 1: Без материализованного представления
    query_without_mv = """
    SELECT
        category_id,
        count() AS product_count,
        avg(price) AS avg_price
    FROM ecommerce.ecom_offers
    GROUP BY category_id
    ORDER BY product_count DESC
    LIMIT 20;
    """
    
    # Запрос 2: С материализованным представлением
    query_with_mv = """
    SELECT
        category_id,
        product_count,
        avg_price
    FROM ecommerce.catalog_by_category_mv
    ORDER BY product_count DESC
    LIMIT 20;
    """
    
    # Запрос 3: Анализ покрытия
    query_coverage = """
    SELECT
        avg(coverage_ratio) * 100 as avg_coverage_percent,
        countIf(coverage_ratio > 0.5) as well_covered_categories,
        count() as total_categories
    FROM ecommerce.catalog_coverage_mv;
    """
    
    print("=== Тестирование производительности ===")
    
    # Выполняем каждый запрос 5 раз для усреднения
    for i in range(5):
        print(f"\nПопытка {i+1}:")
        time1, _ = execute_query(query_without_mv, "Без MV")
        time2, _ = execute_query(query_with_mv, "С MV")
        time3, result3 = execute_query(query_coverage, "Покрытие")
        
        if time1 and time2:
            results.append({
                'iteration': i+1,
                'without_mv': time1,
                'with_mv': time2,
                'speedup': time1 / time2 if time2 > 0 else 0,
                'coverage_query': time3
            })
    
    # Анализ результатов
    if results:
        df = pd.DataFrame(results)
        print("\n=== Результаты ===")
        print(f"Среднее время без MV: {df['without_mv'].mean():.3f} сек")
        print(f"Среднее время с MV: {df['with_mv'].mean():.3f} сек")
        print(f"Среднее ускорение: {df['speedup'].mean():.1f}x")
        print(f"Максимальное ускорение: {df['speedup'].max():.1f}x")
        
        if not result3 is None:
            print(f"\nРезультат анализа покрытия:\n{result3}")

if __name__ == "__main__":
    main()