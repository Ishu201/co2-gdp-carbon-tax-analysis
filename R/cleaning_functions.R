# ============================================================
# R/cleaning_functions.R
# Reusable cleaning functions for CO2 & Carbon Tax pipeline
# ============================================================
library(tidyverse)

clean_co2_data <- function(filepath) {
    read_csv(filepath, show_col_types = FALSE) %>%
        filter(!is.na(iso_code)) %>%
        filter(year >= 2000 & year <= 2024) %>%
        select(country, iso_code, year,
               gdp, population, co2,
               co2_per_capita, share_global_co2,
               primary_energy_consumption) %>%
        arrange(country, year) %>%
        group_by(country) %>%
        mutate(gdp = ifelse(is.na(gdp), mean(gdp, na.rm = TRUE), gdp),
               primary_energy_consumption = ifelse(
                   is.na(primary_energy_consumption),
                   mean(primary_energy_consumption, na.rm = TRUE),
                   primary_energy_consumption)) %>%
        ungroup() %>%
        { d <- .
        no_gdp <- d %>%
            group_by(country) %>%
            summarise(all_na = all(is.na(gdp))) %>%
            filter(all_na) %>%
            pull(country)
        d %>% filter(!country %in% no_gdp)
        } %>%
        mutate(gdp_per_capita = gdp / population)
}

clean_carbon_tax_data <- function(filepath) {
    read_csv(filepath, show_col_types = FALSE) %>%
        rename(
            country        = Entity,
            iso_code       = Code,
            year           = Year,
            has_carbon_tax = `Covered by tax instrument in at least one sector`
        ) %>%
        mutate(carbon_tax = ifelse(has_carbon_tax == "No carbon tax",
                                   FALSE, TRUE)) %>%
        select(country, iso_code, year, carbon_tax) %>%
        filter(year >= 2000 & year <= 2024)
}

join_datasets <- function(co2_data, tax_data) {
    co2_data %>%
        inner_join(tax_data %>% select(iso_code, year, carbon_tax),
                   by = c("iso_code", "year"))
}