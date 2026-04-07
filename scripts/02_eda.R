# ============================================================
# scripts/02_eda.R
# Load processed data, create EDA visualisations, save plots
# ============================================================

source("R/analysis_functions.R")
source("R/plot_functions.R")

cat("── Loading processed data...\n")
co2_tax_gdp <- readRDS("data/processed/co2_tax_gdp.rds")

cat("── Creating aggregated datasets...\n")
country_avg    <- create_country_avg(co2_tax_gdp)
top_countries  <- get_top_countries(co2_tax_gdp)

top_country_avg <- country_avg %>%
    filter(country %in% top_countries)

top_country_trends <- co2_tax_gdp %>%
    filter(year >= 2018 & year <= 2024,
           country %in% top_countries)

cat("── Generating EDA plots...\n")

# Plot 1 — CO₂ distribution
p1 <- plot_co2_distribution(country_avg)
save_plot(p1, "01_co2_distribution.png")

# Plot 2 — Top 20 global share
p2 <- plot_top20_share(country_avg, top_countries)
save_plot(p2, "02_top20_global_share.png")

# Plot 3 — Carbon tax donut
p3 <- plot_carbon_tax_donut(country_avg)
save_plot(p3, "03_carbon_tax_adoption.png", width = 6, height = 6)

# Plot 4 — GDP vs CO₂
p4 <- plot_gdp_vs_co2(country_avg, top_countries)
save_plot(p4, "04_gdp_vs_co2.png")

# Plot 5 — CO₂ by country coloured by tax
p5 <- plot_co2_by_country(country_avg, top_countries)
save_plot(p5, "05_co2_by_country.png")

# Plot 6 — Trend tax countries
p6 <- plot_trend_tax(top_country_trends)
save_plot(p6, "06_trend_tax_countries.png", width = 10)

# Plot 7 — Trend no tax countries
p7 <- plot_trend_notax(top_country_trends)
save_plot(p7, "07_trend_notax_countries.png", width = 10)

# Plot 8 — GDP vs CO₂ coloured by tax
p8 <- plot_gdp_co2_tax_color(country_avg, top_countries)
save_plot(p8, "08_gdp_co2_tax_color.png")

cat("✓ Done — all EDA plots saved to plots/\n")