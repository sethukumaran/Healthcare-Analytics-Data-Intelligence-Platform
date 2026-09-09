-- 00_schema.sql
-- Reference DDL for the cleaned analytical model.
-- Data is loaded by src/data_pipeline.py.

-- drug_products
CREATE TABLE IF NOT EXISTS drug_products (
    "productid" TEXT,
    "productndc" TEXT,
    "producttypename" TEXT,
    "proprietaryname" TEXT,
    "proprietarynamesuffix" TEXT,
    "nonproprietaryname" TEXT,
    "dosageformname" TEXT,
    "routename" TEXT,
    "startmarketingdate" TEXT,
    "endmarketingdate" TEXT,
    "marketingcategoryname" TEXT,
    "applicationnumber" TEXT,
    "labelername" TEXT,
    "substancename" TEXT,
    "active_numerator_strength" REAL,
    "active_ingred_unit" TEXT,
    "pharm_classes" TEXT,
    "deaschedule" TEXT
);
 
-- drug_packages
CREATE TABLE IF NOT EXISTS drug_packages (
    "productid" TEXT,
    "productndc" TEXT,
    "ndcpackagecode" TEXT,
    "packagedescription" TEXT
);
 
-- unfinished_products
CREATE TABLE IF NOT EXISTS unfinished_products (
    "productid" TEXT,
    "productndc" TEXT,
    "producttypename" TEXT,
    "nonproprietaryname" TEXT,
    "dosageformname" TEXT,
    "startmarketingdate" TEXT,
    "endmarketingdate" TEXT,
    "marketingcategoryname" TEXT,
    "labelername" TEXT,
    "substancename" TEXT,
    "active_numerator_strength" REAL,
    "active_ingred_unit" TEXT,
    "deaschedule" TEXT
);
 
-- unfinished_packages
CREATE TABLE IF NOT EXISTS unfinished_packages (
    "productid" TEXT,
    "productndc" TEXT,
    "ndcpackagecode" TEXT,
    "packagedescription" TEXT
);
 
-- nutrition_foods
CREATE TABLE IF NOT EXISTS nutrition_foods (
    "ndb_no" INTEGER,
    "shrt_desc" TEXT,
    "water_g" REAL,
    "energ_kcal" INTEGER,
    "protein_g" REAL,
    "lipid_tot_g" REAL,
    "ash_g" REAL,
    "carbohydrt_g" REAL,
    "fiber_td_g" REAL,
    "sugar_tot_g" REAL,
    "calcium_mg" REAL,
    "iron_mg" REAL,
    "magnesium_mg" REAL,
    "phosphorus_mg" REAL,
    "potassium_mg" REAL,
    "sodium_mg" REAL,
    "zinc_mg" REAL,
    "copper_mg" REAL,
    "manganese_mg" REAL,
    "selenium_ugg" REAL,
    "vit_c_mg" REAL,
    "thiamin_mg" REAL,
    "riboflavin_mg" REAL,
    "niacin_mg" REAL,
    "panto_acid_mg" REAL,
    "vit_b6_mg" REAL,
    "folate_tot_ugg" REAL,
    "folic_acid_ugg" REAL,
    "food_folate_ugg" REAL,
    "folate_dfe_ugg" REAL,
    "choline_tot_mg" REAL,
    "vit_b12_ugg" REAL,
    "vit_a_iu" REAL,
    "vit_a_rae" REAL,
    "retinol_ugg" REAL,
    "alpha_carot_ugg" REAL,
    "beta_carot_ugg" REAL,
    "beta_crypt_ugg" REAL,
    "lycopene_ugg" REAL,
    "lut_plus_zea_ugg" REAL,
    "vit_e_mg" REAL,
    "vit_d_ugg" REAL,
    "vit_d_iu" REAL,
    "vit_k_ugg" REAL,
    "fa_sat_g" REAL,
    "fa_mono_g" REAL,
    "fa_poly_g" REAL,
    "cholestrl_mg" REAL,
    "gmwt_1" REAL,
    "gmwt_desc1" TEXT,
    "gmwt_2" REAL,
    "gmwt_desc2" TEXT
);
 
-- medicare_star_summary
CREATE TABLE IF NOT EXISTS medicare_star_summary (
    "contract_id" TEXT,
    "organization_type" TEXT,
    "organization_marketing_name" TEXT,
    "contract_name" TEXT,
    "parent_organization" TEXT,
    "snp" TEXT,
    "sanction_deduction" TEXT,
    "part_c_summary" TEXT,
    "part_d_summary" TEXT,
    "overall_star_rating" REAL
);
 
-- nhanes_dietary
CREATE TABLE IF NOT EXISTS nhanes_dietary (
    "seqn" REAL,
    "wtdrd1" REAL,
    "dr1tkcal" REAL,
    "dr1tprot" REAL,
    "dr1tcarb" REAL,
    "dr1tsugr" REAL,
    "dr1tfibe" REAL,
    "dr1ttfat" REAL,
    "dr1tsfat" REAL,
    "dr1tmfat" REAL,
    "dr1tpfat" REAL,
    "dr1tchol" REAL,
    "dr1tvc" REAL,
    "dr1tvk" REAL,
    "dr1tcalc" REAL,
    "dr1tphos" REAL,
    "dr1tmagn" REAL,
    "dr1tiron" REAL,
    "dr1tzinc" REAL,
    "dr1tsodi" REAL,
    "dr1tpota" REAL,
    "survey_cycle" TEXT
);
