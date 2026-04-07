# ============================================================
# R/plot_functions.R
# Reusable plot functions for CO₂ & Carbon Tax pipeline
# ============================================================
library(tidyverse)
library(ggrepel)

# ── Colour palette ────────────────────────────────────────────
col_darknavy  <- "#03045e"
col_blue      <- "#0077b6"
col_cyan      <- "#00b4d8"
col_lightblue <- "#90e0ef"
col_pale      <- "#caf0f8"

# ── Plot 1: CO₂ distribution histogram ───────────────────────
plot_co2_distribution <- function(country_avg) {
    ggplot(country_avg, aes(x = avg_co2_per_capita)) +
        geom_histogram(binwidth = 1, fill = col_cyan, color = "white") +
        labs(title = "Distribution of Average CO₂ Emissions per Capita",
             x = "Average CO₂ per Capita (tonnes)",
             y = "Number of Countries") +
        theme_minimal()
}

# ── Plot 2: Top 20 countries by global share ──────────────────
plot_top20_share <- function(country_avg, top_countries) {
    country_avg %>%
        filter(country %in% top_countries) %>%
        arrange(desc(avg_share_global)) %>%
        mutate(top5 = row_number() <= 5) %>%
        ggplot(aes(x = reorder(country, avg_share_global),
                   y = avg_share_global, fill = top5)) +
        geom_bar(stat = "identity") +
        coord_flip() +
        scale_fill_manual(values = c("TRUE"  = col_cyan,
                                     "FALSE" = col_pale),
                          guide = "none") +
        labs(title = "Top 20 Countries by Average Share of Global CO₂",
             x = "Country",
             y = "Average Share of Global CO₂ (%)") +
        theme_minimal()
}

# ── Plot 3: Carbon tax adoption donut ────────────────────────
plot_carbon_tax_donut <- function(country_avg) {
    d <- country_avg %>%
        group_by(has_carbon_tax) %>%
        summarise(count = n(), .groups = "drop") %>%
        mutate(
            percentage     = count / sum(count) * 100,
            has_carbon_tax = factor(has_carbon_tax,
                                    levels = c(FALSE, TRUE),
                                    labels = c("No Carbon Tax",
                                               "Has Carbon Tax")),
            label = paste0(has_carbon_tax, "\n",
                           round(percentage, 1), "%")
        )
    
    ggplot(d, aes(x = 2, y = percentage, fill = has_carbon_tax)) +
        geom_bar(stat = "identity", width = 1, color = "white") +
        coord_polar(theta = "y") +
        xlim(0.5, 2.5) +
        geom_text(aes(label = label),
                  position = position_stack(vjust = 0.5),
                  color = "black", size = 3, fontface = "bold") +
        scale_fill_manual(values = c("Has Carbon Tax" = col_cyan,
                                     "No Carbon Tax"  = col_pale)) +
        labs(title = "Carbon Tax Adoption Across Countries") +
        theme_void() +
        theme(legend.position = "none",
              plot.title = element_text(hjust = 0.5,
                                        face = "bold", size = 14))
}

# ── Plot 4: GDP vs CO₂ scatter ────────────────────────────────
plot_gdp_vs_co2 <- function(country_avg, top_countries) {
    country_avg %>%
        filter(country %in% top_countries) %>%
        ggplot(aes(x = avg_gdp_per_capita, y = avg_co2_per_capita)) +
        geom_point(color = col_cyan, size = 2.5, alpha = 0.8) +
        geom_smooth(method = "lm", se = FALSE, color = col_blue) +
        geom_text_repel(aes(label = country), size = 2.8) +
        labs(title = "GDP per Capita vs CO₂ per Capita (Top Emitters)",
             x = "Average GDP per Capita (USD)",
             y = "Average CO₂ per Capita (tonnes)") +
        theme_minimal()
}

# ── Plot 5: CO₂ by country coloured by carbon tax ─────────────
plot_co2_by_country <- function(country_avg, top_countries) {
    country_avg %>%
        filter(country %in% top_countries) %>%
        arrange(avg_co2_per_capita) %>%
        ggplot(aes(x = reorder(country, avg_co2_per_capita),
                   y = avg_co2_per_capita,
                   fill = has_carbon_tax)) +
        geom_bar(stat = "identity") +
        coord_flip() +
        scale_fill_manual(
            values = c("TRUE"  = col_cyan, "FALSE" = col_pale),
            labels = c("TRUE"  = "Has Carbon Tax",
                       "FALSE" = "No Carbon Tax"),
            name   = "Carbon Tax"
        ) +
        labs(title = "Average CO₂ per Capita — Top 20 Emitters",
             x = "Country",
             y = "Average CO₂ per Capita (tonnes)") +
        theme_minimal()
}

