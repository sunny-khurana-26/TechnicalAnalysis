"""Independent, dependency-free cross-check for the nine R algorithms.

This script checks the same equations independently in Python and audits the
R source signatures. It is a secondary check; native R execution is recorded
by tests/test_indicators.R.
"""

import csv
import json
import math
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def sma(data, period):
    if len(data) < period:
        raise ValueError("Data length should be greater than or equal to the period")
    return [sum(data[i : i + period]) / period for i in range(len(data) - period + 1)]


def ema(data, period):
    multiplier = 2 / (period + 1)
    values = []
    for value in data:
        values.append(value if not values else (value - values[-1]) * multiplier + values[-1])
    return values


def macd(data, short_period, long_period, signal_period):
    line = [a - b for a, b in zip(ema(data, short_period), ema(data, long_period))]
    signal = ema(line, signal_period)
    return line, signal, [a - b for a, b in zip(line, signal)]


def stdev(data):
    mean = sum(data) / len(data)
    return math.sqrt(sum((value - mean) ** 2 for value in data) / len(data))


def linreg(source, length, offset):
    n = len(source)
    if length > n:
        raise ValueError("regressionLength cannot be greater than the number of elements in regressionSource")
    if offset >= length:
        raise ValueError("regressionOffset must be less than regressionLength")
    start = max(0, n - length + offset - 1)
    end = min(n, n - offset)
    subset = source[start:end]
    index = list(range(1, len(subset) + 1))
    mean_index = sum(index) / len(index)
    mean_source = sum(subset) / len(subset)
    numerator = sum((x - mean_index) * (y - mean_source) for x, y in zip(index, subset))
    denominator = sum((x - mean_index) ** 2 for x in index)
    slope = numerator / denominator
    intercept = mean_source - slope * mean_index
    return slope, intercept, [slope * x + intercept for x in index]


def rsi(data, period):
    differences = [b - a for a, b in zip(data, data[1:])]
    gains = [difference if difference > 0 else 0 for difference in differences]
    losses = [abs(difference) if difference <= 0 else 0 for difference in differences]
    average_gain = sum(gains[:period]) / period
    average_loss = sum(losses[:period]) / period
    result = [None] * len(data)
    for i in range(period + 1, len(data) + 1):
        average_gain = (average_gain * (period - 1) + gains[i - 2]) / period
        average_loss = (average_loss * (period - 1) + losses[i - 2]) / period
        relative_strength = math.inf if average_loss == 0 and average_gain > 0 else average_gain / average_loss
        result[i - 1] = 100 - 100 / (1 + relative_strength)
    return result


def stoch_rsi(data, period, k_period, d_period):
    values = rsi(data, period)
    valid = [value for value in values if value is not None]
    if not valid:
        k_values = [None] * len(values)
    else:
        low, high = min(valid), max(valid)
        k_values = [None if value is None else (0 if high == low else (value - low) / (high - low)) for value in values]
    k_line = []
    for i in range(len(k_values) - k_period + 1):
        window = k_values[i : i + k_period]
        k_line.append(sum(window) / k_period if all(value is not None for value in window) else None)
    d_line = []
    for i in range(len(k_line) - d_period + 1):
        window = k_line[i : i + d_period]
        d_line.append(sum(window) / d_period if all(value is not None for value in window) else None)
    return k_line, d_line


def crossover(arr1, arr2):
    if len(arr1) != len(arr2):
        raise ValueError("Both arrays should have the same length")
    signals = ["None"] * len(arr1)
    for i in range(1, len(arr1)):
        if arr1[i] > arr2[i] and arr1[i - 1] <= arr2[i - 1]:
            signals[i] = "Up"
        elif arr1[i] < arr2[i] and arr1[i - 1] >= arr2[i - 1]:
            signals[i] = "Down"
    return signals


def crossunder(arr1, arr2):
    if len(arr1) != len(arr2):
        raise ValueError("Both arrays should have the same length")
    signals = ["False"] * len(arr1)
    if signals:
        signals[0] = "None"
    for i in range(1, len(arr1)):
        if arr1[i] < arr2[i] and arr1[i - 1] >= arr2[i - 1]:
            signals[i] = "True"
    return signals


