"""Build the manifest-required Assignment 6 cover-page PDF.

This small writer uses only the PDF text and graphics operators needed for
this one-page cover. The output is still a standards-compliant, renderable PDF.
"""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "submission" / "Khurana_Sunny_CA_BDA400_A06.pdf"


def pdf_escape(value: str) -> str:
    """Escape text for a PDF literal string."""

    return value.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")


def text(x: int, y: int, value: str, size: int, color: tuple[float, float, float]) -> str:
    r, g, b = color
    return f"{r} {g} {b} rg BT /F1 {size} Tf {x} {y} Td ({pdf_escape(value)}) Tj ET\n"


def build() -> None:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    navy = (0.07, 0.21, 0.36)
    blue = (0.15, 0.39, 0.92)
    slate = (0.20, 0.27, 0.36)
    muted = (0.39, 0.47, 0.58)
    light = (0.89, 0.92, 0.96)

    commands = [
        "q 0.07 0.21 0.36 rg 0 650 612 142 re f Q\n",
        text(54, 724, "BDA400 Assignment 6", 24, (1, 1, 1)),
        text(54, 696, "Technical Analysis using R, Visualization Phase", 13, (0.80, 0.89, 1)),
        text(54, 624, "STUDENT", 9, muted),
        text(170, 624, "Sunny Khurana", 12, slate),
        text(54, 594, "STUDENT ID", 9, muted),
        text(170, 594, "664425271", 12, slate),
        text(54, 574, "COURSE", 9, muted),
        text(170, 574, "BDA400 / Data Science Tools and Techniques", 12, slate),
        text(54, 544, "WEIGHT", 9, muted),
        text(170, 544, "15%", 12, slate),
        f"{light[0]} {light[1]} {light[2]} RG 54 528 m 558 528 l S\n",
        text(54, 505, "PROJECT DESCRIPTION", 12, blue),
        text(54, 476, "This project is an R Shiny portfolio dashboard that retrieves historical", 11, slate),
        text(54, 458, "stock data from Yahoo Finance with quantmod, provides a deterministic", 11, slate),
        text(54, 440, "offline fallback for reproducibility, and visualizes price data as line,", 11, slate),
        text(54, 422, "candlestick, or area charts. Users can select Daily, Weekly, or Monthly", 11, slate),
        text(54, 404, "timeframes, configure moving-average periods, toggle Moving Averages, RSI,", 11, slate),
        text(54, 386, "and MACD price-chart layers, and review every Buy, Sell, or Hold observation.", 11, slate),
        text(54, 340, "ASSIGNMENT REPOSITORY", 12, blue),
        text(54, 312, "https://github.com/sunny-khurana-26/TechnicalAnalysis/tree/main/", 8, slate),
        text(54, 298, "Assignment%206%20-%20Technical%20Analysis%20Using%20R%20Visualization%20Stage", 8, slate),
        text(54, 296, "BDA400-A06-Technical-Analysis-R", 10, slate),
        text(54, 270, "Public repository path matches the code and PDF package.", 8, muted),
        text(54, 222, "INCLUDED IMPLEMENTATION", 12, blue),
        text(54, 194, "app.R contains the complete Shiny application. README.md documents", 11, slate),
        text(54, 176, "installation, launch, data retrieval, fallback behavior, indicator", 11, slate),
        text(54, 158, "definitions, trading rules, and current runtime validation findings.", 10, slate),
        text(54, 136, "R 4.2.3/Shiny runtime checks passed; Yahoo request fell back on DNS failure.", 8, muted),
        text(54, 90, "Prepared for Assignment 6 submission", 9, muted),
    ]

    stream = "".join(commands).encode("latin-1")
    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
        b"<< /Length " + str(len(stream)).encode("ascii") + b" >>\nstream\n" + stream + b"endstream",
    ]
    pdf = bytearray(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
    offsets = [0]
    for number, obj in enumerate(objects, start=1):
        offsets.append(len(pdf))
        pdf.extend(f"{number} 0 obj\n".encode("ascii"))
        pdf.extend(obj)
        pdf.extend(b"\nendobj\n")
    xref = len(pdf)
    pdf.extend(f"xref\n0 {len(objects) + 1}\n".encode("ascii"))
    pdf.extend(b"0000000000 65535 f \n")
    for offset in offsets[1:]:
        pdf.extend(f"{offset:010d} 00000 n \n".encode("ascii"))
    pdf.extend(f"trailer\n<< /Size {len(objects) + 1} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF\n".encode("ascii"))
    OUTPUT.write_bytes(pdf)
    print(OUTPUT)


if __name__ == "__main__":
    build()
