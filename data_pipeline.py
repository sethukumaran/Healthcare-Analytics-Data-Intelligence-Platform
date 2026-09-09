"""
Healthcare Analytics Portfolio - Data Engineering / Cleaning Pipeline

Input: data/raw/archive.zip
Output: data/processed/*.csv and healthcare_analytics.db
"""

from pathlib import Path
import zipfile
import re
import sqlite3
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RAW_ZIP = ROOT / "data" / "raw" / "archive.zip"
RAW_DIR = ROOT / "data" / "raw" / "extracted"
PROCESSED_DIR = ROOT / "data" / "processed"
DB_PATH = ROOT / "healthcare_analytics.db"

def snake(name: str) -> str:
    name = str(name).strip().lower()
    return re.sub(r"[^a-z0-9]+", "_", name).strip("_")

def read_csv(path: Path, **kwargs) -> pd.DataFrame:
    # The supplied archive contains legacy characters; latin1 gives a lossless
    # byte-to-character mapping for this dataset.
    return pd.read_csv(path, encoding="latin1", low_memory=False, **kwargs)

def extract_archive():
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(RAW_ZIP) as z:
        z.extractall(RAW_DIR)

def clean_drug_tables():
    names = {
        "Drugs_product.csv": "drug_products",
        "Drugs_package.csv": "drug_packages",
        "Drugs_unfinished_products.csv": "unfinished_products",
        "Drugs_unfinished_package.csv": "unfinished_packages",
    }
    result = {}
    for filename, table in names.items():
        df = read_csv(RAW_DIR / filename)
        df.columns = [snake(c) for c in df.columns]

        if table in {"drug_products", "unfinished_products"}:
            for c in ["startmarketingdate", "endmarketingdate"]:
                df[c] = pd.to_datetime(df[c], errors="coerce").dt.date.astype("string")
            df["active_numerator_strength"] = pd.to_numeric(
                df["active_numerator_strength"], errors="coerce"
            )
        result[table] = df
    return result

def clean_nutrition():
    df = read_csv(RAW_DIR / "Nutritions_US.csv")
    df.columns = [
        snake(str(c).replace("¾", "ug").replace("½", "").replace("+", "_plus_"))
        for c in df.columns
    ]
    for c in df.columns:
        if c not in {"ndb_no", "shrt_desc", "gmwt_desc1", "gmwt_desc2"}:
            df[c] = pd.to_numeric(df[c], errors="coerce")
    return df

def clean_medicare_summary():
    raw = read_csv(RAW_DIR / "Star_rating_fall_summary.csv", header=None)
    columns = [
        str(x).strip() if pd.notna(x) else f"extra_{i}"
        for i, x in enumerate(raw.iloc[1])
    ]
    df = raw.iloc[2:].copy()
    df.columns = columns
    df = df.iloc[:, :10]
    df.columns = [
        "contract_id", "organization_type", "organization_marketing_name",
        "contract_name", "parent_organization", "snp", "sanction_deduction",
        "part_c_summary", "part_d_summary", "overall_star_rating"
    ]
    text_cols = df.columns[:9]
    for c in text_cols:
        df[c] = df[c].astype("string").str.strip()
    df["overall_star_rating"] = pd.to_numeric(
        df["overall_star_rating"], errors="coerce"
    )
    df = df[df["contract_id"].notna()].copy()
    df["overall_star_rating"] = df["overall_star_rating"].clip(0, 5)
    return df

def clean_nhanes():
    common = [
        "seqn", "wtdrd1", "dr1tkcal", "dr1tprot", "dr1tcarb", "dr1tsugr",
        "dr1tfibe", "dr1ttfat", "dr1tsfat", "dr1tmfat", "dr1tpfat",
        "dr1tchol", "dr1tvc", "dr1tvk", "dr1tcalc", "dr1tphos",
        "dr1tmagn", "dr1tiron", "dr1tzinc", "dr1tsodi", "dr1tpota"
    ]
    frames = []
    for cycle in ["2005_2006", "2007_2008", "2009_2010", "2011_2012", "2013_2014"]:
        df = read_csv(RAW_DIR / f"Nhanes_{cycle}.csv")
        mapping = {c.lower(): c for c in df.columns}
        selected = [mapping[c] for c in common if c in mapping]
        x = df[selected].copy()
        x.columns = [c.lower() for c in x.columns]
        x["survey_cycle"] = cycle
        for c in x.columns:
            if c not in {"seqn", "survey_cycle"}:
                x[c] = pd.to_numeric(x[c], errors="coerce")
        frames.append(x)
    return pd.concat(frames, ignore_index=True)

def save_and_load(tables):
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    if DB_PATH.exists():
        DB_PATH.unlink()
    conn = sqlite3.connect(DB_PATH)

    for name, df in tables.items():
        df.to_csv(PROCESSED_DIR / f"{name}.csv", index=False)
        df.to_sql(name, conn, index=False, if_exists="replace")

    index_sql = [
        "CREATE INDEX idx_drug_product_ndc ON drug_products(productndc)",
        "CREATE INDEX idx_drug_product_labeler ON drug_products(labelername)",
        "CREATE INDEX idx_drug_package_product ON drug_packages(productid)",
        "CREATE INDEX idx_med_contract ON medicare_star_summary(contract_id)",
        "CREATE INDEX idx_nhanes_cycle ON nhanes_dietary(survey_cycle)",
        "CREATE INDEX idx_nutrition_kcal ON nutrition_foods(energ_kcal)",
    ]
    for sql in index_sql:
        conn.execute(sql)
    conn.commit()
    conn.close()

def main():
    extract_archive()
    tables = {}
    tables.update(clean_drug_tables())
    tables["nutrition_foods"] = clean_nutrition()
    tables["medicare_star_summary"] = clean_medicare_summary()
    tables["nhanes_dietary"] = clean_nhanes()
    save_and_load(tables)
    print("Pipeline complete.")
    for name, df in tables.items():
        print(f"{name:28s} {df.shape[0]:>8,} rows x {df.shape[1]:>3} cols")

if __name__ == "__main__":
    main()
