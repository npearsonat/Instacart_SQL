# Instacart SQL Analysis

## Project Overview
This project showcases SQL querying and Python visualization skills using grocery order data. 
The analysis includes top products, buying patterns, reorder behavior, and order timing. 
It demonstrates complex SQL queries, data aggregation, joins, and Python plotting.

![Top Products](visuals/Instacart Schema.png.png)

---

## Dataset
- All CSV files are stored in the `SQL Query Results/` folder.  
- The dataset is a **sample subset** for lightweight reproducibility.  
- Full dataset available on Kaggle: [Instacart Market Basket Analysis](https://www.kaggle.com/c/instacart-market-basket-analysis/data)

---

## SQL Queries
SQL scripts are located in the `queries/` folder.  
Examples of queries included:  

```sql
-- Top products by aisle
SELECT aisle, product_name, COUNT(*) AS product_count
FROM orders
JOIN products USING(product_id)
GROUP BY aisle, product_name
ORDER BY product_count DESC;
