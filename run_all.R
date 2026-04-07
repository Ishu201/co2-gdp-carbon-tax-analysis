# ============================================================
# run_all.R
# Master pipeline — runs all scripts in order
# ============================================================

start_time <- Sys.time()

# Step 1: Load and clean data ===================================
source("scripts/01_load_clean.R")

# Step 2: EDA visualisations ====================================
source("scripts/02_eda.R")

# Step 3: Correlation & Regression ===============================
source("scripts/03_analysis.R")

# Done
end_time <- Sys.time()
duration <- round(difftime(end_time, start_time, units = "secs"), 1)
cat(sprintf("Pipeline complete in %s seconds\n", duration))


# Run the Dashboard
shiny::runApp("app")

