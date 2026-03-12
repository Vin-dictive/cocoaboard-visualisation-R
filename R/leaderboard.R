# Leaderboard table data — build dataframe for Sales Rep Leaderboard (and summary row).
# Uses format_utils to avoid invalid digits=0.

build_leaderboard_df <- function(d) {
  if (is.null(d) || nrow(d) == 0) {
    return(data.frame(
      Rank = character(),
      `Sales Rep` = character(),
      Revenue = character(),
      Transactions = integer(),
      Boxes = character(),
      `Avg Deal` = character(),
      `Rev Share` = character(),
      check.names = FALSE
    ))
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
      `Avg Deal` = format_currency(Revenue / Transactions),
      `Rev Share` = format_pct(Revenue / total_rev * 100),
      Revenue = format_currency(Revenue),
      Boxes = format_int(Boxes)
    ) %>%
    select(Rank, `Sales Rep` = Sales.Person, Revenue, Transactions, Boxes, `Avg Deal`, `Rev Share`)
  summary_row <- data.frame(
    Rank = "",
    `Sales Rep` = "AVERAGE / TOTAL",
    Revenue = format_currency(total_rev),
    Transactions = nrow(d),
    Boxes = format_int(sum(d$Boxes.Shipped, na.rm = TRUE)),
    `Avg Deal` = format_currency(mean(d$Amount)),
    `Rev Share` = "100.0%",
    check.names = FALSE
  )
  rbind(lb, summary_row)
}
