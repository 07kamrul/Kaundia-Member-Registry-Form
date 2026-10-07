"""Auditor-grade PDF rendering for the fund transparency report.

Layout matches the app's visual identity (dark green / gold / cream), uses
Noto Sans Bengali with HarfBuzz shaping so Bangla text renders correctly,
and every figure uses South-Asian digit grouping with the ৳ symbol.
"""
from dataclasses import dataclass, field
from datetime import date
from decimal import Decimal
from pathlib import Path

from fpdf import FPDF
from fpdf.fonts import FontFace

from app.services.finance import BN_MONTHS, format_taka

FONT_DIR = Path(__file__).resolve().parent.parent / "static" / "fonts"

# Brand palette (mirrors the frontend CSS variables).
GREEN_DARK = (31, 61, 42)      # --emerald-800
GREEN_MID = (46, 81, 56)       # --emerald-600
GOLD = (201, 163, 76)          # --gold
CREAM = (243, 239, 227)        # --surface-2
RED = (156, 58, 44)            # --red-600
INK = (26, 42, 32)             # --gray-800
INK_SOFT = (71, 86, 74)        # --gray-700

HEADER_ROW_FILL = FontFace(emphasis="BOLD", color=(255, 255, 255), fill_color=GREEN_DARK)
TOTAL_ROW_FILL = FontFace(emphasis="BOLD", color=INK, fill_color=CREAM)


@dataclass
class FinanceReportData:
    org_name: str
    period_label: str
    generated_at_label: str
    income_total: Decimal
    expense_total: Decimal
    balance: Decimal
    income_breakdown: list[tuple[str, Decimal, str]]  # (category, amount, share %)
    expense_breakdown: list[tuple[str, Decimal, str]]
    transactions: list[tuple[date, str, str, str, Decimal]]  # (date, description, category, type, signed amount)
    filter_note: str | None = None


def _taka(value: Decimal | int | float) -> str:
    return f"৳ {format_taka(value)}"


def _date_label(value: date) -> str:
    return f"{value.day} {BN_MONTHS[value.month - 1]} {value.year}"


class _ReportPDF(FPDF):
    """Base A4 document with the letterhead band and the system-report footer
    drawn on every page."""

    def __init__(self, org_name: str, period_label: str, generated_at_label: str):
        super().__init__(orientation="P", unit="mm", format="A4")
        self.org_name = org_name
        self.period_label = period_label
        self.generated_at_label = generated_at_label
        self.set_margins(14, 34, 14)
        self.set_auto_page_break(auto=True, margin=20)

    def header(self) -> None:
        self.set_fill_color(*GREEN_DARK)
        self.rect(0, 0, self.w, 26, style="F")
        self.set_fill_color(*GOLD)
        self.rect(0, 26, self.w, 1.1, style="F")

        self.set_text_color(255, 255, 255)
        self.set_font("bn", "B", 15)
        self.set_xy(14, 6)
        self.cell(text=self.org_name, new_x="LMARGIN", new_y="NEXT")
        self.set_font("bn", "", 10)
        self.set_text_color(*GOLD)
        self.set_x(14)
        self.cell(text="আর্থিক স্বচ্ছতা রিপোর্ট  •  Fund Transparency Report", new_y="NEXT")

        self.set_text_color(255, 255, 255)
        self.set_font("bn", "", 9.5)
        self.set_xy(self.l_margin, 33)
        self.cell(
            text=f"সময়কাল: {self.period_label}   |   তৈরি: {self.generated_at_label}",
            new_x="LMARGIN",
            new_y="NEXT",
        )
        self.ln(2)

    def footer(self) -> None:
        self.set_y(-16)
        self.set_draw_color(*GOLD)
        self.set_line_width(0.3)
        self.line(self.l_margin, self.get_y(), self.w - self.r_margin, self.get_y())
        self.set_y(-13)
        self.set_font("bn", "", 8)
        self.set_text_color(*INK_SOFT)
        self.cell(
            0,
            text=f"এই রিপোর্টটি সিস্টেম দ্বারা স্বয়ংক্রিয়ভাবে তৈরি হয়েছে — {self.org_name}",
            align="L",
        )
        self.set_font("latin", "", 8)
        self.cell(0, text=f"Page {self.page_no()}/{{nb}}", align="R")


def _section_title(pdf: _ReportPDF, title: str) -> None:
    pdf.ln(2)
    pdf.set_font("bn", "B", 11.5)
    pdf.set_text_color(*GREEN_MID)
    pdf.cell(text=title, new_x="LMARGIN", new_y="NEXT")
    pdf.set_draw_color(*GOLD)
    pdf.set_line_width(0.4)
    pdf.line(pdf.l_margin, pdf.get_y() + 0.5, pdf.w - pdf.r_margin, pdf.get_y() + 0.5)
    pdf.ln(2.5)


