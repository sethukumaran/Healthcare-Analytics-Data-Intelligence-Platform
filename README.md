# Healthcare-Analytics-Data-Intelligence-Platform
End-to-end healthcare data analytics project analyzing pharmaceutical, Medicare, nutrition, and NHANES datasets using SQL and Python. Performed data cleaning, transformation, exploratory analysis, KPI development, advanced SQL analysis, and statistical insights. Translated complex healthcare data into actionable business insights to support data.


## 1. Executive Summary

This project demonstrates an end-to-end **Senior Data Analyst workflow**:

**Raw healthcare files → data profiling → cleaning → analytical data model → SQL analysis → Python EDA → KPI outputs → business recommendations**

1. **Pharmaceutical Intelligence** — drug products, packages, unfinished/bulk products.
2. **Medicare Plan Quality** — 2016 Medicare star-rating summary.
3. **Nutrition Intelligence** — food-level nutrient composition.
4. **Dietary Trend Analysis** — selected NHANES dietary intake variables across 2005–2006 through 2013–2014.
## 2. Business Objective

A healthcare analytics team could use this portfolio to answer:

- Which pharmaceutical manufacturers have the largest product portfolios?
- Which dosage forms and routes dominate the market?
- Which active substances are supplied by many manufacturers?
- Which products have multiple package configurations?
- What does Medicare plan quality look like across organization types?
- What percentage of rated Medicare contracts achieve 4+ stars?
- Which plans are below the portfolio benchmark?
- Which foods are high in protein but low in sugar?
- How do calories, protein, fat, sugar, fiber and sodium vary across NHANES cycles?
- Where are data-quality gaps and potential outliers?

---

## 3. Dataset Inventory

| Dataset | Analytical role | Approx. rows |
|---|---|---:|
| Drugs_product.csv | Finished drug product master | 117,365 |
| Drugs_package.csv | Drug package master | 221,361 |
| Drugs_unfinished_products.csv | Unfinished/bulk drug master | 19,042 |
| Drugs_unfinished_package.csv | Unfinished package master | 31,659 |
| Nutritions_US.csv | Food nutrient reference | 8,790 |
| Medicare Star Summary | Plan quality / star rating | 642 |
| NHANES 2005–2014 | Dietary intake | 50,965 combined analytical records |

The processed NHANES table deliberately keeps a **business-relevant subset of the original 400+ columns** to make the analytical model easier to understand and maintain.

---

## 4. Key Portfolio KPIs

The supplied files produce the following analytical footprint:

- **117,365** finished drug products
- **221,361** drug package records
- **19,042** unfinished/bulk products
- **31,659** unfinished package records
- **8,790** nutrition items
- **642** Medicare contract records in the cleaned summary
- **369** Medicare contracts with a numeric overall star rating
- **50,965** selected NHANES dietary records
- **3.74 / 5** average overall Medicare star rating among rated contracts

### Important interpretation note

The Medicare dataset is **historical 2016 data**. It is included for portfolio analysis and must not be interpreted as current Medicare plan performance.

Nutrition and dietary figures are analytical demonstrations, not clinical advice.
# 5. Technology Stack

### SQL
- SQLite
- CTEs
- Window functions
- `CASE WHEN`
- Aggregations
- Ranking
- `NTILE`
- `DENSE_RANK`
- Anti-joins
- Data-quality exception reporting
- Views
- Pareto analysis
- Outlier detection

### Python
- Python 3.10+
- Pandas
- NumPy
- Matplotlib
- SQLite / `sqlite3`
- ZIP/file processing
- Data cleaning
- Feature engineering
- EDA
- KPI generation
- Automated output generation
# 6. SQL Analysis

The SQL layer is divided into five files.

## 6.1 Pharmaceutical Intelligence

`sql/01_drug_intelligence.sql`

Demonstrates:

- Manufacturer market concentration
- Product portfolio size
- Dosage-form mix
- Route mix
- Marketing category mix
- Product lifecycle
- DEA schedule distribution
- Pharmaceutical classes
- Substance/manufacturer coverage
- Package complexity
- Finished vs unfinished products
- Duplicate business-key detection
- Data-quality checks

### Example — Top manufacturers

```sql
SELECT
    labelername,
    COUNT(*) AS product_count
FROM drug_products
WHERE labelername IS NOT NULL
GROUP BY labelername
ORDER BY product_count DESC
LIMIT 20;
```

### Example — Products with multiple packages

```sql
SELECT
    productid,
    proprietaryname,
    COUNT(*) AS package_count
FROM drug_products dp
JOIN drug_packages pk
    USING (productid)
GROUP BY productid, proprietaryname
HAVING COUNT(*) > 1
ORDER BY package_count DESC;
```

---

## 6.2 Medicare Plan Quality

`sql/02_medicare_star_analysis.sql`

Demonstrates:

- Star-rating distribution
- Average performance
- Top/bottom performers
- Organization-type benchmarking
- SNP vs non-SNP comparison
- Sanction analysis
- Parent organization analysis
- Benchmark comparison
- 4+ star penetration
- Data-quality checks

### Example — Portfolio benchmark

```sql
WITH avg_rating AS (
    SELECT AVG(overall_star_rating) AS avg_star
    FROM medicare_star_summary
    WHERE overall_star_rating IS NOT NULL
)
SELECT
    contract_id,
    organization_marketing_name,
    overall_star_rating
FROM medicare_star_summary, avg_rating
WHERE overall_star_rating < avg_star
ORDER BY overall_star_rating;
```

