CREATE SCHEMA data_cleaning ;
USE data_cleaning ;


SELECT * FROM laptopdata ;

-- ---------------------------------------------------------------------------

--  1. CREATE copy of table for backup & inserting table values
CREATE TABLE laptops_backup LIKE laptopdata ;

INSERT INTO laptops_backup
SELECT * FROM laptopdata ;

-- ---------------------------------------------------------------------------

--  2. check number of rows
SELECT COUNT(*) FROM laptopdata ;


--  3. check memory consumption  & Summray of data like data_length in bytes , version, etc.
SELECT DATA_LENGTH/1024 FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'data_cleaning'
AND TABLE_NAME = 'laptopdata' ;

SELECT * FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'data_cleaning'
AND TABLE_NAME = 'laptopdata' ;

-- ---------------------------------------------------------------------------

--  4. Drop non importants cols : Unnamed
SELECT * FROM laptopdata;

ALTER TABLE laptopdata 
DROP COLUMN `Unnamed: 0`; -- For MySQL or standard SQL

-- ---------------------------------------------------------------------------

--  5. Drop null values
DELETE FROM laptopdata
WHERE Company IS NULL 
  AND TypeName IS NULL 
  AND Inches IS NULL 
  AND ScreenResolution IS NULL 
  AND Cpu IS NULL 
  AND Ram IS NULL 
  AND Memory IS NULL 
  AND Gpu IS NULL 
  AND OpSys IS NULL 
  AND Weight IS NULL 
  AND Price IS NULL;

-- ---------------------------------------------------------------------------

-- 6. Drop duplicates 
DELETE FROM laptopdata
WHERE id NOT IN (
    SELECT id FROM (
        SELECT MIN(id) AS id
        FROM laptopdata
        GROUP BY Company, TypeName, Inches, ScreenResolution, 
			Cpu, Ram, Memory, Gpu, OpSys, Weight, Price
    ) AS subquery
);


-- ---------------------------------------------------------------------------

-- 7. to check null values columns wise

SELECT DISTINCT Company FROM laptopdata ;
SELECT DISTINCT TypeName FROM laptopdata ;
SELECT DISTINCT Inches FROM laptopdata ;
SELECT DISTINCT ScreenResolution FROM laptopdata ;
SELECT DISTINCT Cpu FROM laptopdata ;
SELECT DISTINCT Ram FROM laptopdata ;
SELECT DISTINCT Memory FROM laptopdata ;
SELECT DISTINCT Gpu FROM laptopdata ;
SELECT DISTINCT OpSys FROM laptopdata ;
-- There are no null values in any columns 

-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- BELOW COLUMN-WISE DATA CLEANING , SPILTING & CREATE NEW FEATURES 
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------


-- column 'inches' type conversion
ALTER TABLE laptopdata 
MODIFY COLUMN Inches DECIMAL(10, 1) ;

-- ---------------------------------------------------------------------------

-- column 'ram' update & type conversion
UPDATE laptopdata
SET Ram = REPLACE(Ram, 'GB', '');
ALTER TABLE laptopdata
MODIFY COLUMN Ram INTEGER ;

-- ---------------------------------------------------------------------------

-- column 'weight' update & type conversion
UPDATE laptopdata
SET Weight = REPLACE(Weight, 'kg', '');
ALTER TABLE laptopdata
MODIFY COLUMN Weight DECIMAL(5,2);

-- ---------------------------------------------------------------------------

-- COLUMNS 'Price' update & conversion
UPDATE laptopdata
SET Price = ROUND(Price);
ALTER TABLE laptopdata
MODIFY COLUMN Price INTEGER ;

-- ---------------------------------------------------------------------------

-- col 'OpSys' change to root name
SELECT OpSys FROM laptopdata ;

SELECT OpSys ,
CASE 
	WHEN OpSys LIKE '%mac%' THEN 'macos'
    WHEN OpSys LIKE 'windows%' THEN 'windows'
    WHEN OpSys LIKE '%linux%' THEN 'linux'
    WHEN OpSys LIKE 'No OS' THEN 'N/A'
    ELSE 'other'
END AS 'OS_brands'
FROM laptopdata;

UPDATE laptopdata
SET OpSys = 
    CASE 
        WHEN OpSys LIKE '%mac%' THEN 'macos'
        WHEN OpSys LIKE 'windows%' THEN 'windows'
        WHEN OpSys LIKE '%linux%' THEN 'linux'
        WHEN OpSys LIKE 'No OS' THEN 'N/A'
        ELSE 'other'
    END;

-- ---------------------------------------------------------------------------

  -- col 'Gpu'    
  ALTER TABLE laptopdata
  ADD COLUMN gpu_brand VARCHAR(255) AFTER Gpu,
  ADD COLUMN gpu_name VARCHAR(255) AFTER gpu_brand ;
  
  ALTER TABLE laptopdata
  ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY;


CREATE TEMPORARY TABLE temp_gpu_brand AS
SELECT id, SUBSTRING_INDEX(Gpu, ' ', 1) AS gpu_brand
FROM laptopdata;

UPDATE laptopdata l1
SET gpu_brand = (SELECT SUBSTRING_INDEX(Gpu,' ',1) 
				FROM laptopdata l2 WHERE l2.id = l1.id);

DROP TEMPORARY TABLE temp_gpu_brand;


CREATE TEMPORARY TABLE temp_gpu_split AS
SELECT id, REPLACE(Gpu, gpu_brand, '') AS gpu_name
FROM laptopdata;

