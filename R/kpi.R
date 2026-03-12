# KPI calculations: YoY and MoM revenue change.

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
