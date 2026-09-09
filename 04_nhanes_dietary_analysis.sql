-- 04_nhanes_dietary_analysis.sql

-- Q01: Respondent count by survey cycle
SELECT survey_cycle, COUNT(*) AS respondents
FROM nhanes_dietary
GROUP BY survey_cycle
ORDER BY survey_cycle;

-- Q02: Average energy and macronutrients by cycle
SELECT survey_cycle,
       ROUND(AVG(dr1tkcal),2) AS avg_kcal,
       ROUND(AVG(dr1tprot),2) AS avg_protein_g,
       ROUND(AVG(dr1tcarb),2) AS avg_carb_g,
       ROUND(AVG(dr1ttfat),2) AS avg_fat_g,
       ROUND(AVG(dr1tsugr),2) AS avg_sugar_g,
       ROUND(AVG(dr1tfibe),2) AS avg_fiber_g
FROM nhanes_dietary
GROUP BY survey_cycle
ORDER BY survey_cycle;

-- Q03: Sodium trend
SELECT survey_cycle, ROUND(AVG(dr1tsodi),2) AS avg_sodium_mg
FROM nhanes_dietary
WHERE dr1tsodi IS NOT NULL
GROUP BY survey_cycle
ORDER BY survey_cycle;

-- Q04: Protein density (grams per 1,000 kcal)
SELECT survey_cycle,
       ROUND(1000.0*SUM(dr1tprot)/NULLIF(SUM(dr1tkcal),0),2) AS protein_g_per_1000_kcal
FROM nhanes_dietary
WHERE dr1tprot IS NOT NULL AND dr1tkcal > 0
GROUP BY survey_cycle
ORDER BY survey_cycle;

-- Q05: High-sugar dietary observations
SELECT survey_cycle, COUNT(*) AS observations,
       ROUND(100.0*AVG(CASE WHEN dr1tsugr >= 100 THEN 1.0 ELSE 0 END),2) AS pct_ge_100g_sugar
FROM nhanes_dietary
WHERE dr1tsugr IS NOT NULL
GROUP BY survey_cycle;

-- Q06: High sodium observations
SELECT survey_cycle,
       ROUND(100.0*AVG(CASE WHEN dr1tsodi >= 2300 THEN 1.0 ELSE 0 END),2) AS pct_ge_2300mg_sodium
FROM nhanes_dietary
WHERE dr1tsodi IS NOT NULL
GROUP BY survey_cycle;

-- Q07: Calorie outliers by cycle
WITH stats AS (
  SELECT survey_cycle, AVG(dr1tkcal) AS avg_kcal
  FROM nhanes_dietary
  WHERE dr1tkcal IS NOT NULL
  GROUP BY survey_cycle
)
SELECT n.survey_cycle, n.seqn, n.dr1tkcal, s.avg_kcal
FROM nhanes_dietary n
JOIN stats s USING(survey_cycle)
WHERE n.dr1tkcal > 3*s.avg_kcal
ORDER BY n.survey_cycle, n.dr1tkcal DESC
LIMIT 100;

-- Q08: Data completeness by cycle
SELECT survey_cycle,
       ROUND(100.0*AVG(CASE WHEN dr1tkcal IS NOT NULL THEN 1.0 ELSE 0 END),2) AS kcal_complete_pct,
       ROUND(100.0*AVG(CASE WHEN dr1tprot IS NOT NULL THEN 1.0 ELSE 0 END),2) AS protein_complete_pct,
       ROUND(100.0*AVG(CASE WHEN dr1tsodi IS NOT NULL THEN 1.0 ELSE 0 END),2) AS sodium_complete_pct
FROM nhanes_dietary
GROUP BY survey_cycle;

-- Q09: Top nutrient-intake records by protein
SELECT survey_cycle, seqn, dr1tkcal, dr1tprot, dr1ttfat, dr1tcarb
FROM nhanes_dietary
WHERE dr1tprot IS NOT NULL
ORDER BY dr1tprot DESC
LIMIT 25;

-- Q10: Correlation-ready aggregate
SELECT survey_cycle,
       AVG(dr1tkcal) AS avg_kcal,
       AVG(dr1tprot) AS avg_protein,
       AVG(dr1tcarb) AS avg_carb,
       AVG(dr1ttfat) AS avg_fat
FROM nhanes_dietary
GROUP BY survey_cycle;
