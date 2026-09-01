# Moving Average Convergence Divergence (MACD)
# A local EMA fallback keeps this script sourceable on its own. When ema.R is
# sourced first, macd() uses that same required ema() implementation.

if (!exists("ema", mode = "function")) {
  ema <- function(data, period) {
    multiplier <- 2 / (period + 1)
    ema_values <- numeric(length(data))
    for (i in seq_along(data)) {
      if (i == 1) {
        ema_values[i] <- data[i]
      } else {
        ema_values[i] <- (data[i] - ema_values[i - 1]) * multiplier + ema_values[i - 1]
      }
    }
    ema_values
  }
}

macd <- function(data, short_period, long_period, signal_period) {
  periods <- c(short_period, long_period, signal_period)
  if (length(periods) != 3 || any(is.na(periods)) || any(periods < 1) || any(periods != as.integer(periods))) {
    stop("periods must be positive integers", call. = FALSE)
  }
  short_ema <- ema(data, short_period)
  long_ema <- ema(data, long_period)
  macd_line <- short_ema - long_ema
  signal_line <- ema(macd_line, signal_period)
  histogram <- macd_line - signal_line

  list(
    macd_line = macd_line,
    signal_line = signal_line,
    histogram = histogram
  )
}
