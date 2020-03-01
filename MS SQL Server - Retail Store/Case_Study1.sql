--create database Redemption
USE Redemption

--Data Preparation and Understanding

-- Q1. What is the total number of rows in each of the 3 tables in the database?

SELECT
(SELECT COUNT(*) FROM Customer) AS [Table 1 Count],
(SELECT COUNT(*) FROM Transactions) AS [Table 2 Count],
(SELECT COUNT(*) FROM prod_cat_info) AS [Table 3 Count]

-- Q2. What is the total number of transactions that have a return?

SELECT COUNT(Qty) FROM Transactions WHERE Qty < 0

--Q3. As you would have noticed, the dates provided across the datasets are not in a correct format. As first steps, please convert the date variables into valid date formats before proceeding further.

--SELECT COLUMN_NAME, DATA_TYPE
--FROM INFORMATION_SCHEMA.COLUMNS
--WHERE TABLE_NAME = 'Customer' OR TABLE_NAME = 'Transactions' OR TABLE_NAME = 'prod_cat_info'

update Transactions 
set tran_date = CONVERT(date, tran_date, 105)
update Customer
set DOB = CONVERT(date, DOB, 105)

--Q4. What is the time range for the transaction data that is available for analysis? Show the output in number of days, months and years simmultaneously in different columns.

select DATEDIFF(DAY, MIN(tran_date), MAX(tran_date)) as days,
	   DATEDIFF(MONTH, MIN(tran_date), MAX(tran_date)) as months,
	   DATEDIFF(YEAR, MIN(tran_date), MAX(tran_date)) as years
from Transactions

--Q5. Which product category does the sub-category "DIY" belongs to?

select prod_cat
 
from prod_cat_info 

where prod_subcat = 'DIY'

-- DATA ANALYSIS

--Q1. Which channel is most frequently used for transactions?

select top 1 
Store_type, 
count(Store_type) as frequency
from Transactions
group by Store_type
order by COUNT(Store_type) desc

--Q2. What is the count of Male and Female Customers in the database?

select Gender,
COUNT(Gender) as [count] 
from Customer
group by Gender

--Q3. From which city do we have the maximum number of customers and how many?

select top 1 city_code,
COUNT(city_code) as [Number of Customers] 
from Customer
group by city_code
order by COUNT(city_code) desc

--Q4. How many sub-categories are there under the books category?

select prod_cat,
count(prod_subcat) as [Sub-Category Count]
from prod_cat_info
where prod_cat = 'Books'
group by prod_cat

--Q5. What is the maximum quantities of products ever ordered?

select top 1
Qty 
from Transactions
order by Qty desc

--Q6. What is the net total revenue generated in categories Electronics and Books?

--ALTER TABLE Transactions
--ALTER COLUMN total_amt float

--ALTER TABLE Transactions
--ALTER COLUMN Rate int

--ALTER TABLE Transactions
--ALTER COLUMN Tax float

select prod_cat,
sum(total_amt) as [Net total Revenue]
from Transactions left join prod_cat_info on Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code
									     AND Transactions.prod_cat_code = prod_cat_info.prod_cat_code
group by prod_cat
having prod_cat = 'Electronics' OR prod_cat = 'Books'

--Q7. How many Customers have more than 10 Transactions with us, excluding returns?

select cust_id,
COUNT(cust_id) as[Number of Transcations]
from Transactions
where Qty > 0
group by cust_id
having COUNT(cust_id) > 10

--Q8. What is the combined revenue earned from the "Electronics" and "Clothing" categories, from "Flagship Stores"?

select 
SUM(total_amt) as Combined_Revenue
from Transactions inner join prod_cat_info on Transactions.prod_cat_code = prod_cat_info.prod_cat_code and Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code
where prod_cat in ('Electronics', 'Clothing') and Store_type = 'Flagship store'

--Q9. What is the total revenue generated from Male Customers in Electronics Category? Output should display total revenue by prod-sub cat.

select
prod_subcat,
sum(total_amt) as Total_Revenue
from Transactions inner join prod_cat_info on Transactions.prod_cat_code = prod_cat_info.prod_cat_code and Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code
				  left join Customer on Transactions.cust_id = Customer.customer_Id
where Gender = 'M' and prod_cat = 'Electronics'
group by prod_subcat

--Q10. What is percentage of Sales and returns by product sub-category; display only top 5 sub-categories in terms of Sales?

select top 5 
prod_subcat,
sum(case when Qty > 0 then total_amt end) * 100 / (select sum(case when qty > 0 then total_amt end) from Transactions) as [Sales Percentage],
sum(case when Qty < 0 then total_amt end) * 100 / (select sum(case when qty < 0 then total_amt end) from Transactions) as [Returns Percentage]

from Transactions inner join prod_cat_info on Transactions.prod_cat_code = prod_cat_info.prod_cat_code and Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code
group by prod_subcat
order by sum(case when Qty > 0 then total_amt end) * 100 / (select sum(case when qty > 0 then total_amt end) from Transactions) desc

--Q11. For all customers aged between 25 to 35 years, find what is the net total revenue generated by these consumers in last 30 days of transactions from max transaction date available in the area.

select sum(t.Total_Revenue) as Net_total_revenue from (
select cust_id,
DATEDIFF(year, DOB, GETDATE()) as Customer_age,
tran_date,
sum(total_amt) as Total_Revenue
from Transactions inner join Customer on customer_Id = cust_id
where DATEDIFF(year, DOB, GETDATE()) >=25 and DATEDIFF(year, DOB, GETDATE()) <= 35
group by cust_id, DOB, tran_date
having tran_date >= (select convert(date, DATEADD(day, -30, max(tran_date))) from Transactions) and tran_date <= max(tran_date)) as t

--Q12. Which product category has seen the max value of returns in the last 3 months of Transactions?

--alter table Transactions
--alter column Qty int


select top 1
p.prod_cat,
sum(p.Returns) as Ret
from (
select tran_date,
prod_cat,
sum(Qty) as [Returns]
from Transactions inner join prod_cat_info on Transactions.prod_cat_code = prod_cat_info.prod_cat_code  and Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code
where Qty < 0
group by prod_cat, tran_date
having tran_date >= (select convert(date, DATEADD(month, -3, max(tran_date))) from Transactions) and tran_date <= max(tran_date) 
) p
group by p.prod_cat
order by sum(p.Returns) asc

--Q13. Which store type sells the maximum products; by value of sales amount and by quantity sold?

select top 1
Store_type,
sum(Qty) as Total_Quantity,
sum(total_amt) as Total_amount
from Transactions
group by Store_type
order by Total_amount desc

--Q14. What are the categories for which average revenue is above the overall average?

select
prod_cat,
AVG(total_amt) as Average_Revenue
from Transactions join prod_cat_info on Transactions.prod_cat_code = prod_cat_info.prod_cat_code and Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code
group by prod_cat
having AVG(total_amt) > (select AVG(total_amt) from Transactions)

--Q15. Find the average and total revenue by each sub-category for the categories which are among Top 5 categories in terms of quantity sold.

select
prod_subcat,
AVG(total_amt) as Average_Revenue,
sum(total_amt) as Total_Revenue
from Transactions join prod_cat_info on Transactions.prod_cat_code = prod_cat_info.prod_cat_code and Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code
where prod_cat in (select y.prod_cat from (select top 5 prod_cat, sum(Qty) as Qty from Transactions join prod_cat_info on Transactions.prod_cat_code = prod_cat_info.prod_cat_code and Transactions.prod_subcat_code = prod_cat_info.prod_sub_cat_code
				group by prod_cat
				order by sum(Qty) desc) as y)

group by prod_subcat








