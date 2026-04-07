# ============================================================
# app/server.R
# Reactive logic and plot rendering
# ============================================================

server <- function(input, output, session) {
    
    # ── Reactive filtered data ───────────────────────────────
    filtered_avg <- reactive({
        d <- country_avg
        if (input$tax_filter == "Has tax")
            d <- d %>% filter(has_carbon_tax == TRUE)
        if (input$tax_filter == "No tax")
            d <- d %>% filter(has_carbon_tax == FALSE)
        if (input$gdp_filter != "All")
            d <- d %>% filter(gdp_level == input$gdp_filter)
        if (input$top_only)
            d <- d %>% filter(country %in% top_countries)
        d
    })
    
    filtered_trends <- reactive({
        d <- co2_tax_gdp %>%
            filter(between(year,
                           input$year_range[1],
                           input$year_range[2]))
        if (input$tax_filter == "Has tax")
            d <- d %>% filter(carbon_tax == TRUE)
        if (input$tax_filter == "No tax")
            d <- d %>% filter(carbon_tax == FALSE)
        if (input$gdp_filter != "All")
            d <- d %>% filter(gdp_level == input$gdp_filter)
        if (input$top_only)
            d <- d %>% filter(country %in% top_countries)
        d
    })
    
    # ── Value boxes ──────────────────────────────────────────
    output$vbox_countries <- renderUI({
        value_card(n_distinct(filtered_avg()$country),
                   "Countries", NULL, col_cyan)
    })
    output$vbox_corr <- renderUI({
        value_card("0.83", "GDP vs CO₂ (r)",
                   "Pearson correlation", col_blue)
    })
    output$vbox_r2 <- renderUI({
        value_card("71.6%", "Model R²",
                   "GDP + Carbon Tax", col_cyan)
    })
    output$vbox_tax_effect <- renderUI({
        value_card("−3.24", "Carbon Tax Effect",
                   "tonnes CO₂ per capita", col_darknavy)
    })
    output$vbox_gdp_corr <- renderUI({
        value_card("0.83", "GDP vs CO₂ (r)",
                   "p < 0.001", col_cyan)
    })
    output$vbox_gdp_r2 <- renderUI({
        value_card("67.8%", "GDP alone explains",
                   "R-squared", col_blue)
    })
    output$vbox_gdp_coef <- renderUI({
        value_card("+3.19 tonnes", "CO₂ per $10k GDP",
                   "regression coefficient", col_darknavy)
    })
    output$vbox_tax_raw <- renderUI({
        value_card("+3.59", "Without GDP control",
                   "misleading positive effect", col_darknavy)
    })
    output$vbox_tax_controlled <- renderUI({
        value_card("−3.24", "With GDP control",
                   "true negative effect", col_cyan)
    })
    output$vbox_tax_sig <- renderUI({
        value_card("p < 0.001", "Significance",
                   "after GDP control", col_blue)
    })
    
    # ── Tab 1: Histogram ─────────────────────────────────────
    output$plot_hist <- renderPlotly({
        plot_ly(filtered_avg(),
                x = ~avg_co2_per_capita,
                type = "histogram",
                nbinsx = 30,
                marker = list(
                    color = col_cyan,
                    line  = list(color = "white",
                                 width = 0.5)
                ),
                hovertemplate = "CO₂: %{x:.1f}<br>Count: %{y}<extra></extra>") %>%
            layout(
                xaxis = list(title = "Avg CO₂ per Capita (tonnes)"),
                yaxis = list(title = "Number of Countries"),
                showlegend    = FALSE,
                paper_bgcolor = "white",
                plot_bgcolor  = "white"
            )
    })
    
    # ── Tab 1: Donut ─────────────────────────────────────────
    output$plot_donut <- renderPlotly({
        d <- filtered_avg() %>%
            group_by(has_carbon_tax) %>%
            summarise(n = n(), .groups = "drop") %>%
            mutate(label = ifelse(has_carbon_tax,
                                  "Has Carbon Tax",
                                  "No Carbon Tax"))
        plot_ly(d,
                labels = ~label,
                values = ~n,
                type   = "pie",
                hole   = 0.5,
                marker = list(
                    colors = c(col_cyan, col_pale),
                    line   = list(color = "white",
                                  width = 2)
                ),
                textinfo = "label+percent",
                hovertemplate = "%{label}: %{value}<extra></extra>") %>%
            layout(
                showlegend    = FALSE,
                paper_bgcolor = "white"
            )
    })
    
    # ── Tab 1: Top 20 bar ────────────────────────────────────
    output$plot_top20 <- renderPlotly({
        d <- filtered_avg() %>%
            arrange(desc(avg_share_global)) %>%
            slice_head(n = 20) %>%
            arrange(avg_share_global) %>%
            mutate(top5 = row_number() > (n() - 5))
        plot_ly(d,
                x = ~avg_share_global,
                y = ~reorder(country, avg_share_global),
                type = "bar", orientation = "h",
                color  = ~top5,
                colors = c(col_lightblue, col_cyan),
                hovertemplate = "<b>%{y}</b><br>%{x:.2f}%<extra></extra>") %>%
            layout(
                xaxis      = list(title = "Share of Global CO₂ (%)"),
                yaxis      = list(title = ""),
                showlegend = FALSE,
                margin     = list(l = 120),
                paper_bgcolor = "white",
                plot_bgcolor  = "white"
            )
    })
    
    # ── Tab 1: Coefficient comparison ────────────────────────
    output$plot_coef <- renderPlotly({
        d <- data.frame(
            model    = c("Without GDP control",
                         "With GDP control"),
            estimate = c(3.593, -3.243),
            color    = c(col_darknavy, col_cyan)
        )
        plot_ly(d,
                x = ~estimate,
                y = ~model,
                type = "bar", orientation = "h",
                marker = list(color = d$color),
                hovertemplate = "<b>%{y}</b><br>%{x:.3f} tonnes<extra></extra>") %>%
            add_segments(
                x = 0, xend = 0,
                y = 0.5, yend = 2.5,
                line = list(color = "grey", dash = "dash"),
                showlegend = FALSE
            ) %>%
            layout(
                xaxis  = list(title = "Carbon Tax Coefficient"),
                yaxis  = list(title = ""),
                margin = list(l = 160),
                paper_bgcolor = "white",
                plot_bgcolor  = "white"
            )
    })
    
    # ── Tab 1: World map CO₂ ─────────────────────────────────
    output$plot_map_co2 <- renderPlotly({
        d <- filtered_avg() %>%
            mutate(tax_label = ifelse(has_carbon_tax,
                                      "Has carbon tax",
                                      "No carbon tax"))
        plot_ly(d,
                type         = "choropleth",
                locations    = ~country,
                locationmode = "country names",
                z    = ~avg_co2_per_capita,
                text = ~paste0(
                    "<b>", country, "</b><br>",
                    "CO₂: ", round(avg_co2_per_capita, 1),
                    " tonnes<br>", tax_label
                ),
                hoverinfo  = "text",
                colorscale = list(
                    c(0,   col_pale),
                    c(0.5, col_cyan),
                    c(1,   col_darknavy)
                ),
                colorbar = list(title = "CO₂ per<br>Capita")) %>%
            layout(
                geo = list(
                    showframe      = FALSE,
                    showcoastlines = TRUE,
                    projection     = list(type = "natural earth")
                ),
                paper_bgcolor = "white"
            )
    })
    
    # ── Tab 2: GDP world map ─────────────────────────────────
    output$plot_map_gdp <- renderPlotly({
        d <- filtered_avg()
        plot_ly(d,
                type         = "choropleth",
                locations    = ~country,
                locationmode = "country names",
                z    = ~avg_gdp_per_capita,
                text = ~paste0(
                    "<b>", country, "</b><br>",
                    "GDP: $", round(avg_gdp_per_capita, 0)
                ),
                hoverinfo  = "text",
                colorscale = list(
                    c(0,   col_pale),
                    c(0.5, col_cyan),
                    c(1,   col_darknavy)
                ),
                colorbar = list(title = "GDP per<br>Capita ($)")) %>%
            layout(
                geo = list(
                    showframe      = FALSE,
                    showcoastlines = TRUE,
                    projection     = list(type = "natural earth")
                ),
                paper_bgcolor = "white"
            )
    })
    
    # ── Tab 2: GDP vs CO₂ scatter ────────────────────────────
    output$plot_gdp_co2 <- renderPlotly({
        d <- filtered_avg()
        plot_ly(d,
                x = ~avg_gdp_per_capita,
                y = ~avg_co2_per_capita,
                type   = "scatter",
                mode   = "markers",
                color  = ~gdp_level,
                colors = c(col_pale, col_cyan, col_darknavy),
                text   = ~country,
                marker = list(size = 8, opacity = 0.8),
                hovertemplate = paste0(
                    "<b>%{text}</b><br>",
                    "GDP: $%{x:,.0f}<br>",
                    "CO₂: %{y:.1f}<extra></extra>"
                )) %>%
            layout(
                xaxis  = list(title = "GDP per Capita (USD)"),
                yaxis  = list(title = "CO₂ per Capita (tonnes)"),
                legend = list(orientation = "h", y = -0.2),
                paper_bgcolor = "white",
                plot_bgcolor  = "white"
            )
    })
    
    # ── Tab 2: GDP group bar ─────────────────────────────────
    output$plot_gdp_group <- renderPlotly({
        d <- filtered_avg() %>%
            group_by(gdp_level) %>%
            summarise(avg_co2 = mean(avg_co2_per_capita,
                                     na.rm = TRUE),
                      .groups = "drop")
        plot_ly(d,
                x = ~gdp_level,
                y = ~avg_co2,
                type   = "bar",
                marker = list(color = c(col_pale,
                                        col_cyan,
                                        col_darknavy)),
                hovertemplate = "<b>%{x}</b><br>%{y:.1f} tonnes<extra></extra>") %>%
            layout(
                xaxis      = list(title = "GDP Level"),
                yaxis      = list(title = "Avg CO₂ per Capita"),
                showlegend = FALSE,
                paper_bgcolor = "white",
                plot_bgcolor  = "white"
            )
    })
    
    # ── Tab 2: CO₂ trend by GDP group ────────────────────────
    output$plot_gdp_trend <- renderPlotly({
        d <- filtered_trends() %>%
            group_by(year, gdp_level) %>%
            summarise(avg_co2 = mean(co2_per_capita,
                                     na.rm = TRUE),
                      .groups = "drop")
        plot_ly(d,
                x      = ~year,
                y      = ~avg_co2,
                color  = ~gdp_level,
                colors = c(col_pale, col_cyan, col_darknavy),
                type   = "scatter",
                mode   = "lines+markers",
                hovertemplate = paste0(
                    "<b>%{fullData.name}</b><br>",
                    "Year: %{x}<br>",
                    "CO₂: %{y:.1f}<extra></extra>"
                )) %>%
            layout(
                xaxis  = list(title = "Year"),
                yaxis  = list(title = "Avg CO₂ per Capita"),
                legend = list(orientation = "h", y = -0.2),
                paper_bgcolor = "white",
                plot_bgcolor  = "white"
            )
    })
    
    # ── Tab 3: CO₂ by country ────────────────────────────────
    output$plot_co2_country <- renderPlotly({
        d <- filtered_avg() %>%
            filter(country %in% top_countries) %>%
            arrange(avg_co2_per_capita)
        plot_ly(d,
                x    = ~avg_co2_per_capita,
                y    = ~reorder(country, avg_co2_per_capita),
                type = "bar", orientation = "h",
                color  = ~has_carbon_tax,
                colors = c("FALSE" = col_lightblue,
                           "TRUE"  = col_cyan),
                hovertemplate = paste0(
                    "<b>%{y}</b><br>",
                    "%{x:.1f} tonnes<extra></extra>"
                )) %>%
            layout(
                xaxis  = list(title = "Avg CO₂ per Capita (tonnes)"),
                yaxis  = list(title = ""),
                legend = list(title = list(text = "Carbon Tax"),
                              orientation = "h", y = -0.15),
                margin = list(l = 120),
                paper_bgcolor = "white",
                plot_bgcolor  = "white"
            )
    })
    
    # ── Tab 3: Trend all top countries ───────────────────────
    output$plot_trend_all <- renderPlotly({
        d <- co2_tax_gdp %>%
            filter(country %in% top_countries,
                   between(year,
                           input$year_range[1],
                           input$year_range[2])) %>%
            group_by(country, year, carbon_tax) %>%
            summarise(co2_pc = mean(co2_per_capita,
                                    na.rm = TRUE),
                      .groups = "drop")
        
        # Custom 20 colour palette
        custom_colors <- c(
            "#21497E", "#2A7FAA", "#47B9C6", "#ACE9DF",
            "#1B6CA8", "#0D4F8B", "#3A9BBF", "#6EC6D4",
            "#0A3D6B", "#155C8A", "#2E8AAD", "#54B8CB",
            "#083358", "#1A6F9E", "#35A0C0", "#62CDD8",
            "#0C4470", "#2080B0", "#4AAFC3", "#78D8E0"
        )
        
        plot_ly(d,
                x      = ~year,
                y      = ~co2_pc,
                color  = ~country,
                colors = custom_colors,
                type   = "scatter",
                mode   = "lines+markers",
                hovertemplate = paste0(
                    "<b>%{fullData.name}</b><br>",
                    "Year: %{x}<br>",
                    "CO₂: %{y:.1f}<extra></extra>"
                )) %>%
            layout(
                xaxis  = list(title = "Year"),
                yaxis  = list(title = "CO₂ per Capita (tonnes)"),
                legend = list(orientation = "v"),
                paper_bgcolor = "white",
                plot_bgcolor  = "white"
            )
    })
    
    # ── Tab 3: GDP vs CO₂ coloured by tax ────────────────────
    output$plot_gdp_tax <- renderPlotly({
        d <- filtered_avg() %>%
            filter(country %in% top_countries)
        plot_ly(d,
                x    = ~avg_gdp_per_capita,
                y    = ~avg_co2_per_capita,
                type = "scatter",
                mode = "markers+text",
                color  = ~has_carbon_tax,
                colors = c("FALSE" = "gray70",
                           "TRUE"  = col_cyan),
                text         = ~country,
                textposition = "top center",
                marker = list(size = 10, opacity = 0.85),
                hovertemplate = paste0(
                    "<b>%{text}</b><br>",
                    "GDP: $%{x:,.0f}<br>",
                    "CO₂: %{y:.1f}<extra></extra>"
                )) %>%
            layout(
                xaxis  = list(title = "GDP per Capita (USD)"),
                yaxis  = list(title = "CO₂ per Capita (tonnes)"),
                legend = list(title = list(text = "Carbon Tax"),
                              orientation = "h", y = -0.15),
                paper_bgcolor = "white",
                plot_bgcolor  = "white"
            )
    })
    
    # ── Tab 4: Correlation heatmap ────────────────────────────
    output$plot_corr_heat <- renderPlotly({
        d <- filtered_avg() %>%
            select(avg_co2_per_capita, avg_gdp_per_capita,
                   avg_share_global, avg_energy) %>%
            rename(
                `CO₂ per capita`   = avg_co2_per_capita,
                `GDP per capita`   = avg_gdp_per_capita,
                `Global CO₂ share` = avg_share_global,
                `Energy use`       = avg_energy
            )
        cor_mat <- cor(d, use = "complete.obs")
        plot_ly(
            x = colnames(cor_mat),
            y = rownames(cor_mat),
            z = cor_mat,
            type = "heatmap",
            colorscale = list(
                c(0,   col_darknavy),
                c(0.5, "white"),
                c(1,   col_cyan)
            ),
            zmin = -1, zmax = 1,
            hovertemplate = "%{x} vs %{y}<br>r = %{z:.3f}<extra></extra>") %>%
            layout(
                xaxis = list(title = ""),
                yaxis = list(title = ""),
                paper_bgcolor = "white"
            )
    })
    
    # ── Tab 4: Country averages table ────────────────────────
    output$tbl_country_avg <- renderDT({
        filtered_avg() %>%
            arrange(desc(avg_share_global)) %>%
            mutate(across(where(is.numeric), ~round(., 2))) %>%
            datatable(filter   = "top",
                      options  = list(pageLength = 15,
                                      scrollX    = TRUE),
                      rownames = FALSE)
    })
    
    # ── Tab 4: Full dataset table ─────────────────────────────
    output$tbl_full <- renderDT({
        filtered_trends() %>%
            mutate(across(where(is.numeric), ~round(., 3))) %>%
            datatable(filter   = "top",
                      options  = list(pageLength = 15,
                                      scrollX    = TRUE),
                      rownames = FALSE)
    })
}