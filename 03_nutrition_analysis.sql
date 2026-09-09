-- 03_nutrition_analysis.sql

-- Q01: Most calorie-dense foods
SELECT ndb_no, shrt_desc, energ_kcal, protein_g, fiber_td_g, sugar_tot_g
FROM nutrition_foods
WHERE energ_kcal IS NOT NULL
ORDER BY energ_kcal DESC
LIMIT 25;

-- Q02: Highest protein foods
SELECT ndb_no, shrt_desc, protein_g, energ_kcal,
       ROUND(100.0*protein_g/NULLIF(energ_kcal,0),2) AS protein_per_100_kcal
FROM nutrition_foods
WHERE protein_g IS NOT NULL AND energ_kcal > 0
ORDER BY protein_g DESC
LIMIT 25;

-- Q03: High-protein, low-sugar foods
SELECT shrt_desc, protein_g, sugar_tot_g, fiber_td_g, energ_kcal
FROM nutrition_foods
WHERE protein_g >= 20 AND sugar_tot_g <= 5
ORDER BY protein_g DESC;

-- Q04: Fiber-rich foods
SELECT shrt_desc, fiber_td_g, energ_kcal, protein_g
FROM nutrition_foods
WHERE fiber_td_g IS NOT NULL
ORDER BY fiber_td_g DESC
LIMIT 25;

-- Q05: High-sodium foods
SELECT shrt_desc, sodium_mg, energ_kcal
FROM nutrition_foods
WHERE sodium_mg IS NOT NULL
ORDER BY sodium_mg DESC
LIMIT 25;

-- Q06: Macro profile
SELECT
  ROUND(AVG(protein_g),2) AS avg_protein_g,
  ROUND(AVG(lipid_tot_g),2) AS avg_fat_g,
  ROUND(AVG(carbohydrt_g),2) AS avg_carbs_g,
  ROUND(AVG(fiber_td_g),2) AS avg_fiber_g,
  ROUND(AVG(sugar_tot_g),2) AS avg_sugar_g
FROM nutrition_foods;

-- Q07: Nutrient completeness
SELECT
  ROUND(100.0*AVG(CASE WHEN protein_g IS NOT NULL THEN 1.0 ELSE 0 END),2) AS protein_complete_pct,
  ROUND(100.0*AVG(CASE WHEN sodium_mg IS NOT NULL THEN 1.0 ELSE 0 END),2) AS sodium_complete_pct,
  ROUND(100.0*AVG(CASE WHEN vit_c_mg IS NOT NULL THEN 1.0 ELSE 0 END),2) AS vit_c_mg_complete_pct
FROM nutrition_foods;
-- Note: column aliases may vary; use Python data dictionary for exact nutrient names if needed.

-- Q08: Energy vs protein relationship
SELECT
  ROUND(AVG(energ_kcal),2) AS avg_kcal,
  ROUND(AVG(protein_g),2) AS avg_protein
FROM nutrition_foods
WHERE energ_kcal IS NOT NULL AND protein_g IS NOT NULL;

-- Q09: Food weight conversion opportunities
SELECT shrt_desc, gmwt_1, gmwt_desc1, gmwt_2, gmwt_desc2
FROM nutrition_foods
WHERE gmwt_1 IS NOT NULL OR gmwt_2 IS NOT NULL
LIMIT 50;
