# Local market-data fixture and provider record

\`stock_data.csv\` is a small frozen OHLCV sample for two symbols. It is kept local so the tests are deterministic and do not depend on network availability. The rows retain the required fields \`date\`, \`open\`, \`high\`, \`low\`, \`close\`, and \`volume\`.

This is a clearly labeled reproducible fallback assembled from public sample archives, not a retrieval from a reputable financial-data provider. No provider export is claimed for these cached rows. \`R/data_utils.R\` labels loaded rows as \`local_reproducible_fallback\` so data-source filtering remains explicit.

## Yahoo Finance attempt

On 2026-09-01, with R 4.2.3 and quantmod 0.4.25, public Yahoo Finance retrieval was attempted through \`getSymbols(..., src = "yahoo")\` for AAPL and MSFT. Both requests failed with \`Could not resolve host: query2.finance.yahoo.com\`. Because no provider response was received, the cached CSV was not relabeled or replaced with fabricated values.

The public archive locations recorded for the cached rows are:

- AAPL sample: <https://github.com/mohabmes/pystocklib/blob/master/data/AAPL.csv>
- MSFT sample: <https://github.com/matplotlib/sample_data/blob/master/msft.csv>

For a future project extension, retrieve a daily OHLCV export from a reputable provider such as Yahoo Finance or Stooq, record the provider, symbol set, date range, retrieval date, and export URL, normalize the column names to this schema, and replace the local fixture before the external LMS/repository submission step. That provider export has not been performed here; the student must complete and document it if the instructor requires provider-backed data for submission.