UPDATE laptopdata l1
JOIN temp_gpu_split t
ON l1.id = t.id
SET l1.gpu_name = t.gpu_name;

DROP TEMPORARY TABLE temp_gpu_split;

ALTER TABLE laptopdata DROP COLUMN Gpu;

-- ---------------------------------------------------------------------------

-- col 'cpu'

ALTER TABLE laptopdata
ADD COLUMN cpu_brand VARCHAR(255) AFTER Cpu,
ADD COLUMN cpu_name VARCHAR(255) AFTER cpu_brand,
ADD COLUMN cpu_speed DECIMAL(10,1) AFTER cpu_name;


UPDATE laptopdata l1
JOIN (
    SELECT id, SUBSTRING_INDEX(Cpu, ' ', 1) AS cpu_brand
    FROM laptopdata
) l2 ON l1.id = l2.id
SET l1.cpu_brand = l2.cpu_brand;

UPDATE laptopdata l1
JOIN (
    SELECT id, CAST(REPLACE(SUBSTRING_INDEX(Cpu, ' ', -1), 'GHz', '') AS DECIMAL(10,2)) AS cpu_speed
    FROM laptopdata
) l2 ON l1.id = l2.id
SET l1.cpu_speed = l2.cpu_speed;

UPDATE laptopdata l1
JOIN (
    SELECT id, REPLACE(REPLACE(Cpu, SUBSTRING_INDEX(Cpu, ' ', 1), ''), SUBSTRING_INDEX(Cpu, ' ', -1), '') AS cpu_name
    FROM laptopdata
) l2 ON l1.id = l2.id
SET l1.cpu_name = l2.cpu_name;


ALTER TABLE laptopdata DROP COLUMN Cpu;


-- ---------------------------------------------------------------------------

-- col 'ScreenResolution'

ALTER TABLE laptopdata
ADD COLUMN resolution_width INTEGER AFTER ScreenResolution,
ADD COLUMN resolution_height INTEGER AFTER ScreenResolution ;

UPDATE laptopdata
SET resolution_width = SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution, ' ', -1), 'x', 1),
    resolution_height = SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution, ' ', -1), 'x', -1);


ALTER TABLE laptopdata
ADD COLUMN touchscreen INTEGER AFTER resolution_height;

SELECT screenResolution LIKE '%Touch%' FROM laptopdata ;

UPDATE laptopdata
SET touchscreen = screenResolution LIKE '%Touch%' ;


ALTER TABLE laptopdata DROP COLUMN ScreenResolution ;


-- ---------------------------------------------------------------------------

-- col 'cpu_name'

SELECT cpu_name,
SUBSTRING_INDEX(TRIM(cpu_name), ' ', 2) FROM laptopdata ;

UPDATE laptopdata
SET cpu_name = SUBSTRING_INDEX(TRIM(cpu_name), ' ', 2) ;


-- ---------------------------------------------------------------------------

-- col 'memory'

SELECT Memory FROM laptopdata ;

ALTER TABLE laptopdata
ADD COLUMN memory_type VARCHAR(255) AFTER Memory,
ADD COLUMN primrary_storage INTEGER AFTER Memory,
ADD COLUMN secondary_storage INTEGER AFTER Memory ;


SELECT Memory,
CASE
	WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    WHEN Memory LIKE '%SSD%' THEN 'SSD'
    WHEN Memory LIKE '%HDD%' THEN 'HDD'
    WHEN Memory LIKE '%Flash Storage%' THEN 'Flash Storage'
    WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    ELSE NULL
END AS 'memory_type'
FROM laptopdata ;

UPDATE laptopdata
SET memory_type = 
CASE
	WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    WHEN Memory LIKE '%SSD%' THEN 'SSD'
    WHEN Memory LIKE '%HDD%' THEN 'HDD'
    WHEN Memory LIKE '%Flash Storage%' THEN 'Flash Storage'
    WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    ELSE NULL
END ;


SELECT Memory,
REGEXP_SUBSTR(SUBSTRING_INDEX(Memory, '+', 1), '[0-9]+'),
CASE 
	WHEN Memory LIKE '%+%' THEN REGEXP_SUBSTR(SUBSTRING_INDEX(Memory, '+', -1), '[0-9]+')
    ELSE 0
END 
FROM laptopdata ;

UPDATE laptopdata
SET primrary_storage = REGEXP_SUBSTR(SUBSTRING_INDEX(Memory, '+', 1), '[0-9]+'),
	secondary_storage = CASE 
							WHEN Memory LIKE '%+%' THEN REGEXP_SUBSTR(SUBSTRING_INDEX(Memory, '+', -1), '[0-9]+')
							ELSE 0
						END ; 

SELECT primrary_storage, 
		CASE 
			WHEN primrary_storage <=2 THEN primrary_storage*1024 
            ELSE primrary_storage
		END
FROM laptopdata ;

SELECT secondary_storage, 
		CASE 
			WHEN secondary_storage <=2 THEN secondary_storage*1024 
            ELSE secondary_storage
		END
FROM laptopdata ;

UPDATE laptopdata
SET primrary_storage = CASE WHEN primrary_storage <=2 THEN primrary_storage*1024 ELSE primrary_storage END,
	secondary_storage = CASE WHEN secondary_storage <=2 THEN secondary_storage*1024 ELSE secondary_storage END ;


ALTER TABLE laptopdata DROP COLUMN Memory ;


-- ---------------------------------------------------------------------------

ALTER TABLE laptopdata DROP COLUMN gpu_name ;


-- ---------------------------------------------------------------------------




SELECT * FROM laptopdata ;