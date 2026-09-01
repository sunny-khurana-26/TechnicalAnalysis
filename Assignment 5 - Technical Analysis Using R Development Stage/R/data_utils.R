# Data frames, time-frame/data-source filters, indicator stock selection, and
# a deterministic moving-average trading rule. Core R only.

LOCAL_FALLBACK_SOURCE <- "local_reproducible_fallback"

prepare_market_data <- function(data) {
  required_columns <- c("symbol", "date", "open", "high", "low", "close", "volume")
  missing_columns <- setdiff(required_columns, names(data))
  if (length(missing_columns) > 0) {
    stop(paste("missing market-data columns:", paste(missing_columns, collapse = ", ")), call. = FALSE)
  }
  data$date <- as.Date(data$date)
  if (!"data_source" %in% names(data)) {
    data$data_source <- rep("unspecified", nrow(data))
  }
  if (!"time_frame" %in% names(data)) {
    data$time_frame <- rep("daily", nrow(data))
  }
  data$data_source <- as.character(data$data_source)
  data$time_frame <- as.character(data$time_frame)
  data[order(data$symbol, data$date), , drop = FALSE]
}

normalize_time_frame <- function(time_frame) {
  if (length(time_frame) != 1 || is.na(time_frame)) {
    stop("time_frame must be one of: daily, weekly, monthly", call. = FALSE)
  }
  value <- tolower(as.character(time_frame))
  aliases <- c(day = "daily", week = "weekly", month = "monthly")
  if (value %in% names(aliases)) {
    value <- aliases[[value]]
  }
  if (!value %in% c("daily", "weekly", "monthly")) {
    stop("time_frame must be one of: daily, weekly, monthly", call. = FALSE)
  }
  value
}

aggregate_market_data <- function(data, time_frame = "daily") {
  data <- prepare_market_data(data)
  requested_frame <- normalize_time_frame(time_frame)
  if (requested_frame == "daily" || nrow(data) == 0) {
    data$time_frame <- rep(requested_frame, nrow(data))
    return(data)
  }

  weekday <- as.POSIXlt(data$date)$wday
  bucket_start <- if (requested_frame == "weekly") {
    data$date - ((weekday + 6L) %% 7L)
  } else {
    as.Date(format(data$date, "%Y-%m-01"))
  }
  group_key <- paste(data$symbol, data$data_source, bucket_start, sep = "\r")
  groups <- split(seq_len(nrow(data)), group_key, drop = TRUE)
  aggregated <- lapply(groups, function(index) {
    rows <- data[index, , drop = FALSE]
    rows <- rows[order(rows$date), , drop = FALSE]
    data.frame(
      symbol = rows$symbol[1],
      date = bucket_start[index[1]],
      open = rows$open[1],
      high = max(rows$high),
      low = min(rows$low),
      close = rows$close[nrow(rows)],
      volume = sum(rows$volume),
      data_source = rows$data_source[1],
      time_frame = requested_frame,
      stringsAsFactors = FALSE
    )
  })
  result <- do.call(rbind, aggregated)
  rownames(result) <- NULL
  result[order(result$symbol, result$date), , drop = FALSE]
}

load_stock_data <- function(path = file.path("data", "stock_data.csv")) {
  prices <- read.csv(path, stringsAsFactors = FALSE)
  prices <- prepare_market_data(prices)
  if (nrow(prices) > 0 && all(prices$data_source == "unspecified")) {
    prices$data_source <- LOCAL_FALLBACK_SOURCE
  }
  prices$time_frame <- "daily"
  split(prices, prices$symbol)
}

