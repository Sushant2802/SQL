
-- 1 Select a particular database
CREATE DATABASE zomato ;
USE zomato ;

SELECT * FROM users ;


-- 2.count number of rows 
SELECT COUNT(*) FROM users ;


-- 3 return n random records
SELECT * FROM users 
ORDER BY RAND() LIMIT 5 ;  -- Replacate 'sample' function from pandas 


-- 4 find null values 
SELECT * FROM orders 
WHERE restaurant_rating IS NULL ;


-- 5. find number of orders placed by each customer
SELECT t2.name, COUNT(*) AS '#orders' 
FROM orders t1
JOIN users t2
ON t1.user_id = t2.user_id
GROUP BY t2.user_id, t2.name ;


-- 6. find restaurant with most number of menu items
SELECT t1.r_name, COUNT(*) AS 'MENU_COUNT' 
FROM restaurants t1
JOIN menu t2
ON t1.r_id = t2.r_id 
GROUP BY t2.r_id, t1.r_name ;


-- 7. find number of votes and avg rating for all the restaurants
SELECT t2.r_name, 
       COUNT(*) AS `vote_count`, 
       ROUND(AVG(t1.restaurant_rating), 2) AS `average_rating`
FROM orders t1
JOIN restaurants t2 ON t1.r_id = t2.r_id
WHERE t1.restaurant_rating IS NOT NULL
GROUP BY t2.r_id, t2.r_name;


-- 8. find the food that is being sold at most number of restaurants
SELECT t2.f_name, COUNT(*)  
FROM menu t1
JOIN food t2
ON  t1.f_id = t2.f_id
GROUP BY t1.f_id, t2.f_name
ORDER BY COUNT(*) DESC limit 1;


-- 9.find restaurant with max revenue in a given month
SELECT t2.r_name, SUM(amount) AS 'revenue'
FROM orders t1
JOIN restaurants t2
ON t1.r_id = t2.r_id 
WHERE MONTHNAME(DATE(date)) = 'may'
GROUP BY t1.r_id, t2.r_name  
ORDER BY revenue DESC LIMIT 1 ;


-- 10. Find restaurants with sales > x
 SELECT t2.r_name, SUM(amount) AS 'revenue' 
 FROM orders t1
 JOIN restaurants t2
 ON t1.r_id = t2.r_id 
 GROUP BY t1.r_id, t2.r_name 
 HAVING revenue > 1500 ; 
 
 
 -- 11. find customers who have never ordered
 SELECT user_id, name FROM users
 EXCEPT
 SELECT t1.user_id, name FROM orders t1
 JOIN users t2
 ON t1.user_id = t2.user_id ;


-- 12. show order details of a particular customer in a given date range 
 SELECT t1.order_id, f_name, date  
 FROM orders t1
 JOIN 
	order_details t2 ON t1.order_id = t2.order_id
 JOIN 
	food t3 ON t2.f_id = t3.f_id
 WHERE user_id = 3  AND date BETWEEN '2022-05-15' AND '2022-06015' ;


-- 13. customer favorite food
-- SELECT t1.user_id, t3.f_id, COUNT(*) AS 'fav_food'
-- FROM users t1
-- JOIN
-- 	orders t2 ON t1.user_id = t2.user_id
-- JOIN 
-- 	order_details t3 ON t2.order_id = t3.order_id 
-- GROUP BY t1.user_id, t3.f_id
-- ORDER BY COUNT(*) DESC ;


-- 14 find most costly restaurants(AVG price/dish)
SELECT t2.r_name, SUM(price)/COUNT(*) AS 'avg_price'
FROM menu t1
JOIN restaurants t2 ON t1.r_id = t2.r_id
GROUP BY t1.r_id,  t2.r_name 
ORDER BY avg_price DESC LIMIT 1 ;


-- 15. FIND delivery partner compensation using the formula (#deliveries * 100 + 1000*avg_rating)
SELECT partner_name, COUNT(*) * 100 + AVG(delivery_rating) * 1000 'salaries'
FROM orders t1
JOIN delivery_partner t2 ON t1.partner_id = t2.partner_id
GROUP BY t1.partner_id,  t2.partner_name 
ORDER BY salaries DESC ;


-- 16.. Find revenue per month for a restaurant 
SELECT 
	MONTHNAME(DATE(t1.date)) , SUM(t1.amount) AS 'revenue'
FROM 
	orders t1
JOIN 
	restaurants t2 ON t1.r_id = t2.r_id 
WHERE t2.r_name = 'kfc'
GROUP BY MONTH(DATE(t1.date)) , MONTHNAME(DATE(t1.date))  
ORDER BY MONTH(DATE(date)) ;
    

-- 17. find correlation between delivery_time and total rating
-- SELECT CORR(delivery_time, delivery_rating + restaurant_rating) AS 'corr'
-- FROM orders ;

-- 18. find correlation bbetween #orders and avg price for all restaurant 


-- 19 find all the veg restaurant 
SELECT t3.r_name 
FROM menu t1
JOIN 
	food t2 ON t1.f_id = t2.f_id 
JOIN 
	restaurants t3 ON t1.r_id = t3.r_id
GROUP BY t1.r_id , t3.r_name
HAVING MIN(type) = 'Veg' AND MAX(TYPE) = 'Veg' ;


-- 20. FIND min and max order value for all customers
SELECT name, MIN(amount), MAX(amount) FROM orders t1
JOIN users t2
ON t1.user_id = t2.user_id
GROUP BY t1.user_id, t2.name ;

