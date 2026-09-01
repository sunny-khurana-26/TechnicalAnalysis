# Deterministic base-R test runner. Run from the assignment directory with:
#   Rscript tests/test_indicators.R

file_arg <- grep("^--file=", commandArgs(), value = TRUE)
script_path <- if (length(file_arg) == 1) sub("^--file=", "", file_arg) else file.path("tests", "test_indicators.R")
root <- dirname(dirname(normalizePath(script_path, mustWork = FALSE)))

source(file.path(root, "R", "sma.R"))
source(file.path(root, "R", "ema.R"))
source(file.path(root, "R", "macd.R"))
source(file.path(root, "R", "stdev.R"))
source(file.path(root, "R", "linreg.R"))
source(file.path(root, "R", "rsi.R"))
source(file.path(root, "R", "stoch_rsi.R"))
source(file.path(root, "R", "crossover.R"))
source(file.path(root, "R", "crossunder.R"))
source(file.path(root, "R", "data_utils.R"))

expect_error <- function(expression, expected_message) {
  observed <- tryCatch(
    {
      force(expression)
      ""
    },
    error = function(error) conditionMessage(error)
  )
  stopifnot(identical(observed, expected_message))
}

sample_data <- c(10, 12, 15, 20, 18, 22, 25, 24, 21)
stopifnot(all.equal(sma(sample_data, 3), c(12.3333333333, 15.6666666667, 17.6666666667, 20, 21.6666666667, 23.6666666667, 23.3333333333), tolerance = 1e-9))
stopifnot(all.equal(ema(sample_data, 3), c(10, 11, 13, 16.5, 17.25, 19.625, 22.3125, 23.15625, 22.078125), tolerance = 1e-9))

macd_result <- macd(c(100, 105, 110, 115, 120, 125, 130), 3, 5, 2)
stopifnot(identical(names(macd_result), c("macd_line", "signal_line", "histogram")))
stopifnot(all.equal(macd_result$macd_line, c(0, 0.8333333333, 1.8055555556, 2.6620370370, 3.3371913580, 3.8393775720, 4.2002100480), tolerance = 1e-9))
stopifnot(all.equal(stdev(sample_data), 4.9466287310, tolerance = 1e-9))

regression_result <- linreg(c(1, 3, 2, 5, 4, 6), 5, 1)
stopifnot(all.equal(regression_result$slope, 0.6, tolerance = 1e-12))
stopifnot(all.equal(regression_result$intercept, 2, tolerance = 1e-12))
stopifnot(all.equal(regression_result$predicted_values, c(2.6, 3.2, 3.8, 4.4), tolerance = 1e-12))

rsi_data <- c(45, 50, 48, 55, 52, 49, 58, 60, 65, 62)
rsi_result <- rsi(rsi_data, 5)
stopifnot(length(rsi_result) == length(rsi_data), sum(is.na(rsi_result)) == 5)
stopifnot(all.equal(rsi_result[6:10], c(50.5263157895, 68.9256198347, 71.8352059925, 78.2107931909, 66.8596640607), tolerance = 1e-9))

# Supplied PDF example call, recorded exactly. Its ten observations are shorter
# than the requested RSI period, so the implementation reports that limitation.
data <- c(45, 50, 48, 55, 52, 49, 58, 60, 65, 62)
pdf_stoch_call <- tryCatch(
  stoch_rsi_result <- stoch_rsi(data, period = 14, k_period = 3, d_period = 3),
  error = function(error) conditionMessage(error)
)
stopifnot(identical(pdf_stoch_call, "data must contain more observations than period"))

stoch_result <- stoch_rsi(c(45, 50, 48, 55, 52, 49, 58, 60, 65, 62, 66, 64, 68, 70, 67, 71, 69, 72, 74, 73, 75, 76, 74, 77, 78), 5, 3, 3)
stopifnot(identical(names(stoch_result), c("k_line", "d_line")))
stopifnot(length(stoch_result$k_line) == 23, length(stoch_result$d_line) == 21)

arr1 <- c(10, 12, 15, 20, 18, 22, 25, 24, 21)
arr2 <- c(18, 20, 22, 18, 15, 12, 10, 11, 13)
stopifnot(identical(crossover(arr1, arr2), c("None", "None", "None", "Up", "None", "None", "None", "None", "None")))
stopifnot(identical(crossunder(arr1, arr2), c("None", "False", "False", "False", "False", "False", "False", "False", "False")))

expect_error(sma(c(1, 2), 3), "Data length should be greater than or equal to the period")
expect_error(linreg(c(1, 2), 3, 0), "regressionLength cannot be greater than the number of elements in regressionSource")
expect_error(linreg(c(1, 2, 3), 2, 2), "regressionOffset must be less than regressionLength")
expect_error(crossover(c(1), c(1, 2)), "Both arrays should have the same length")
expect_error(crossunder(c(1), c(1, 2)), "Both arrays should have the same length")
expect_error(stdev(numeric(0)), "data must contain at least one value")
expect_error(linreg(c(1, 2), 1, 0), "regressionLength must be at least 2 for linear regression")
stopifnot(all.equal(rsi(rep(10, 8), 3)[4:8], rep(50, 5)))

stock_frames <- load_stock_data(file.path(root, "data", "stock_data.csv"))
stopifnot(identical(sort(names(stock_frames)), c("AAPL", "MSFT")))
stopifnot(all(c("date", "open", "high", "low", "close", "volume") %in% names(stock_frames$AAPL)))
stopifnot(identical(unique(stock_frames$AAPL$data_source), "local_reproducible_fallback"))
filtered <- filter_market_data(
  stock_frames$MSFT,
  "2003-08-18",
  "2003-08-29",
  time_frame = "daily",
  data_source = "local_reproducible_fallback"
)
stopifnot(nrow(filtered) == 10)
weekly <- filter_market_data(stock_frames$MSFT, "2003-08-18", "2003-08-29", time_frame = "weekly")
stopifnot(nrow(weekly) == 2, all(weekly$time_frame == "weekly"))
monthly <- filter_market_data(stock_frames$MSFT, "2003-08-01", "2003-08-31", time_frame = "monthly")
stopifnot(nrow(monthly) == 1, monthly$open[1] == 25.88, monthly$close[1] == 26.52)
stopifnot(nrow(filter_market_data(stock_frames$MSFT, data_source = "not_a_source")) == 0)
indicator_matches <- filter_stocks_by_indicator(stock_frames, indicator = "sma", period = 3, operator = ">", threshold = 20)
stopifnot(nrow(indicator_matches) == 1, identical(indicator_matches$symbol, "MSFT"), indicator_matches$indicator_value[1] > 20)
rule_data <- add_trading_rule(filtered, 3, 5)
stopifnot(all(rule_data$signal %in% c("Buy", "Sell", "Hold")))

cat("PASS: 9 indicators, required errors, OHLCV frames, time-frame/data-source filters, indicator stock filter, and trading rule.\n")
