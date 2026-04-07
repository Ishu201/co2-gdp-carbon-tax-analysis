# Global CO₂ Emissions: GDP & Carbon Tax Analysis

![R](https://img.shields.io/badge/R-4.5-276DC3?style=flat&logo=r)
![Shiny](https://img.shields.io/badge/Shiny-Dashboard-blue?style=flat)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=flat)

A full data analytics case study investigating whether GDP per capita
predicts CO₂ emissions and whether carbon tax reduces emissions :
built as part of ALY6070 at Northeastern University Vancouver.

---

## Research Questions

> **Q1:** Does GDP per capita predict CO₂ emissions per capita across countries?

> **Q2:** Does having a carbon tax affect CO₂ emissions in top emitting countries?

---

## Key Findings

| Finding | Result |
|---|---|
| GDP vs CO₂ correlation | r = 0.824, p < 0.001 - strong positive |
| Carbon tax without GDP control | +3.59 tonnes - misleading positive |
| Carbon tax with GDP control | -3.24 tonnes - true negative effect |
| Model R² (GDP + Carbon tax) | 70.8% of CO₂ variation explained |
| Confounding variable | GDP confirmed as confounder |

> Carbon tax **does** reduce emissions - but only after controlling
> for GDP. Without the control, wealthier countries that adopt carbon
> tax appear to emit more, simply because wealth drives emissions.

---

## Project Structure
<img width="602" height="608" alt="image" src="https://github.com/user-attachments/assets/771ced92-b83a-4ab5-9846-b356eca3f323" />

---

## Data

Raw datasets are not included due to GitHub file size limits.

| File | Source | Save as |
|---|---|---|
| CO₂ emissions | [Our World in Data](https://ourworldindata.org/co2-and-greenhouse-gas-emissions) | `data/raw/co2-emission.csv` |
| Carbon tax | [World Bank Carbon Pricing](https://carbonpricingdashboard.worldbank.org) | `data/raw/carbon-tax-data.csv` |

See [`data/raw/README.md`](data/raw/README.md) for full download instructions.

**Dataset coverage:**
- 164 countries
- 2000 – 2024
- 4,100 observations after cleaning and joining

---

## How to Run

### 1. Clone the repository
```bash
git clone https://github.com/YOUR_USERNAME/co2-gdp-carbon-tax-analysis.git
```

### 2. Download the data
Follow instructions in [`data/raw/README.md`](data/raw/README.md)

### 3. Install required packages
```r
install.packages(c(
  "tidyverse", "ggplot2", "ggrepel",
  "broom", "shiny", "plotly", "DT",
  "knitr", "kableExtra", "rmarkdown"
))
```

### 4. Run the full pipeline
```r
source("run_all.R")
```

### 5. Launch the dashboard
```r
shiny::runApp("app")
```

### 6. View the report
```r
rmarkdown::render("co2_gdp_carbon_tax_analysis.Rmd")
```
Or open `co2_gdp_carbon_tax_analysis.html` directly in your browser.

---

## Dashboard

An interactive Shiny dashboard with 4 tabs:

| Tab | Content |
|---|---|
| Overview | CO₂ distribution, top 20 emitters, world map, carbon tax adoption |
| Q1 : GDP & CO₂ | GDP world map, scatter plots, trend by income group |
| Q2 : Carbon Tax | CO₂ by country, trends, GDP confounding analysis |
| Data Explorer | Correlation heatmap, filterable data tables |

**Filters:** Year range, carbon tax status, GDP level, top 20 only

---

## Visualisations

| Plot | Description |
|---|---|
| `01_co2_distribution.png` | Distribution of CO₂ per capita |
| `02_top20_global_share.png` | Top 20 countries by global share |
| `03_carbon_tax_adoption.png` | Carbon tax adoption donut chart |
| `04_gdp_vs_co2.png` | GDP vs CO₂ scatter with regression |
| `05_co2_by_country.png` | CO₂ per capita coloured by tax status |
| `06_trend_tax_countries.png` | CO₂ trend - carbon tax countries |
| `07_co2_trend_no_tax.png` | CO₂ trend - no tax countries |
| `08_gdp_co2_tax_color.png` | GDP vs CO₂ coloured by tax |
| `09_actual_vs_fitted.png` | Actual vs fitted - Model 3 |

---

## Tools & Packages

| Category | Tools |
|---|---|
| Language | R 4.5 |
| Data wrangling | tidyverse, dplyr, readr |
| Visualisation | ggplot2, ggrepel, plotly |
| Statistical analysis | broom, base R |
| Dashboard | shiny, DT |
| Reporting | rmarkdown, knitr, kableExtra |

---

## Pipeline Architecture
<img width="481" height="523" alt="image" src="https://github.com/user-attachments/assets/d4df0e86-9628-4a3c-a77b-1cdb10b265d6" />

---

## Author

**Isuri Nawodya** |
Master of Professional Studies in Analytics |
Northeastern University Vancouver

---

## Data Sources

- Hannah Ritchie, Max Roser and Pablo Rosado (2020) - CO₂ and
  Greenhouse Gas Emissions. *Our World in Data*.
  [ourworldindata.org](https://ourworldindata.org/co2-and-greenhouse-gas-emissions)

- World Bank Group — Carbon Pricing Dashboard.
  [carbonpricingdashboard.worldbank.org](https://carbonpricingdashboard.worldbank.org)

---
