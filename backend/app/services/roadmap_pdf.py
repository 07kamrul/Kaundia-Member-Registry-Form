"""A4 roadmap handout - same letterhead, palette and Bangla shaping as the
fund transparency report (app.services.finance_pdf)."""
from dataclasses import dataclass
from datetime import date

from fpdf.fonts import FontFace

from app.services.finance import BN_MONTHS
from app.services.finance_pdf import (
    CREAM,
    GOLD,
    GREEN_DARK,
    GREEN_MID,
    HEADER_ROW_FILL,
    INK,
    INK_SOFT,
    ReportPDF,
    register_report_fonts,
    section_title,
)

ROADMAP_REPORT_TITLE = "আমাদের পরিকল্পনা  •  Our Roadmap"
AMBER = (169, 121, 30)  # --gold (in-progress pill)
BAR_HEIGHT_MM = 2.6
SECTION_MIN_SPACE_MM = 45

STATUS_LABELS = {"planned": "পরিকল্পিত", "in_progress": "চলমান", "done": "সম্পন্ন"}
STATUS_COLORS = {"planned": INK_SOFT, "in_progress": AMBER, "done": GREEN_MID}

_BN_DIGITS = str.maketrans("0123456789", "০১২৩৪৫৬৭৮৯")


def bn_digits(value: int | str) -> str:
    return str(value).translate(_BN_DIGITS)


def bn_date(value: date) -> str:
    return bn_digits(f"{value.day} {BN_MONTHS[value.month - 1]} {value.year}")


@dataclass(frozen=True)
class RoadmapPdfItem:
    text: str
    status: str
    target_date: date | None
    owner: str | None
    note: str | None
    completed_at: date | None


@dataclass(frozen=True)
class RoadmapPdfSection:
    name: str
    window: str
    done: int
    total: int
    percent: int
    items: tuple[RoadmapPdfItem, ...]


@dataclass(frozen=True)
class RoadmapReportData:
    org_name: str
    generated_at_label: str
    last_updated_label: str
    overall_done: int
    overall_in_progress: int
    overall_planned: int
    overall_total: int
    overall_percent: int
    sections: tuple[RoadmapPdfSection, ...]


def _progress_bar(pdf: ReportPDF, percent: int) -> None:
    width = pdf.w - pdf.l_margin - pdf.r_margin
    x, y = pdf.l_margin, pdf.get_y()
    pdf.set_fill_color(*CREAM)
    pdf.rect(x, y, width, BAR_HEIGHT_MM, style="F")
    if percent > 0:
        pdf.set_fill_color(*GREEN_MID)
        pdf.rect(x, y, width * percent / 100, BAR_HEIGHT_MM, style="F")
    pdf.set_y(y + BAR_HEIGHT_MM + 3)


def _kpi_row(pdf: ReportPDF, data: RoadmapReportData) -> None:
    cells = [
        ("সার্বিক অগ্রগতি", f"{bn_digits(data.overall_percent)}%", GREEN_DARK),
        ("সম্পন্ন", bn_digits(data.overall_done), GREEN_MID),
        ("চলমান", bn_digits(data.overall_in_progress), AMBER),
        ("পরিকল্পিত", bn_digits(data.overall_planned), INK_SOFT),
    ]
    gap = 3
    width = (pdf.w - pdf.l_margin - pdf.r_margin - gap * 3) / 4
    x0, y0 = pdf.l_margin, pdf.get_y()
    for index, (label, value, color) in enumerate(cells):
        x = x0 + index * (width + gap)
        if index == 0:
            pdf.set_fill_color(*CREAM)
            pdf.set_draw_color(*GOLD)
            pdf.set_line_width(0.3)
            pdf.rect(x, y0, width, 16, style="DF")
        else:
            pdf.set_fill_color(247, 246, 241)
            pdf.rect(x, y0, width, 16, style="F")
        pdf.set_xy(x + 2, y0 + 2.5)
        pdf.set_text_color(*INK_SOFT)
        pdf.set_font("bn", "", 8.5)
        pdf.cell(text=label)
        pdf.set_xy(x + 2, y0 + 7)
        pdf.set_text_color(*color)
        pdf.set_font("bn", "B", 12)
        pdf.cell(text=value)
    pdf.set_xy(x0, y0 + 19)


def _item_detail(item: RoadmapPdfItem) -> str:
    if item.note:
        return f"{item.text}\nহালনাগাদ: {item.note}"
    return item.text


def _date_cell(item: RoadmapPdfItem) -> str:
    if item.status == "done" and item.completed_at:
        return bn_date(item.completed_at)
    return bn_date(item.target_date) if item.target_date else "—"


def _section(pdf: ReportPDF, section: RoadmapPdfSection) -> None:
    # Keep a heading with at least its first rows instead of orphaning it.
    if pdf.get_y() > pdf.h - pdf.b_margin - SECTION_MIN_SPACE_MM:
        pdf.add_page()
    section_title(
        pdf,
        f"{section.name} — {section.window}   "
        f"({bn_digits(section.done)}/{bn_digits(section.total)} সম্পন্ন — {bn_digits(section.percent)}%)",
    )
    _progress_bar(pdf, section.percent)
    # Reset state the title/bar left behind; fpdf tables inherit it.
    pdf.set_fill_color(255, 255, 255)
    pdf.set_text_color(*INK)
    pdf.set_font("bn", "", 9.5)
    if not section.items:
        pdf.set_font("bn", "", 9.5)
        pdf.set_text_color(*INK_SOFT)
        pdf.cell(text="এই সময়সীমায় কোনো পরিকল্পনা নেই।", new_x="LMARGIN", new_y="NEXT")
        pdf.set_text_color(*INK)
        return
    with pdf.table(
        col_widths=(8, 86, 20, 38, 30),
        text_align=("CENTER", "LEFT", "CENTER", "LEFT", "LEFT"),
        line_height=5.2,
        headings_style=HEADER_ROW_FILL,
        borders_layout="HORIZONTAL_LINES",
    ) as table:
        head = table.row()
        for label in ("#", "পরিকল্পনা", "অবস্থা", "তারিখ", "দায়িত্বে"):
            head.cell(label)
        for index, item in enumerate(section.items, start=1):
            row = table.row()
            row.cell(bn_digits(index))
            row.cell(_item_detail(item))
            row.cell(
                STATUS_LABELS.get(item.status, item.status),
                style=FontFace(color=STATUS_COLORS.get(item.status, INK), emphasis="BOLD"),
            )
            row.cell(_date_cell(item))
            row.cell(item.owner or "—")


def build_roadmap_pdf(data: RoadmapReportData) -> bytes:
    pdf = ReportPDF(
        data.org_name,
        data.last_updated_label,
        data.generated_at_label,
        report_title=ROADMAP_REPORT_TITLE,
        meta_line=f"সর্বশেষ আপডেট: {data.last_updated_label}   |   তৈরি: {data.generated_at_label}",
    )
    register_report_fonts(pdf)
    pdf.add_page()

    pdf.set_font("bn", "", 10)
    pdf.set_text_color(*INK_SOFT)
    pdf.cell(text="আমরা কোথায় আছি, কোথায় যাচ্ছি এবং কীভাবে যাচ্ছি।", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(2)
    pdf.set_text_color(*INK)

    _kpi_row(pdf, data)
    for section in data.sections:
        _section(pdf, section)

    return bytes(pdf.output())
