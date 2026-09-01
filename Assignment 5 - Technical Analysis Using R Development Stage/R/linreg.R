# Simple linear regression over the source subset specified by the assignment.

linreg <- function(regressionSource, regressionLength, regressionOffset) {
  n <- length(regressionSource)

  if (length(regressionLength) != 1 || is.na(regressionLength) || regressionLength < 1 || regressionLength != as.integer(regressionLength)) {
    stop("regressionLength must be a positive integer", call. = FALSE)
  }
  if (length(regressionOffset) != 1 || is.na(regressionOffset) || regressionOffset < 0 || regressionOffset != as.integer(regressionOffset)) {
    stop("regressionOffset must be a non-negative integer", call. = FALSE)
  }

  if (regressionLength > n) {
    stop(
      "regressionLength cannot be greater than the number of elements in regressionSource",
      call. = FALSE
    )
  }
  if (regressionOffset >= regressionLength) {
    stop("regressionOffset must be less than regressionLength", call. = FALSE)
  }
  if (regressionLength == 1) {
    stop("regressionLength must be at least 2 for linear regression", call. = FALSE)
  }

  start_index <- max(1, n - regressionLength + regressionOffset)
  end_index <- min(n, n - regressionOffset)
  source_subset <- regressionSource[start_index:end_index]

  index_values <- seq_len(length(source_subset))
  sum_index <- sum(index_values)
  sum_source <- sum(source_subset)
  mean_index <- sum_index / length(index_values)
  mean_source <- sum_source / length(source_subset)

  numerator <- sum((index_values - mean_index) * (source_subset - mean_source))
  denominator <- sum((index_values - mean_index)^2)
  slope <- numerator / denominator
  intercept <- mean_source - slope * mean_index
  predicted_values <- slope * index_values + intercept

  list(
    slope = slope,
    intercept = intercept,
    predicted_values = predicted_values
  )
}
