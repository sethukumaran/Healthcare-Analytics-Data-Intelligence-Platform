-- 02_medicare_star_analysis.sql

-- Q01: Overall star distribution
SELECT overall_star_rating, COUNT(*) AS contracts
FROM medicare_star_summary
WHERE overall_star_rating IS NOT NULL
GROUP BY overall_star_rating
ORDER BY overall_star_rating;

-- Q02: Average star rating
SELECT ROUND(AVG(overall_star_rating), 2) AS avg_overall_star_rating,
       MIN(overall_star_rating) AS min_rating,
       MAX(overall_star_rating) AS max_rating
FROM medicare_star_summary
WHERE overall_star_rating IS NOT NULL;

-- Q03: Top 20 contracts
SELECT contract_id, organization_marketing_name, organization_type,
       overall_star_rating
FROM medicare_star_summary
WHERE overall_star_rating IS NOT NULL
ORDER BY overall_star_rating DESC, organization_marketing_name
LIMIT 20;

-- Q04: Lowest-rated contracts
SELECT contract_id, organization_marketing_name, organization_type,
       overall_star_rating
FROM medicare_star_summary
WHERE overall_star_rating IS NOT NULL
ORDER BY overall_star_rating ASC, organization_marketing_name
LIMIT 20;

-- Q05: Organization type performance
SELECT organization_type,
       COUNT(*) AS contracts,
       ROUND(AVG(overall_star_rating),2) AS avg_rating,
       ROUND(MIN(overall_star_rating),1) AS min_rating,
       ROUND(MAX(overall_star_rating),1) AS max_rating
FROM medicare_star_summary
WHERE overall_star_rating IS NOT NULL
GROUP BY organization_type
HAVING COUNT(*) >= 3
ORDER BY avg_rating DESC;

-- Q06: Rating bands
SELECT
  CASE
    WHEN overall_star_rating >= 4.5 THEN 'Excellent (4.5-5)'
    WHEN overall_star_rating >= 3.5 THEN 'Good (3.5-4)'
    WHEN overall_star_rating >= 2.5 THEN 'Average (2.5-3)'
    ELSE 'Needs Improvement (<2.5)'
  END AS rating_band,
  COUNT(*) AS contracts,
  ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM medicare_star_summary
                         WHERE overall_star_rating IS NOT NULL),2) AS pct
FROM medicare_star_summary
WHERE overall_star_rating IS NOT NULL
GROUP BY rating_band
ORDER BY contracts DESC;

-- Q07: SNP vs non-SNP performance
SELECT snp, COUNT(*) AS contracts,
       ROUND(AVG(overall_star_rating),2) AS avg_rating
FROM medicare_star_summary
WHERE overall_star_rating IS NOT NULL
GROUP BY snp
ORDER BY avg_rating DESC;

-- Q08: Sanction deduction and rating
SELECT sanction_deduction, COUNT(*) AS contracts,
       ROUND(AVG(overall_star_rating),2) AS avg_rating
FROM medicare_star_summary
WHERE overall_star_rating IS NOT NULL
GROUP BY sanction_deduction;

-- Q09: Parent organizations with multiple contracts
SELECT parent_organization,
       COUNT(*) AS contracts,
       ROUND(AVG(overall_star_rating),2) AS avg_rating,
       ROUND(MIN(overall_star_rating),1) AS min_rating,
       ROUND(MAX(overall_star_rating),1) AS max_rating
FROM medicare_star_summary
WHERE parent_organization IS NOT NULL
  AND overall_star_rating IS NOT NULL
GROUP BY parent_organization
HAVING COUNT(*) >= 2
ORDER BY contracts DESC, avg_rating DESC
LIMIT 30;

-- Q10: Organizations with rating below portfolio average
WITH avg_rating AS (
  SELECT AVG(overall_star_rating) AS avg_star
  FROM medicare_star_summary
  WHERE overall_star_rating IS NOT NULL
)
SELECT contract_id, organization_marketing_name, overall_star_rating
FROM medicare_star_summary, avg_rating
WHERE overall_star_rating < avg_star
ORDER BY overall_star_rating;

-- Q11: Percent of contracts rated 4+ stars
SELECT ROUND(
  100.0 * SUM(CASE WHEN overall_star_rating >= 4 THEN 1 ELSE 0 END)
  / COUNT(*), 2) AS pct_4_plus
FROM medicare_star_summary
WHERE overall_star_rating IS NOT NULL;

-- Q12: Data quality checks
SELECT
  COUNT(*) AS total_rows,
  SUM(CASE WHEN contract_id IS NULL THEN 1 ELSE 0 END) AS missing_contract_id,
  SUM(CASE WHEN organization_type IS NULL THEN 1 ELSE 0 END) AS missing_org_type,
  SUM(CASE WHEN overall_star_rating IS NULL THEN 1 ELSE 0 END) AS missing_rating,
  SUM(CASE WHEN overall_star_rating < 0 OR overall_star_rating > 5 THEN 1 ELSE 0 END) AS invalid_rating
FROM medicare_star_summary;
