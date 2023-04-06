CREATE DATABASE Weather;
USE Weather;

CREATE TABLE County(
County_ID INT NOT NULL PRIMARY KEY,
County_Name VARCHAR (50) NOT NULL
);

CREATE TABLE Temperature(
County_ID INT NOT NULL,
Temp_Date DATE NOT NULL,
Temp_ID INT NOT NULL PRIMARY KEY, 
Temp_Celcuis INT NOT NULL,
FOREIGN KEY (County_ID) REFERENCES County(County_ID)
);

CREATE TABLE Cloud(
County_ID INT NOT NULL,
Cloud_Date DATE NOT NULL,
Cloud_ID INT NOT NULL PRIMARY KEY, 
Cloud_Cover INT NOT NULL,
FOREIGN KEY (County_ID) REFERENCES County(County_ID)
);

CREATE TABLE Precip(
County_ID INT NOT NULL,
Precip_Date DATE NOT NULL,
Precip_ID INT NOT NULL PRIMARY KEY, 
Precip_Mm INT NOT NULL,
FOREIGN KEY (County_ID) REFERENCES County(County_ID)
);

CREATE TABLE Wind_Gust(
County_ID INT NOT NULL,
Wind_Gust_Date DATE NOT NULL,
Wind_Gust_ID INT NOT NULL PRIMARY KEY, 
Wind_Gust_Mph INT NOT NULL,
FOREIGN KEY (County_ID) REFERENCES County(County_ID)
);

CREATE TABLE Wind_Speed(
County_ID INT NOT NULL,
Wind_Speed_Date DATE NOT NULL,
Wind_Speed_ID INT NOT NULL PRIMARY KEY, 
Wind_Speed_Mph INT NOT NULL,
FOREIGN KEY (County_ID) REFERENCES County(County_ID)
);

SELECT * FROM County;
SELECT * FROM Temperature;
SELECT * FROM Precip;
SELECT * FROM Wind_Gust;
SELECT * FROM Wind_Speed;
SELECT * FROM Cloud;


-- not all county data is in the database. Thinking about how it could expand over time
INSERT INTO County
(County_ID,County_Name)
VALUES
(1, 'Lancashire'),
(2, 'Surrey'),
(3, 'Yorkshire'),
(4, 'Cumbria'),
(5, 'Cornwall'),
(6, 'Cambridgeshire');

-- Query of total rain in mm by year 
USE Weather;
SELECT 
	YEAR (Precip_Date) AS YEAR,
    SUM(Precip_Mm) AS Precip_Sum_MM
    FROM Precip
    GROUP BY YEAR (Precip_Date);
    
-- Query of total rain by day of the week

SELECT 
	DAYNAME(Precip_Date) AS DAY,
    SUM(Precip_Mm) AS Precip_Sum_MM
    FROM Precip
    GROUP BY DAYNAME(Precip_Date)
    ORDER BY SUM(Precip_Mm);

-- Inner join, for average rain and cloud cover per day per county, with a subquery. Originally viewed Precip and Cloud Date to check dates are matching up. Then adjusted once checked to neaten up.
SELECT
	-- County.County_Name, Precip.Precip_Mm, Cloud.Cloud_Cover, Precip.Precip_Date, Cloud.Cloud_Date
    County.County_Name, Precip.Precip_Mm, Cloud.Cloud_Cover, Precip.Precip_Date AS Weather_Date
FROM
County 
	INNER JOIN Precip ON County.County_ID = Precip.County_ID
	INNER JOIN Cloud ON County.County_ID = Cloud.County_ID 
WHERE Precip.Precip_Date = Cloud.Cloud_Date AND Precip.Precip_Mm >5
;

-- A stored function based on wind_gusts
DELIMITER //
CREATE FUNCTION How_windy
(Wind_Gust_Mph INTEGER)
RETURNS VARCHAR(30)
DETERMINISTIC
BEGIN
    DECLARE How_windy VARCHAR(30);

    IF Wind_Gust_Mph < 10 THEN
		SET How_windy = 'Minor breeze';
        
    ELSEIF (Wind_Gust_Mph > 10 AND 
			Wind_Gust_Mph <= 25) THEN
        SET How_windy = 'A bit blowy';
        
	ELSEIF (Wind_Gust_Mph > 25 AND 
			Wind_Gust_Mph <= 35) THEN
        SET How_windy = 'Hold your hat!';
        
	ELSEIF (Wind_Gust_Mph > 35) THEN
        SET How_windy = 'Mighty windy';
        
    END IF;
	-- return the wind_level
	RETURN (How_windy);
END//
DELIMITER ;

SELECT Wind_Gust_Mph,
How_windy(Wind_Gust_Mph)
FROM Wind_Gust
GROUP BY (Wind_Gust_Mph)
;
-- more useful query of stored function
SELECT Wind_Gust_Date,
How_windy(Wind_Gust_Mph)
From Wind_Gust
ORDER BY (Wind_Gust_Date);

-- AVG Temp in Lancashire grouped by Year. 
SELECT 
AVG(Temp_Celcuis) AS Average_Temperature_Lancashire
FROM Temperature WHERE County_ID = 1
GROUP BY YEAR (Temp_Date);

-- AVG Temp filtered by County ID
SELECT AVG(Temp_Celcuis), County_ID
FROM Temperature 
GROUP BY (County_ID);


-- Set up test view
CREATE VIEW Avg_Temp AS
SELECT AVG(Temp_Celcuis), County_ID
FROM Temperature 
GROUP BY (County_ID)
;

SELECT * FROM Avg_Temp;

-- Set up more complex view and create view
CREATE VIEW January_Weather_Data AS
SELECT
c.County_ID, c.County_Name AS County_Name,
cl.Cloud_Cover, cl.Cloud_Date AS DATE,
p.Precip_Mm, t.Temp_Celcuis, wg.Wind_Gust_Mph, ws.Wind_Speed_Mph

FROM
Cloud cl
LEFT JOIN County c
ON c.County_ID = cl.County_ID

RIGHT JOIN Precip p
ON p.Precip_Date = cl.Cloud_Date

JOIN Temperature t
ON t.Temp_Date = cl.Cloud_Date
 
JOIN Wind_Gust wg
ON wg.Wind_Gust_Date = cl.Cloud_Date 
 
JOIN Wind_Speed ws
ON ws.Wind_Speed_Date = cl.Cloud_Date 
 
ORDER BY cl.Cloud_Date; 

SELECT * FROM January_Weather_Data;
 
-- to create a trigger for deleted counties created an archive table to first store any deleted counties 
CREATE TABLE County_Archives (
County_ID INT NOT NULL PRIMARY KEY,
County_Name VARCHAR (50) NOT NULL,
Deleted_At TIMESTAMP DEFAULT NOW()
);

-- trigger to make sure any deleted counties are stored in County_Archives table
DELIMITER //
CREATE TRIGGER County_Deleted 
BEFORE DELETE ON County FOR EACH ROW 
BEGIN 
INSERT INTO County_Archives(County_ID, County_Name)
VALUES (OLD.County_ID, OLD.County_Name);
END//
DELIMITER ;

-- testing trigger to see if 5/Cornwall has been moved
DELETE FROM County
WHERE County_ID = 5;

SELECT * FROM County_Archives;
