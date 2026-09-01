# BDA400 Assignment 6 - Technical Analysis using R, Visualization Phase
# Student: Sunny Khurana
#
# This Shiny dashboard retrieves historical OHLCV data from Yahoo Finance with
# quantmod. If Yahoo Finance is unavailable, it uses a deterministic local
# fallback so the dashboard remains inspectable and reproducible offline.
#
# Install once in an R session if needed:
# install.packages(c("shiny", "ggplot2", "quantmod", "TTR"))

# -----------------------------------------------------------------------------
# 1. DATA COLLECTION AND SETUP
# -----------------------------------------------------------------------------

required_packages <- c("shiny", "ggplot2", "quantmod", "TTR", "zoo")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  quietly = TRUE,
  FUN.VALUE = logical(1)
)]

if (length(missing_packages) > 0) {
  stop(
    paste(
      "Install the missing R packages before launching this app:",
      paste(missing_packages, collapse = ", ")
    )
  )
}

library(shiny)
library(ggplot2)
library(quantmod)

# Generate reproducible weekday OHLCV data for offline demonstration.
generate_fallback_data <- function(symbol, from, to) {
  all_dates <- seq.Date(as.Date(from), as.Date(to), by = "day")
  dates <- all_dates[as.integer(format(all_dates, "%u")) <= 5]

  if (length(dates) == 0) {
    stop("The selected date range does not contain a weekday.")
  }

  # The symbol-derived offset makes different symbols visibly distinct while
  # keeping every fallback result deterministic across runs.
  symbol_seed <- sum(utf8ToInt(toupper(symbol)))
  step <- seq_along(dates)
  close_price <- 100 +
    cumsum(0.08 + 0.45 * sin(step / 8 + symbol_seed) +
      0.25 * cos(step / 23 + symbol_seed / 3))
  open_price <- close_price - 0.35 * sin(step / 4 + symbol_seed)
  high_price <- pmax(open_price, close_price) + 0.6 + abs(sin(step / 5))
  low_price <- pmin(open_price, close_price) - 0.6 - abs(cos(step / 7))
  volume <- as.numeric(1000000 + 100000 * abs(sin(step / 6 + symbol_seed)))

  data.frame(
    date = dates,
    Open = round(open_price, 2),
    High = round(high_price, 2),
    Low = round(low_price, 2),
    Close = round(close_price, 2),
    Volume = round(volume),
    stringsAsFactors = FALSE
  )
}

fetch_stock_data <- function(symbol, from, to) {
  normalized_symbol <- toupper(trimws(as.character(symbol)[1]))
  from_date <- as.Date(from)
  to_date <- as.Date(to)
  if (!grepl("^[A-Z0-9.\\-]{1,12}$", normalized_symbol)) {
    return(list(
      data = data.frame(),
      source = "Input validation",
      message = "Enter a valid ticker symbol such as AAPL or MSFT.",
      fallback = FALSE,
      error = TRUE
    ))
  }
  if (is.na(from_date) || is.na(to_date) || from_date >= to_date) {
    return(list(
      data = data.frame(),
      source = "Input validation",
      message = "The start date must be earlier than the end date.",
      fallback = FALSE,
      error = TRUE
    ))
  }

  tryCatch(
    {
      yahoo_data <- suppressWarnings(
        quantmod::getSymbols(
          normalized_symbol,
          src = "yahoo",
          from = from_date,
          to = to_date,
          auto.assign = FALSE,
          warnings = FALSE
        )
      )
      if (NROW(yahoo_data) == 0) {
        stop("Yahoo Finance returned no rows for this ticker and period.")
      }

      result <- data.frame(
        date = as.Date(zoo::index(yahoo_data)),
        Open = as.numeric(quantmod::Op(yahoo_data)),
        High = as.numeric(quantmod::Hi(yahoo_data)),
        Low = as.numeric(quantmod::Lo(yahoo_data)),
        Close = as.numeric(quantmod::Cl(yahoo_data)),
        Volume = as.numeric(quantmod::Vo(yahoo_data)),
        stringsAsFactors = FALSE
      )
      result <- result[stats::complete.cases(result), , drop = FALSE]
      if (nrow(result) == 0) {
        stop("Yahoo Finance returned no complete observations.")
      }

      list(
        data = result,
        source = "Yahoo Finance",
        message = paste("Live Yahoo Finance data loaded for", normalized_symbol),
        fallback = FALSE,
        error = FALSE
      )
    },
    error = function(error) {
      fallback <- generate_fallback_data(normalized_symbol, from, to)
      list(
        data = fallback,
        source = "Deterministic offline fallback",
        message = paste(
          "Yahoo Finance was unavailable:", conditionMessage(error),
          "Showing deterministic offline fallback data instead."
        ),
        fallback = TRUE,
        error = FALSE
      )
    }
  )
}

