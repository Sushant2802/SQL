USE data_cleaning ;

RENAME TABLE laptopdata TO laptop;

ALTER TABLE laptop
ADD COLUMN `index` INT AUTO_INCREMENT PRIMARY KEY FIRST;

SELECT * FROM laptop ;

-- -------------------------------------------------------------------------------------


-- 1. head, tail & sample
SELECT * FROM laptop 
ORDER BY `index` LIMIT 5 ;

SELECT * FROM laptop 
ORDER BY `index` DESC LIMIT 5 ;

SELECT * FROM laptop 
ORDER BY RAND() LIMIT 5 ;


-- ---------------------------------------------------------------------------------------

-- 2. FOR numerical cols 
    
    -- 8 number summary [count, min, max, mean, std, q1, q2, q3]
WITH quartiles AS (
    SELECT 
        Price,
        NTILE(4) OVER (ORDER BY Price) AS quartile
    FROM laptop
)
SELECT
    COUNT(Price) AS count_price,
    MIN(Price) AS min_price,
    MAX(Price) AS max_price,
    ROUND(AVG(Price), 2) AS avg_price,
    ROUND(STD(Price), 2) AS std_price,
    MAX(CASE WHEN quartile = 1 THEN Price END) AS Q1,
    MAX(CASE WHEN quartile = 2 THEN Price END) AS Median,
    MAX(CASE WHEN quartile = 3 THEN Price END) AS Q3
FROM quartiles;

SELECT * FROM laptop ;


    -- missing values
SELECT COUNT(Price)
FROM laptop
WHERE Price IS NULL ;   
 
    
    
	-- outliers
WITH ranked_prices AS (
    SELECT 
        Price,
        ROW_NUMBER() OVER (ORDER BY Price) AS row_num,
        COUNT(*) OVER () AS total_rows
    FROM laptop
),
quartiles AS (
    SELECT
        MIN(CASE WHEN row_num >= total_rows * 0.25 THEN Price END) AS Q1,
        MIN(CASE WHEN row_num >= total_rows * 0.75 THEN Price END) AS Q3
    FROM ranked_prices
)
SELECT l.*
FROM laptop l
CROSS JOIN quartiles q
WHERE l.Price < q.Q1 - (1.5 * (q.Q3 - q.Q1))
   OR l.Price > q.Q3 + (1.5 * (q.Q3 - q.Q1));

SELECT * FROM laptop ;



    -- -> horizontal/ vertical histograms

SELECT t1.buckets, 
			REPEAT('*',COUNT(*)/5) FROM (SELECT price, 
CASE 
	WHEN price BETWEEN 0 AND 25000 THEN '0-25K'
    WHEN price BETWEEN 25001 AND 50000 THEN '25K-50K'
    WHEN price BETWEEN 50001 AND 75000 THEN '50K-75K'
    WHEN price BETWEEN 75001 AND 100000 THEN '75K-100K'
	ELSE '>100K'
END AS 'buckets'
FROM laptop) t1
GROUP BY t1.buckets;

SELECT * FROM laptop ;


-- ---------------------------------------------------------------------------------------

-- 3. for categorical cols 

	-- value counts -> pie chart
SELECT Company, COUNT(Company) FROM laptop 
GROUP BY Company ;

SELECT * FROM laptop ;


-- ---------------------------------------------------------------------------------------

-- 4. Numerical - Numerical
	-- scatterplot
SELECT price, cpu_speed FROM laptop ;

SELECT * FROM laptop ;
        

-- ---------------------------------------------------------------------------------------

-- 5. Categorical - Categorical
	-- contigency table -> stacked bar chart

SELECT DISTINCT touchscreen FROM laptop;
SELECT Company,
SUM(CASE WHEN Touchscreen = 1 THEN 1 ELSE 0 END) AS 'Touchscreen_yes',
SUM(CASE WHEN Touchscreen = 0 THEN 1 ELSE 0 END) AS 'Touchscreen_no'
FROM laptop
GROUP BY Company;


SELECT DISTINCT cpu_brand FROM laptop;

SELECT Company,
SUM(CASE WHEN cpu_brand = 'Intel' THEN 1 ELSE 0 END) AS 'intel',
SUM(CASE WHEN cpu_brand = 'AMD' THEN 1 ELSE 0 END) AS 'amd',
SUM(CASE WHEN cpu_brand = 'Samsung' THEN 1 ELSE 0 END) AS 'samsung'
FROM laptop
GROUP BY Company;

SELECT * FROM laptop ;


-- ---------------------------------------------------------------------------------------

-- 6. Numerical - Categorical 
    -- -> compare distribution across categories
    
SELECT Company, MIN(Price),
		MAX(Price), AVG(Price), STD(Price)
FROM laptop
GROUP BY Company ;

SELECT * FROM laptop ;
        

-- ---------------------------------------------------------------------------------------

-- 7. missing value treatment

-- IN our dataset there is no null value, so let's create it
UPDATE laptop
SET Price = NULL
WHERE `index` IN (7, 869, 1148, 827, 865, 821, 1056, 1043, 692, 1114) ;

-- now handle above index missing values
SELECT * FROM laptop 
WHERE Price IS NULL ;


-- Replace with mean values
WITH avgPrice AS (
	SELECT AVG(Price) AS averagePrice
    FROM laptop
    )
    
UPDATE laptop
SET Price = (SELECT averagePrice FROM avgPrice )
WHERE Price IS NULL ;


-- replace comany wise mean
WITH AvgPriceByCompany AS (
    SELECT Company, 
        AVG(Price) AS AveragePrice
    FROM laptop
    GROUP BY Company
)
UPDATE laptop
SET Price = (
    SELECT AveragePrice
    FROM AvgPriceByCompany
    WHERE AvgPriceByCompany.Company = laptop.Company
)
WHERE Price IS NULL;


SELECT * FROM laptop ;
    

-- ---------------------------------------------------------------------------------------

-- 8. Feature Enginnering
-- COL 'ppi'
ALTER TABLE laptop
ADD COLUMN ppi INTEGER ;

UPDATE laptop
SET ppi = ROUND(SQRT(resolution_width*resolution_width + 
					resolution_height*resolution_height)/ Inches) ;

SELECT * FROM laptop 
ORDER BY ppi DESC ;
    

-- COL 'type'
ALTER TABLE laptop
ADD COLUMN screen_size VARCHAR(255) AFTER Inches;

CREATE TEMPORARY TABLE T AS
SELECT 
    l.index,
    NTILE(3) OVER (ORDER BY Inches) AS tile
FROM laptop l;

UPDATE laptop l
JOIN T
ON l.index = T.index
SET l.screen_size = T.tile;

DROP TEMPORARY TABLE T;

SELECT * FROM laptop; 


-- ---------------------------------------------------------------------------------------

-- 9. One Hot Encoding 

SELECT gpu_brand,
	CASE WHEN gpu_brand = 'Intel' THEN 1 ELSE 0 END AS 'intel',
    CASE WHEN gpu_brand = 'AMD' THEN 1 ELSE 0 END AS 'amd',
    CASE WHEN gpu_brand = 'Nvdia' THEN 1 ELSE 0 END AS 'nvdia',
    CASE WHEN gpu_brand = 'ARM' THEN 1 ELSE 0 END AS 'arm'
FROM laptop ;


SELECT * FROM laptop ;

-- ---------------------------------------------------------------------------------------
