# ============================================================
# CASE STUDY: GDP, Carbon Tax & CO₂ Emissions
# Data Sources: Our World in Data | World Bank Carbon Pricing
# ============================================================

# ── 1. LIBRARIES ─────────────────────────────────────────────
library(tidyverse)
library(ggplot2)
library(readr)
library(ggrepel)
library(broom)


# ── 2. LOAD DATA ─────────────────────────────────────────────

# Load the co2 dataset
co2EmissionData <- read_csv("data/raw/co2-emission.csv")

# Load the carbon tax dataset
carbonTaxData <- read_csv("data/raw/carbon-tax-data.csv")


# ── 3. INITIAL EXPLORATION ───────────────────────────────────

# Initial exploration of the co2 dataset
dim(co2EmissionData)
names(co2EmissionData)
glimpse(co2EmissionData)
summary(co2EmissionData)
View(co2EmissionData)

# Initial exploration of the carbon tax dataset
dim(carbonTaxData)
names(carbonTaxData)
glimpse(carbonTaxData)
summary(carbonTaxData)
View(carbonTaxData)



# ── 4. CLEAN CARBON TAX DATA ─────────────────────────────────

# Rename columns for consistency
carbonTaxData <- carbonTaxData %>%
    rename(
        country        = Entity,
        iso_code       = Code,
        year           = Year,
        has_carbon_tax = `Covered by tax instrument in at least one sector`
    )

# Check unique values before creating binary
unique(carbonTaxData$has_carbon_tax)

# Convert to TRUE/FALSE binary variable
carbonTaxData <- carbonTaxData %>%
    mutate(carbon_tax = ifelse(has_carbon_tax == "No carbon tax", FALSE, TRUE)) %>%
    select(country, iso_code, year, carbon_tax)  # drop original text column


# ── 5. FILTER YEAR RANGE ─────────────────────────────────────

# Filter the co2 dataset for the years 2020-2024
co2EmissionData <- co2EmissionData %>%
    filter(year >= 2000 & year <= 2024)


# ── 6. CLEAN CO₂ DATA ────────────────────────────────────────

# Check for missing values in the co2 dataset
colSums(is.na(co2EmissionData))

# Remove continental/global aggregates (rows without iso_code)
co2EmissionData %>%
    select(country, iso_code) %>%
    View()

co2EmissionData <- co2EmissionData %>%
    filter(!is.na(iso_code))

# Select only relevant columns for analysis
co2EmissionDataCleaned <- co2EmissionData %>%
    select(country, iso_code, year,
           gdp,population,co2,co2_per_capita,share_global_co2,primary_energy_consumption)



# ── 7. HANDLE MISSING DATA ────────────────────────────────────

# Check for missing values in the co2 cleaned dataset
colSums(is.na(co2EmissionDataCleaned))

# Check which countries are missing GDP
co2EmissionDataCleaned %>%
    filter(is.na(gdp)) %>%
    select(country, year) %>%
    distinct(country)

# For countries with SOME GDP data - impute using that country's mean
co2EmissionDataCleaned <- co2EmissionDataCleaned %>%
    arrange(country, year) %>%
    group_by(country) %>%
    mutate(gdp = ifelse(is.na(gdp), 
                        mean(gdp, na.rm = TRUE),  # country's own average
                        gdp)) %>%
    ungroup()

# Identify countries with NO GDP data at all (imputation failed)
co2EmissionDataCleaned %>%
    filter(is.na(gdp)) %>%
    distinct(country)

no_gdp_countries <- co2EmissionDataCleaned %>%
    group_by(country) %>%
    summarise(all_na = all(is.na(gdp))) %>%
    filter(all_na) %>%
    pull(country)

# Confirm their co2 emitting level before dropping
co2EmissionDataCleaned %>%
    filter(country %in% no_gdp_countries) %>%
    group_by(country) %>%
    summarise(avg_co2 = mean(co2, na.rm = TRUE)) %>%
    arrange(desc(avg_co2)) %>%
    head(10)

