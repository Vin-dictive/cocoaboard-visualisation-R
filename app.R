#
# CocoaBoard - Chocolate Sales Dashboard (R Shiny)
# Visualization-only port from DSCI-532_2026_8_cocoaboard.
# Deploy to Posit Cloud Connect.
#

library(shiny)
library(bslib)
library(ggplot2)
library(dplyr)
library(tidyr)
library(plotly)
library(DT)
library(lubridate)
library(bsicons)
library(scales)

# ---- Data ----
# Resolve path: project root when run via runApp() or Connect
data_path <- if (file.exists("data/raw/Chocolate_Sales.csv")) {
  "data/raw/Chocolate_Sales.csv"
} else if (file.exists("../data/raw/Chocolate_Sales.csv")) {
  "../data/raw/Chocolate_Sales.csv"
} else {
  stop("Chocolate sales CSV not found. Use data/raw/Chocolate_Sales.csv")
}

raw <- read.csv(data_path, stringsAsFactors = FALSE)
raw$Date <- as.Date(raw$Date, format = "%d/%m/%Y")
raw$Amount <- as.numeric(gsub("[$,]", "", raw$Amount))

# Country names for plotly map (plot_geo expects standard names)
country_map <- c(
  "UK" = "United Kingdom",
  "USA" = "United States",
  "Australia" = "Australia",
  "Canada" = "Canada",
  "India" = "India",
  "New Zealand" = "New Zealand"
)

# ---- KPI helpers ----
compute_yoy <- function(data) {
  if (is.null(data) || nrow(data) == 0) return("N/A")
  monthly <- data %>%
    mutate(Month = lubridate::floor_date(Date, "month")) %>%
    group_by(Month) %>%
    summarise(Amount = sum(Amount), .groups = "drop")
  last_date <- max(data$Date)
  current_year <- lubridate::year(last_date)
  last_month <- lubridate::month(last_date)
  current_rev <- monthly %>%
    filter(lubridate::year(Month) == current_year, lubridate::month(Month) <= last_month) %>%
    pull(Amount) %>% sum()
  prior_rev <- monthly %>%
    filter(lubridate::year(Month) == current_year - 1, lubridate::month(Month) <= last_month) %>%
    pull(Amount) %>% sum()
  if (prior_rev == 0) return("N/A")
  pct <- (current_rev - prior_rev) / prior_rev * 100
  sprintf("%s%.1f%%", if (pct >= 0) "+" else "", pct)
}

compute_mom <- function(data) {
  if (is.null(data) || nrow(data) == 0) return("N/A")
  monthly <- data %>%
    mutate(Month = lubridate::floor_date(Date, "month")) %>%
    group_by(Month) %>%
    summarise(Amount = sum(Amount), .groups = "drop") %>%
    arrange(Month)
  if (nrow(monthly) < 2) return("N/A")
  current_rev <- monthly$Amount[nrow(monthly)]
  prior_rev <- monthly$Amount[nrow(monthly) - 1]
  if (prior_rev == 0) return("N/A")
  pct <- (current_rev - prior_rev) / prior_rev * 100
  sprintf("%s%.1f%%", if (pct >= 0) "+" else "", pct)
}

