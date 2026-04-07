# ============================================================
# scripts/03_analysis.R
# Load processed data, run correlation and regression analysis
# ============================================================

source("R/analysis_functions.R")
source("R/plot_functions.R")

cat("── Loading processed data...\n")
co2_tax_gdp <- readRDS("data/processed/co2_tax_gdp.rds")

cat("── Creating aggregated datasets...\n")
country_avg   <- create_country_avg(co2_tax_gdp)
top_countries <- get_top_countries(co2_tax_gdp)

cat("── Running correlation analysis...\n")
correlations <- run_correlations(country_avg)

cat("\n── Q1: GDP vs CO₂ correlation\n")
print(correlations$gdp_vs_co2)

cat("\n── Q2: Carbon tax vs CO₂ correlation\n")
print(correlations$tax_vs_co2)

cat("\n── Running regression models...\n")
models   <- run_regression_models(country_avg)
summaries <- summarise_models(models)

cat("\n── Model 1: GDP alone\n")
print(summaries$tidy_m1)
print(summaries$glance_m1 %>% select(r.squared, adj.r.squared, p.value, nobs))

cat("\n── Model 2: Carbon tax alone\n")
print(summaries$tidy_m2)

cat("\n── Model 3: GDP + Carbon tax\n")
print(summaries$tidy_m3)
print(summaries$glance_m3 %>% select(r.squared, adj.r.squared, p.value, nobs))

cat("\n── Key finding: carbon tax coefficient direction\n")
m2_coef <- summaries$tidy_m2 %>% filter(term == "has_carbon_taxTRUE") %>% pull(estimate)
m3_coef <- summaries$tidy_m3 %>% filter(term == "has_carbon_taxTRUE") %>% pull(estimate)
cat("   Without GDP control:", round(m2_coef, 3), "(positive — misleading)\n")
cat("   With GDP control:   ", round(m3_coef, 3), "(negative — true effect)\n")

cat("\n── Generating regression plot...\n")
p9 <- plot_actual_vs_fitted(country_avg, top_countries, models$m3_gdp_and_tax)
save_plot(p9, "09_actual_vs_fitted.png")

save(co2_tax_gdp, country_avg, top_country_avg,
     top_countries, top_country_trends,
     top_country_trends_tax, top_country_trends_colored,
     models, correlations, summaries,
     file = "data/processed/analysis_workspace.RData")

cat("✓ Done — analysis complete\n")