# Aggregate daily OHLCV observations without requiring an additional calendar
# package. Weekly periods begin on Monday; monthly periods use calendar months.
resample_ohlcv <- function(data, timeframe) {
  if (timeframe == "Daily") {
    return(data)
  }

  if (timeframe == "Weekly") {
    period <- data$date - (as.integer(format(data$date, "%u")) - 1)
  } else {
    period <- as.Date(format(data$date, "%Y-%m-01"))
  }

  groups <- split(seq_len(nrow(data)), period)
  do.call(
    rbind,
    lapply(groups, function(rows) {
      data.frame(
        date = max(data$date[rows]),
        Open = data$Open[rows[1]],
        High = max(data$High[rows], na.rm = TRUE),
        Low = min(data$Low[rows], na.rm = TRUE),
        Close = data$Close[rows[length(rows)]],
        Volume = sum(data$Volume[rows], na.rm = TRUE),
        stringsAsFactors = FALSE
      )
    })
  )
}

add_indicators <- function(data, short_period, long_period) {
  data$MA_short <- as.numeric(TTR::SMA(data$Close, n = short_period))
  data$MA_long <- as.numeric(TTR::SMA(data$Close, n = long_period))
  data$RSI14 <- as.numeric(TTR::RSI(data$Close, n = 14))
  # Use the conventional EMA-based MACD and document the same parameters in
  # README.md and the chart legend.
  macd <- TTR::MACD(data$Close, nFast = 12, nSlow = 26, nSig = 9, maType = "EMA")
  data$MACD <- as.numeric(macd[, "macd"])
  data$MACDSignal <- as.numeric(macd[, "signal"])
  data
}

# RSI and MACD have different units from price. To keep every selected
# indicator as a visible layer on the price chart, map each one into a labeled
# band of the price range. The source values and thresholds remain unchanged;
# only their display coordinates are rescaled.
scale_to_price_band <- function(values, price_min, price_max, band_min, band_max,
                                source_min, source_max) {
  price_span <- price_max - price_min
  source_span <- source_max - source_min
  if (!is.finite(price_span) || price_span <= 0) {
    price_span <- max(abs(price_max), 1)
  }
  if (!is.finite(source_span) || source_span <= 0) {
    result <- rep(price_min + mean(c(band_min, band_max)) * price_span, length(values))
  } else {
    result <- price_min + price_span * (
      band_min + (values - source_min) / source_span * (band_max - band_min)
    )
  }
  result[!is.finite(values)] <- NA_real_
  result
}

