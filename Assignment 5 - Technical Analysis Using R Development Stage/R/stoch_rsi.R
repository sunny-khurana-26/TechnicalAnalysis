# Stochastic RSI (StochRSI). %K is the StochRSI and %D is its 3-day SMA.
# The function accepts d_period so the assignment's configurable signature is preserved.
# Local fallbacks make this script sourceable independently.

if (!exists("sma", mode = "function")) {
  sma <- function(data, period) {
    if (length(data) < period) {
      stop("Data length should be greater than or equal to the period", call. = FALSE)
    }
    sma_values <- numeric(length(data) - period + 1)
    for (i in seq_len(length(sma_values))) {
      sma_values[i] <- sum(data[i:(i + period - 1)]) / period
    }
    sma_values
  }
}

if (!exists("rsi", mode = "function")) {
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
}

stoch_rsi <- function(data, period, k_period, d_period) {
  periods <- c(period, k_period, d_period)
  if (length(periods) != 3 || any(is.na(periods)) || any(periods < 1) || any(periods != as.integer(periods))) {
    stop("period, k_period, and d_period must be positive integers", call. = FALSE)
  }
  rsi_values <- rsi(data, period)
  valid_rsi <- rsi_values[!is.na(rsi_values)]
  if (length(valid_rsi) < k_period) {
    stop("not enough valid RSI values for k_period", call. = FALSE)
  }
  min_rsi <- min(valid_rsi)
  max_rsi <- max(valid_rsi)

  k_values <- rep(NA_real_, length(rsi_values))
  if (max_rsi != min_rsi) {
    valid_index <- !is.na(rsi_values)
    k_values[valid_index] <- (rsi_values[valid_index] - min_rsi) / (max_rsi - min_rsi)
  } else {
    k_values[!is.na(rsi_values)] <- 0
  }

  k_line <- sma(k_values, k_period)
  d_line <- sma(k_line, d_period)

  list(k_line = k_line, d_line = d_line)
}
