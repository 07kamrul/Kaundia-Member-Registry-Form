"""Official minutes PDF for a meeting - same letterhead, palette and Bangla
shaping as the fund transparency / roadmap reports (app.services.finance_pdf).
"""
from dataclasses import dataclass
from datetime import date

from app.services.finance import BN_MONTHS
from app.services.finance_pdf import (
    CREAM,
    GOLD,
    GREEN_DARK,
    GREEN_MID,
    HEADER_ROW_FILL,
    INK,
    INK_SOFT,
    RED,
    ReportPDF,
    register_report_fonts,
    section_title,
)

RESOLUTION_BOOK_REPORT_TITLE = "সভার কার্যবিবরণী  •  Meeting Minutes"

_BN_DIGITS = str.maketrans("0123456789", "০১২৩৪৫৬৭৮৯")

STATUS_LABELS = {"pending": "অপেক্ষমাণ", "in_progress": "চলমান", "done": "সম্পন্ন"}
TYPE_LABELS = {"online": "অনলাইন", "offline": "অফলাইন"}


def bn_digits(value: int | str) -> str:
    return str(value).translate(_BN_DIGITS)


def bn_date(value: date | None) -> str:
    if value is None:
        return "—"
    return bn_digits(f"{value.day} {BN_MONTHS[value.month - 1]} {value.year}")


@dataclass(frozen=True)
class MinutesPdfResolution:
    resolution_no: int
    decision: str
    vote_for: int
    vote_against: int
    vote_neutral: int
    assigned_to: str | None
    task: str | None
    due_date: date | None
    status: str


@dataclass(frozen=True)
class MinutesPdfAttendance:
    full_name: str
    status: str


@dataclass(frozen=True)
class MinutesPdfData:
    org_name: str
    generated_at_label: str
    meeting_no: str
    meeting_date: date
    meeting_time: str | None
    meeting_type: str
    chairperson: str
    agenda: str
    summary: str | None
    next_meeting_date: date | None
    resolutions: tuple[MinutesPdfResolution, ...]
    attendance: tuple[MinutesPdfAttendance, ...]


def _vote_bar(pdf: ReportPDF, vote_for: int, vote_against: int, vote_neutral: int) -> None:
    total = vote_for + vote_against + vote_neutral
    width = pdf.w - pdf.l_margin - pdf.r_margin
    x, y = pdf.l_margin, pdf.get_y()
    bar_height = 2.6
    pdf.set_fill_color(232, 229, 218)
    pdf.rect(x, y, width, bar_height, style="F")
    if total > 0:
        segments = (
            (vote_for, GREEN_MID),
            (vote_against, RED),
            (vote_neutral, GOLD),
        )
        cursor = x
        for count, color in segments:
            if count <= 0:
                continue
            seg_width = width * count / total
            pdf.set_fill_color(*color)
            pdf.rect(cursor, y, seg_width, bar_height, style="F")
            cursor += seg_width
    pdf.set_y(y + bar_height + 2)


def _header_block(pdf: ReportPDF, data: MinutesPdfData) -> None:
    width = pdf.w - pdf.l_margin - pdf.r_margin
    pdf.set_fill_color(*CREAM)
    pdf.set_draw_color(*GOLD)
    pdf.set_line_width(0.3)
    x0, y0 = pdf.l_margin, pdf.get_y()
    pdf.rect(x0, y0, width, 18, style="DF")
    pairs = [
        ("সভা নম্বর", data.meeting_no),
        ("তারিখ", bn_date(data.meeting_date)),
        ("ধরন", TYPE_LABELS.get(data.meeting_type, data.meeting_type)),
        ("সভাপতি", data.chairperson),
    ]
    cell_width = width / 4
    for index, (label, value) in enumerate(pairs):
        x = x0 + index * cell_width
        pdf.set_xy(x + 2, y0 + 2.5)
        pdf.set_text_color(*INK_SOFT)
        pdf.set_font("bn", "", 8)
        pdf.cell(text=label)
        pdf.set_xy(x + 2, y0 + 7)
        pdf.set_text_color(*INK)
        pdf.set_font("bn", "B", 9.5)
        pdf.multi_cell(w=cell_width - 4, h=5, text=value, new_x="RIGHT", new_y="TOP")
    pdf.set_xy(x0, y0 + 21)


