# BDA400 Assignment 6

## Technical Analysis using R, Visualization Phase

**Student:** Sunny Khurana  
**Student ID:** 664425271  
**Course:** BDA400 / Data Science Tools and Techniques

### Project description

This project is an R Shiny portfolio dashboard that retrieves historical stock data from Yahoo Finance with `quantmod`, provides a deterministic offline fallback for reproducibility, and visualizes price data as line, candlestick, or area charts. Users can select Daily, Weekly, or Monthly timeframes, configure short and long moving-average periods, toggle Moving Averages, RSI, and MACD layers on the price chart, and review every generated Buy, Sell, or Hold observation with chart annotations.

### Assignment repository

`https://github.com/sunny-khurana-26/TechnicalAnalysis/tree/main/Assignment%206%20-%20Technical%20Analysis%20Using%20R%20Visualization%20Stage`

The public repository path above matches the code and PDF submitted for this assignment.

### Included implementation

The repository includes `app.R` and `README.md` with installation, launch, data-source, fallback, indicator, signal-rule, and validation instructions.

### Native runtime status

R 4.2.3 and the local course library are available. Source/function checks, deterministic fallback and resampling checks, indicator-layer and signal checks, input-validation checks, and a `shiny::testServer()` dashboard path passed. A genuine local Shiny launch served the dashboard HTML; Yahoo Finance was attempted and fell back because the runtime could not resolve `query2.finance.yahoo.com`.
