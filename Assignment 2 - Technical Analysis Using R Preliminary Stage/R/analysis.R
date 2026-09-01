# BDA400 Assignment 2 — Technical Analysis Using R, Preliminary Stage
# Network-free by default: use source = "sample" for a deterministic run.

mode_value <- function(x) {
  x <- x[!is.na(x)]
  if (!length(x)) return(NA_real_)
  counts <- table(x)
  as.numeric(names(counts)[counts == max(counts)][1])
}

load_stock_data <- function(portfolio_file = "portfolio.txt", source = c("sample", "yahoo", "auto"), sample_dir = "data") {
  source <- match.arg(source)
  symbols <- toupper(trimws(readLines(portfolio_file, warn = FALSE)))
  symbols <- symbols[nzchar(symbols)]
  if (!length(symbols)) stop("portfolio.txt contains no symbols")
  result <- setNames(vector("list", length(symbols)), symbols)
  for (symbol in symbols) {
    sample_file <- file.path(sample_dir, paste0(symbol, "_sample.csv"))
    if (source == "sample" || (source == "auto" && file.exists(sample_file))) {
      if (!file.exists(sample_file)) stop("Missing deterministic sample file: ", sample_file)
      df <- read.csv(sample_file, stringsAsFactors = FALSE)
      df$Date <- as.Date(df$Date)
      result[[symbol]] <- df
    } else {
      if (!requireNamespace("quantmod", quietly = TRUE)) stop("Install quantmod before Yahoo loading")
      xt <- quantmod::getSymbols(symbol, src = "yahoo", auto.assign = FALSE)
      df <- data.frame(Date = as.Date(zoo::index(xt)), as.data.frame(xt), check.names = FALSE)
      names(df) <- sub(paste0("^", symbol, "."), "", names(df))
      result[[symbol]] <- df
    }
  }
  result
}

calculate_statistics <- function(stock_df, moving_average_window = 5) {
  if (!"Adjusted" %in% names(stock_df)) stop("Input must contain an Adjusted column")
  prices <- as.numeric(stock_df$Adjusted)
  ma <- rep(NA_real_, length(prices))
  if (length(prices) >= moving_average_window) {
    ma[moving_average_window:length(prices)] <- stats::filter(prices, rep(1 / moving_average_window, moving_average_window), sides = 1)[moving_average_window:length(prices)]
  }
  list(
    moving_average_window = moving_average_window,
    moving_average = ma,
    mean = mean(prices, na.rm = TRUE),
    mode = mode_value(prices),
    median = median(prices, na.rm = TRUE),
    standard_deviation = stats::sd(prices, na.rm = TRUE)
  )
}

calculate_portfolio_statistics <- function(stock_data, moving_average_window = 5) {
  lapply(stock_data, calculate_statistics, moving_average_window = moving_average_window)
}