def build_meeting_minutes_pdf(data: MinutesPdfData) -> bytes:
    pdf = ReportPDF(
        data.org_name,
        data.meeting_no,
        data.generated_at_label,
        report_title=RESOLUTION_BOOK_REPORT_TITLE,
        meta_line=f"সভা নম্বর: {data.meeting_no}   |   তারিখ: {bn_date(data.meeting_date)}   |   তৈরি: {data.generated_at_label}",
    )
    register_report_fonts(pdf)
    pdf.add_page()

    _header_block(pdf, data)

    # Agenda
    section_title(pdf, "আলোচ্যসূচি")
    pdf.set_font("bn", "", 10)
    pdf.set_text_color(*INK)
    pdf.multi_cell(w=0, text=data.agenda, new_x="LMARGIN", new_y="NEXT")
    pdf.ln(1)

    # Summary
    section_title(pdf, "আলোচনার সারসংক্ষেপ")
    pdf.set_font("bn", "", 10)
    pdf.multi_cell(w=0, text=data.summary or "—", new_x="LMARGIN", new_y="NEXT")

    # Attendance
    section_title(
        pdf,
        f"উপস্থিতি — {bn_digits(sum(1 for a in data.attendance if a.status == 'present'))}"
        f"/{bn_digits(len(data.attendance))} উপস্থিত",
    )
    if data.attendance:
        with pdf.table(
            col_widths=(10, 110, 40),
            text_align=("CENTER", "LEFT", "CENTER"),
            line_height=5.2,
            headings_style=HEADER_ROW_FILL,
            borders_layout="HORIZONTAL_LINES",
        ) as table:
            head = table.row()
            for label in ("#", "সদস্যের নাম", "উপস্থিতি"):
                head.cell(label)
            for index, entry in enumerate(data.attendance, start=1):
                row = table.row()
                row.cell(bn_digits(index))
                row.cell(entry.full_name)
                row.cell("উপস্থিত" if entry.status == "present" else "অনুপস্থিত")
    else:
        pdf.set_font("bn", "", 9.5)
        pdf.set_text_color(*INK_SOFT)
        pdf.cell(text="উপস্থিতি রেকর্ড করা হয়নি।", new_x="LMARGIN", new_y="NEXT")
        pdf.set_text_color(*INK)

    # Resolutions with vote bars
    section_title(pdf, f"গৃহীত সিদ্ধান্ত — {bn_digits(len(data.resolutions))} টি")
    if not data.resolutions:
        pdf.set_font("bn", "", 9.5)
        pdf.set_text_color(*INK_SOFT)
        pdf.cell(text="কোনো সিদ্ধান্ত রেকর্ড করা হয়নি।", new_x="LMARGIN", new_y="NEXT")
        pdf.set_text_color(*INK)
    for resolution in data.resolutions:
        if pdf.get_y() > 220:
            pdf.add_page()
        pdf.set_font("bn", "B", 10)
        pdf.set_text_color(*GREEN_DARK)
        pdf.cell(
            text=f"সিদ্ধান্ত-{bn_digits(resolution.resolution_no)}  ({STATUS_LABELS.get(resolution.status, resolution.status)})",
            new_x="LMARGIN",
            new_y="NEXT",
        )
        pdf.set_font("bn", "", 9.5)
        pdf.set_text_color(*INK)
        pdf.multi_cell(w=0, text=resolution.decision, new_x="LMARGIN", new_y="NEXT")
        _vote_bar(pdf, resolution.vote_for, resolution.vote_against, resolution.vote_neutral)
        pdf.set_font("bn", "", 8.5)
        pdf.set_text_color(*INK_SOFT)
        votes = (
            f"পক্ষে {bn_digits(resolution.vote_for)} • বিপক্ষে {bn_digits(resolution.vote_against)}"
            f" • নিরপেক্ষ {bn_digits(resolution.vote_neutral)}"
        )
        extras: list[str] = [votes]
        if resolution.assigned_to:
            extras.append(f"দায়িত্বে: {resolution.assigned_to}")
        if resolution.task:
            extras.append(f"কাজ: {resolution.task}")
        if resolution.due_date:
            extras.append(f"শেষ তারিখ: {bn_date(resolution.due_date)}")
        pdf.multi_cell(w=0, text="   |   ".join(extras), new_x="LMARGIN", new_y="NEXT")
        pdf.ln(1.5)
        pdf.set_text_color(*INK)

    # Next meeting
    if data.next_meeting_date:
        section_title(pdf, "পরবর্তী সভা")
        pdf.set_font("bn", "", 10)
        pdf.cell(text=f"পরবর্তী সভার তারিখ: {bn_date(data.next_meeting_date)}", new_x="LMARGIN", new_y="NEXT")

    return bytes(pdf.output())