# ---- UI ----
ui <- page_navbar(
  title = "CocoaBoard",
  theme = bs_theme(bootswatch = "flatly", primary = "#5D3A1A"),
  fillable = TRUE,
  nav_panel(
    "Chocolate Sales Dashboard",
    layout_sidebar(
      sidebar = sidebar(
        title = "Filters",
        position = "left",
        width = 280,
        open = "open",
        dateRangeInput(
          "date_range",
          "Date Range",
          start = paste0(max(raw$Date, na.rm = TRUE) %>% format("%Y"), "-01-01"),
          end = max(raw$Date, na.rm = TRUE) %>% format("%Y-%m-%d"),
          min = min(raw$Date, na.rm = TRUE),
          max = max(raw$Date, na.rm = TRUE)
        ),
        selectizeInput(
          "country",
          "Country",
          choices = sort(unique(raw$Country)),
          selected = character(0),
          multiple = TRUE,
          options = list(placeholder = "All countries")
        ),
        selectizeInput(
          "product",
          "Product",
          choices = sort(unique(raw$Product)),
          selected = character(0),
          multiple = TRUE,
          options = list(placeholder = "All products")
        )
      ),
      layout_column_wrap(
        width = 1/3,
        value_box(
          title = "Total Revenue",
          value = textOutput("total_revenue"),
          showcase = bsicons::bs_icon("currency-dollar", size = "2rem"),
          theme = "primary"
        ),
        value_box(
          title = "Total Boxes Shipped",
          value = textOutput("total_boxes"),
          showcase = bsicons::bs_icon("box-seam", size = "2rem"),
          theme = "primary"
        ),
        value_box(
          title = "Active Sales Reps",
          value = textOutput("active_reps"),
          showcase = bsicons::bs_icon("people", size = "2rem"),
          theme = "primary"
        ),
        value_box(
          title = "Avg Revenue (Filtered)",
          value = textOutput("avg_revenue"),
          showcase = bsicons::bs_icon("calculator", size = "2rem"),
          theme = "primary"
        ),
        value_box(
          title = "Year-over-Year Revenue",
          value = textOutput("yoy_revenue"),
          showcase = bsicons::bs_icon("graph-up-arrow", size = "2rem"),
          theme = "primary"
        ),
        value_box(
          title = "Month-over-Month Revenue",
          value = textOutput("mom_revenue"),
          showcase = bsicons::bs_icon("bar-chart-line", size = "2rem"),
          theme = "primary"
        )
      ),
      layout_columns(
        card(
          card_header("Sales by Country"),
          plotlyOutput("map_chart", height = "420px"),
          full_screen = TRUE
        ),
        card(
          card_header("Sales Rep Leaderboard"),
          DTOutput("leaderboard_table"),
          full_screen = TRUE
        ),
        col_widths = c(7, 5)
      ),
      card(
        card_header("Revenue Trend — Top 5 Sales Reps"),
        plotlyOutput("revenue_trend", height = "380px"),
        full_screen = TRUE
      )
    )
  )
)