# Drop countries with no GDP data
co2EmissionDataCleaned <- co2EmissionDataCleaned %>%
    filter(!country %in% no_gdp_countries)

# Check for missing values in the co2 cleaned dataset
colSums(is.na(co2EmissionDataCleaned))

# Impute primary_energy_consumption with country mean (since it's not a key variable for our analysis)
co2EmissionDataCleaned <- co2EmissionDataCleaned %>%
    arrange(country, year) %>%
    group_by(country) %>%
    mutate(primary_energy_consumption = ifelse(is.na(primary_energy_consumption),
                                               mean(primary_energy_consumption, na.rm = TRUE),
                                               primary_energy_consumption)) %>%
    ungroup()


# ── 8. ENGINEER FEATURES ─────────────────────────────────────

# Calculate GDP per capita (main variable for Q1)
co2EmissionDataCleaned <- co2EmissionDataCleaned %>%
    mutate(gdp_per_capita = gdp / population)



# ── 9. VERIFY CLEANED DATASET ────────────────────────────────

dim(co2EmissionDataCleaned)
names(co2EmissionDataCleaned)
glimpse(co2EmissionDataCleaned)
summary(co2EmissionDataCleaned)
View(co2EmissionDataCleaned)



# ── 10. JOIN DATASETS ─────────────────────────────────────────

# Filter carbon tax to same year range first
carbonTaxData <- carbonTaxData %>%
    filter(year >= 2000 & year <= 2024)

# Join on iso_code + year
co2_tax_gdp  <- co2EmissionDataCleaned %>%
    inner_join(carbonTaxData %>% select(iso_code, year, carbon_tax),
               by = c("iso_code", "year"))

# Verify join result
dim(co2_tax_gdp)
glimpse(co2_tax_gdp)

# Check no countries were lost unexpectedly
n_distinct(co2_tax_gdp$country)


# =========================================================================
# Visualization
# =========================================================================
# Create a directory for plots if it doesn't exist
if (!dir.exists("plots")) dir.create("plots")

## Create Relevent Datasets for Visualization
top_countries <- co2_tax_gdp %>%
    filter(year >= 2020 & year <= 2024) %>%        # last 5 years
    group_by(country) %>%
    summarise(avg_share = mean(share_global_co2, na.rm = TRUE)) %>%
    arrange(desc(avg_share)) %>%
    slice_head(n = 20) %>%
    pull(country)


country_avg <- co2_tax_gdp %>%
    group_by(country) %>%
    summarise(
        avg_co2_per_capita = mean(co2_per_capita,  na.rm = TRUE),
        avg_population      = mean(population,  na.rm = TRUE),
        avg_gdp_per_capita = mean(gdp_per_capita,  na.rm = TRUE),
        avg_share_global   = mean(share_global_co2, na.rm = TRUE),
        avg_energy         = mean(primary_energy_consumption, na.rm = TRUE),
        has_carbon_tax     = max(carbon_tax, na.rm = TRUE),  # ever had tax?
        .groups = "drop"
    )

top_country_trends <- co2_tax_gdp %>%
    filter((year >= 2020 & year <= 2024) & country %in% top_countries)

top_country_avg <- country_avg %>%
    filter(country %in% top_countries)


## Distribution of co2_per_capita across all countries - Histogram
p1 <- ggplot(country_avg, aes(x = avg_co2_per_capita)) +
    geom_histogram(binwidth = 1, fill = "#00b4d8", color = "black") +
    labs(title = "Distribution of Average CO2 Emissions per Capita",
         x = "Average CO₂ Emissions per Capita (tonnes)",
         y = "Number of Countries") +
    theme_minimal()
print(p1)
ggsave("plots/01_co2_distribution.png", plot = p1, width = 8, height = 5, dpi = 300)

## Top 20 countries by share_global_co2 - Bar Chart
top_countries_data <- country_avg %>%
    filter(country %in% top_countries) %>%
    arrange(avg_share_global)

