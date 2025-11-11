--credit_card_transcations (transaction_id, city, transaction_date, card_type, exp_type, gender, amount)

create table credit_card_transcations

(
transaction_id int,
city varchar(255),
transaction_date datetime,
card_type varchar(255),

exp_type varchar(100),
gender varchar(25),
amount int

)

alter table dbo.credit_card_transcations alter column amount bigint
select * from dbo.credit_card_tran scations
--1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

with cte as (
select sum(amount) as total_amount 
from credit_card_transcations
)
select top 5 ct.city, sum(ct.amount) as spend ,c.total_amount as total_amount ,cast((sum(ct.amount)*100.0/c.total_amount) as decimal(5,2)) as pct
from credit_card_transcations ct
inner join cte c on 1=1
group by ct.city,c.total_amount
order by spend desc

-------------------------------------------------------------------------------------------------------
with cte as (
select sum(amount) as total_amount 
from credit_card_transcations
)

select top 5 city, sum(amount) as city_spends , total_amount , cast(sum(amount)*100.0/total_amount as decimal(5,2)) as pct_contribution
from credit_card_transcations c
inner join cte on 1=1
group by city,total_amount
order by city_spends desc

--select top 5 city,spend,total_amount,(spend*100.00/total_amount) as pct_contribution
--from cte
--order by spend desc

--2- write a query to print highest spend month and amount spent in that month for each card type
with cte as (

select card_type,datepart(year,transaction_date) as yo,datepart(month,transaction_date) as mo,sum(amount) as spend
from credit_card_transcations
group by card_type,datepart(year,transaction_date),datepart(month,transaction_date)

)
select card_type,yo,mo,spend from (

select *, rank() over(partition by card_type order by spend desc) as rn
from cte
) a where rn=1
order by spend desc



--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
with cte as 
(select * from(

select *, sum(amount) over(partition by card_type order by transaction_date,transaction_id) as cum_spend
from credit_card_transcations) a
where cum_spend>=1000000
)
select * from (
select *,rank() over(partition by card_type order by cum_spend asc) as rn
from cte) a where rn=1

--order by card_type


--4- write a query to find city which had lowest percentage spend for gold card type

select top 1 city, SUM(amount) as spend,
sum(case when card_type='Gold' then amount end) as gold_amount
,(sum(case when card_type='Gold' then amount end)*100.0/SUM(amount)) as pct
from credit_card_transcations
group by city
having sum(case when card_type='Gold' then amount end) is not null
order by pct



--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
with cte as 
(
select city,max(amount) as max_spend, min(amount) as min_spend
from credit_card_transcations
group by city
)
select c.city,
max(case when amount = max_spend then ct.exp_type end) as highest_expense_type,
max(case when amount = min_spend then ct.exp_type end) as lowest_expense_type
from cte c
inner join
credit_card_transcations ct
on c.city=ct.city
--where c.city='Delhi'
group by c.city
order by c.city

select * from credit_card_transcations
where city='Delhi'
order by amount desc
--6- write a query to find percentage contribution of spends by females for each expense type

select exp_type,sum(amount) as spend, 
sum(case when gender ='F' then amount end) as spend_F,
sum(case when gender ='F' then amount end)*100.0/sum(amount) as pct_F
from
credit_card_transcations
--where gender='F'
group by exp_type

--7- which card and expense type combination saw highest month over month growth in Jan-2014
With cte as 
(
select card_type,exp_type, datepart(year,transaction_date) as Yr,datepart(month,transaction_date) as Mo,SUM(amount) as spend
from credit_card_transcations
group by card_type,exp_type,datepart(year,transaction_date),datepart(month,transaction_date)
)
,cte1 as 
(
select *, lag(spend,1,0) over(partition by card_type,exp_type order by yr, mo) as prev_spend
from cte

)
select * from(
select *,rank() over(order by MOM_change desc) as rnk
from(
select *, ((spend-prev_spend)*100.0/prev_spend) as MOM_change
from cte1
where yr='2014' and mo='1'
)a )b
where rnk=1


with cte as 




--8- during weekends which city has highest total spend to total no of transcations ratio 
with cte as 

(
select city, sum(amount) as spend,count(1) as total_amount
from credit_card_transcations
where DATEPART(weekday,transaction_date) in (1,7)
group by city
)

,cte1 as 
(
select *, (spend*1.00/total_amount) as ratio
from cte
)
select * from(
select *, rank() over(order by ratio desc) as rnk
from cte1) a where rnk=1
--9- which city took least number of days to reach its 500th transaction after the first transaction in that city
with cte as 
(
select*,
ROW_NUMBER() over(partition by city order by transaction_date asc) as rn
from credit_card_transcations  --where city ='surat'
--order by city,rn
)
,cte1 as (
select city,transaction_date as date
from cte where rn=500
)
,cte2 as(
select c1.city, datediff(day,min(c.transaction_date),c1.date ) as no_of_days
from credit_card_transcations c
join cte1 c1 on c.city=c1.city
group by c1.city, c1.date
)
select * from(
select *, rank() over(order by no_of_days) as rnk
from cte2
) a where rnk=1

select * from credit_card_transcations