filter_market_data <- function(data, start_date = NULL, end_date = NULL, symbol = NULL,
                               time_frame = "daily", data_source = NULL) {
  if (is.list(data) && !is.data.frame(data)) {
    filtered_frames <- lapply(
      data,
      filter_market_data,
      start_date = start_date,
      end_date = end_date,
      symbol = symbol,
      time_frame = time_frame,
      data_source = data_source
    )
    names(filtered_frames) <- names(data)
    return(filtered_frames)
  }

  filtered <- prepare_market_data(data)
  if (!is.null(symbol)) {
    filtered <- filtered[filtered$symbol %in% symbol, , drop = FALSE]
  }
  if (!is.null(data_source)) {
    filtered <- filtered[filtered$data_source %in% data_source, , drop = FALSE]
  }
  if (!is.null(start_date)) {
    filtered <- filtered[filtered$date >= as.Date(start_date), , drop = FALSE]
  }
  if (!is.null(end_date)) {
    filtered <- filtered[filtered$date <= as.Date(end_date), , drop = FALSE]
  }
  aggregate_market_data(filtered, time_frame)
}

compare_indicator_value <- function(value, operator, threshold) {
  if (operator == ">") return(value > threshold)
  if (operator == ">=") return(value >= threshold)
  if (operator == "<") return(value < threshold)
  if (operator == "<=") return(value <= threshold)
  if (operator == "==") return(value == threshold)
  value != threshold
}

filter_stocks_by_indicator <- function(data, indicator = "sma", period = 5, operator = ">",
                                       threshold, start_date = NULL, end_date = NULL,
                                       time_frame = "daily", data_source = NULL) {
  if (!indicator %in% c("sma", "ema", "rsi", "stdev")) {
    stop("indicator must be one of: sma, ema, rsi, stdev", call. = FALSE)
  }
  if (!operator %in% c(">", ">=", "<", "<=", "==", "!=")) {
    stop("operator must be one of: >, >=, <, <=, ==, !=", call. = FALSE)
  }
  if (length(threshold) != 1 || is.na(threshold)) {
    stop("threshold must be one numeric value", call. = FALSE)
  }
  frames <- if (is.data.frame(data)) list(data) else data
  if (!is.list(frames)) {
    stop("data must be a market-data frame or list of frames", call. = FALSE)
  }

  matches <- lapply(frames, function(frame) {
    filtered <- filter_market_data(frame, start_date, end_date, time_frame = time_frame, data_source = data_source)
    if (nrow(filtered) == 0) return(NULL)
    values <- if (indicator == "sma") {
      tail(sma(filtered$close, period), 1)
    } else if (indicator == "ema") {
      tail(ema(filtered$close, period), 1)
    } else if (indicator == "rsi") {
      valid <- rsi(filtered$close, period)
      valid <- valid[!is.na(valid)]
      if (length(valid) == 0) return(NULL)
      tail(valid, 1)
    } else {
      stdev(filtered$close)
    }
    if (length(values) != 1 || is.na(values) || !compare_indicator_value(values, operator, threshold)) {
      return(NULL)
    }
    data.frame(
      symbol = as.character(filtered$symbol[1]),
      data_source = as.character(filtered$data_source[1]),
      time_frame = as.character(filtered$time_frame[1]),
      indicator = indicator,
      indicator_value = as.numeric(values),
      operator = operator,
      threshold = as.numeric(threshold),
      observations = nrow(filtered),
      stringsAsFactors = FALSE
    )
  })
  matches <- Filter(Negate(is.null), matches)
  if (length(matches) == 0) {
    return(data.frame(
      symbol = character(0), data_source = character(0), time_frame = character(0),
      indicator = character(0), indicator_value = numeric(0), operator = character(0),
      threshold = numeric(0), observations = integer(0), stringsAsFactors = FALSE
    ))
  }
  result <- do.call(rbind, matches)
  rownames(result) <- NULL
  result
}

align_sma <- function(values, period) {
  output <- rep(NA_real_, length(values))
  if (length(values) >= period) {
    output[period:length(values)] <- sma(values, period)
  }
  output
}

add_trading_rule <- function(data, short_period = 3, long_period = 5) {
  data$sma_short <- align_sma(data$close, short_period)
  data$sma_long <- align_sma(data$close, long_period)
  data$signal <- "Hold"
  comparable <- !is.na(data$sma_short) & !is.na(data$sma_long)
  data$signal[comparable & data$sma_short > data$sma_long] <- "Buy"
  data$signal[comparable & data$sma_short < data$sma_long] <- "Sell"
  data
}
