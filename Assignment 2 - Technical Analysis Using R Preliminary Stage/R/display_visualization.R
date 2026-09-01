# Display and visualization utilities. Run from the repository root.
source(file.path("R", "analysis.R"))

print_stock_data <- function(stock_data, rows = 6) {
  for (symbol in names(stock_data)) {
    cat("\n---", symbol, "---\n")
    print(utils::head(stock_data[[symbol]], rows))
  }
}

summary_table <- function(stock_data, statistics) {
  do.call(rbind, lapply(names(stock_data), function(symbol) {
    s <- statistics[[symbol]]
    data.frame(Symbol = symbol, Mean = s$mean, Mode = s$mode, Median = s$median,
               StandardDeviation = s$standard_deviation,
               LatestMovingAverage = tail(stats::na.omit(s$moving_average), 1))
  }))
}

plot_stock_data <- function(stock_data, statistics, output_file = "report-assets/closing_prices.png") {
  dir.create(dirname(output_file), showWarnings = FALSE, recursive = TRUE)
  png(output_file, width = 1200, height = 700, res = 120)
  on.exit(dev.off(), add = TRUE)
  cols <- c("#1F4D78", "#C27C0E", "#497A5A", "#9B1C1C")
  all_values <- unlist(lapply(seq_along(stock_data), function(i) {
    c(stock_data[[i]]$Adjusted, statistics[[names(stock_data)[i]]]$moving_average)
  }), use.names = FALSE)
  y_limits <- range(all_values, na.rm = TRUE, finite = TRUE)
  first <- TRUE
  for (i in seq_along(stock_data)) {
    symbol <- names(stock_data)[i]
    x <- stock_data[[symbol]]
    if (first) {
      plot(x$Date, x$Adjusted, type = "l", lwd = 2, col = cols[i],
           xlab = "Date", ylab = "Adjusted close",
           main = "Deterministic sample portfolio", ylim = y_limits)
      first <- FALSE
    } else lines(x$Date, x$Adjusted, lwd = 2, col = cols[i])
    lines(x$Date, statistics[[symbol]]$moving_average, lwd = 1.5,
          lty = 2, col = cols[i])
  }
  legend("topleft", legend = c(names(stock_data), paste(names(stock_data), "5-day MA")),
         col = c(cols[seq_along(stock_data)], cols[seq_along(stock_data)]),
         lty = c(rep(1, length(stock_data)), rep(2, length(stock_data))), bty = "n")
}

stock_data <- load_stock_data(source = "sample")
stats <- calculate_portfolio_statistics(stock_data)
print_stock_data(stock_data)
print(summary_table(stock_data, stats), row.names = FALSE)
plot_stock_data(stock_data, stats)
