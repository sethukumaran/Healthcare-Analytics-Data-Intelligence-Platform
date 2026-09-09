"""
Healthcare Analytics Portfolio - Python Analytics

Generates:
- data quality report
- executive KPI tables
- manufacturer / drug analytics
- Medicare star-rating analytics
- NHANES dietary trend analytics
- nutrition screening
- publication-ready PNG figures

Run from repository root:
    python src/analysis.py
"""

from pathlib import Path
import sqlite3
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / "healthcare_analytics.db"
OUT = ROOT / "outputs"
FIG = OUT / "figures"
TAB = OUT / "tables"
FIG.mkdir(parents=True, exist_ok=True)
TAB.mkdir(parents=True, exist_ok=True)

def q(sql):
    with sqlite3.connect(DB) as conn:
        return pd.read_sql_query(sql, conn)

def save(df, name):
    df.to_csv(TAB / f"{name}.csv", index=False)
    return df

def data_quality():
    tables = [
        "drug_products", "drug_packages", "unfinished_products",
        "unfinished_packages", "nutrition_foods",
        "medicare_star_summary", "nhanes_dietary"
    ]
    rows = []
    with sqlite3.connect(DB) as conn:
        for table in tables:
            df = pd.read_sql_query(f"SELECT * FROM {table} LIMIT 0", conn)
            total = pd.read_sql_query(f"SELECT COUNT(*) n FROM {table}", conn).iloc[0,0]
            rows.append({"table": table, "rows": total, "columns": len(df.columns)})
    return save(pd.DataFrame(rows), "data_quality_summary")

def drug_analysis():
    manufacturer = q("""
        SELECT labelername, COUNT(*) product_count
        FROM drug_products
        WHERE labelername IS NOT NULL
        GROUP BY labelername
        ORDER BY product_count DESC
        LIMIT 15
    """)
    save(manufacturer, "top_15_drug_manufacturers")

    dosage = q("""
        SELECT dosageformname, COUNT(*) product_count
        FROM drug_products
        WHERE dosageformname IS NOT NULL
        GROUP BY dosageformname
        ORDER BY product_count DESC
        LIMIT 15
    """)
    save(dosage, "top_15_dosage_forms")

    plt.figure(figsize=(10,6))
    manufacturer.sort_values("product_count").plot(
        x="labelername", y="product_count", kind="barh", legend=False
    )
    plt.title("Top Drug Manufacturers by Number of Listed Products")
    plt.xlabel("Product count")
    plt.ylabel("Labeler")
    plt.tight_layout()
    plt.savefig(FIG / "top_drug_manufacturers.png", dpi=180)
    plt.close()

    return manufacturer, dosage

def medicare_analysis():
    rating = q("""
        SELECT overall_star_rating, COUNT(*) contracts
        FROM medicare_star_summary
        WHERE overall_star_rating IS NOT NULL
        GROUP BY overall_star_rating
        ORDER BY overall_star_rating
    """)
    save(rating, "medicare_star_distribution")

    org = q("""
        SELECT organization_type, COUNT(*) contracts,
               ROUND(AVG(overall_star_rating),2) avg_rating
        FROM medicare_star_summary
        WHERE overall_star_rating IS NOT NULL
        GROUP BY organization_type
        HAVING COUNT(*) >= 3
        ORDER BY avg_rating DESC
    """)
    save(org, "medicare_organization_performance")

    plt.figure(figsize=(9,5))
    plt.bar(rating["overall_star_rating"].astype(str), rating["contracts"])
    plt.title("Medicare Overall Star-Rating Distribution")
    plt.xlabel("Overall star rating")
    plt.ylabel("Number of contracts")
    plt.tight_layout()
    plt.savefig(FIG / "medicare_star_distribution.png", dpi=180)
    plt.close()

    return rating, org

def nhanes_analysis():
    trend = q("""
        SELECT survey_cycle,
               AVG(dr1tkcal) avg_kcal,
               AVG(dr1tprot) avg_protein_g,
               AVG(dr1tcarb) avg_carb_g,
               AVG(dr1ttfat) avg_fat_g,
               AVG(dr1tsugr) avg_sugar_g,
               AVG(dr1tfibe) avg_fiber_g,
               AVG(dr1tsodi) avg_sodium_mg
        FROM nhanes_dietary
        GROUP BY survey_cycle
        ORDER BY survey_cycle
    """)
    save(trend, "nhanes_dietary_trends")

    plt.figure(figsize=(10,5))
    plt.plot(trend["survey_cycle"], trend["avg_sodium_mg"], marker="o")
    plt.title("Average Daily Sodium Intake by NHANES Survey Cycle")
    plt.xlabel("Survey cycle")
    plt.ylabel("Average sodium (mg)")
    plt.xticks(rotation=25)
    plt.tight_layout()
    plt.savefig(FIG / "nhanes_sodium_trend.png", dpi=180)
    plt.close()

    return trend

def nutrition_analysis():
    high_protein = q("""
        SELECT shrt_desc, energ_kcal, protein_g, fiber_td_g, sugar_tot_g
        FROM nutrition_foods
        WHERE protein_g >= 20 AND sugar_tot_g <= 5
        ORDER BY protein_g DESC
        LIMIT 50
    """)
    save(high_protein, "high_protein_low_sugar_foods")

    macro = q("""
        SELECT AVG(energ_kcal) avg_kcal,
               AVG(protein_g) avg_protein_g,
               AVG(lipid_tot_g) avg_fat_g,
               AVG(carbohydrt_g) avg_carb_g,
               AVG(fiber_td_g) avg_fiber_g,
               AVG(sugar_tot_g) avg_sugar_g
        FROM nutrition_foods
    """)
    save(macro, "nutrition_macro_summary")
    return high_protein, macro

def executive_kpis():
    kpi = q("""
        SELECT
          (SELECT COUNT(*) FROM drug_products) AS finished_drug_products,
          (SELECT COUNT(*) FROM drug_packages) AS drug_packages,
          (SELECT COUNT(*) FROM unfinished_products) AS unfinished_products,
          (SELECT COUNT(*) FROM nutrition_foods) AS nutrition_items,
          (SELECT COUNT(*) FROM medicare_star_summary) AS medicare_contracts,
          (SELECT COUNT(*) FROM nhanes_dietary) AS nhanes_records,
          (SELECT ROUND(AVG(overall_star_rating),2)
             FROM medicare_star_summary
             WHERE overall_star_rating IS NOT NULL) AS avg_medicare_star_rating
    """)
    return save(kpi, "executive_kpis")

def main():
    data_quality()
    drug_analysis()
    medicare_analysis()
    nhanes_analysis()
    nutrition_analysis()
    executive_kpis()
    print(f"Analysis complete. Outputs saved under {OUT}")

if __name__ == "__main__":
    main()