---

# 7. Advanced SQL Demonstrations

`sql/05_advanced_sql_patterns.sql`

This file is specifically designed to demonstrate **senior-level SQL skills**.

### CTE + Window Function

```sql
WITH manufacturer_category AS (
    SELECT
        marketingcategoryname,
        labelername,
        COUNT(*) AS products
    FROM drug_products
    GROUP BY marketingcategoryname, labelername
),
ranked AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY marketingcategoryname
            ORDER BY products DESC
        ) AS rnk
    FROM manufacturer_category
)
SELECT *
FROM ranked
WHERE rnk <= 3;
```

### Pareto Analysis

```sql
WITH counts AS (
    SELECT
        labelername,
        COUNT(*) AS products
    FROM drug_products
    GROUP BY labelername
),
running AS (
    SELECT
        labelername,
        products,
        SUM(products) OVER (
            ORDER BY products DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_products,
        SUM(products) OVER () AS total_products
    FROM counts
)
SELECT
    labelername,
    products,
    ROUND(
        100.0 * cumulative_products / total_products,
        2
    ) AS cumulative_pct
FROM running
ORDER BY products DESC;
```

### Quartile Analysis

```sql
WITH x AS (
    SELECT
        contract_id,
        organization_marketing_name,
        overall_star_rating,
        NTILE(4) OVER (
            ORDER BY overall_star_rating
        ) AS rating_quartile
    FROM medicare_star_summary
    WHERE overall_star_rating IS NOT NULL
)
SELECT
    rating_quartile,
    COUNT(*) AS contracts,
    ROUND(AVG(overall_star_rating), 2) AS avg_rating
FROM x
GROUP BY rating_quartile
ORDER BY rating_quartile;
```

---

# 8. Python Analytics

`src/data_pipeline.py`

Responsibilities:

- Archive extraction
- Encoding-safe ingestion
- Column-name standardization
- Date parsing
- Numeric conversion
- NHANES cycle consolidation
- Medicare header cleanup
- Nutrition column cleanup
- SQLite database creation
- Index creation

`src/analysis.py`

Responsibilities:

- Data-quality summary
- Executive KPIs
- Manufacturer analysis
- Dosage-form analysis
- Medicare rating analysis
- NHANES trend analysis
- Nutrition screening
- Chart generation
- CSV output generation

---

# 9. Python Example

```python
import sqlite3
import pandas as pd

DB = "healthcare_analytics.db"

def query(sql):
    with sqlite3.connect(DB) as conn:
        return pd.read_sql_query(sql, conn)

top_manufacturers = query("""
    SELECT
        labelername,
        COUNT(*) AS product_count
    FROM drug_products
    WHERE labelername IS NOT NULL
    GROUP BY labelername
    ORDER BY product_count DESC
    LIMIT 15
""")

print(top_manufacturers)
```

---

# 10. Key Analytical Findings

## Pharmaceutical

The drug product dataset contains more than **117K finished products**, with more than **221K package records**, indicating substantial package-level complexity.

The leading dosage forms include tablets, liquids, film-coated tablets, creams and injectable solutions.

The portfolio can be used to identify manufacturer concentration, product lifecycle patterns and substances supplied by multiple labelers.

## Medicare

Among contracts with a numeric overall rating:

- Average overall rating: **3.74 / 5**
- **27.9%** achieve 4+ stars
- The majority of rated contracts fall between 3.0 and 4.5 stars
- Very low-rated contracts represent a small portion of the rated population

SNP and non-SNP plans can also be benchmarked separately.

## NHANES

Average dietary intake changes across survey cycles.

The analytical model makes it possible to investigate:

- calories
- protein
- carbohydrate
- total fat
- sugar
- fiber
- sodium

For example, average sodium intake in this analytical subset is above 3,000 mg in each included cycle. This is a descriptive portfolio finding, not a clinical conclusion.

## Nutrition

The nutrition reference data supports food-level screening such as:

- high protein / low sugar
- high fiber
- high sodium
- calorie density
- macro-nutrient comparison

---

# 11. Data Quality Framework

The project explicitly checks:

### Completeness
- Missing labeler
- Missing generic name
- Missing dosage form
- Missing marketing dates
- Missing Medicare contract IDs
- Missing Medicare ratings
- Missing dietary nutrient values

### Validity
- Medicare rating outside 0–5
- Numeric conversion failures
- Negative/invalid nutrient values where applicable
- Unexpected duplicate business keys

### Consistency
- Finished products vs package records
- Product-to-package relationships
- Survey-cycle consistency
- Marketing-date parsing

### Referential integrity

The package tables are tested against their product masters using joins and anti-joins.

---

# 12. Senior Data Analyst Skills Demonstrated

This project is intentionally broader than simple SQL aggregation.

### Data Engineering
- Multi-file ingestion
- Data normalization
- Data type standardization
- Data validation
- Reproducible pipeline

### SQL
- Complex joins
- CTEs
- Window functions
- Ranking
- Percent-of-total
- Pareto analysis
- Quartiles
- Conditional aggregation
- Anti-joins
- Views
- Exception reporting

### Python
- Pandas
- NumPy
- Automated EDA
- Feature engineering
- Data-quality checks
- Visualization
- Reusable functions
- SQLite integration

### Business Analytics
- KPI design
- Benchmarking
- Segmentation
- Portfolio concentration
- Trend analysis
- Outlier detection
- Decision-oriented storytelling

