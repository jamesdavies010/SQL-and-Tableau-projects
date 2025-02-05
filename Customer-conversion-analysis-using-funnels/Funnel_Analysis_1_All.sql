/* 

Code #1: Unique users over the whole time period

-----

I have two SQL codes:

1) Unique users over the whole time period
2) Unique users per month


In this code (below), I have assumed that a user who makes a purchase (or is involved in any other stage) in November, December and January should be counted only once. I am showing unique users.

I have used this code for my funnels where I give an overview by country (not including any months),

*/

SELECT   
  event_name AS stage,
  COUNT (DISTINCT user_pseudo_id) AS unique_user_visits,
FROM `tc-da-1.turing_data_analytics.raw_events` AS raw_events
WHERE event_name IN ('page_view','view_item','add_to_cart','begin_checkout','add_payment_info','purchase')
  -- AND country = 'Canada' /* then replace with 'United States' or 'India' and download data */
GROUP BY 1
ORDER BY 2 DESC