# ---- Server ----
server <- function(input, output, session) {
  # Filtered data (date + country + product)
  filtered <- reactive({
    d <- raw
    d <- d %>% filter(
      Date >= as.Date(input$date_range[1]),
      Date <= as.Date(input$date_range[2])
    )
    if (length(input$country) > 0) d <- d %>% filter(Country %in% input$country)
    if (length(input$product) > 0) d <- d %>% filter(Product %in% input$product)
    d
  })

  # Map data: date + product only (no country filter) so all countries visible
  map_data <- reactive({
    d <- raw
    d <- d %>% filter(
      Date >= as.Date(input$date_range[1]),
      Date <= as.Date(input$date_range[2])
    )
    if (length(input$product) > 0) d <- d %>% filter(Product %in% input$product)
    d
  })

  # For YoY/MoM: country + product filters only (no date filter)
  non_date_filtered <- reactive({
    d <- raw
    if (length(input$country) > 0) d <- d %>% filter(Country %in% input$country)
    if (length(input$product) > 0) d <- d %>% filter(Product %in% input$product)
    d
  })

  # Value boxes
  output$total_revenue <- renderText({
    sprintf("$%s", format(sum(filtered()$Amount), big.mark = ",", trim = TRUE))
  })
  output$total_boxes <- renderText({
    format(sum(filtered()$Boxes.Shipped, na.rm = TRUE), big.mark = ",")
  })
  output$active_reps <- renderText({
    n_distinct(filtered()$Sales.Person)
  })
  output$avg_revenue <- renderText({
    d <- filtered()
    if (nrow(d) == 0) return("$0")
    sprintf("$%s", format(mean(d$Amount), big.mark = ",", digits = 0, trim = TRUE))
  })
  output$yoy_revenue <- renderText(compute_yoy(non_date_filtered()))
  output$mom_revenue <- renderText(compute_mom(non_date_filtered()))

  # Choropleth map
  output$map_chart <- renderPlotly({
    d <- map_data()
    if (nrow(d) == 0) {
      return(plot_ly() %>% layout(title = "No data to display"))
    }
    by_country <- d %>%
      group_by(Country) %>%
      summarise(Amount = sum(Amount), .groups = "drop") %>%
      mutate(CountryPlotly = recode(Country, !!!country_map))
    plot_geo(by_country) %>%
      add_trace(
        type = "choropleth",
        locations = ~CountryPlotly,
        z = ~Amount,
        locationmode = "country names",
        colorscale = "Oranges",
        text = ~paste(Country, paste0("$", format(Amount, big.mark = ","))),
        hoverinfo = "text",
        colorbar = list(title = "Revenue (USD)")
      ) %>%
      layout(
        geo = list(scope = "world", showframe = FALSE, showcoastlines = TRUE),
        margin = list(l = 0, r = 0, t = 30, b = 0)
      )
  })

  # Leaderboard table
  output$leaderboard_table <- renderDT({
    d <- filtered()
    if (nrow(d) == 0) {
      return(datatable(data.frame(Rank = character(), `Sales Rep` = character(), Revenue = character(),
                                  Transactions = integer(), Boxes = character(), `Avg Deal` = character(), `Rev Share` = character()),
                       options = list(dom = "t"), rownames = FALSE))
    }
    total_rev <- sum(d$Amount)
    lb <- d %>%
      group_by(Sales.Person) %>%
      summarise(
        Revenue = sum(Amount),
        Transactions = n(),
        Boxes = sum(Boxes.Shipped, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      arrange(desc(Revenue)) %>%
      mutate(
        Rank = row_number(),
        `Avg Deal` = sprintf("$%s", format(Revenue / Transactions, big.mark = ",", trim = TRUE)),
        `Rev Share` = sprintf("%.1f%%", Revenue / total_rev * 100),
        Revenue = sprintf("$%s", format(Revenue, big.mark = ",", trim = TRUE)),
        Boxes = format(Boxes, big.mark = ",")
      ) %>%
      select(Rank, `Sales Rep` = Sales.Person, Revenue, Transactions, Boxes, `Avg Deal`, `Rev Share`)
    summary_row <- data.frame(
      Rank = "",
      `Sales Rep` = "AVERAGE / TOTAL",
      Revenue = sprintf("$%s", format(total_rev, big.mark = ",", trim = TRUE)),
      Transactions = nrow(d),
      Boxes = format(sum(d$Boxes.Shipped, na.rm = TRUE), big.mark = ","),
      `Avg Deal` = sprintf("$%s", format(mean(d$Amount), big.mark = ",", digits = 0, trim = TRUE)),
      `Rev Share` = "100.0%",
      check.names = FALSE
    )
    lb <- rbind(lb, summary_row)
    datatable(lb, options = list(dom = "tip", pageLength = 15), rownames = FALSE)
  })

  # Revenue trend (top 5 reps, monthly)
  output$revenue_trend <- renderPlotly({
    d <- filtered()
    if (nrow(d) == 0) {
      return(plot_ly() %>% layout(title = "No data to display"))
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
    p <- ggplot(monthly, aes(Month, Amount, colour = Sales.Person)) +
      geom_line(linewidth = 1) +
      geom_point(size = 2) +
      scale_colour_manual(values = setNames(cols[seq_along(unique(monthly$Sales.Person))], unique(monthly$Sales.Person))) +
      scale_y_continuous(labels = scales::dollar_format()) +
      labs(x = "Month", y = "Revenue (USD)", colour = "Sales Rep") +
      theme_minimal()
    ggplotly(p, tooltip = c("x", "y", "colour")) %>%
      layout(legend = list(orientation = "h", y = 1.1))
  })
}

# ---- Run ----
shinyApp(ui, server)
