/* Task:

You are given a task from your product manager to give statistics on how subscriptions churn looks like from a weekly retention standpoint. 
You should provide weekly subscriptions data that shows how many subscribers started their subscription in a particular week and how many remain active in the following 6 weeks. 
Your end result should show weekly retention cohorts for each week of data available in the dataset and their retention from week 0 to week 6. 
Assume that you are doing this analysis on 2021-02-07.

*/


/* Adjust this date range if you want fewer cohorts */

WITH date_range AS (
  SELECT
    DATE '2020-11-01' AS start_date,
    DATE '2021-02-06' AS end_date
)
,

/* replace FROM clause with dataset provided to run the query */

main AS (
  SELECT *
  FROM `tc-da-1.turing_data_analytics.subscriptions` AS subscriptions
  JOIN date_range
    ON subscriptions.subscription_start >= date_range.start_date
      AND subscription_start <= date_range.end_date
)
,

/* CASE gives a 1 or 0 depending on whether user is still active (1) or not (0) in a given week. 
The 1s for each week are then summed to calculate the total number of active users in each week. */ 

output AS (
  SELECT
    DATE_TRUNC(subscription_start, WEEK) AS cohort_start,
    COUNT(user_pseudo_id) AS number_of_users,
    SUM(CASE WHEN (subscription_end >= DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 1 WEEK) OR subscription_end IS NULL) 
      AND end_date > DATE_ADD(DATE_TRUNC(subscription_start, WEEK),INTERVAL 1 WEEK) THEN 1 ELSE NULL END) AS week_1,
    SUM(CASE WHEN (subscription_end >= DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 2 WEEK) OR subscription_end IS NULL) 
      AND end_date > DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 2 WEEK) THEN 1 ELSE NULL END) AS week_2,
    SUM(CASE WHEN (subscription_end >= DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 3 WEEK) OR subscription_end IS NULL) 
      AND end_date > DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 3 WEEK) THEN 1 ELSE NULL END) AS week_3,
    SUM(CASE WHEN (subscription_end >= DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 4 WEEK) OR subscription_end IS NULL) 
      AND end_date > DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 4 WEEK) THEN 1 ELSE NULL END) AS week_4,
    SUM(CASE WHEN (subscription_end >= DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 5 WEEK) OR subscription_end IS NULL) 
      AND end_date > DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 5 WEEK) THEN 1 ELSE NULL END) AS week_5,
    SUM(CASE WHEN (subscription_end >= DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 6 WEEK) OR subscription_end IS NULL) 
      AND end_date > DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 6 WEEK) THEN 1 ELSE NULL END) AS week_6
  FROM main
  GROUP BY 1
)


/* Use this to check the results of each CTE */

SELECT *
FROM output





----------


/* Use this to validate whether the CASE statement is correctly calculating the number of active weeks for each user_pseudo_id

,
validation AS (
  SELECT
    user_pseudo_id,
    subscription_start,
    subscription_end,
    CASE WHEN (subscription_end >= DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 1 WEEK) OR subscription_end IS NULL) 
      AND end_date > DATE_ADD(DATE_TRUNC(subscription_start, WEEK),INTERVAL 1 WEEK) THEN 1 ELSE NULL END AS week_1,
    CASE WHEN (subscription_end >= DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 2 WEEK) OR subscription_end IS NULL) 
      AND end_date > DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 2 WEEK) THEN 1 ELSE NULL END AS week_2,
    CASE WHEN (subscription_end >= DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 3 WEEK) OR subscription_end IS NULL) 
      AND end_date > DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 3 WEEK) THEN 1 ELSE NULL END AS week_3,
    CASE WHEN (subscription_end >= DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 4 WEEK) OR subscription_end IS NULL) 
      AND end_date > DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 4 WEEK) THEN 1 ELSE NULL END AS week_4,
    CASE WHEN (subscription_end >= DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 5 WEEK) OR subscription_end IS NULL) 
      AND end_date > DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 5 WEEK) THEN 1 ELSE NULL END AS week_5,
    CASE WHEN (subscription_end >= DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 6 WEEK) OR subscription_end IS NULL) 
      AND end_date > DATE_ADD(DATE_TRUNC(subscription_start, WEEK), INTERVAL 6 WEEK) THEN 1 ELSE NULL END AS week_6
  FROM main
    -- WHERE DATE_TRUNC(subscription_start, WEEK) = '2020-11-01' 
    -- ORDER BY 3 ASC
    -- LIMIT 18000
)

*/

/* If you want to calculate churn rate and retention rate, use these:

churn_rate AS (
  SELECT
    output.cohort_start,
    output.number_of_users,
    ROUND((1-(week_1 / number_of_users)), 2) AS cr_week_1,
    ROUND((1-(week_2 / number_of_users)), 2) AS cr_week_2,
    ROUND((1-(week_3 / number_of_users)), 2) AS cr_week_3,
    ROUND((1-(week_4 / number_of_users)), 2) AS cr_week_4,
    ROUND((1-(week_5 / number_of_users)), 2) AS cr_week_5,
    ROUND((1-(week_6 / number_of_users)), 2) AS cr_week_6
  FROM output
)

retention_rate_vs_week_0 AS (
  SELECT
    output.cohort_start,
    output.number_of_users,
    ROUND(((week_1 / number_of_users)), 2) AS rr_week_1,
    ROUND(((week_2 / number_of_users)), 2) AS rr_week_2,
    ROUND(((week_3 / number_of_users)), 2) AS rr_week_3,
    ROUND(((week_4 / number_of_users)), 2) AS rr_week_4,
    ROUND(((week_5 / number_of_users)), 2) AS rr_week_5,
    ROUND(((week_6 / number_of_users)), 2) AS rr_week_6
  FROM output
)

retention_rate_vs_previous_week AS (
  SELECT
    output.cohort_start,
    output.number_of_users,
    ROUND(((week_1 / number_of_users)), 2) AS rr_week_1,
    ROUND(((week_2 / week_1)), 2) AS rr_week_2,
    ROUND(((week_3 / week_2)), 2) AS rr_week_3,
    ROUND(((week_4 / week_3)), 2) AS rr_week_4,
    ROUND(((week_5 / week_4)), 2) AS rr_week_5,
    ROUND(((week_6 / week_5)), 2) AS rr_week_6
  FROM output
)

*/