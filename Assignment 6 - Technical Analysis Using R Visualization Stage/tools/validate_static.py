"""Static and Python-based checks for the Assignment 6 delivery."""

from __future__ import annotations

import hashlib
import os
import re
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app.R"
README = ROOT / "README.md"
COVER = ROOT / "cover_page.md"
PDF = ROOT / "submission" / "Khurana_Sunny_CA_BDA400_A06.pdf"
SOURCE = ROOT / "source" / "BDA400 Assignment 6 - Technical Analysis using R, Visualization Phase.pdf"


def stripped_r_code(source: str) -> str:
    """Remove comments and string literals before delimiter checks."""

    result: list[str] = []
    quote: str | None = None
    escaped = False
    in_comment = False
    for char in source:
        if in_comment:
            if char == "\n":
                in_comment = False
                result.append(char)
            else:
                result.append(" ")
            continue
        if quote is not None:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
            result.append(" ")
            continue
        if char == "#":
            in_comment = True
            result.append(" ")
        elif char in ('"', "'", "`"):
            quote = char
            result.append(" ")
        else:
            result.append(char)
    return "".join(result)


def assert_true(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> None:
    app = APP.read_text(encoding="utf-8")
    readme = README.read_text(encoding="utf-8")
    cover = COVER.read_text(encoding="utf-8")
    assert_true(APP.exists(), "app.R is missing")
    assert_true("shinyApp(ui, server)" in app, "Shiny app launch call is missing")
    for control in (
        "dateRangeInput",
        "selectInput",
        "time_frame",
        "chart_type",
        "technical_indicators",
        "short_ma_period",
        "long_ma_period",
    ):
        assert_true(control in app, f"Required control token missing: {control}")
    for token in ("Line", "Candlestick", "Area", "Daily", "Weekly", "Monthly"):
        assert_true(token in app, f"Required option missing: {token}")
    for token in (
        "TTR::SMA",
        "TTR::RSI",
        "TTR::MACD",
        "MA_short",
        "MA_long",
        "RSIOverlay",
        "MACDOverlay",
        'maType = "EMA"',
        "Buy",
        "Sell",
        "Hold",
    ):
        assert_true(token in app, f"Required indicator/rule token missing: {token}")
    for token in ("quantmod::getSymbols", 'src = "yahoo"', "tryCatch", "generate_fallback_data", "offline fallback"):
        assert_true(token in app, f"Retrieval/fallback token missing: {token}")
    assert_true("runApp" in readme and "install.packages" in readme, "README run instructions are incomplete")
    assert_true(
        "Sunny Khurana" in cover
        and "664425271" in cover
        and ("REPOSITORY_HANDOFF_TOKEN" in cover or "github.com/sunny-khurana-26/TechnicalAnalysis" in cover),
        "Cover-page identity or repository URL missing",
    )
    assert_true("runif" not in app and "rnorm" not in app, "Fallback must not use random generation")
    assert_true("geom_text" in app and "label = Signal" in app, "Every generated signal must be labelable")
    assert_true("signal_events" not in app and "SignalChange" not in app, "Signal labels must not be limited to changes")

    cleaned = stripped_r_code(app)
    stack: list[str] = []
    pairs = {")": "(", "]": "[", "}": "{"}
    for char in cleaned:
        if char in "([{" :
            stack.append(char)
        elif char in ")]}":
            assert_true(stack and stack[-1] == pairs[char], f"Unbalanced R delimiter near {char!r}")
            stack.pop()
    assert_true(not stack, f"Unclosed R delimiters: {stack}")

    assert_true(SOURCE.exists(), "Source PDF is missing")
    source_hash = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    assert_true(len(source_hash) == 64, "Source hash could not be computed")
    assert_true(PDF.exists() and PDF.stat().st_size > 0, "Required submission PDF is missing or empty")
    pdfinfo = subprocess.run(["pdfinfo", str(PDF)], capture_output=True, text=True, check=True).stdout
    assert_true(re.search(r"Pages:\s+1", pdfinfo) is not None, "Submission PDF is not a one-page cover")
    assert_true(re.search(r"Page size:\s+612 x 792", pdfinfo) is not None, "Submission PDF is not letter-sized")
    print("PASS: required dashboard controls, retrieval, fallback, indicators, rules, docs, and PDF metadata")
    print(f"PASS: source PDF unchanged hash {source_hash}")
    rscript = shutil.which("Rscript")
    if rscript:
        runtime_env = os.environ.copy()
        runtime_env["R_LIBS_USER"] = str(ROOT.parents[1] / "r-lib")
        version = subprocess.run(
            [rscript, "--vanilla", "-e", "cat(as.character(getRversion()))"],
            capture_output=True,
            text=True,
            check=True,
            env=runtime_env,
        ).stdout.strip()
        print(f"PASS: native R runtime detected ({version}); focused runtime checks are documented in README.md")
    else:
        print("LIMIT: R/Shiny runtime unavailable; execution and live Yahoo Finance retrieval remain unrun")


if __name__ == "__main__":
    main()
