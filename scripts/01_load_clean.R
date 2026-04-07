# ============================================================
# scripts/01_load_clean.R
# Load raw data, clean, join and save to processed/
# ============================================================

source("R/cleaning_functions.R")

cat("── Loading raw data...\n")
co2_raw <- read_csv("data/raw/co2-emission.csv", show_col_types = FALSE)
tax_raw <- read_csv("data/raw/carbon-tax-data.csv", show_col_types = FALSE)

cat("── Cleaning CO₂ data...\n")
co2_clean <- clean_co2_data("data/raw/co2-emission.csv")

cat("── Cleaning carbon tax data...\n")
tax_clean <- clean_carbon_tax_data("data/raw/carbon-tax-data.csv")

cat("── Joining datasets...\n")
co2_tax_gdp <- join_datasets(co2_clean, tax_clean)

cat("── Verifying joined data...\n")
cat("   Rows:", nrow(co2_tax_gdp), "\n")
cat("   Countries:", n_distinct(co2_tax_gdp$country), "\n")
cat("   Year range:", paste(range(co2_tax_gdp$year), collapse = " - "), "\n")
cat("   Missing values:\n")
print(colSums(is.na(co2_tax_gdp)))

cat("── Saving to data/processed/...\n")
saveRDS(co2_tax_gdp, "data/processed/co2_tax_gdp.rds")

cat("✓ Done — co2_tax_gdp.rds saved\n")
