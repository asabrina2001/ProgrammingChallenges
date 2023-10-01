/* creates database named 'marketing_campaign' with three tables named 'marketing_data', 
'website_revenue', and 'campaign_info' using MS SQL Server RDBMS */
CREATE DATABASE marketing_campaign
GO

USE [marketing_campaign]

create table marketing_data (
 date datetime,
 campaign_id varchar(50),
 geo varchar(50),
 cost float,
 impressions float,
 clicks float,
 conversions float
);

create table website_revenue (
 activity_date datetime,
 campaign_id varchar(50),
 state varchar(2),
 revenue float
);

create table campaign_info (
 campaign_id varchar(50),
 name varchar(50),
 status varchar(50),
 last_updated_date datetime
);

/* bulk inserts data from csv into tables */
BULK INSERT campaign_info
FROM 'C:\Users\dwitj\Downloads\campaign_info.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2 
);

BULK INSERT marketing_data
FROM 'C:\Users\dwitj\Downloads\marketing_performance.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2  
);

BULK INSERT website_revenue
FROM 'C:\Users\dwitj\Downloads\website_revenue.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2 
);

/* returns all three tables in database*/
USE [marketing_campaign]
SELECT*FROM campaign_info;
SELECT*FROM marketing_data;
SELECT*FROM website_revenue;

/* Problem 1: Returns the sum of impressions by day */
SELECT 
	DATENAME(WEEKDAY, date) AS day_of_week,
	SUM(impressions) AS total_impressions
FROM marketing_data
GROUP BY DATENAME(WEEKDAY, date)
ORDER BY -- orders output by day of the week starting from sunday
     CASE
          WHEN DATENAME(WEEKDAY, date) = 'Sunday' THEN 1
          WHEN DATENAME(WEEKDAY, date) = 'Monday' THEN 2
          WHEN DATENAME(WEEKDAY, date) = 'Tuesday' THEN 3
          WHEN DATENAME(WEEKDAY, date) = 'Wednesday' THEN 4
          WHEN DATENAME(WEEKDAY, date) = 'Thursday' THEN 5
          WHEN DATENAME(WEEKDAY, date) = 'Friday' THEN 6
          WHEN DATENAME(WEEKDAY, date) = 'Saturday' THEN 7
     END ASC;

/* Problem 2: Write a query to get the top three revenue-generating states in 
order of best to worst. How much revenue did the third best state generate?

Answer: The third best state, Ohio, generated $37577 in revenue */ 

SELECT TOP 3 -- limits output to top three rows based on descending order of total revenue
	state,
	sum(revenue) AS total_revenue -- aggregates total revenue for each group
FROM
	website_revenue
GROUP BY -- groups rows by state
	state
ORDER BY -- orders output by decreasing revenue
	total_revenue DESC;

-- returns state with 3rd highest revenue and its total revenue
SELECT
	state,
	sum(revenue) AS total_revenue
FROM
	website_revenue
GROUP BY
	state
ORDER BY
	total_revenue DESC
OFFSET 2 ROWS
FETCH NEXT 1 ROW ONLY;

/* Problem 3: Write a query that shows total cost, impressions, clicks, and 
revenue of each campaign. Make sure to include the campaign name in the output. */

WITH CombinedData AS ( -- combines data from marketing_data and website_revenue tables
    SELECT campaign_id, cost, impressions, clicks, NULL AS revenue FROM marketing_data
    UNION ALL
    SELECT campaign_id, NULL AS cost, NULL AS impressions, NULL AS clicks, revenue FROM website_revenue
)

SELECT  -- returns name, total cost, impressions, clicks, and revenue of each campaign
    name AS campaign_name,
	SUM(cost) AS total_cost,
	SUM(impressions) AS total_impressions,
	SUM(clicks) AS total_clicks,
	SUM(revenue) AS total_revenue
FROM
    CombinedData
LEFT JOIN -- joins campaign_info table with CombinedData to return campaign names
    campaign_info ON campaign_info.campaign_id = CombinedData.campaign_id
