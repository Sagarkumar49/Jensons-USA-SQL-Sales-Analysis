-- Find the total number of products sold by each store along with the store name.
select stores.store_name, count(order_items.quantity)
from stores join orders
on stores.store_id=orders.store_id
join order_items
on orders.order_id=order_items.order_id
group by stores.store_name; 

-- Calculate the cumulative sum of quantities sold for each product over time.

select products.product_name,orders.order_date,order_items.quantity,
sum(order_items.quantity) 
over (partition by products.product_name order by orders.order_date) cumulative_quantity
from products 
join order_items 
join orders
on products.product_id = order_items.product_id and orders.order_id=order_items.order_id;

-- Find the product with the highest total sales (quantity * price) for each category.

with a as (select categories.category_name,products.product_name,
sum(order_items.quantity*order_items.list_price) total_sales
from products
join categories 
join order_items
on products.category_id = categories.category_id 
and products.product_id = order_items.product_id
group by products.product_name,categories.category_name)



select  category_name,product_name,total_sales from 
(select * ,
rank () over (partition by category_name order by total_sales desc)rnk  from a )b 
where rnk = 1; 

-- Find the customer who spent the most money on orders.
SELECT 
    CONCAT(customers.first_name,
            ' ',
            customers.last_name) full_name,
    SUM(order_items.quantity * order_items.list_price) spent
FROM
    customers
        JOIN
    orders
        JOIN
    order_items ON customers.customer_id = orders.customer_id
        AND orders.order_id = order_items.order_id
GROUP BY CONCAT(customers.first_name,
        ' ',
        customers.last_name)
ORDER BY spent DESC
LIMIT 1;



-- Find the highest-priced product for each category name.

with a as (select categories.category_name,products.product_name,products.list_price 
from categories join products
on categories.category_id=products.category_id)
select category_name,product_name,list_price from
(select * , dense_rank() over(partition by category_name order by list_price)rnk from a)b
where rnk =1;



-- Find the total number of orders placed by each customer per store.
select stores.store_name,
concat(customers.first_name," ", customers.last_name)full_name,
count(orders.order_id)total_order
from stores 
join orders 
join customers
on stores.store_id=orders.store_id 
and 
orders.customer_id=customers.customer_id
group by stores.store_name,full_name;



-- Find the names of staff members who have not made any sales.
select concat(staffs.first_name," " ,staffs.last_name)full_name,
count(orders.order_id)sales
from staffs left join orders
on staffs.staff_id=orders.staff_id
group by full_name
having sales = 0;

select concat(staffs.first_name," " ,staffs.last_name)full_name from staffs
where not exists (select order_id from orders 
where staffs.staff_id=orders.staff_id);


-- Find the top 3 most sold products in terms of quantity.
with a as 
(select products.product_name,count(order_items.quantity)total_sold
from products join order_items
on products.product_id=order_items.product_id
group by products.product_name
order by total_sold desc)
select * from (
select *,dense_rank() over(order by total_sold desc)rnk from a)b
where rnk<=3;

-- Find the median value of the price list. 
with a as (select list_price,
row_number() over(order by list_price)rn ,
count(*)over()n from products)

select case 
		when n % 2 = 0 THEN (select avg(list_price) from a where rn in (n/2,n/2+1))
        else (select list_price from a where rn = (n+1)/2)
        end as median from a limit 1;
        

-- List all products that have never been ordered.(use Exists)

select product_name from products
where not exists 
(select order_id from order_items where products.product_id=order_items.product_id);



-- List the names of staff members who have made more sales than the average number of sales by all staff members.

with a as (select concat(staffs.first_name," ", staffs.last_name)full_name,
coalesce(sum(order_items.quantity*order_items.list_price),0)total_sales
from staffs left join orders
on staffs.staff_id=orders.staff_id
left join order_items
on orders.order_id = order_items.order_id
group by full_name)

select * from a 
where total_sales>(select avg(total_sales) from a);


-- Identify the customers who have ordered all types of products (i.e., from every category).
select concat(customers.first_name," ",customers.last_name)full_name,
count(order_items.product_id)
from customers
join orders
join order_items
join products
on customers.customer_id=orders.customer_id 
and orders.order_id=order_items.order_id
and order_items.product_id=products.product_id
group by full_name
having count(distinct products.category_id)=
(select count(category_id) from categories);




 
