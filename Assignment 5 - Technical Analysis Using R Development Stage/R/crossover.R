# Crossover signals: Up, Down, or None.

crossover <- function(arr1, arr2) {
  if (length(arr1) != length(arr2)) {
    stop("Both arrays should have the same length", call. = FALSE)
  }

  crossover_signals <- rep("None", length(arr1))
  if (length(arr1) >= 2) {
    for (i in 2:length(arr1)) {
      if (arr1[i] > arr2[i] && arr1[i - 1] <= arr2[i - 1]) {
        crossover_signals[i] <- "Up"
      } else if (arr1[i] < arr2[i] && arr1[i - 1] >= arr2[i - 1]) {
        crossover_signals[i] <- "Down"
      }
    }
  }

  crossover_signals
}