def _kpi_row(pdf: _ReportPDF, data: FinanceReportData) -> None:
    net = data.income_total - data.expense_total
    cells = [
        ("সর্বমোট আয়", _taka(data.income_total), GREEN_MID),
        ("সর্বমোট ব্যয়", _taka(data.expense_total), RED),
        ("নিট জমা", _taka(net), INK),
    ]
    gap = 3
    width = (pdf.w - pdf.l_margin - pdf.r_margin - gap) / 4
    x0, y0 = pdf.l_margin, pdf.get_y()

    pdf.set_fill_color(*CREAM)
    pdf.set_draw_color(*GOLD)
    pdf.set_line_width(0.3)
    pdf.rect(x0, y0, width, 16, style="DF")
    pdf.set_xy(x0 + 2, y0 + 2.5)
    pdf.set_text_color(*INK_SOFT)
    pdf.set_font("bn", "", 8.5)
    pdf.cell(text="বর্তমান ব্যালেন্স")
    pdf.set_xy(x0 + 2, y0 + 7)
    pdf.set_text_color(*GREEN_DARK)
    pdf.set_font("bn", "B", 11)
    pdf.cell(text=_taka(data.balance))

    for index, (label, value, color) in enumerate(cells):
        x = x0 + (index + 1) * (width + gap)
        pdf.set_fill_color(247, 246, 241)
        pdf.rect(x, y0, width, 16, style="F")
        pdf.set_xy(x + 2, y0 + 2.5)
        pdf.set_text_color(*INK_SOFT)
        pdf.set_font("bn", "", 8.5)
        pdf.cell(text=label)
        pdf.set_xy(x + 2, y0 + 7)
        pdf.set_text_color(*color)
        pdf.set_font("bn", "B", 10)
        pdf.cell(text=value)

    pdf.set_xy(x0, y0 + 19)


def _breakdown_table(
    pdf: _ReportPDF, rows: list[tuple[str, Decimal, str]], total: Decimal
) -> None:
    with pdf.table(
        col_widths=(86, 52, 28),
        text_align=("LEFT", "RIGHT", "RIGHT"),
        line_height=5.4,
        headings_style=HEADER_ROW_FILL,
        borders_layout="HORIZONTAL_LINES",
    ) as table:
        head = table.row()
        head.cell("খাত")
        head.cell("পরিমাণ")
        head.cell("অংশ (%)")
        for label, amount, share in rows:
            row = table.row()
            row.cell(label)
            row.cell(_taka(amount))
            row.cell(share)
        total_row = table.row(style=TOTAL_ROW_FILL)
        total_row.cell("সর্বমোট")
        total_row.cell(_taka(total))
        total_row.cell("100.00" if total > 0 else "—")


def build_finance_report_pdf(data: FinanceReportData) -> bytes:
    pdf = _ReportPDF(data.org_name, data.period_label, data.generated_at_label)
    pdf.add_font("bn", "", str(FONT_DIR / "NotoSansBengali-Regular.ttf"))
    pdf.add_font("bn", "B", str(FONT_DIR / "NotoSansBengali-Bold.ttf"))
    pdf.add_font("latin", "", str(FONT_DIR / "NotoSans-Regular.ttf"))
    pdf.add_font("latin", "B", str(FONT_DIR / "NotoSans-Bold.ttf"))
    pdf.set_fallback_fonts(["latin"])
    pdf.set_text_shaping(True)
    pdf.set_text_color(*INK)
    pdf.add_page()

    _kpi_row(pdf, data)

    if data.filter_note:
        pdf.set_font("bn", "", 9)
        pdf.set_text_color(*INK_SOFT)
        pdf.multi_cell(0, text=f"প্রয়োগকৃত ফিল্টার: {data.filter_note}", new_x="LMARGIN", new_y="NEXT")

    _section_title(pdf, "আয়ের বিবরণ (খাতভিত্তিক)")
    if data.income_breakdown:
        _breakdown_table(pdf, data.income_breakdown, data.income_total)
    else:
        pdf.set_font("bn", "", 9.5)
        pdf.cell(text="এই সময়কালে কোনো আয় নেই।", new_x="LMARGIN", new_y="NEXT")

    _section_title(pdf, "ব্যয়ের বিবরণ (খাতভিত্তিক)")
    if data.expense_breakdown:
        _breakdown_table(pdf, data.expense_breakdown, data.expense_total)
    else:
        pdf.set_font("bn", "", 9.5)
        pdf.cell(text="এই সময়কালে কোনো ব্যয় নেই।", new_x="LMARGIN", new_y="NEXT")

    _section_title(pdf, "লেনদেনের তালিকা")
    if data.transactions:
        with pdf.table(
            col_widths=(26, 70, 34, 14, 28),
            text_align=("LEFT", "LEFT", "LEFT", "CENTER", "RIGHT"),
            line_height=5.2,
            headings_style=HEADER_ROW_FILL,
            borders_layout="HORIZONTAL_LINES",
        ) as table:
            head = table.row()
            head.cell("তারিখ")
            head.cell("বিবরণ")
            head.cell("খাত")
            head.cell("ধরন")
            head.cell("পরিমাণ")
            for txn_date, description, category, type_label, signed in data.transactions:
                row = table.row()
                row.cell(_date_label(txn_date))
                row.cell(description[:120])
                row.cell(category)
                type_face = FontFace(color=GREEN_MID if signed > 0 else RED, emphasis="BOLD")
                row.cell(type_label, style=type_face)
                row.cell(("+" if signed > 0 else "−") + _taka(abs(signed))[2:], style=type_face)
    else:
        pdf.set_font("bn", "", 9.5)
        pdf.cell(text="এই সময়কালে কোনো লেনদেন নেই।", new_x="LMARGIN", new_y="NEXT")

    return bytes(pdf.output())
