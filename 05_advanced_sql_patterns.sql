-- 05_advanced_sql_patterns.sql
-- Senior-level SQL patterns demonstrated on the portfolio database.

-- Q01: CTE + window ranking: rank manufacturers within product categories
WITH manufacturer_category AS (
    SELECT marketingcategoryname, labelername, COUNT(*) AS products
    FROM drug_products
    GROUP BY marketingcategoryname, labelername
),
ranked AS (
    SELECT *,
           DENSE_RANK() OVER (
             PARTITION BY marketingcategoryname
             ORDER BY products DESC
           ) AS rnk
    FROM manufacturer_category
)
SELECT *
FROM ranked
WHERE rnk <= 3
ORDER BY marketingcategoryname, rnk;

-- Q02: Pareto analysis: manufacturers contributing to 80% of products
WITH counts AS (
  SELECT labelername, COUNT(*) AS products
  FROM drug_products
  GROUP BY labelername
),
running AS (
  SELECT labelername, products,
         SUM(products) OVER (ORDER BY products DESC
                             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_products,
         SUM(products) OVER () AS total_products
  FROM counts
)
SELECT labelername, products,
       ROUND(100.0*cumulative_products/total_products,2) AS cumulative_pct
FROM running
ORDER BY products DESC;

-- Q03: Rating quartiles using NTILE
WITH x AS (
  SELECT contract_id, organization_marketing_name, overall_star_rating,
         NTILE(4) OVER (ORDER BY overall_star_rating) AS rating_quartile
  FROM medicare_star_summary
  WHERE overall_star_rating IS NOT NULL
)
SELECT rating_quartile, COUNT(*) AS contracts,
       ROUND(AVG(overall_star_rating),2) AS avg_rating
FROM x
GROUP BY rating_quartile
ORDER BY rating_quartile;

-- Q04: Z-score-style outlier screening for calories by survey cycle
WITH stats AS (
  SELECT survey_cycle, AVG(dr1tkcal) AS mean_kcal,
         AVG(dr1tkcal*dr1tkcal) AS mean_sq
  FROM nhanes_dietary
  WHERE dr1tkcal IS NOT NULL
  GROUP BY survey_cycle
),
scored AS (
  SELECT n.*,
         (n.dr1tkcal-s.mean_kcal) /
         NULLIF(sqrt(s.mean_sq-s.mean_kcal*s.mean_kcal),0) AS z_score
  FROM nhanes_dietary n JOIN stats s USING(survey_cycle)
  WHERE n.dr1tkcal IS NOT NULL
)
SELECT survey_cycle, seqn, dr1tkcal, ROUND(z_score,2) AS z_score
FROM scored
WHERE ABS(z_score) >= 3
ORDER BY ABS(z_score) DESC;

-- Q05: Anti-join: packages with no matching product
SELECT p.*
FROM drug_packages p
LEFT JOIN drug_products d ON d.productid = p.productid
WHERE d.productid IS NULL;

-- Q06: Self-contained KPI view for Medicare
DROP VIEW IF EXISTS vw_medicare_kpis;
CREATE VIEW vw_medicare_kpis AS
SELECT
  COUNT(*) AS rated_contracts,
  ROUND(AVG(overall_star_rating),2) AS avg_rating,
  ROUND(100.0*AVG(CASE WHEN overall_star_rating >= 4 THEN 1.0 ELSE 0 END),2) AS pct_4_plus,
  ROUND(100.0*AVG(CASE WHEN overall_star_rating <= 2 THEN 1.0 ELSE 0 END),2) AS pct_2_or_below
FROM medicare_star_summary
WHERE overall_star_rating IS NOT NULL;

SELECT * FROM vw_medicare_kpis;

-- Q07: Data-quality exception report
SELECT 'drug_products' AS table_name, 'missing_labeler' AS issue, COUNT(*) AS issue_count
FROM drug_products WHERE labelername IS NULL OR TRIM(labelername)=''
UNION ALL
SELECT 'drug_products','missing_start_date',COUNT(*)
FROM drug_products WHERE startmarketingdate IS NULL OR TRIM(startmarketingdate)=''
UNION ALL
SELECT 'medicare_star_summary','missing_contract_id',COUNT(*)
FROM medicare_star_summary WHERE contract_id IS NULL
UNION ALL
SELECT 'medicare_star_summary','invalid_star_rating',COUNT(*)
FROM medicare_star_summary WHERE overall_star_rating < 0 OR overall_star_rating > 5
UNION ALL
SELECT 'nhanes_dietary','missing_calories',COUNT(*)
FROM nhanes_dietary WHERE dr1tkcal IS NULL;
