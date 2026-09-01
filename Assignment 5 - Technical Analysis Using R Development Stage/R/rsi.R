# Relative Strength Index (RSI) using Wilder smoothing.

rsi <- function(data, period) {
  if (length(period) != 1 || is.na(period) || period < 1 || period != as.integer(period)) {
    stop("period must be a positive integer", call. = FALSE)
  }
  if (length(data) <= period) {
    stop("data must contain more observations than period", call. = FALSE)
  }
  diff_values <- diff(data)
  gains <- numeric(length(diff_values))
  losses <- numeric(length(diff_values))

  for (i in seq_along(diff_values)) {
    if (diff_values[i] > 0) {
      gains[i] <- diff_values[i]
    } else {
      losses[i] <- abs(diff_values[i])
    }
  }

  avg_gain <- mean(gains[1:period])
  avg_loss <- mean(losses[1:period])
  rsi_values <- rep(NA_real_, length(data))

  if (length(data) > period) {
    for (i in (period + 1):length(data)) {
      avg_gain <- (avg_gain * (period - 1) + gains[i - 1]) / period
      avg_loss <- (avg_loss * (period - 1) + losses[i - 1]) / period
      if (avg_loss == 0 && avg_gain == 0) {
        rsi_values[i] <- 50
      } else if (avg_loss == 0) {
        rsi_values[i] <- 100
      } else {
        rs <- avg_gain / avg_loss
        rsi_values[i] <- 100 - (100 / (1 + rs))
      }
    }
  }

  rsi_values
}
