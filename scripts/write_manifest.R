#!/usr/bin/env Rscript
# Regenerate manifest.json with full R package metadata for Posit Connect.
# Run from project root: Rscript scripts/write_manifest.R
# Or in R: setwd("path/to/cocoaboard-visualisation-R"); source("scripts/write_manifest.R")

# Ensure we're in project root (directory containing app.R)
if (!file.exists("app.R")) {
  if (file.exists("../app.R")) setwd("..") else stop("Run from project root (directory containing app.R)")
}

if (!requireNamespace("rsconnect", quietly = TRUE)) {
  install.packages("rsconnect", repos = "https://cloud.r-project.org")
}
rsconnect::writeManifest(
  appDir = ".",
  appFiles = c("app.R", "data/raw/Chocolate_Sales.csv"),
  appPrimaryDoc = "app.R",
  appMode = "shiny"
)
message("manifest.json updated. Commit and push if deploying to Posit Connect.")