# ── Plot 6: CO₂ trend — carbon tax countries ──────────────────
plot_trend_tax <- function(top_country_trends) {
    d <- top_country_trends %>%
        filter(carbon_tax == TRUE) %>%
        group_by(country) %>%
        mutate(trend_dir = ifelse(
            coef(lm(co2_per_capita ~ year))[2] > 0,
            "Increasing", "Decreasing")) %>%
        ungroup()
    
    ggplot(d, aes(x = year, y = co2_per_capita, color = trend_dir)) +
        geom_line(linewidth = 0.8) +
        geom_point(size = 1.5) +
        facet_wrap(~ country, scales = "free_y") +
        scale_color_manual(values = c("Increasing" = col_lightblue,
                                      "Decreasing" = col_cyan)) +
        labs(title = "CO₂ Trend — Countries with Carbon Tax",
             subtitle = "Colour indicates trend direction",
             x = "Year", y = "CO₂ per Capita (tonnes)",
             color = "Trend") +
        theme_minimal() +
        theme(strip.text  = element_text(face = "bold", size = 8),
              axis.text.x = element_text(angle = 45, hjust = 1, size = 7),
              legend.position = "bottom")
}

# ── Plot 7: CO₂ trend — no carbon tax countries ───────────────
plot_trend_notax <- function(top_country_trends) {
    d <- top_country_trends %>%
        filter(carbon_tax == FALSE) %>%
        group_by(country) %>%
        mutate(trend_dir = ifelse(
            coef(lm(co2_per_capita ~ year))[2] > 0,
            "Increasing", "Decreasing")) %>%
        ungroup()
    
    ggplot(d, aes(x = year, y = co2_per_capita, color = trend_dir)) +
        geom_line(linewidth = 0.8) +
        geom_point(size = 1.5) +
        facet_wrap(~ country, scales = "free_y") +
        scale_color_manual(values = c("Increasing" = col_cyan,
                                      "Decreasing" = col_lightblue)) +
        labs(title = "CO₂ Trend — Countries without Carbon Tax",
             subtitle = "Colour indicates trend direction",
             x = "Year", y = "CO₂ per Capita (tonnes)",
             color = "Trend") +
        theme_minimal() +
        theme(strip.text  = element_text(face = "bold", size = 8),
              axis.text.x = element_text(angle = 45, hjust = 1, size = 7),
              legend.position = "bottom")
}

# ── Plot 8: GDP vs CO₂ coloured by carbon tax ────────────────
plot_gdp_co2_tax_color <- function(country_avg, top_countries) {
    country_avg %>%
        filter(country %in% top_countries) %>%
        ggplot(aes(x = avg_gdp_per_capita, y = avg_co2_per_capita,
                   color = has_carbon_tax)) +
        geom_point(size = 2.5, alpha = 0.8) +
        geom_text_repel(aes(label = country), size = 2.8) +
        scale_color_manual(
            values = c("TRUE"  = col_cyan, "FALSE" = "gray50"),
            labels = c("TRUE"  = "Has Carbon Tax",
                       "FALSE" = "No Carbon Tax"),
            name   = "Carbon Tax"
        ) +
        labs(title = "GDP per Capita vs CO₂ per Capita (Top Emitters)",
             x = "Average GDP per Capita (USD)",
             y = "Average CO₂ per Capita (tonnes)") +
        theme_minimal(base_size = 12) +
        theme(plot.title = element_text(face = "bold", hjust = 0.5),
              legend.position = "bottom")
}

# ── Plot 9: Actual vs fitted ──────────────────────────────────
plot_actual_vs_fitted <- function(country_avg, top_countries, model) {
    country_avg %>%
        mutate(fitted = fitted(model)) %>%
        filter(country %in% top_countries) %>%
        ggplot(aes(x = fitted, y = avg_co2_per_capita,
                   color = has_carbon_tax, label = country)) +
        geom_point(size = 3) +
        geom_abline(slope = 1, intercept = 0,
                    linetype = "dashed", color = "steelblue") +
        geom_text_repel(size = 2.8) +
        scale_color_manual(
            values = c("TRUE"  = col_cyan, "FALSE" = "darkgray"),
            labels = c("TRUE"  = "Has Carbon Tax",
                       "FALSE" = "No Carbon Tax")
        ) +
        labs(title    = "Actual vs Fitted CO₂ per Capita (Model 3)",
             subtitle = "Points close to dashed line = well predicted",
             x        = "Fitted values",
             y        = "Actual CO₂ per Capita",
             color    = "Carbon Tax") +
        theme_minimal() +
        theme(plot.title = element_text(face = "bold", hjust = 0.5),
              legend.position = "bottom")
}

# ── Save plot helper ──────────────────────────────────────────
save_plot <- function(plot, filename, width = 8, height = 6, dpi = 300) {
    ggsave(paste0("plots/", filename),
           plot = plot, width = width,
           height = height, dpi = dpi)
    cat("✓ Saved:", filename, "\n")
}