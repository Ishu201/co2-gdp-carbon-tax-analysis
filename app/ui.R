# ============================================================
# app/ui.R
# Dashboard layout and structure
# ============================================================

ui <- tagList(
    tags$head(
        tags$link(rel  = "stylesheet",
                  type = "text/css",
                  href = "styles.css")
    ),
    
    navbarPage(
        title = "Global CO₂ Analysis",
        id    = "nav",
        
        # ── TAB 1: OVERVIEW ──────────────────────────────
        tabPanel("Overview",
                 sidebarLayout(
                     filter_panel(),
                     mainPanel(
                         width = 10,
                         
                         div(class = "value-row",
                             uiOutput("vbox_countries"),
                             uiOutput("vbox_corr"),
                             uiOutput("vbox_r2"),
                             uiOutput("vbox_tax_effect")
                         ),
                         
                         div(class = "two-col",
                             div(class = "chart-card",
                                 div(class = "chart-title",
                                     "CO₂ per Capita Distribution"),
                                 plotlyOutput("plot_hist",
                                              height = "280px")),
                             div(class = "chart-card",
                                 div(class = "chart-title",
                                     "Carbon Tax Adoption Worldwide"),
                                 plotlyOutput("plot_donut",
                                              height = "280px"))
                         ),
                         
                         div(class = "two-col",
                             div(class = "chart-card",
                                 div(class = "chart-title",
                                     "Top 20 Countries by Global CO₂ Share"),
                                 plotlyOutput("plot_top20",
                                              height = "350px")),
                             div(class = "chart-card",
                                 div(class = "chart-title",
                                     "Carbon Tax Effect with and without GDP Control"),
                                 plotlyOutput("plot_coef",
                                              height = "350px"))
                         ),
                         
                         div(class = "chart-card",
                             div(class = "chart-title",
                                 "World Map: CO₂ per Capita & Carbon Tax Status"),
                             plotlyOutput("plot_map_co2",
                                          height = "400px"))
                     )
                 )
        ),
        
        # ── TAB 2: Q1 GDP & CO₂ ─────────────────────────
        tabPanel("GDP & CO₂",
                 sidebarLayout(
                     filter_panel(),
                     mainPanel(
                         width = 10,
                         
                         div(class = "value-row-3",
                             uiOutput("vbox_gdp_corr"),
                             uiOutput("vbox_gdp_r2"),
                             uiOutput("vbox_gdp_coef")
                         ),
                         
                         div(class = "chart-card",
                             div(class = "chart-title",
                                 "World Map: GDP per Capita Distribution"),
                             plotlyOutput("plot_map_gdp",
                                          height = "380px")),
                         
                         div(class = "two-col",
                             div(class = "chart-card",
                                 div(class = "chart-title",
                                     "GDP per Capita vs CO₂ per Capita"),
                                 plotlyOutput("plot_gdp_co2",
                                              height = "320px")),
                             div(class = "chart-card",
                                 div(class = "chart-title",
                                     "Average CO₂ by GDP Level"),
                                 plotlyOutput("plot_gdp_group",
                                              height = "320px"))
                         ),
                         
                         div(class = "two-col-wide",
                             div(class = "chart-card",
                                 div(class = "chart-title",
                                     "CO₂ Trend Over Years by GDP Level"),
                                 plotlyOutput("plot_gdp_trend",
                                              height = "320px")),
                             div(class = "chart-card",
                                 div(class = "chart-title",
                                     "Interpretation"),
                                 finding_box(
                                     "GDP strongly predicts CO₂",
                                     "GDP per capita is a strong predictor of CO₂ emissions per capita (r = 0.83, p < 0.001). For every $10,000 increase in GDP, CO₂ per capita increases by ~3 tonnes.",
                                     col_cyan
                                 ),
                                 finding_box(
                                     "Wealthier countries emit more",
                                     "High income countries consistently emit more CO₂ per capita than middle and low income countries, reflecting higher energy consumption.",
                                     col_blue
                                 ),
                                 finding_box(
                                     "Diverging trends",
                                     "High income countries show stable or declining emissions while middle income countries show increasing trends as they develop.",
                                     col_darknavy
                                 )
                             )
                         )
                     )
                 )
        ),
        
        # ── TAB 3: Q2 CARBON TAX ────────────────────────
        tabPanel("Carbon Tax",
                 sidebarLayout(
                     filter_panel(),
                     mainPanel(
                         width = 10,
                         
                         div(class = "value-row-3",
                             uiOutput("vbox_tax_raw"),
                             uiOutput("vbox_tax_controlled"),
                             uiOutput("vbox_tax_sig")
                         ),
                         
                         div(class = "two-col",
                             div(class = "chart-card",
                                 div(class = "chart-title",
                                     "CO₂ per Capita by Country (coloured by Tax)"),
                                 plotlyOutput("plot_co2_country",
                                              height = "360px")),
                             div(class = "chart-card",
                                 div(class = "chart-title",
                                     "CO₂ Trend of all Top Countries"),
                                 plotlyOutput("plot_trend_all",
                                              height = "360px"))
                         ),
                         
                         div(class = "two-col-wide",
                             div(class = "chart-card",
                                 div(class = "chart-title",
                                     "GDP vs CO₂ coloured by Carbon Tax"),
                                 plotlyOutput("plot_gdp_tax",
                                              height = "360px")),
                             div(class = "chart-card",
                                 div(class = "chart-title",
                                     "Interpretation"),
                                 finding_box(
                                     "Confounding effect of GDP",
                                     "Without controlling for GDP, carbon tax appears to increase CO₂ (+3.59 tonnes). This is misleading as wealthier countries both adopt carbon tax AND emit more.",
                                     col_darknavy
                                 ),
                                 finding_box(
                                     "True effect after GDP control",
                                     "After controlling for GDP, carbon tax is associated with 3.24 fewer tonnes of CO₂ per capita (p < 0.001). The direction completely flips.",
                                     col_cyan
                                 ),
                                 finding_box(
                                     "Policy conclusion",
                                     "Carbon tax is effective when economic scale is accounted for. It needs complementary measures for maximum impact.",
                                     col_blue
                                 )
                             )
                         )
                     )
                 )
        ),
        
        # ── TAB 4: DATA EXPLORER ─────────────────────────
        tabPanel("Data Explorer",
                 sidebarLayout(
                     filter_panel(),
                     mainPanel(
                         width = 10,
                         
                         div(class = "chart-card",
                             div(class = "chart-title",
                                 "Correlation Heatmap"),
                             plotlyOutput("plot_corr_heat",
                                          height = "380px")),
                         
                         div(class = "chart-card",
                             div(class = "chart-title",
                                 "Country Averages"),
                             DTOutput("tbl_country_avg")),
                         
                         div(class = "chart-card",
                             div(class = "chart-title",
                                 "Full Dataset"),
                             DTOutput("tbl_full"))
                     )
                 )
        )
    )
)