add_price_chart_scales <- function(data) {
  price_range <- range(c(data$Low, data$High), na.rm = TRUE, finite = TRUE)
  macd_values <- c(data$MACD, data$MACDSignal)
  macd_limit <- max(abs(macd_values), na.rm = TRUE)
  if (!is.finite(macd_limit) || macd_limit == 0) {
    macd_limit <- 1
  }

  data$RSIOverlay <- scale_to_price_band(
    data$RSI14, price_range[1], price_range[2],
    band_min = 0.03, band_max = 0.24, source_min = 0, source_max = 100
  )
  data$RSI30Band <- scale_to_price_band(
    30, price_range[1], price_range[2],
    band_min = 0.03, band_max = 0.24, source_min = 0, source_max = 100
  )
  data$RSI70Band <- scale_to_price_band(
    70, price_range[1], price_range[2],
    band_min = 0.03, band_max = 0.24, source_min = 0, source_max = 100
  )
  data$MACDOverlay <- scale_to_price_band(
    data$MACD, price_range[1], price_range[2],
    band_min = 0.31, band_max = 0.50,
    source_min = -macd_limit, source_max = macd_limit
  )
  data$MACDSignalOverlay <- scale_to_price_band(
    data$MACDSignal, price_range[1], price_range[2],
    band_min = 0.31, band_max = 0.50,
    source_min = -macd_limit, source_max = macd_limit
  )
  data$MACDZeroBand <- scale_to_price_band(
    0, price_range[1], price_range[2],
    band_min = 0.31, band_max = 0.50,
    source_min = -macd_limit, source_max = macd_limit
  )
  data
}

# -----------------------------------------------------------------------------
# 2. SHINY UI AND STOCK-DATA VISUALIZATION
# -----------------------------------------------------------------------------

default_start <- as.Date("2023-01-01")
default_end <- as.Date("2023-07-01")

ui <- fluidPage(
  tags$head(
    tags$title("Sunny Khurana - Technical Analysis Dashboard"),
    tags$style(HTML("\n      body { background: #f4f7fb; color: #1f2937; }\n      .dashboard-title { color: #12355b; margin-bottom: 0; }\n      .subtitle { color: #64748b; margin-top: 4px; }\n      .control-panel { background: white; border-radius: 10px; padding: 16px; box-shadow: 0 1px 5px rgba(15, 23, 42, .08); }\n      .status-box { border-left: 4px solid #2563eb; background: white; padding: 12px 16px; margin: 12px 0; }\n      .metric { background: white; border-radius: 8px; padding: 10px 14px; margin-bottom: 8px; box-shadow: 0 1px 4px rgba(15, 23, 42, .06); }\n    "))
  ),
  div(
    class = "container-fluid",
    h1(class = "dashboard-title", "Technical Analysis Portfolio Dashboard"),
    p(class = "subtitle", "Sunny Khurana | BDA400 Assignment 6 | Yahoo Finance with offline fallback"),
    sidebarLayout(
      sidebarPanel(
        class = "control-panel",
        textInput("stock_symbol", "Stock symbol", value = "AAPL", width = "100%"),
        dateRangeInput(
          "date_range",
          "Select date range",
          start = default_start,
          end = default_end,
          min = as.Date("2015-01-01"),
          max = Sys.Date()
        ),
        selectInput(
          "time_frame",
          "Time frame",
          choices = c("Daily", "Weekly", "Monthly"),
          selected = "Daily"
        ),
        selectInput(
          "chart_type",
          "Chart type",
          choices = c("Line", "Candlestick", "Area"),
          selected = "Candlestick"
        ),
        numericInput("short_ma_period", "Short moving-average period", value = 20, min = 2, step = 1),
        numericInput("long_ma_period", "Long moving-average period", value = 50, min = 3, step = 1),
        checkboxGroupInput(
          "technical_indicators",
          "Technical indicators",
          choices = c("Moving Averages", "RSI", "MACD"),
          selected = c("Moving Averages", "RSI", "MACD")
        ),
        checkboxInput("show_signals", "Show Buy/Sell/Hold annotations", value = TRUE),
        actionButton("load", "Load / refresh data", class = "btn-primary"),
        br(), br(),
        p(class = "help-block", "The configurable short/long SMA rule is calculated after the selected timeframe is applied. Click Load / refresh data after changing periods. Every generated Buy, Sell, or Hold observation is labelled when annotations are enabled.")
      ),
      mainPanel(
        uiOutput("status"),
        fluidRow(
          column(4, div(class = "metric", strong("Latest close"), br(), textOutput("latest_close", inline = TRUE))),
          column(4, div(class = "metric", strong("Current signal"), br(), textOutput("latest_signal", inline = TRUE))),
          column(4, div(class = "metric", strong("Observations"), br(), textOutput("observation_count", inline = TRUE)))
        ),
        plotOutput("stock_chart", height = "720px"),
        h4("Trading rule"),
        p("Buy when the short-period SMA is above the long-period SMA; Sell when it is below; Hold when either average is not yet available or the averages are equal. The chart labels every generated Buy, Sell, or Hold observation.")
      )
    )
  )
)

