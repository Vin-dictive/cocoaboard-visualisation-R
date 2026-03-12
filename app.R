#
# CocoaBoard - Chocolate Sales Dashboard (R Shiny)
# Modular layout: R/format_utils.R, R/kpi.R, R/leaderboard.R, R/charts.R
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
library(shinycssloaders)

# Load modules (order matters: format_utils before leaderboard)
source("R/format_utils.R", local = TRUE)
source("R/kpi.R", local = TRUE)
source("R/leaderboard.R", local = TRUE)
source("R/charts.R", local = TRUE)

# ---- Data ----
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

# Chart/card heights — taller cards, scrollable dashboard
HEIGHT_PIE_PX <- "620px"
HEIGHT_TREND_PX <- "620px"
HEIGHT_LEADERBOARD_PX <- "620px"

# ---- UI ----
ui <- page_navbar(
  title = "CocoaBoard",
  theme = bs_theme(version = 5),
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
          start = paste0(format(max(raw$Date, na.rm = TRUE), "%Y"), "-01-01"),
          end = format(max(raw$Date, na.rm = TRUE), "%Y-%m-%d"),
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
      div(
        class = "dashboard-scroll",
        style = "overflow-y: auto; min-height: 0; flex: 1 1 auto; padding: 1rem;",
        layout_column_wrap(
          width = 1/3,
        value_box(
          title = "Total Revenue",
          value = withSpinner(textOutput("total_revenue"), type = 4, size = 0.8),
          showcase = bsicons::bs_icon("currency-dollar", size = "2rem")
        ),
        value_box(
          title = "Total Boxes Shipped",
          value = withSpinner(textOutput("total_boxes"), type = 4, size = 0.8),
          showcase = bsicons::bs_icon("box-seam", size = "2rem")
        ),
        value_box(
          title = "Active Sales Reps",
          value = withSpinner(textOutput("active_reps"), type = 4, size = 0.8),
          showcase = bsicons::bs_icon("people", size = "2rem")
        ),
        value_box(
          title = "Avg Revenue (Filtered)",
          value = withSpinner(textOutput("avg_revenue"), type = 4, size = 0.8),
          showcase = bsicons::bs_icon("calculator", size = "2rem")
        ),
        value_box(
          title = "Year-over-Year Revenue",
          value = withSpinner(textOutput("yoy_revenue"), type = 4, size = 0.8),
          showcase = bsicons::bs_icon("graph-up-arrow", size = "2rem")
        ),
        value_box(
          title = "Month-over-Month Revenue",
          value = withSpinner(textOutput("mom_revenue"), type = 4, size = 0.8),
          showcase = bsicons::bs_icon("bar-chart-line", size = "2rem")
        )
      ),
      layout_columns(
        card(
          card_header("Revenue by Product"),
          withSpinner(plotlyOutput("pie_product", height = HEIGHT_PIE_PX), type = 4, proxy.height = HEIGHT_PIE_PX),
          full_screen = TRUE,
          style = "min-height: 620px;"
        ),
        card(
          card_header("Sales Rep Leaderboard"),
          withSpinner(DTOutput("leaderboard_table"), type = 4, proxy.height = HEIGHT_LEADERBOARD_PX),
          full_screen = TRUE,
          style = "min-height: 620px;"
        ),
        col_widths = c(5, 7)
      ),
      card(
        card_header("Revenue Trend — Top 5 Sales Reps"),
        withSpinner(plotlyOutput("revenue_trend", height = HEIGHT_TREND_PX), type = 4, proxy.height = HEIGHT_TREND_PX),
        full_screen = TRUE,
        style = "min-height: 620px;"
      )
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

  # For YoY/MoM: country + product only (no date filter)
  non_date_filtered <- reactive({
    d <- raw
    if (length(input$country) > 0) d <- d %>% filter(Country %in% input$country)
    if (length(input$product) > 0) d <- d %>% filter(Product %in% input$product)
    d
  })

  # Value boxes (use format_utils to avoid digits=0)
  output$total_revenue <- renderText({
    format_currency(sum(filtered()$Amount))
  })
  output$total_boxes <- renderText({
    format_int(sum(filtered()$Boxes.Shipped, na.rm = TRUE))
  })
  output$active_reps <- renderText({
    format_int(n_distinct(filtered()$Sales.Person))
  })
  output$avg_revenue <- renderText({
    d <- filtered()
    if (nrow(d) == 0) return("$0")
    format_currency(mean(d$Amount))
  })
  output$yoy_revenue <- renderText(compute_yoy(non_date_filtered()))
  output$mom_revenue <- renderText(compute_mom(non_date_filtered()))

  # Pie chart: revenue by product (filtered)
  output$pie_product <- renderPlotly({
    build_pie_product(filtered())
  })

  # Leaderboard table (modular builder)
  output$leaderboard_table <- renderDT({
    datatable(
      build_leaderboard_df(filtered()),
      options = list(dom = "tip", pageLength = 15),
      rownames = FALSE
    )
  })

  # Revenue trend (modular builder)
  output$revenue_trend <- renderPlotly({
    build_revenue_trend(filtered())
  })
}

shinyApp(ui, server)
