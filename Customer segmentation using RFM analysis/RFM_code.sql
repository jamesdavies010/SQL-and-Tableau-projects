/* 

This project focuses on analysing customer purchase behaviour using the RFM model (Recency, Frequency, and Monetary analysis). The goal is to segment customers based on their purchasing habits and adapt the marketing strategy to each customer segement. 

*/

# note to self: remove original transactions associated with refunds (not done) as well as refunds (done).
WITH dataset_filtered AS (
  SELECT
    *,
    UnitPrice*Quantity AS ItemOrderValue
  FROM `tc-da-1.turing_data_analytics.rfm`
  WHERE InvoiceDate BETWEEN '2010-12-01' AND '2011-12-02'
    AND CustomerID  IS NOT NULL 
    AND Quantity > 0 --removes any purchases that customers have returned
    AND UnitPrice > 0
)
,

/* This CTE is required to calculate 'Recency' metrics */
end_date AS (
  SELECT
    MAX(InvoiceDate) AS LastDate
  FROM dataset_filtered
)
,

customer_order_metrics AS (
  SELECT
    CustomerID,
    MAX(InvoiceDate) AS DateOfLastPurchase,
    MIN(InvoiceDate) AS DateOfFirstPurchase,
    COUNT(DISTINCT InvoiceNo) AS NumberOfOrders,
    ROUND(SUM(ItemOrderValue), 2) AS TotalValueOfOrders
  FROM dataset_filtered
  GROUP BY 1
)
,

rfm_metrics AS (
  SELECT
    CustomerID,
    DATE_DIFF(DateOfLastPurchase, DateOfFirstPurchase, DAY) + 1 AS DaysActive,
    DATE_DIFF(LastDate, DateOfFirstPurchase, DAY) + 1 AS DateDiffFirstToPresentDay,
    (DATE_DIFF(LastDate, DateOfFirstPurchase, DAY) + 1)/NumberOfOrders AS DaysPerOrder,
    TotalValueOfOrders/NumberOfOrders AS AverageOrderValue,
  FROM customer_order_metrics
  CROSS JOIN end_date
)
,

quantile_design AS (
  SELECT
    APPROX_QUANTILES(DateOfLastPurchase, 3) AS recency_rankings,--to adjust to quartiles, just change '3' to '4'
    APPROX_QUANTILES(NumberOfOrders, 3) AS frequency_rankings,
    APPROX_QUANTILES(TotalValueOfOrders, 3) AS monetary_rankings
  FROM customer_order_metrics
)
,

quantiles_approx AS (
  SELECT
    recency_rankings[offset(1)] AS FirstTertileRecency,--33rd percentile
    recency_rankings[offset(2)] AS SecondTertileRecency,--66th percentile
    frequency_rankings[offset(1)] AS FirstTertileFrequency,--33rd percentile
    frequency_rankings[offset(2)] AS SecondTertileFrequency,--66th percentile
    monetary_rankings[offset(1)] AS FirstTertileMonetary,--33rd percentile
    monetary_rankings[offset(2)] AS SecondTertileMonetary,--66th percentile
  FROM quantile_design
)
,

rankings AS (
  SELECT 
    CustomerID,
    CASE
    /* Quantiles should in theory be < rather than <=, but for practical purposes I think this is better */
      WHEN DateOfLastPurchase <= FirstTertileRecency THEN 3
      WHEN DateOfLastPurchase > FirstTertileRecency AND DateOfLastPurchase <= SecondTertileRecency THEN 2
      ELSE 1
    END AS RecencyRanking,
    CASE 
      WHEN NumberOfOrders <= FirstTertileFrequency THEN 3
      WHEN NumberOfOrders > FirstTertileFrequency AND NumberOfOrders <= SecondTertileFrequency THEN 2
      ELSE 1
    END AS FrequencyRanking,
    CASE 
      WHEN TotalValueOfOrders <= FirstTertileMonetary THEN 3
      WHEN TotalValueOfOrders > FirstTertileMonetary AND TotalValueOfOrders <= SecondTertileMonetary THEN 2
      ELSE 1
    END AS MonetaryRanking,
    -- *, # use to validate results
  FROM rfm_metrics
  JOIN customer_order_metrics USING (CustomerID)
  CROSS JOIN quantiles_approx
)
,

rfm_ids AS (
  SELECT
    CustomerID,
    CONCAT(RecencyRanking,FrequencyRanking,MonetaryRanking) AS RFM_ID
  FROM rankings
)
,

customer_types AS (
  SELECT
    CustomerID,
    CASE 
      WHEN RFM_ID IN ('111', '112', '211') THEN 'Top customer'
      WHEN RFM_ID IN ('122', '121','131', '132', '113') THEN 'Potentially loyal customer'--This I would change if I had my time again
      WHEN RFM_ID IN ('133', '123', '213') THEN 'Recent or promising customer'
      WHEN RFM_ID IN ('311', '221', '212', '321', '231') THEN 'Must not lose'
      WHEN RFM_ID IN ('232', '223', '233', '222') THEN 'Customer needing attention'
      WHEN RFM_ID IN ('312', '313', '322', '323') THEN 'On the way out'
      WHEN RFM_ID IN ('333', '331', '332') THEN 'Lost'
      ELSE 'Unknown'
    END AS Customer_Type
  FROM rfm_ids
)
,

output AS (
  SELECT
    *
  FROM customer_order_metrics
  JOIN rfm_metrics USING (CustomerID)
  JOIN rankings USING (CustomerID)
  JOIN rfm_ids USING (CustomerID)
  JOIN customer_types USING (CustomerID)
)

SELECT *
FROM output

/*

Considerations for the future, based on the Vinted style guide:

Column naming
General guidelines
Schema, table and column names should be in snake_case
Use names based on the business terminology, rather than the source terminology
Don’t use reserved words as column names
Column names typically should be in singular form, except for columns containing counts (i.e. start with num_)
Consistency is key! Use the same field names across models where possible, e.g. a key to the user table should be named user_id rather than customer_id

Vocabulary
The primary key of a model should be named <object>_id, e.g. account_id – this makes it easier to know what id is being referenced in downstream joined models
Always add a suffix to the full id when distinguishing specific ids, e.g. user_id_buyer and not buyer_id. This makes it clear that you can join user_id_buyer on a user_id column.
Codes and statuses that map to an id should have the same prefix as the id it maps to, e.g. report_reason_code and transaction_status.
Timestamp columns should be named <event>_at, e.g. created_at, and should be in UTC. If a different timezone is being used, this should be indicated with a suffix, e.g created_at_pt
Booleans should be prefixed with is_ or has_
Columns which represent numeric values with a known unit should be suffixed with that unit, e.g. price_eur instead of price
Column naming for aggregations should add the appropriate prefix (num_, total_, min_, max_, avg_) to the column that the aggregation was applied to, e.g.:
Price/revenue fields should be in decimal

*/