p2 <- ggplot(
    top_countries_data %>%
        arrange(desc(avg_share_global)) %>%
        mutate(top5 = row_number() <= 5),
    
    aes(x = reorder(country, avg_share_global), 
        y = avg_share_global,
        fill = top5)
) +
    geom_bar(stat = "identity") +
    coord_flip() +
    
    scale_fill_manual(values = c("TRUE" = "#00b4d8", "FALSE" = "#caf0f8"),
                      guide = "none") +
    
    labs(title = "Top 20 Countries by Average Share of Global CO2 Emissions (2020–2024)",
         x = "Country",
         y = "Average Share of Global CO2 Emissions (%)") +
    
    theme_minimal()
print(p2)
ggsave("plots/02_top20_global_share.png", plot = p2, width = 8, height = 5, dpi = 300)

## Carbon tax presence across countries - Pie Chart
carbon_tax_distribution <- country_avg %>%
    group_by(has_carbon_tax) %>%
    summarise(count = n()) %>%
    mutate(
        percentage = count / sum(count) * 100,
        has_carbon_tax = factor(has_carbon_tax,
                                levels = c(0, 1),
                                labels = c("No Carbon Tax", "Has Carbon Tax")),
        label = paste0(has_carbon_tax, "\n", round(percentage, 1), "%")
    )

p3 <- ggplot(carbon_tax_distribution, 
       aes(x = 2, y = percentage, fill = has_carbon_tax)) +
    geom_bar(stat = "identity", width = 1, color = "white") +
    coord_polar(theta = "y") +
    
    # Donut shape
    xlim(0.5, 2.5) +
    geom_text(aes(label = label),
              position = position_stack(vjust = 0.5),
              color = "black",
              size = 3,
              fontface = "bold") +
    labs(title = "Carbon Tax Adoption Across Countries") +
    theme_void() +
    
    # Remove legend
    theme(
        legend.position = "none",
        plot.title = element_text(
            hjust = 0.5,
            face = "bold",
            size = 14
        )) +

    scale_fill_manual(values = c(
        "Has Carbon Tax" = "#00b4d8",
        "No Carbon Tax"  = "#caf0f8"
    ))
print(p3)
ggsave("plots/03_carbon_tax_distribution.png", plot = p3, width = 6, height = 6, dpi = 300)

 ## QUESTION 1 Visualizations --------------------------------------------

## gdp_per_capita vs co2_per_capita in top emmission countries - Scatterplot with regression line
p4 <- ggplot(
    country_avg %>% filter(country %in% top_countries),
    aes(
        x = avg_gdp_per_capita, 
        y = avg_co2_per_capita,
        color = country %in% (
            country_avg %>%
                filter(country %in% top_countries) %>%
                arrange(desc(avg_co2_per_capita)) %>%
                slice(c(1:5, (n()-4):n())) %>%
                pull(country)
        )
    )
) +
    
    geom_point(size = 2.5, alpha = 0.8) +
    
    scale_color_manual(values = c("TRUE" = "#00b4d8", "FALSE" = "grey70"),
                       guide = "none") +
    
    ggrepel::geom_text_repel(
        data = country_avg %>%
            filter(country %in% top_countries) %>%
            arrange(desc(avg_co2_per_capita)) %>%
            slice(c(1:5, (n()-4):n())),
        aes(label = country),
        size = 2.8,
        color = "#00b4d8"
    ) +
    
    geom_smooth(method = "lm", se = FALSE, color = "black", linewidth = 0.55) +
    
    labs(
        title = "GDP per Capita vs CO2 Emissions per Capita (Top Emitters)",
        x = "Average GDP per Capita (USD)",
        y = "Average CO2 Emissions per Capita (tonnes)"
    ) +
    
    theme_minimal()

print(p4)

ggsave("plots/04_gdp_vs_co2.png", plot = p4, width = 8, height = 5, dpi = 300)


## QUESTION 2 Visualizations --------------------------------------------
country_avg <- country_avg %>%
    mutate(has_carbon_tax = as.logical(has_carbon_tax))