GROUP BY
	name;

/* Problem 4: Write a query to get the number of conversions of Campaign5 by state. 
Which state generated the most conversions for this campaign? 

Answer: Georgia was the state that generated the most conversions of Campaign5.*/

SELECT -- use 'SELECT TOP 1' statement to return state that generated the most conversions (GA) 
	RIGHT(geo,2) AS state,
	SUM(conversions) AS total_conversions
FROM
    marketing_data
INNER JOIN
    campaign_info ON campaign_info.campaign_id = marketing_data.campaign_id
WHERE
	name = 'Campaign5'
GROUP BY
	geo
ORDER BY
	total_conversions DESC;


/*Problem 5: In your opinion, which campaign was the most efficient, and why?

Answer: In my opinion, Campaign5 was the most efficient. With regard to overall profitability, 
Campaign5 generated the most amount of revenue for every dollar spent as it leads in 
return on as spending (ROAS). Additionally, Campaign5 had the highest revenue per impressions.
Looking at audience engagement, Campaign5 also had the highest impression to conversion rate, 
indicating that this campaign drove the most conversions from its total traffic */

WITH CombinedData AS (
    SELECT campaign_id, cost, impressions, clicks, conversions, NULL AS revenue FROM marketing_data
    UNION ALL
    SELECT campaign_id, NULL, NULL, NULL, NULL, revenue FROM website_revenue
)

SELECT 
    name AS campaign_name,
	ROUND(SUM(revenue)/SUM(cost), 2) AS ROAS, -- return on ad spending
	ROUND(SUM(revenue)/SUM(impressions), 2) AS RPI, -- revenue per impression
	ROUND(SUM(conversions)/SUM(impressions)*100,2) AS 'Impression to Sale CVR (%)', -- impression to sale conversion rate
	SUM(cost) AS total_cost,
	SUM(revenue) AS total_revenue,
	SUM(impressions) AS total_impressions,
	SUM(clicks) AS total_clicks,
	SUM(conversions) AS total_conversions
FROM
    CombinedData
LEFT JOIN
    campaign_info ON campaign_info.campaign_id = CombinedData.campaign_id
GROUP BY
	name
ORDER BY
	ROAS DESC;


/* Bonus Question: Write a query that showcases the best day of the week (e.g., 
Sunday, Monday, Tuesday, etc.) to run ads.

Answer: I believe the best day of the week to run ads is Wednesday. From the average ROAS, Wednesday
is the day of the week that generates the most revenue per dollar spent on advertising. 
Wednesday also has the highest revenue per impression and impression to sale conversion rate.*/

WITH CombinedData AS (
    SELECT date, campaign_id, cost, impressions, clicks, conversions, NULL AS revenue FROM marketing_data
    UNION ALL
    SELECT date, campaign_id, NULL, NULL, NULL, NULL, revenue FROM website_revenue
)

SELECT 
    DATENAME(weekday, CombinedData.date) AS day_of_week,
	ROUND(AVG(revenue)/AVG(cost), 2) AS avg_ROAS, -- return on ad spending
	ROUND(AVG(revenue)/AVG(impressions), 2) AS avg_RPI, -- revenue per impression
	ROUND(AVG(conversions)/AVG(impressions)*100,2) AS 'Impression to Sale CVR (%)', -- impression to sale conversion rate
	ROUND(AVG(cost)/AVG(conversions),2) AS CPC, -- cost per conversion
	ROUND(AVG(cost), 2) AS avg_cost,
	ROUND(AVG(revenue), 2) AS avg_revenue,
	ROUND(AVG(impressions), 2) AS avg_impressions,
	ROUND(AVG(clicks), 2) AS avg_clicks,
	ROUND(AVG(conversions), 2) AS avg_conversions
FROM
    CombinedData
LEFT JOIN
    campaign_info ON campaign_info.campaign_id = CombinedData.campaign_id
GROUP BY DATENAME(weekday, CombinedData.date)
ORDER BY avg_ROAS DESC;