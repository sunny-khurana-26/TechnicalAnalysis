# Deterministic example results

These values are the expected outputs for the examples in \`tests/test_indicators.R\`. Values are rounded to 9 decimal places for display; tests use a 1e-9 tolerance. Native R 4.2.3 currently passes; the exact runner output is saved in \`native_r_test_output.txt\`.

| Indicator | Example | Result summary |
| --- | --- | --- |
| SMA | \`sma(c(10,12,15,20,18,22,25,24,21), 3)\` | \`12.333333333, 15.666666667, 17.666666667, 20, 21.666666667, 23.666666667, 23.333333333\` |
| EMA | same vector, period 3 | \`10, 11, 13, 16.5, 17.25, 19.625, 22.3125, 23.15625, 22.078125\` |
| MACD | \`c(100,105,110,115,120,125,130)\`, 3/5/2 | line ends \`3.337191358, 3.839377572, 4.200210048\`; signal ends \`2.970679012, 3.549811385, 3.983410494\` |
| stdev | same sample vector as SMA | \`4.946628731\` (population divisor \`n\`) |
| linreg | \`c(1,3,2,5,4,6)\`, length 5, offset 1 | slope \`0.6\`; intercept \`2\`; predicted \`2.6, 3.2, 3.8, 4.4\` |
| RSI | \`c(45,50,48,55,52,49,58,60,65,62)\`, period 5 | first 5 are \`NA\`; remaining \`50.526315789, 68.925619835, 71.835205993, 78.210793191, 66.859664061\` |
| StochRSI | supplied PDF call uses \`data <- c(45, 50, 48, 55, 52, 49, 58, 60, 65, 62)\`; \`stoch_rsi(data, period = 14, k_period = 3, d_period = 3)\` | Documented exact call; the ten-value example is intentionally undersized for RSI period 14. Executable shape check uses a separate 25-value fixture with 5/3/3. |
| crossover | assignment two-array example | one \`"Up"\` event at position 4; all other positions \`"None"\` |
| crossunder | assignment two-array example | first value \`"None"\`; remaining positions \`"False"\` |

## Verification status

- Python independent cross-check: **PASS**; 9 indicator equations, required error messages, R signatures, and the 39-row two-symbol fixture were checked.
- Native R runner: **PASS** with R 4.2.3 and the requested \`R_LIBS_USER\`; exact output is saved in \`native_r_test_output.txt\`.
- Data provenance: \`data/stock_data.csv\` is a clearly labeled frozen fallback from public sample archives. A quantmod/Yahoo attempt on 2026-09-01 failed because \`query2.finance.yahoo.com\` could not be resolved; no provider data was fabricated.
- Added filter coverage: tested daily/weekly/monthly time-frame handling, exact data-source filtering, and an SMA-based stock selector.
