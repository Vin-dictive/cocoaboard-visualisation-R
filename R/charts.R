# Chart builders — pie by product, revenue trend (top 5 reps).
# Return plotly objects for use in renderPlotly.

CHART_HEIGHT_PIE <- 480
CHART_HEIGHT_TREND <- 460

#' Pie chart of revenue by product (filtered data).
build_pie_product <- function(d) {
  if (is.null(d) || nrow(d) == 0) {
    return(plotly::plot_ly() %>% plotly::layout(title = "No data to display"))
  }
  by_product <- d %>%
    group_by(Product) %>%
    summarise(Amount = sum(Amount), .groups = "drop") %>%
    arrange(desc(Amount))
  plotly::plot_ly(
    by_product,
    labels = ~Product,
    values = ~Amount,
    type = "pie",
    textinfo = "none",
    hovertemplate = "%{label}<br>Revenue: $%{value:,.0f}<br>%{percent}<extra></extra>",
    marker = list(
      line = list(color = "white", width = 1)
    )
  ) %>%
    plotly::layout(
      title = "Revenue by Product",
      showlegend = TRUE,
      legend = list(orientation = "v", x = 1.02, y = 0.5),
      margin = list(t = 40, b = 20, l = 20, r = 120)
    ) %>%
    plotly::config(displayModeBar = TRUE)
}

#' Revenue trend line chart for top 5 sales reps (monthly).
build_revenue_trend <- function(d) {
  if (is.null(d) || nrow(d) == 0) {
    return(plotly::plot_ly() %>% plotly::layout(title = "No data to display"))
  }
  top5 <- d %>%
    group_by(Sales.Person) %>%
    summarise(Total = sum(Amount), .groups = "drop") %>%
    slice_max(Total, n = 5) %>%
    pull(Sales.Person)
  monthly <- d %>%
    filter(Sales.Person %in% top5) %>%
    mutate(Month = lubridate::floor_date(Date, "month")) %>%
    group_by(Month, Sales.Person) %>%
    summarise(Amount = sum(Amount), .groups = "drop")
  cols <- c("#E63946", "#1D8CD6", "#2ECC71", "#9B59B6", "#F39C12")
  p <- ggplot2::ggplot(monthly, ggplot2::aes(Month, Amount, colour = Sales.Person)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::geom_point(size = 2) +
    ggplot2::scale_colour_manual(
      values = setNames(cols[seq_along(unique(monthly$Sales.Person))], unique(monthly$Sales.Person))
    ) +
    ggplot2::scale_y_continuous(labels = scales::dollar_format()) +
    ggplot2::labs(x = "Month", y = "Revenue (USD)", colour = "Sales Rep") +
    ggplot2::theme_minimal()
  plotly::ggplotly(p, tooltip = c("x", "y", "colour")) %>%
    plotly::layout(
      legend = list(orientation = "h", y = 1.08),
      height = CHART_HEIGHT_TREND
    )
}