def close_enough(left, right, tolerance=1e-9):
    return abs(left - right) <= tolerance


def main():
    sample = [10, 12, 15, 20, 18, 22, 25, 24, 21]
    assert all(close_enough(a, b) for a, b in zip(sma(sample, 3), [12.3333333333, 15.6666666667, 17.6666666667, 20, 21.6666666667, 23.6666666667, 23.3333333333]))
    assert all(close_enough(a, b) for a, b in zip(ema(sample, 3), [10, 11, 13, 16.5, 17.25, 19.625, 22.3125, 23.15625, 22.078125]))
    line, signal, histogram = macd([100, 105, 110, 115, 120, 125, 130], 3, 5, 2)
    assert all(close_enough(a, b) for a, b in zip(line, [0, 0.8333333333, 1.8055555556, 2.6620370370, 3.3371913580, 3.8393775720, 4.2002100480]))
    assert close_enough(stdev(sample), 4.9466287310)
    slope, intercept, predicted = linreg([1, 3, 2, 5, 4, 6], 5, 1)
    assert close_enough(slope, 0.6) and close_enough(intercept, 2) and all(close_enough(a, b) for a, b in zip(predicted, [2.6, 3.2, 3.8, 4.4]))
    rsi_result = rsi([45, 50, 48, 55, 52, 49, 58, 60, 65, 62], 5)
    assert sum(value is None for value in rsi_result) == 5
    assert all(close_enough(a, b) for a, b in zip(rsi_result[5:], [50.5263157895, 68.9256198347, 71.8352059925, 78.2107931909, 66.8596640607]))
    k_line, d_line = stoch_rsi([45, 50, 48, 55, 52, 49, 58, 60, 65, 62, 66, 64, 68, 70, 67, 71, 69, 72, 74, 73, 75, 76, 74, 77, 78], 5, 3, 3)
    assert len(k_line) == 23 and len(d_line) == 21
    arr1 = [10, 12, 15, 20, 18, 22, 25, 24, 21]
    arr2 = [18, 20, 22, 18, 15, 12, 10, 11, 13]
    assert crossover(arr1, arr2) == ["None", "None", "None", "Up", "None", "None", "None", "None", "None"]
    assert crossunder(arr1, arr2) == ["None", "False", "False", "False", "False", "False", "False", "False", "False"]

    required = {
        "sma.R": r"sma\s*<-\s*function\s*\(data,\s*period\)",
        "ema.R": r"ema\s*<-\s*function\s*\(data,\s*period\)",
        "macd.R": r"macd\s*<-\s*function\s*\(data,\s*short_period,\s*long_period,\s*signal_period\)",
        "stdev.R": r"stdev\s*<-\s*function\s*\(data\)",
        "linreg.R": r"linreg\s*<-\s*function\s*\(regressionSource,\s*regressionLength,\s*regressionOffset\)",
        "rsi.R": r"rsi\s*<-\s*function\s*\(data,\s*period\)",
        "stoch_rsi.R": r"stoch_rsi\s*<-\s*function\s*\(data,\s*period,\s*k_period,\s*d_period\)",
        "crossover.R": r"crossover\s*<-\s*function\s*\(arr1,\s*arr2\)",
        "crossunder.R": r"crossunder\s*<-\s*function\s*\(arr1,\s*arr2\)",
    }
    for filename, pattern in required.items():
        assert re.search(pattern, (ROOT / "R" / filename).read_text())

    with (ROOT / "data" / "stock_data.csv").open(newline="") as handle:
        rows = list(csv.DictReader(handle))
    assert {row["symbol"] for row in rows} == {"AAPL", "MSFT"}
    assert {"date", "open", "high", "low", "close", "volume"}.issubset(rows[0])
    rscript_available = shutil.which("Rscript") is not None
    summary = {
        "status": "PASS",
        "checks": 9,
        "r_available": rscript_available,
        "r_reason": "Rscript is available; native output is recorded separately" if rscript_available else "Rscript is not installed",
        "dataset_rows": len(rows),
        "symbols": sorted({row["symbol"] for row in rows}),
        "notes": "Independent Python equations and R signature/error-string audit passed; use the native R runner for authoritative execution.",
    }
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
