# BDA400 Assignment 5 - Technical Analysis Using R, Development Stage

Student: Sunny Khurana  
Student ID: 664425271  
Course: BDA400 / Data Science Tools and Techniques  
Assignment value: 15%

## Contents

- \`R/\` contains one core-R script per required indicator, with the exact function names and signatures from the 23-page assignment PDF.
- \`R/data_utils.R\` loads the local OHLCV data, supports daily/weekly/monthly time frames, filters by date/symbol/data source, selects stocks by SMA/EMA/RSI/stdev criteria, and demonstrates a moving-average trading rule.
- \`data/stock_data.csv\` contains deterministic AAPL and MSFT OHLCV rows with the required fields. It remains a clearly labeled reproducible fallback because public Yahoo Finance access failed during the documented quantmod attempt.
- \`tests/test_indicators.R\` is the primary base-R test runner.
- \`tests/crosscheck.py\` independently checks the equations and audits R signatures as a secondary check.
- \`results/python_crosscheck.json\` records the reproducible cross-check result.
- \`results/native_r_test_output.txt\` records the current native R 4.2.3 test output using the requested R library path.
- \`submission/Khurana_Sunny_CA_BDA400_A05.pdf\` is the polished explanation and cover document.

## Run guide

From this assignment directory:

\`\`\`text
Rscript tests/test_indicators.R
\`\`\`

The R test runner sources all nine indicators, checks numeric outputs, checks required error messages, loads both stock data frames, tests daily/weekly/monthly time-frame aggregation, filters by date and data source, selects a stock by an SMA criterion, and verifies the trading-rule output. The implementation uses only base R functions.

If R is not installed, run the independent fallback:

\`\`\`text
python3 tests/crosscheck.py
\`\`\`

Expected fallback output is a JSON object with \`"status": "PASS"\`, \`"checks": 9\`, \`"dataset_rows": 39\`, and symbols \`AAPL\` and \`MSFT\`. It is a secondary independent audit; the native R result is in \`results/native_r_test_output.txt\`.

## Required function map

| Script | Function | Output |
| --- | --- | --- |
| \`sma.R\` | \`sma(data, period)\` | one mean per complete window |
| \`ema.R\` | \`ema(data, period)\` | one EMA per input value |
| \`macd.R\` | \`macd(data, short_period, long_period, signal_period)\` | named \`macd_line\`, \`signal_line\`, \`histogram\` |
| \`stdev.R\` | \`stdev(data)\` | population standard deviation |
| \`linreg.R\` | \`linreg(regressionSource, regressionLength, regressionOffset)\` | named \`slope\`, \`intercept\`, \`predicted_values\` |
| \`rsi.R\` | \`rsi(data, period)\` | same-length RSI vector with leading \`NA\` values |
| \`stoch_rsi.R\` | \`stoch_rsi(data, period, k_period, d_period)\` | named \`k_line\`, \`d_line\` |
| \`crossover.R\` | \`crossover(arr1, arr2)\` | \`"Up"\`, \`"Down"\`, or \`"None"\` strings |
| \`crossunder.R\` | \`crossunder(arr1, arr2)\` | first \`"None"\`, then \`"True"\`/\`"False"\` strings |

## Behavior notes

- SMA raises \`Data length should be greater than or equal to the period\` when the input is shorter than the period.
- \`linreg\` preserves both required assignment errors verbatim.
- \`crossover\` and \`crossunder\` raise \`Both arrays should have the same length\` for mismatched inputs.
- MACD follows the assignment's simplified definition: the short EMA minus the long EMA, an EMA signal line, and their difference as histogram.
- RSI uses the assignment's gain/loss vectors and Wilder smoothing; flat windows resolve to RSI 50, while rising-only windows resolve to 100. StochRSI normalizes valid RSI values, then applies SMA for \`%K\` and \`%D\`. Per the PDF, \`%K\` is the StochRSI and \`%D\` is the 3-day SMA of \`%K\`; the function keeps the required \`d_period\` argument.
- Supplied PDF StochRSI example call (documented exactly; its ten observations are shorter than the RSI period and therefore require a longer input to execute): \`data <- c(45, 50, 48, 55, 52, 49, 58, 60, 65, 62)\`; \`stoch_rsi_result <- stoch_rsi(data, period = 14, k_period = 3, d_period = 3)\`.
- Invalid or undersized inputs now fail with explicit messages instead of producing undefined arithmetic, including empty standard-deviation input, one-point regression, invalid periods, and insufficient valid RSI values.
- The trading demonstration labels each row \`Buy\`, \`Sell\`, or \`Hold\` from aligned short/long SMAs and leaves rows without both averages as \`Hold\`.
- \`filter_market_data\` accepts \`time_frame = "daily"\`, \`"weekly"\`, or \`"monthly"\`; weekly rows use Monday buckets and monthly rows use the first calendar day. OHLCV aggregation uses first open, maximum high, minimum low, last close, and summed volume.
- \`filter_stocks_by_indicator\` returns matching symbols using a latest-value criterion for \`sma\`, \`ema\`, or \`rsi\`, or the full-period \`stdev\`, with operators \`>\`, \`>=\`, \`<\`, \`<=\`, \`==\`, and \`!=\`.

## Repository handoff

This assignment is stored in the public course repository under `Assignment 5 - Technical Analysis Using R Development Stage/`:

https://github.com/sunny-khurana-26/TechnicalAnalysis/tree/main/Assignment%205%20-%20Technical%20Analysis%20Using%20R%20Development%20Stage