## co2_per_capita by country coloured by has_carbon_tax - Bar Chart
p5 <- ggplot(
    country_avg %>% filter(country %in% top_countries) %>% arrange(avg_co2_per_capita),
    aes(x = reorder(country, avg_co2_per_capita), y = avg_co2_per_capita, fill = has_carbon_tax)
) +
    geom_bar(stat = "identity") +
    coord_flip() +
    scale_fill_manual(values = c("TRUE" = "#00b4d8", "FALSE" = "#caf0f8"), guide = "none") +
    labs(
        title = "Average CO2 Emissions per Capita in Top 20 Emitters (2020–2024)",
        x = "Country",
        y = "Average CO2 Emissions per Capita (tonnes)"
    ) +
    theme_minimal()
print(p5)
ggsave("plots/05_co2_by_carbon_tax.png", plot = p5, width = 8, height = 5, dpi = 300)


## CO₂ trend over time on Carbon taxed Countries - Line Chart facet by top 20 emitters
top_country_trends_tax <- top_country_trends %>%
    filter(carbon_tax == TRUE) %>%
    group_by(country) %>%
    summarise(
        slope = coef(lm(co2_per_capita ~ year))[2],
        .groups = "drop"
    ) %>%
    mutate(trend_dir = ifelse(slope > 0, "Increasing", "Decreasing")) %>%
    left_join(top_country_trends %>% filter(carbon_tax == TRUE), by = "country")

p6 <- ggplot(
    top_country_trends_tax,
    aes(x = year, y = co2_per_capita, color = trend_dir)
) +
    geom_line(linewidth = 0.8) +
    geom_point(size = 1.5) +
    facet_wrap(~ country, scales = "free_y") +
    scale_color_manual(values = c("Increasing" = "#caf0f8", "Decreasing" = "#00b4d8")) +
    labs(
        title = "CO2 per Capita Trend (Countries with Carbon Tax)",
        subtitle = "Color indicates overall trend direction",
        x     = "Year",
        y     = "CO2 per Capita (tonnes)",
        color = "Trend Direction"
    ) +
    theme_minimal() +
    theme(
        strip.text  = element_text(face = "bold", size = 8),
        axis.text.x = element_text(angle = 45, hjust = 1, size = 7),
        legend.position = "bottom",
    )
print(p6)
ggsave("plots/06_co2_trend_tax.png", plot = p6, width = 10, height = 6, dpi = 300)


## CO2 trend over time on no carbon taxed countries
top_country_trends_colored <- top_country_trends %>%
    filter(carbon_tax == FALSE) %>%
    group_by(country) %>%
    summarise(
        slope = coef(lm(co2_per_capita ~ year))[2],  # linear slope
        .groups = "drop"
    ) %>%
    mutate(trend_dir = ifelse(slope > 0, "Increasing", "Decreasing")) %>%
    left_join(top_country_trends, by = "country")


p7 <- ggplot(
    top_country_trends_colored,
    aes(x = year, y = co2_per_capita, color = trend_dir)
) +
    geom_line(linewidth = 0.8) +
    geom_point(size = 1.5) +
    facet_wrap(~ country, scales = "free_y") +
    scale_color_manual(values = c("Increasing" = "#00b4d8", "Decreasing" = "#caf0f8")) +
    labs(
        title = "CO2 per Capita Trend (Countries without Carbon Tax)",
        subtitle = "Color indicates overall trend direction",
        x     = "Year",
        y     = "CO2 per Capita (tonnes)",
        color = "Trend Direction"
    ) +
    theme_minimal() +
    theme(
        strip.text  = element_text(face = "bold", size = 8),
        axis.text.x = element_text(angle = 45, hjust = 1, size = 7),
        legend.position = "bottom",
    )
print(p7)
ggsave("plots/07_co2_trend_no_tax.png", plot = p7, width = 10, height = 6, dpi = 300)

