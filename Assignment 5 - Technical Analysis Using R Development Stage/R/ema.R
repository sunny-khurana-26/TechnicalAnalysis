# Exponential Moving Average (EMA)
# The assignment specifies the first observation as the seed value.

ema <- function(data, period) {
  if (length(period) != 1 || is.na(period) || period < 1 || period != as.integer(period)) {
    stop("period must be a positive integer", call. = FALSE)
  }
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
