# CocoaBoard (R Shiny)

Chocolate Sales Dashboard — R/Shiny port of the visualization components from [DSCI-532_2026_8_cocoaboard](https://github.com/UBC-MDS/DSCI-532_2026_8_cocoaboard).


## Features

- **Filters:** Date range, Country (multi), Product (multi)
- **Value boxes:** Total Revenue, Total Boxes Shipped, Active Sales Reps, Avg Revenue, YoY Revenue, MoM Revenue (with loading spinners)
- **Revenue by Product:** Pie chart (filtered by date, country, product)
- **Leaderboard table:** Rank, Revenue, Transactions, Boxes, Avg Deal, Rev Share + summary row
- **Revenue trend:** Line chart for top 5 sales reps by month

## Deployed App

- **Stable (main):** [https://019cdf39-321a-e2fd-813d-f826a07acc26.share.connect.posit.cloud](https://019cdf39-321a-e2fd-813d-f826a07acc26.share.connect.posit.cloud)

## Dataset

The dashboard uses the **Chocolate Sales** dataset from Kaggle:

- **Source:** [Chocolate Sales | Kaggle](https://www.kaggle.com/datasets/saidaminsaidaxmadov/chocolate-sales)

## Run locally

```r
# Install dependencies (once)
install.packages(c("shiny", "bslib", "ggplot2", "dplyr", "tidyr", "plotly", "DT", "lubridate", "bsicons", "scales", "shinycssloaders"))

# From project root (cocoaboard-visualisation-R/)
shiny::runApp()
```

Or in RStudio: open `cocoaboard.Rproj`, then run the app (e.g. Run App on `app.R`).

## Deploy to Posit Connect Cloud

Connect Cloud needs a **generated** `manifest.json` (from `rsconnect::writeManifest()`)