# -----------------------------------------------------------------------------
# 3. TECHNICAL-INDICATOR LAYERS AND TRADING RULES / ANNOTATIONS
# -----------------------------------------------------------------------------

server <- function(input, output, session) {
  loaded <- eventReactive(input$load, {
    req(input$stock_symbol, input$date_range)
    requested_long_period <- max(3L, as.integer(input$long_ma_period))
    # A generous day-based warm-up also supports Monthly resampling, where a
    # 50-period average needs substantially more calendar history than 50 days.
    from <- as.Date(input$date_range[1]) - max(150L, requested_long_period * 45L)
    to <- as.Date(input$date_range[2]) + 1
    withProgress(message = "Retrieving stock data", value = 0.2, {
      result <- fetch_stock_data(input$stock_symbol, from, to)
      incProgress(0.8)
      result
    })
  }, ignoreNULL = FALSE)

  prepared_data <- reactive({
    result <- loaded()
    validate(need(!isTRUE(result$error), result$message))
    short_period <- as.integer(input$short_ma_period)
    long_period <- as.integer(input$long_ma_period)
    validate(
      need(is.finite(short_period) && is.finite(long_period), "Enter both moving-average periods."),
      need(short_period >= 2, "The short moving-average period must be at least 2."),
      need(long_period > short_period, "The long moving-average period must be greater than the short period.")
    )
    data <- resample_ohlcv(result$data, input$time_frame)
    validate(need(nrow(data) >= long_period, "Not enough history for the selected long moving-average period."))
    data <- add_indicators(data, short_period, long_period)

    # Calculate indicators and signals while the warm-up rows are still
    # present, then retain only the requested display range.
    data$Signal <- ifelse(
      is.na(data$MA_short) | is.na(data$MA_long),
      "Hold",
      ifelse(data$MA_short > data$MA_long, "Buy", ifelse(data$MA_short < data$MA_long, "Sell", "Hold"))
    )
    data <- data[
      data$date >= as.Date(input$date_range[1]) &
        data$date <= as.Date(input$date_range[2]),
      ,
      drop = FALSE
    ]
    validate(need(nrow(data) >= 2, "Not enough observations in the selected date range."))
    add_price_chart_scales(data)
  })

  output$status <- renderUI({
    result <- loaded()
    div(class = "status-box", strong(result$source), br(), result$message)
  })

  output$latest_close <- renderText({
    data <- prepared_data()
    sprintf("$%.2f", tail(data$Close, 1))
  })

  output$latest_signal <- renderText({
    tail(prepared_data()$Signal, 1)
  })

  output$observation_count <- renderText({
    format(nrow(prepared_data()), big.mark = ",")
  })

  output$stock_chart <- renderPlot({
    data <- prepared_data()
    validate(need(nrow(data) >= 2, "Choose a wider date range to draw the chart."))

    signal_colors <- c(Buy = "#15803d", Sell = "#b91c1c", Hold = "#64748b")
    price_plot <- ggplot(data, aes(x = date))

    if (input$chart_type == "Line") {
      price_plot <- price_plot +
        geom_line(aes(y = Close), color = "#2563eb", linewidth = 0.8)
    } else if (input$chart_type == "Area") {
      price_plot <- price_plot +
        geom_area(aes(y = Close), fill = "#93c5fd", alpha = 0.55) +
        geom_line(aes(y = Close), color = "#1d4ed8", linewidth = 0.7)
    } else {
      price_plot <- price_plot +
        geom_segment(aes(x = date, xend = date, y = Low, yend = High), color = "#334155", linewidth = 0.35) +
        geom_rect(
          aes(
            xmin = date - 0.35,
            xmax = date + 0.35,
            ymin = pmin(Open, Close),
            ymax = pmax(Open, Close),
            fill = Close >= Open
          ),
          color = "#334155",
          linewidth = 0.25
        ) +
        scale_fill_manual(values = c(`TRUE` = "#86efac", `FALSE` = "#fca5a5"), guide = "none")
    }

    if ("Moving Averages" %in% input$technical_indicators) {
      price_plot <- price_plot +
        geom_line(aes(y = MA_short, color = "Short SMA"), linewidth = 0.8, na.rm = TRUE) +
        geom_line(aes(y = MA_long, color = "Long SMA"), linewidth = 0.8, na.rm = TRUE)
    }

    # RSI and MACD are intentionally drawn on this same price chart. Their
    # values are unchanged but are mapped into labeled price-axis bands so
    # their toggles have an immediate, visible effect without distorting the
    # price scale.
    if ("RSI" %in% input$technical_indicators) {
      price_plot <- price_plot +
        geom_line(aes(y = RSIOverlay, color = "RSI (0-100, scaled)"), linewidth = 0.7, na.rm = TRUE) +
        geom_hline(yintercept = data$RSI30Band[1], linetype = "dotted", color = "#0891b2") +
        geom_hline(yintercept = data$RSI70Band[1], linetype = "dotted", color = "#0891b2")
    }

    if ("MACD" %in% input$technical_indicators) {
      price_plot <- price_plot +
        geom_line(aes(y = MACDOverlay, color = "MACD (12/26 EMA)"), linewidth = 0.7, na.rm = TRUE) +
        geom_line(aes(y = MACDSignalOverlay, color = "MACD signal (9 EMA)"), linewidth = 0.7, na.rm = TRUE) +
        geom_hline(yintercept = data$MACDZeroBand[1], linetype = "dotted", color = "#64748b")
    }

    if (isTRUE(input$show_signals)) {
      # The assignment example annotates the filtered observations themselves,
      # so every row receives its generated Buy/Sell/Hold label here.
      price_plot <- price_plot +
        geom_point(aes(y = Close, color = Signal), size = 1.8, alpha = 0.75) +
        geom_text(
          aes(y = Close, label = Signal, color = Signal),
          vjust = -0.9,
          fontface = "bold",
          size = 2.0,
          alpha = 0.85,
          check_overlap = TRUE
        )
    }

    price_plot <- price_plot +
      scale_color_manual(
        values = c(
          signal_colors,
          `Short SMA` = "#f59e0b",
          `Long SMA` = "#7c3aed",
          `RSI (0-100, scaled)` = "#0891b2",
          `MACD (12/26 EMA)` = "#2563eb",
          `MACD signal (9 EMA)` = "#f97316"
        ),
        name = "Price-chart layers"
      ) +
      labs(
        title = paste(toupper(input$stock_symbol), "price and trading signals"),
        subtitle = paste(input$time_frame, "observations | RSI/MACD are rescaled into labeled price-chart bands"),
        x = NULL,
        y = "Price",
        caption = "RSI band: 0-100 with 30/70 guides. MACD band: 12/26 EMA difference with 9 EMA signal and zero guide."
      ) +
      theme_minimal(base_size = 12) +
      theme(
        plot.title = element_text(face = "bold", color = "#12355b"),
        legend.position = "bottom",
        panel.grid.minor = element_blank()
      )

    print(price_plot)
  }, res = 110)
}

shinyApp(ui, server)
