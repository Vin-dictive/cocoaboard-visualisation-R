# Format helpers — avoid invalid digits=0 in format() for numeric values.

#' Format a number as currency (integer display, no decimals).
#' Uses round + format to avoid "invalid value 0 for 'digits' argument".
format_currency <- function(x) {
  if (length(x) == 0 || all(is.na(x))) return("$0")
  sprintf("$%s", format(round(as.numeric(x), 0), big.mark = ",", trim = TRUE))
}

#' Format a number as integer with thousands separator.
format_int <- function(x) {
  if (length(x) == 0 || all(is.na(x))) return("0")
  format(round(as.numeric(x), 0), big.mark = ",", trim = TRUE)
}

#' Format a percentage to one decimal place.
format_pct <- function(x) {
  if (length(x) == 0 || all(is.na(x))) return("0%")
  sprintf("%.1f%%", as.numeric(x))
}
