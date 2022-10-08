#DBMS-2 mini-project

use dbms2_miniproject;

#1. Join all the tables and create a new table called combined_table.
#(market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)

CREATE TABLE combined_table AS SELECT mf.Ord_id, mf.Prod_id, mf.Ship_id, mf.Cust_id, 
Sales, Discount, Order_Quantity, Profit, Shipping_Cost,Product_Base_Margin, cd.Customer_Name, cd.Province, cd.Region, 
cd.Customer_Segment, od.Order_Date, od.Order_Priority,pd.Product_Category, pd.Product_Sub_Category, od.Order_ID, 
sd.Ship_Mode, sd.Ship_Date
FROM market_fact mf INNER JOIN cust_dimen cd ON mf.Cust_id = cd.Cust_id
INNER JOIN orders_dimen od ON od.Ord_id = mf.Ord_id
INNER JOIN prod_dimen pd ON pd.Prod_id = mf.Prod_id
INNER JOIN shipping_dimen sd ON sd.Ship_id = mf.Ship_id; 
select * from combined_table;

#2. Find the top 3 customers who have the maximum number of orders
SELECT Customer_Name, SUM(Order_Quantity) AS Total_Order FROM 
combined_table GROUP BY Customer_Name ORDER BY total_order DESC 
LIMIT 3;

#3. Create a new column DaysTakenForDelivery that contains the date difference 
#of Order_Date and Ship_Date.

alter table combined_table add column DaysTakenForDelivery int ;
update combined_table set Daystakenfordelivery = str_to_date(ship_date, '%d-%m-%YYYY') - str_to_date(order_date, '%d-%m-%YYYY');

#4. Find the customer whose order took the maximum time to get delivered.
select customer_name,Daystakenfordelivery from combined_table where Daystakenfordelivery=
(select max(DaysTakenForDelivery) from combined_table);

#5. Retrieve total sales made by each product from the data (use Windows function)
select distinct prod_id,sum(sales) over(partition by prod_id) as total_sales from combined_table;

#6. Retrieve total profit made from each product from the data (use windows function)
select distinct prod_id,sum(profit) over(partition by prod_id) as total_profit from combined_table;

#7. Count the total number of unique customers in January and how many of them 
#came back every month over the entire year in 2011.

select month(str_to_date(order_date, '%d-%m-%Y'))as month, count(distinct(cust_id)) as total_unique_customers,year(str_to_date(order_date,'%d-%m-%Y'))
from market_fact mf join orders_dimen od on mf.ord_id = od.ord_id
where year(str_to_date(order_date, '%d-%m-%Y')) = 2011 and mf.cust_id in 
(select distinct(cust_id) from market_fact mf join orders_dimen od on mf.ord_id = od.ord_id 
where month(str_to_date(order_date,'%d-%m-%Y'))=1 and year(str_to_date(order_date, '%d-%m-%Y')) = 2011)
group by month(str_to_date(order_date, '%d-%m-%Y'));


#8. Retrieve month-by-month customer retention rate since the start of the business.(using views)

Create view Visit_log AS 
SELECT cust_id, TIMESTAMPDIFF(month,'2009-01-01', order_date) AS 
visit_month FROM combined_table GROUP BY 1, 2 ORDER BY 1, 2;

# STEP 2: Identify the time lapse between each visit. So, for each person and for each month, we see when the next visit is.

Create view Time_Lapse AS SELECT distinct cust_id, visit_month, lead(visit_month, 1) 
over(partition BY cust_id ORDER BY cust_id, visit_month) led FROM Visit_log;

# STEP 3: Calculate the time gaps between visits:

Create view time_lapse_calculated as SELECT cust_id, visit_month, led, led - visit_month AS time_diff from Time_Lapse;
 
# STEP 4: 
Create view customer_category as SELECT cust_id,visit_month,
 CASE
 WHEN time_diff <=1 THEN "retained"
 WHEN time_diff>1 THEN "irregular"
 WHEN time_diff IS NULL THEN "churned"
 END as cust_category
FROM time_lapse_calculated; 

# STEP 5: 
SELECT visit_month,(COUNT(if 
(cust_category="retained",1,NULL))/COUNT(cust_id)) AS retention
FROM customer_category GROUP BY 1 order by visit_month asc;