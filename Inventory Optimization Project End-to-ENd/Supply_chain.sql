CREATE TABLE staging_orders (
"Type" TEXT,
  "Days for shipping (real)" INTEGER,
  "Days for shipment (scheduled)" INTEGER,
  "Benefit per order" REAL,
  "Sales per customer" REAL,
  "Delivery Status" TEXT,
  "Late_delivery_risk" INTEGER,
  "Category Id" INTEGER,
  "Category Name" TEXT,
  "Customer City" TEXT,
  "Customer Country" TEXT,
  "Customer Fname" TEXT,
  "Customer Id" INTEGER,
  "Customer Segment" TEXT,
  "Customer State" TEXT,
  "Customer Street" TEXT,
  "Department Id" INTEGER,
  "Department Name" TEXT,
  "Market" TEXT,
  "Order City" TEXT,
  "Order Country" TEXT,
  "Order Customer Id" INTEGER,
  "order date (DateOrders)" TIMESTAMP,
  "Order Id" INTEGER,
  "Order Item Cardprod Id" INTEGER,
  "Order Item Discount" REAL,
  "Order Item Discount Rate" REAL,
  "Order Item Id" INTEGER,
  "Order Item Product Price" REAL,
  "Order Item Profit Ratio" REAL,
  "Order Item Quantity" INTEGER,
  "Sales" REAL,
  "Order Item Total" REAL,
  "Order Profit Per Order" REAL,
  "Order Region" TEXT,
  "Order State" TEXT,
  "Order Status" TEXT,
  "Product Card Id" INTEGER,
  "Product Category Id" INTEGER,
  "Product Name" TEXT,
  "Product Price" REAL,
  "Product Status" INTEGER,
  "shipping date (DateOrders)" TIMESTAMP,
  "Shipping Mode" TEXT,
  "order Processing Time" INTEGER,
  "Order Processing Time" INTEGER,
  "Delay" INTEGER,
  "Is_Delayed" boolean,
  "order_month" INTEGER,
  "order_day" TEXT,
  "order_hour" INTEGER,
  "Profitablity Flag" TEXT
);

DROP TABLE IF EXISTS staging_orders;
SELECT *FROM staging_orders;

SELECT COUNT(*) AS TOTAL_ORDERS
FROM staging_orders;

SELECT *FROM staging_orders
LIMIT 10;

--Total Revenue
select round(sum("Sales")::Numeric,2) as Total_revenue
from staging_orders;

--Total Orders
select count(distinct "Order Id") as Total_orders
from staging_orders;

--Total Number of Columns
SELECT COUNT(*) AS total_columns
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'staging_orders';

 --Total sales, quantity sold, and number of orders by products
 select "Product Card Id" AS product_id,
 		"Product Name" AS product_name,
		 sum("Order Item Quantity") AS total_quantity_sold,
		 ROUND(SUM("Sales")::Numeric, 2) AS total_revenue,
		 COUNT(DISTINCT "Order Id") as total_orders
 FROM staging_orders
 GROUP BY 
 	"Product Card Id",
	 "Product Name"
	ORDER BY total_revenue DESC;


--Top 10 Products By demand
SELECT
    "Product Card Id" AS product_id,
    "Product Name" AS product_name,
    SUM("Order Item Quantity") AS total_quantity_sold
FROM staging_orders
GROUP BY
    "Product Card Id",
    "Product Name"
ORDER BY total_quantity_sold DESC
LIMIT 10;

--Average Selling Price and Average order quantity by product
SELECT
    "Product Card Id" AS product_id,
    "Product Name" AS product_name,
    ROUND(AVG("Sales")::NUMERIC, 2) AS average_line_sales,
    ROUND(AVG("Order Item Quantity")::NUMERIC, 2) AS average_quantity_per_line,
    SUM("Order Item Quantity") AS total_quantity_sold
FROM staging_orders
GROUP BY
    "Product Card Id",
    "Product Name"
ORDER BY total_quantity_sold DESC;

--Category-wise revenue and demand
SELECT
    "Category Name",
    SUM("Order Item Quantity") AS total_quantity_sold,
    ROUND(SUM("Sales")::NUMERIC, 2) AS total_revenue,
    COUNT(DISTINCT "Order Id") AS total_orders,
    COUNT(DISTINCT "Product Card Id") AS total_products
FROM staging_orders
GROUP BY "Category Name"
ORDER BY total_revenue DESC;

--Monthly sales trend
SELECT
    DATE_TRUNC('month', "order date (DateOrders)")::DATE AS sales_month,
    SUM("Order Item Quantity") AS total_quantity_sold,
    ROUND(SUM("Sales")::NUMERIC, 2) AS total_revenue,
    COUNT(DISTINCT "Order Id") AS total_orders
FROM staging_orders
WHERE "order date (DateOrders)" IS NOT NULL
GROUP BY sales_month
ORDER BY sales_month;

--Profitablity Distribution
SELECT
    CASE
        WHEN "Order Profit Per Order" > 0 THEN 'Profitable'
        WHEN "Order Profit Per Order" = 0 THEN 'Break-even'
        ELSE 'Loss'
    END AS profitability_status,
    COUNT(*) AS total_records,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM staging_orders
GROUP BY profitability_status
ORDER BY total_records DESC;

--Late delivery percentage
SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
     WHERE "Late_delivery_risk" = 1
    ) AS late_delivery_records,
    ROUND(
        COUNT(*) FILTER (
            WHERE "Late_delivery_risk" = 1
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_percentage
FROM staging_orders;

--Average shipping delay
SELECT
    ROUND(
        AVG(
            "Days for shipping (real)" -
            "Days for shipment (scheduled)"
        )::NUMERIC,
        2
    ) AS average_shipping_delay_days
FROM staging_orders;

--Which product categories generate the most profit, and which lose money?
SELECT
    "Category Name" AS product_category,
    ROUND(
        SUM("Order Profit Per Order")::NUMERIC,
        2
    ) AS total_profit,
    ROUND(
        AVG("Order Item Profit Ratio")::NUMERIC * 100,
        2
    ) AS average_profit_margin,
    ROUND(
        SUM("Sales")::NUMERIC,
        2
    ) AS total_revenue,
    SUM("Order Item Quantity") AS total_quantity_sold
FROM staging_orders
GROUP BY "Category Name"
ORDER BY total_profit DESC;