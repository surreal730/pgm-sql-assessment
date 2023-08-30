CREATE DATABASE PMG_assessment;

create table IF NOT EXISTS marketing_data (
 date timestamp,
 campaign_id varchar(50),
 geo varchar(50),
 cost float,
 impressions float,
 clicks float,
 conversions float
);

create table IF NOT EXISTS website_revenue (
 date timestamp,
 campaign_id varchar(50),
 state varchar(2),
 revenue float
);

create table IF NOT EXISTS campaign_info (
 id varchar(50),
 name varchar(50),
 status varchar(50),
 last_updated_date timestamp
);

COPY marketing_data FROM '/home/jovyan/git/PMG/ProgrammingChallenges/sql-assessment/marketing_performance.csv' WITH (FORMAT csv, HEADER true);
COPY website_revenue FROM '/home/jovyan/git/PMG/ProgrammingChallenges/sql-assessment/website_revenue.csv' WITH (FORMAT csv, HEADER true);
COPY campaign_info FROM '/home/jovyan/git/PMG/ProgrammingChallenges/sql-assessment/campaign_info.csv' WITH (FORMAT csv, HEADER true);

-- DROP TABLE marketing_data;
-- DROP TABLE website_revenue;
-- DROP TABLE campaign_info;

-- SELECT * from marketing_data
-- SELECT * from website_revenue
-- SELECT * from campaign_info

-- 1. Write a query to get the sum of impressions by day.
SELECT 
    date::date AS day, 
    SUM(impressions) AS total_impressions
FROM marketing_data
GROUP BY day
ORDER BY day;

-- 2. Write a query to get the top three revenue-generating states in order of best to worst. How much revenue did the third best state generate?
SELECT 
    state,
    sum(revenue) as total_revenue
from website_revenue
group by state
order by total_revenue desc 
limit 3;

-- The third best state was OH (37577)

-- 3. Write a query that shows total cost, impressions, clicks, and revenue of each campaign. Make sure to include the campaign name in the output.
WITH 
Q1 AS (
    SELECT 
        name,
        sum(cost) as total_cost, 
        sum(impressions) as total_impressions, 
        sum(clicks) as total_clicks 
    from marketing_data as x
    inner join campaign_info as y
    on x.campaign_id = y.id
    GROUP by name),
Q2 AS (
    SELECT 
        name, 
        sum(revenue) as total_revenue
    from website_revenue as a
    inner join campaign_info as b
    on a.campaign_id = b.id
    group by name)

SELECT 
    COALESCE(Q1.name, Q2.name) AS name,
    Round(COALESCE(Q1.total_cost, 0)::numeric,2) AS total_cost,
    COALESCE(Q1.total_impressions, 0) AS total_impressions,
    COALESCE(Q1.total_clicks, 0) AS total_clicks,
    COALESCE(Q2.total_revenue, 0) AS total_revenue
FROM Q1
INNER JOIN Q2 ON Q1.name = Q2.name
ORDER BY name;

-- 4. Write a query to get the number of conversions of Campaign5 by state. Which state generated the most conversions for this campaign?
SELECT name, geo, sum(conversions) as total_conversions
FROM campaign_info as x
inner join marketing_data as y
on x.id = y.campaign_id
where name = 'Campaign5'
group by name, geo
order by total_conversions desc

-- GA generated the most conversions for this campaign (672)

-- 5. In your opinion, which campaign was the most efficient, and why?
    -- I will decide the campaign efficiency based on 4 metrics:
        -- 1. Click through rate (CTR)
        -- 2. cost per conversion
        -- 3. Return on ad spend (ROAS)
        -- 4. Conversion Rate
     -- It's also worth noting that there isn't a universally definitive "most efficient" campaign because each metric highlights different aspects of efficiency. 

    -- The following query generate a table for the following metrics
WITH Q4 AS
(WITH 
Q1 AS (
    SELECT 
        name,
        sum(cost) as total_cost, 
        sum(impressions) as total_impressions, 
        sum(clicks) as total_clicks 
    from marketing_data as x
    inner join campaign_info as y
    on x.campaign_id = y.id
    GROUP by name),
Q2 AS (
    SELECT 
        name, 
        sum(revenue) as total_revenue
    from website_revenue as a
    inner join campaign_info as b
    on a.campaign_id = b.id
    group by name),
Q3 AS (SELECT name, sum(conversions) as total_conversions
FROM campaign_info as x
inner join marketing_data as y
on x.id = y.campaign_id
group by name
order by total_conversions desc)

SELECT 
    COALESCE(Q1.name, Q2.name) AS name,
    COALESCE(Q1.total_cost, 0) AS total_cost,
    COALESCE(Q1.total_impressions, 0) AS total_impressions,
    COALESCE(Q1.total_clicks, 0) AS total_clicks,
    COALESCE(Q2.total_revenue, 0) AS total_revenue,
    COALESCE(Q3.total_conversions, 0) AS total_conversions
FROM Q1
INNER JOIN Q2 ON Q1.name = Q2.name
INNER JOIN Q3 ON Q1.name = Q3.name
ORDER BY name)

SELECT
    name,
    Round(((total_clicks/total_impressions) * 100)::numeric,1) AS CTR,
    Round((total_cost/total_conversions)::numeric,2) as CostPerConversion,
    Round(((total_revenue/total_cost) * 100)::numeric,1) as ReturnOnAdSpend,
    Round((total_conversions/total_clicks)::numeric,2) as ConversionRate
FROM Q4
order by name
   
    -- If efficiency means high CTR: "Campaign5" has the highest CTR.
    -- If efficiency means low Cost Per Conversion: "Campaign4" has the lowest cost per conversion.
    -- If efficiency means high ROAS: "Campaign4" has the highest ROAS.
    -- If efficiency means high Conversion Rate: "Campaign2" and "Campaign3" have the highest conversion rates.

    -- In my opinion Campaign4 both seems to perform well in terms of low cost per conversion and high ROAS.


-- 6. Write a query that showcases the best day of the week (e.g., Sunday, Monday, Tuesday, etc.) to run ads.
WITH Q1 AS 
(SELECT date::date as date, sum(impressions) as total_impressions, sum(clicks) as total_clicks, sum(conversions) as total_conversions
from marketing_data
group by date),
Q2 AS 
(SELECT date::date as date, sum(revenue) as total_revenue
from website_revenue
group by date)

SELECT CASE EXTRACT(DOW FROM COALESCE(Q1.date, Q2.date))
    WHEN 0 THEN 'Sunday'
    WHEN 1 THEN 'Monday'
    WHEN 2 THEN 'Tuesday'
    WHEN 3 THEN 'Wednesday'
    WHEN 4 THEN 'Thursday'
    WHEN 5 THEN 'Friday'
    WHEN 6 THEN 'Saturday'
END AS day_of_week, sum(total_impressions) as total_impressions , sum(total_clicks) as total_clicks, sum(total_revenue) as total_revenue
FROM Q1 full outer join Q2 on Q1.date = Q2.date
WHERE total_impressions IS NOT NULL AND total_clicks IS NOT NULL AND total_revenue IS NOT NULL
group by day_of_week
order by total_impressions desc, total_clicks desc, total_revenue desc
limit 1;


