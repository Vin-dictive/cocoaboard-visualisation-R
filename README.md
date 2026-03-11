# CocoaBoard (R Shiny)

Chocolate Sales Dashboard — R/Shiny port of the visualization components from [DSCI-532_2026_8_cocoaboard](https://github.com/UBC-MDS/DSCI-532_2026_8_cocoaboard). No AI chat tab; dashboard only (filters, KPIs, map, leaderboard, revenue trend).

**Deployed app:** [Add your Posit Connect URL here after deployment, and add the same URL to the repository **About** section (Settings → About → Website).]

## Features

- **Filters:** Date range, Country (multi), Product (multi)
- **Value boxes:** Total Revenue, Total Boxes Shipped, Active Sales Reps, Avg Revenue, YoY Revenue, MoM Revenue
- **Choropleth map:** Sales by country (Plotly)
- **Leaderboard table:** Rank, Revenue, Transactions, Boxes, Avg Deal, Rev Share + summary row
- **Revenue trend:** Line chart for top 5 sales reps by month

## Data

- **Source:** `data/raw/Chocolate_Sales.csv` (same as the Python CocoaBoard project).
- Ensure the file exists at `data/raw/Chocolate_Sales.csv` relative to the project root.

## Run locally

```r
# Install dependencies (once)
install.packages(c("shiny", "bslib", "ggplot2", "dplyr", "tidyr", "plotly", "DT", "lubridate", "bsicons", "scales"))

# From project root (cocoaboard-visualisation-R/)
shiny::runApp()
```

Or in RStudio: open `cocoaboard.Rproj`, then run the app (e.g. Run App on `app.R`).

## Deploy to Posit Cloud Connect

1. Push this project to a Git repository (GitHub, GitLab, etc.). Ensure **`manifest.json`** is in the repo root (same folder as `app.R`). Connect requires this file for git-backed deployment.
2. In [Posit Cloud](https://posit.cloud/), go to Connect and create a new content → **Shiny Application**.
3. Connect the repo and set:
   - **Subdirectory:** leave blank (app is at root).
   - **Application path:** `app.R` (or leave default if it detects `app.R`).
4. Ensure the Connect server has access to the repo and that `data/raw/Chocolate_Sales.csv` is committed.
5. Deploy. Connect will install R package dependencies from `library()` calls in `app.R`.

### manifest.json

A **`manifest.json`** is included in the project root so Posit Connect can discover and deploy the app (“A manifest.json file was not found” is avoided). It declares `appmode: shiny` and `entrypoint: app.R`.

To regenerate a full manifest (including R package metadata) from your machine, run from the project root:

```r
install.packages("rsconnect")
rsconnect::writeManifest(appDir = ".", appPrimaryDoc = "app.R", appMode = "shiny")
```

Then commit the updated `manifest.json` if you want Connect to use your exact package snapshot.

### Optional: lock dependencies with renv

```r
# In project root
install.packages("renv")
renv::init()
# Run app, then:
renv::snapshot()
```

Commit `renv.lock` and `renv/` so Connect uses the same package versions.

## Project structure

```
cocoaboard-visualisation-R/
├── app.R              # Shiny app (single file)
├── manifest.json      # Posit Connect deployment manifest (required for git-backed deploy)
├── cocoaboard.Rproj   # R project
├── data/
│   └── raw/
│       └── Chocolate_Sales.csv
└── README.md
```
