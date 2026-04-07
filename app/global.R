# ============================================================
# app/global.R
# Runs automatically before ui.R and server.R
# Loads data, defines palette, helpers, and shared objects
# ============================================================

library(shiny)
library(plotly)
library(DT)
library(tidyverse)
library(broom)

# ── Load workspace ────────────────────────────────────────────
if (file.exists("data/processed/analysis_workspace.RData")) {
    load("data/processed/analysis_workspace.RData")
} else {
    load("../data/processed/analysis_workspace.RData")
}

# ── Colour palette ────────────────────────────────────────────
col_darknavy  <- "#21497E"
col_blue      <- "#2A7FAA"
col_cyan      <- "#47B9C6"
col_lightblue <- "#ACE9DF"
col_pale      <- "#D5F8E2"

# ── GDP level classification ──────────────────────────────────
country_avg <- country_avg %>%
    mutate(
        has_carbon_tax = as.logical(has_carbon_tax),
        gdp_level = case_when(
            avg_gdp_per_capita > 12000 ~ "High income",
            avg_gdp_per_capita > 3000  ~ "Middle income",
            TRUE                       ~ "Low income"
        ),
        gdp_level = factor(gdp_level,
                           levels = c("Low income",
                                      "Middle income",
                                      "High income"))
    )

co2_tax_gdp <- co2_tax_gdp %>%
    mutate(
        gdp_level = case_when(
            gdp_per_capita > 12000 ~ "High income",
            gdp_per_capita > 3000  ~ "Middle income",
            TRUE                   ~ "Low income"
        ),
        gdp_level = factor(gdp_level,
                           levels = c("Low income",
                                      "Middle income",
                                      "High income"))
    )

# ── Interpretation box helper ─────────────────────────────────
finding_box <- function(title, text, color) {
    div(
        style = paste0(
            "border-left: 4px solid ", color, ";",
            "padding: 10px 14px;",
            "margin-bottom: 10px;",
            "background: #f8fbff;",
            "border-radius: 0 6px 6px 0;"
        ),
        strong(title,
               style = paste0("color:", color, ";")),
        p(text,
          style = "font-size: 13px; color: #444;
                   margin-top: 5px; line-height: 1.6;")
    )
}

# ── Value card helper ─────────────────────────────────────────
value_card <- function(value, label, sub = NULL, color) {
    div(
        style = paste0(
            "background: white;",
            "border-radius: 8px;",
            "padding: 16px 20px;",
            "border-top: 4px solid ", color, ";",
            "box-shadow: 0 1px 4px rgba(0,0,0,0.08);",
            "text-align: center;"
        ),
        div(style = paste0(
            "font-size: 28px; font-weight: bold; color:", color, ";"
        ), value),
        div(style = "font-size: 12px; color: #777;
                     text-transform: uppercase;
                     letter-spacing: 0.05em;
                     margin-top: 4px;", label),
        if (!is.null(sub))
            div(style = "font-size: 11px; color: #aaa;
                         margin-top: 4px;", sub)
    )
}

# ── Sidebar filter panel helper ───────────────────────────────
filter_panel <- function() {
    sidebarPanel(
        width = 2,
        h5("Filters"),
        sliderInput("year_range", "Year range",
                    min   = 2000, max = 2024,
                    value = c(2000, 2024),
                    sep   = ""),
        selectInput("tax_filter", "Carbon tax",
                    choices  = c("All", "Has tax", "No tax"),
                    selected = "All"),
        selectInput("gdp_filter", "GDP level",
                    choices  = c("All",
                                 "High income",
                                 "Middle income",
                                 "Low income"),
                    selected = "All"),
        hr(),
        checkboxInput("top_only",
                      "Top 20 emitters only",
                      value = FALSE),
        hr(),
        div(style = "font-size: 11px; color: white;
             line-height: 1.6; margin-top: 8px;",
            "Data source: Our World in Data",
            br(),
            "Carbon pricing: World Bank",
            br(),
            "Period: 2000 – 2024"
        )
    )
}