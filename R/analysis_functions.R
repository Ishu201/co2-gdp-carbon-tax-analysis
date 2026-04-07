# ============================================================
# R/analysis_functions.R
# Reusable analysis functions for CO2 & Carbon Tax pipeline
# ============================================================
library(tidyverse)
library(broom)

# ── Create aggregated datasets ────────────────────────────────
create_country_avg <- function(data) {
    data %>%
        group_by(country) %>%
        summarise(
            avg_co2_per_capita = mean(co2_per_capita,  na.rm = TRUE),
            avg_gdp_per_capita = mean(gdp_per_capita,  na.rm = TRUE),
            avg_share_global   = mean(share_global_co2, na.rm = TRUE),
            avg_energy         = mean(primary_energy_consumption, na.rm = TRUE),
            has_carbon_tax     = as.logical(max(carbon_tax, na.rm = TRUE)),
            .groups = "drop"
        )
}

get_top_countries <- function(data, n = 20, year_min = 2018, year_max = 2024) {
    data %>%
        filter(between(year, year_min, year_max)) %>%
        group_by(country) %>%
        summarise(avg_share = mean(share_global_co2, na.rm = TRUE),
                  .groups = "drop") %>%
        arrange(desc(avg_share)) %>%
        slice_head(n = n) %>%
        pull(country)
}

# ── Correlation analysis ──────────────────────────────────────
run_correlations <- function(country_avg) {
    cor_gdp <- cor.test(country_avg$avg_gdp_per_capita,
                        country_avg$avg_co2_per_capita,
                        method = "pearson")
    
    cor_tax <- cor.test(as.numeric(country_avg$has_carbon_tax),
                        country_avg$avg_co2_per_capita,
                        method = "pearson")
    
    list(
        gdp_vs_co2 = tidy(cor_gdp),
        tax_vs_co2 = tidy(cor_tax)
    )
}

# ── Regression models ─────────────────────────────────────────
run_regression_models <- function(country_avg) {
    m1 <- lm(avg_co2_per_capita ~ avg_gdp_per_capita,
             data = country_avg)
    
    m2 <- lm(avg_co2_per_capita ~ has_carbon_tax,
             data = country_avg)
    
    m3 <- lm(avg_co2_per_capita ~ avg_gdp_per_capita + has_carbon_tax,
             data = country_avg)
    
    list(
        m1_gdp_only    = m1,
        m2_tax_only    = m2,
        m3_gdp_and_tax = m3
    )
}

# ── Model summary helper ──────────────────────────────────────
summarise_models <- function(models) {
    list(
        tidy_m1   = tidy(models$m1_gdp_only),
        tidy_m2   = tidy(models$m2_tax_only),
        tidy_m3   = tidy(models$m3_gdp_and_tax),
        glance_m1 = glance(models$m1_gdp_only),
        glance_m3 = glance(models$m3_gdp_and_tax)
    )
}