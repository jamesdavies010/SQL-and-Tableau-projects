/* 

Code #2: Unique users per month

-----

I have two SQL codes:

1) Unique users over the whole time period
2) Unique users per month


In this code (below), I have assumed that a user who makes a purchase (or is involved in any other stage) in November, December and January should be counted three times (once in each month's statistics). I am showing unique users per month.

As a result, if you sum the months of November, December and January together, you will have a slightly higher number than in the overview graph. This is expected, but I believe more useful than the alternative.

I have used this code for my funnels and tables where month is referred to,

*/

WITH raw_events AS (
  SELECT   
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', event_date)) AS year_month,
    *
  FROM `tc-da-1.turing_data_analytics.raw_events`
)
,

raw_events_window_func AS (
  SELECT
    event_name,
    event_date,
    country,
    ROW_NUMBER() OVER (PARTITION BY user_pseudo_id,event_name,year_month ORDER BY event_timestamp) AS row_num,
  FROM raw_events
)
,

unique_user_visits AS (
  SELECT
    event_name AS Stage,
    COUNT(event_name) AS UniqueUserVisits
  FROM raw_events_window_func
  WHERE
    country = 'United States'
    AND event_date LIKE '202011%'
    AND event_name IN ('page_view','view_item','add_to_cart','begin_checkout','add_payment_info','purchase')
    AND row_num = 1
  GROUP BY 1
)

SELECT *
FROM unique_user_visits
ORDER BY 2 DESC
