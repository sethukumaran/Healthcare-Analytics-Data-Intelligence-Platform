-- 01_drug_intelligence.sql
-- SQLite-compatible SQL. Run against healthcare_analytics.db.

-- Q01: Row counts
SELECT 'drug_products' AS table_name, COUNT(*) AS row_count FROM drug_products
UNION ALL SELECT 'drug_packages', COUNT(*) FROM drug_packages
UNION ALL SELECT 'unfinished_products', COUNT(*) FROM unfinished_products
UNION ALL SELECT 'unfinished_packages', COUNT(*) FROM unfinished_packages;

-- Q02: Distinct manufacturers / labelers
SELECT COUNT(DISTINCT labelername) AS distinct_labelers
FROM drug_products;

-- Q03: Top 20 manufacturers by product count
SELECT labelername, COUNT(*) AS product_count
FROM drug_products
GROUP BY labelername
ORDER BY product_count DESC
LIMIT 20;

-- Q04: Top proprietary drug names
SELECT proprietaryname, COUNT(*) AS product_count
FROM drug_products
WHERE proprietaryname IS NOT NULL AND TRIM(proprietaryname) <> ''
GROUP BY proprietaryname
ORDER BY product_count DESC
LIMIT 20;

-- Q05: Product mix by dosage form
SELECT dosageformname, COUNT(*) AS product_count,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_products
FROM drug_products
GROUP BY dosageformname
ORDER BY product_count DESC
LIMIT 25;

-- Q06: Product mix by route
SELECT routename, COUNT(*) AS product_count
FROM drug_products
WHERE routename IS NOT NULL
GROUP BY routename
ORDER BY product_count DESC
LIMIT 20;

-- Q07: Product mix by marketing category
SELECT marketingcategoryname, COUNT(*) AS product_count
FROM drug_products
GROUP BY marketingcategoryname
ORDER BY product_count DESC;

-- Q08: Products with multiple packages
SELECT productid, proprietaryname, COUNT(*) AS package_count
FROM drug_products dp
JOIN drug_packages pk USING(productid)
GROUP BY productid, proprietaryname
HAVING COUNT(*) > 1
ORDER BY package_count DESC
LIMIT 25;

-- Q09: Average packages per product
WITH p AS (
    SELECT productid, COUNT(*) AS package_count
    FROM drug_packages
    GROUP BY productid
)
SELECT ROUND(AVG(package_count), 2) AS avg_packages_per_product,
       MAX(package_count) AS max_packages
FROM p;

-- Q10: Active vs discontinued products based on end marketing date
SELECT CASE WHEN endmarketingdate IS NULL OR TRIM(endmarketingdate) = ''
            THEN 'Active / no end date'
            ELSE 'Has end date'
       END AS lifecycle_status,
       COUNT(*) AS products
FROM drug_products
GROUP BY lifecycle_status;

-- Q11: Products started by year
SELECT substr(startmarketingdate,1,4) AS start_year,
       COUNT(*) AS products_started
FROM drug_products
WHERE startmarketingdate IS NOT NULL
GROUP BY start_year
ORDER BY start_year;

-- Q12: Products with missing critical attributes
SELECT
  SUM(CASE WHEN nonproprietaryname IS NULL OR TRIM(nonproprietaryname)='' THEN 1 ELSE 0 END) AS missing_generic_name,
  SUM(CASE WHEN labelername IS NULL OR TRIM(labelername)='' THEN 1 ELSE 0 END) AS missing_labeler,
  SUM(CASE WHEN dosageformname IS NULL OR TRIM(dosageformname)='' THEN 1 ELSE 0 END) AS missing_dosage_form,
  SUM(CASE WHEN startmarketingdate IS NULL OR TRIM(startmarketingdate)='' THEN 1 ELSE 0 END) AS missing_start_date
FROM drug_products;

-- Q13: Controlled substance schedule distribution
SELECT COALESCE(deaschedule,'Not scheduled') AS dea_schedule,
       COUNT(*) AS products
FROM drug_products
GROUP BY COALESCE(deaschedule,'Not scheduled')
ORDER BY products DESC;

-- Q14: Pharmaceutical class coverage
SELECT pharm_classes, COUNT(*) AS products
FROM drug_products
WHERE pharm_classes IS NOT NULL AND TRIM(pharm_classes) <> ''
GROUP BY pharm_classes
ORDER BY products DESC
LIMIT 25;

-- Q15: Generic ingredient concentration
SELECT substancename, COUNT(*) AS product_count,
       COUNT(DISTINCT labelername) AS labeler_count
FROM drug_products
WHERE substancename IS NOT NULL AND TRIM(substancename) <> ''
GROUP BY substancename
HAVING COUNT(*) >= 20
ORDER BY product_count DESC
LIMIT 25;

-- Q16: Same substance sold by many labelers
SELECT substancename, COUNT(DISTINCT labelername) AS labelers,
       COUNT(*) AS products
FROM drug_products
WHERE substancename IS NOT NULL
GROUP BY substancename
HAVING COUNT(DISTINCT labelername) >= 10
ORDER BY labelers DESC, products DESC
LIMIT 25;

-- Q17: Finished vs unfinished product comparison
SELECT 'Finished' AS product_type, COUNT(*) AS products FROM drug_products
UNION ALL
SELECT 'Unfinished / bulk', COUNT(*) FROM unfinished_products;

-- Q18: Unfinished products by marketing category
SELECT marketingcategoryname, COUNT(*) AS products
FROM unfinished_products
GROUP BY marketingcategoryname
ORDER BY products DESC;

-- Q19: Packaging description patterns
SELECT
  CASE
    WHEN packagedescription LIKE '%BOTTLE%' THEN 'Bottle'
    WHEN packagedescription LIKE '%VIAL%' THEN 'Vial'
    WHEN packagedescription LIKE '%BOX%' THEN 'Box'
    WHEN packagedescription LIKE '%TUBE%' THEN 'Tube'
    WHEN packagedescription LIKE '%BLISTER%' THEN 'Blister'
    ELSE 'Other'
  END AS package_type,
  COUNT(*) AS package_count
FROM drug_packages
GROUP BY package_type
ORDER BY package_count DESC;

-- Q20: Duplicate business keys / quality check
SELECT productndc, COUNT(*) AS rows_per_ndc
FROM drug_products
GROUP BY productndc
HAVING COUNT(*) > 1
ORDER BY rows_per_ndc DESC
LIMIT 50;
