# BDA400 Assignment 6 - Technical Analysis using R, Visualization Phase

Student: Sunny Khurana  
Student ID: 664425271  
Course: BDA400 / Data Science Tools and Techniques

## Project overview

This repository contains a documented R Shiny portfolio dashboard for interactive technical analysis. The dashboard retrieves historical OHLCV stock data from Yahoo Finance through `quantmod`, supports a deterministic offline fallback when the network request fails, and provides:

- Daily, Weekly, and Monthly timeframes.
- User-selectable Line, Candlestick, and Area price charts.
- Independent Moving Averages, RSI, and MACD toggles.
- Configurable short/long SMA trading signals (defaults: 20 and 50 periods).
- Clear Buy, Sell, and Hold annotations for every filtered observation.
- User-configurable short and long moving-average periods, with input validation.
- User-facing status messages and validation for invalid symbols, dates, empty data, and insufficient observations.

## Files

- `app.R` - complete Shiny application, including data collection, charting, indicators, and trading rules.
- `cover_page.md` - cover-page content with the public repository URL.
- `submission/Khurana_Sunny_CA_BDA400_A06.pdf` - student-specific cover-page PDF package.

## Repository URL

Assignment repository:

`https://github.com/sunny-khurana-26/TechnicalAnalysis/tree/main/Assignment%206%20-%20Technical%20Analysis%20Using%20R%20Visualization%20Stage`

The public repository path above contains the submitted `app.R`, README, cover content, and PDF package.

## Install and run

1. Install R (recommended R 4.2 or newer).
2. Open R or RStudio in this directory.
3. Use the local course library for this assignment:

```r
Sys.setenv(R_LIBS_USER = "/Users/sidhant/Desktop/pitte/users/sunny_khurana/BDA400/r-lib")
```

4. Install the required packages once if they are not already available:

```r
install.packages(c("shiny", "ggplot2", "quantmod", "TTR", "zoo"))
```

5. Launch the app:

```r
shiny::runApp(".")
```

The app starts with AAPL and a 2023-01-01 through 2023-07-01 range. Enter another supported ticker, choose a date range, choose a timeframe and chart type, then click **Load / refresh data**.

## Data and fallback behavior

The live path calls the assignment-specified Yahoo Finance source through the equivalent of `quantmod::getSymbols(..., src = "yahoo", auto.assign = FALSE)`. A `tryCatch()` block handles connection errors, invalid responses, empty results, and incomplete rows. The fallback creates weekday OHLCV observations using fixed trigonometric formulas and a symbol-derived offset; it does not use random numbers, so offline results are deterministic.

## Indicator and signal definitions

- Short SMA: user-configured simple moving average of Close (default 20 periods).
- Long SMA: user-configured simple moving average of Close (default 50 periods).
- RSI: 14-period Relative Strength Index.
- MACD: 12/26 exponential moving-average difference with a 9-period EMA signal line, using `TTR::MACD(..., maType = "EMA")`.
- Buy: short SMA > long SMA.
- Sell: short SMA < long SMA.
- Hold: either SMA is unavailable, or the two averages are equal.

The dashboard fetches a warm-up window before the selected start date so longer, user-configured averages have sufficient history. RSI and MACD are plotted as visible layers on the same price chart after being rescaled into labeled price-axis bands; their source units and RSI 30/70 and MACD zero guides are preserved. When annotations are enabled, every filtered row is labelled with its generated `Buy`, `Sell`, or `Hold` value, matching the source example's observation-level annotation.

## Validation note

Native runtime validation is current: R 4.2.3 with the local course library passed source/parse checks, deterministic fallback and resampling checks, indicator and overlay-band checks, Buy/Sell/Hold signal checks, input-validation checks, and a `shiny::testServer()` weekly line-chart path with all three indicators enabled. A real local `shiny::runApp()` also served the dashboard HTML on `127.0.0.1:8765`; the server was stopped after capture. The live Yahoo Finance request was attempted and correctly entered the deterministic fallback because this environment could not resolve `query2.finance.yahoo.com`.

Verified local package versions: shiny 1.8.0, ggplot2 3.4.4, quantmod 0.4.25, TTR 0.24.4, and zoo 1.8.12. Static validation was run with `tools/validate_static.py`. `source/` and `verification.md` were preserved for a fresh verifier.

## Submission checklist

- Use the public repository path above on the LMS repository-link field.
- Confirm the public repository is accessible.
- Run the app in R/RStudio and exercise each chart type, timeframe, indicator toggle, date range, and fallback/error path.
- Submit the PDF using the student-specific filename `Khurana_Sunny_CA_BDA400_A06.pdf`.
