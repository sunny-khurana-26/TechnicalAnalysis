# Simple Moving Average (SMA)
# Core R only; the output has one value per complete period-sized window.

sma <- function(data, period) {
  if (length(period) != 1 || is.na(period) || period < 1 || period != as.integer(period)) {
    stop("period must be a positive integer", call. = FALSE)
  }
  if (length(data) < period) {
    stop("Data length should be greater than or equal to the period", call. = FALSE)
  }

  sma_values <- numeric(length(data) - period + 1)
  for (i in seq_len(length(sma_values))) {
    current_window <- data[i:(i + period - 1)]
    sma_values[i] <- sum(current_window) / period
  }

  sma_values
}