## gdp_per_capita vs co2_per_capita in top emmission countries - Scatterplot colored by carbon tax presence
p8 <- ggplot(
    country_avg %>% filter(country %in% top_countries),
    aes(x = avg_gdp_per_capita, y = avg_co2_per_capita, color = has_carbon_tax)
) +
    geom_point(size = 2.5, alpha = 0.8) +
    ggrepel::geom_text_repel(aes(label = country), size = 2.8) +
    scale_color_manual(
        values = c("TRUE" = "#00b4d8", "FALSE" = "gray50"),
        labels = c("TRUE" = "Has Carbon Tax", "FALSE" = "No Carbon Tax"),
        name = "Carbon Tax Status"
    ) +
    labs(
        title = "GDP per Capita vs CO2 Emissions per Capita (Top Emitters)",
        x = "Average GDP per Capita (USD)",
        y = "Average CO2 Emissions per Capita (tonnes)"
    ) +
    theme_minimal(base_size = 12) +
    theme(
        plot.title = element_text(face = "bold", hjust = 0.5),
        legend.position = "bottom"
    )
print(p8)
ggsave("plots/08_gdp_vs_co2_colored.png", plot = p8, width = 8, height = 5, dpi = 300)


## ==========================================================================
## Correlation Analysis
## ==========================================================================

# Q1: correlation between GDP per capita and CO2 per capita
cor_res_1 <- cor.test(country_avg$avg_gdp_per_capita, 
                    country_avg$avg_co2_per_capita, 
                    method = "pearson")

# Convert to tidy table
tidy_cor_1 <- tidy(cor_res_1)


# Q2: Correlation between carbon tax presence and CO₂ per capita
cor_res_2 <- cor.test(as.numeric(country_avg$has_carbon_tax), 
                    country_avg$avg_co2_per_capita, 
                    method = "pearson")

# Convert to tidy table
tidy_cor_2 <- tidy(cor_res_2)



## ===========================================================================
## Regression Analysis
## ===========================================================================

# Model1: Linear regression of CO₂ per capita on GDP per capita
lm_q1 <- lm(avg_co2_per_capita ~ avg_gdp_per_capita, data = country_avg)
tidy_lm_q1 <- tidy(lm_q1)

# Model2: Linear regression of CO₂ per capita on carbon tax presence
lm_q2 <- lm(avg_co2_per_capita ~ has_carbon_tax, data = country_avg)
tidy_lm_q2 <- tidy(lm_q2)

# Model3: Multiple regression of CO₂ per capita on GDP per capita and carbon tax presence
lm_q3 <- lm(avg_co2_per_capita ~ avg_gdp_per_capita + has_carbon_tax, data = country_avg)
tidy_lm_q3 <- tidy(lm_q3)

glance(lm_q1)  # R-squared for model 1
glance(lm_q3)  # R-squared for model 3


# Actual vs Fitted values plot
country_avg$fitted_m3 <- fitted(lm_q3)

p9 <- ggplot(country_avg %>% filter(country %in% top_countries),
       aes(x = fitted_m3, y = avg_co2_per_capita, 
           label = country, color = has_carbon_tax)) +
    geom_point(size = 3) +
    geom_abline(slope = 1, intercept = 0, 
                linetype = "dashed", color = "steelblue") +
    ggrepel::geom_text_repel(size = 2.8) +
    scale_color_manual(
        values = c("TRUE" = "#00b4d8", "FALSE" = "darkgray"),
        labels = c("TRUE" = "Has carbon tax", "FALSE" = "No carbon tax")
    ) +
    labs(
        title    = "Actual vs Fitted CO2 per Capita (Model 3)",
        subtitle = "Points close to dashed line = well predicted by model",
        x        = "Fitted values",
        y        = "Actual CO2 per capita",
        color    = "Carbon Tax"
    ) +
    theme_minimal() +
    theme(
        plot.title = element_text(face = "bold", hjust = 0.5),
        legend.position = "bottom"
    )
print(p9)
ggsave("plots/09_actual_vs_fitted.png", plot = p9, width = 8, height = 5, dpi = 300)


