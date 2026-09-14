import { PDFDocument, StandardFonts, rgb } from "pdf-lib";
import type { FormData } from "./types";

function drawLine(
  page: ReturnType<PDFDocument["addPage"]>,
  x1: number,
  y1: number,
  x2: number,
  y2: number,
  thickness = 0.5
) {
  page.drawLine({
    start: { x: x1, y: y1 },
    end: { x: x2, y: y2 },
    thickness,
    color: rgb(0, 0, 0),
  });
}

function drawRect(
  page: ReturnType<PDFDocument["addPage"]>,
  x: number,
  y: number,
  w: number,
  h: number,
  border = true
) {
  page.drawRectangle({
    x,
    y,
    width: w,
    height: h,
    borderWidth: border ? 0.5 : 0,
    borderColor: rgb(0, 0, 0),
    color: undefined,
  });
}

export async function generatePdf(data: FormData): Promise<Buffer> {
  const pdfDoc = await PDFDocument.create();

  // Register a font that supports basic ASCII (Bengali will render as boxes without proper font embedding)
  // For production, embed a Bengali font (e.g., Noto Sans Bengali, SolaimanLipi)
  const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
  const fontBold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

  const pageWidth = 595; // A4
  const pageHeight = 842;
  const margin = 40;
  const page = pdfDoc.addPage([pageWidth, pageHeight]);

  let y = pageHeight - margin;

  // ── HEADER ──
  const titleText = "Uttar Kaundia Abashan Malik Kalyan Porishod";
  const titleWidth = fontBold.widthOfTextAtSize(titleText, 18);
  page.drawText(titleText, {
    x: (pageWidth - titleWidth) / 2,
    y,
    size: 18,
    font: fontBold,
    color: rgb(0, 0, 0),
  });
  y -= 8;

  // Subtitle
  const subText = "Member Registration Form";
  const subWidth = font.widthOfTextAtSize(subText, 12);
  page.drawText(subText, {
    x: (pageWidth - subWidth) / 2,
    y,
    size: 12,
    font,
    color: rgb(0, 0, 0),
  });
  y -= 20;

  drawLine(page, margin, y, pageWidth - margin, y, 1.5);
  y -= 5;

  // ── FORM NO & DATE ──
  page.drawText(`Form No: ${data.submissionDate.replace(/-/g, "")}`, {
    x: margin,
    y,
    size: 9,
    font,
  });
  page.drawText(`Date: ${data.submissionDate}`, {
    x: pageWidth - margin - 120,
    y,
    size: 9,
    font,
  });
  y -= 20;

  // ── SECTION: MEMBER INFO ──
  const sectionLabel = "1. Member Information";
  page.drawText(sectionLabel, {
    x: margin,
    y,
    size: 12,
    font: fontBold,
  });
  y -= 18;
  drawLine(page, margin, y, pageWidth - margin, y, 0.5);
  y -= 5;

  const memberFields: [string, string][] = [
    ["Full Name", data.fullName],
    ["Father/Husband", data.fatherOrHusband],
    ["Mother", data.mother],
    ["Date of Birth", data.dob],
    ["Nationality", data.nationality],
    ["Occupation", data.occupation],
    ["NID No", data.nid],
    ["Mobile", data.mobile],
    ["WhatsApp", data.whatsapp],
    ["Email", data.email],
  ];

  for (const [label, value] of memberFields) {
    const labelWidth = 130;
    const rowHeight = 18;

    // Draw row background
    drawRect(page, margin, y - rowHeight, pageWidth - margin * 2, rowHeight);

    // Label
    page.drawText(label + ":", {
      x: margin + 5,
      y: y - 13,
      size: 9,
      font: fontBold,
    });

    // Value
    page.drawText(value || "-", {
      x: margin + labelWidth + 5,
      y: y - 13,
      size: 9,
      font,
    });

    y -= rowHeight;
  }

  y -= 15;

  // ── SECTION: PROPERTY INFO ──
  page.drawText("2. Property Information", {
    x: margin,
    y,
    size: 12,
    font: fontBold,
  });
  y -= 18;
  drawLine(page, margin, y, pageWidth - margin, y, 0.5);
  y -= 5;

  const propertyFields: [string, string][] = [
    ["Property Type", data.propertyType === "other" ? data.propertyTypeOther : data.propertyType],
    ["Khatian No", data.khatianNo],
    ["Dag No", data.dagNo],
    ["Land Quantity", data.landQuantity],
    ["Ownership", data.ownership],
    ["Applicable Docs", data.applicableDocs.join(", ")],
  ];

  for (const [label, value] of propertyFields) {
    const labelWidth = 130;
    const rowHeight = 18;

    drawRect(page, margin, y - rowHeight, pageWidth - margin * 2, rowHeight);

    page.drawText(label + ":", {
      x: margin + 5,
      y: y - 13,
      size: 9,
      font: fontBold,
    });

    page.drawText(value || "-", {
      x: margin + labelWidth + 5,
      y: y - 13,
      size: 9,
      font,
    });

    y -= rowHeight;
  }

  y -= 15;

  // ── SECTION: NOMINEES ──
  page.drawText("3. Nominees", {
    x: margin,
    y,
    size: 12,
    font: fontBold,
  });
  y -= 18;
  drawLine(page, margin, y, pageWidth - margin, y, 0.5);
  y -= 5;

  const nomineeFields: [string, string][] = [
    ["Name", data.nominees[0]?.name || ""],
    ["Relation", data.nominees[0]?.relation || ""],
    ["Mobile", data.nominees[0]?.mobile || ""],
    ["Address", data.nominees[0]?.address || ""],
  ];

  for (const [label, value] of nomineeFields) {
    const labelWidth = 130;
    const rowHeight = 18;

    drawRect(page, margin, y - rowHeight, pageWidth - margin * 2, rowHeight);

    page.drawText(label + ":", {
      x: margin + 5,
      y: y - 13,
      size: 9,
      font: fontBold,
    });

    page.drawText(value || "-", {
      x: margin + labelWidth + 5,
      y: y - 13,
      size: 9,
      font,
    });

    y -= rowHeight;
  }

  if (data.nominees[1]) {
    y -= 5;
    page.drawText("Nominee 2:", {
      x: margin,
      y,
      size: 10,
      font: fontBold,
    });
    y -= 15;

    const nominee2Fields: [string, string][] = [
      ["Name", data.nominees[1].name],
      ["Relation", data.nominees[1].relation],
      ["Mobile", data.nominees[1].mobile],
      ["Address", data.nominees[1].address],
    ];

    for (const [label, value] of nominee2Fields) {
      const labelWidth = 130;
      const rowHeight = 18;

      drawRect(page, margin, y - rowHeight, pageWidth - margin * 2, rowHeight);

      page.drawText(label + ":", {
        x: margin + 5,
        y: y - 13,
        size: 9,
        font: fontBold,
      });

      page.drawText(value || "-", {
        x: margin + labelWidth + 5,
        y: y - 13,
        size: 9,
        font,
      });

      y -= rowHeight;
    }
  }

  y -= 15;

  // ── SECTION: PAYMENT ──
  page.drawText("4. Payment", {
    x: margin,
    y,
    size: 12,
    font: fontBold,
  });
  y -= 18;
  drawLine(page, margin, y, pageWidth - margin, y, 0.5);
  y -= 5;

  const paymentFields: [string, string][] = [
    ["Admission Fee (TK)", data.admissionFee],
    ["Subscription (TK)", data.subscription],
    ["Receipt No", data.receiptNo],
    ["Payment Method", data.paymentMethod],
  ];

  for (const [label, value] of paymentFields) {
    const labelWidth = 130;
    const rowHeight = 18;

    drawRect(page, margin, y - rowHeight, pageWidth - margin * 2, rowHeight);

    page.drawText(label + ":", {
      x: margin + 5,
      y: y - 13,
      size: 9,
      font: fontBold,
    });

    page.drawText(value || "-", {
      x: margin + labelWidth + 5,
      y: y - 13,
      size: 9,
      font,
    });

    y -= rowHeight;
  }

  y -= 20;

  // ── SIGNATURE AREA ──
  drawLine(page, margin, y, pageWidth - margin, y, 1);
  y -= 15;

  page.drawText("Signature: ________________________", {
    x: margin,
    y,
    size: 9,
    font,
  });

  page.drawText(`Date: ${data.submissionDate}`, {
    x: pageWidth - margin - 150,
    y,
    size: 9,
    font,
  });

  y -= 30;

  // ── OFFICE USE ONLY ──
  page.drawText("For Office Use Only:", {
    x: margin,
    y,
    size: 9,
    font: fontBold,
  });
  y -= 15;
  drawLine(page, margin, y, pageWidth - margin, y, 0.5);
  y -= 15;

  const officeFields = [
    "Verified By: _______________",
    "Treasurer: _______________",
    "General Secretary: _______________",
    "President: _______________",
  ];

  for (const field of officeFields) {
    page.drawText(field, {
      x: margin,
      y,
      size: 8,
      font,
    });
    y -= 15;
  }

  // Footer
  page.drawText("Uttar Kaundia Abashan Malik Kalyan Porishod", {
    x: margin,
    y: margin,
    size: 8,
    font,
    color: rgb(0.5, 0.5, 0.5),
  });

  const pdfBytes = await pdfDoc.save();
  return Buffer.from(pdfBytes);
}

export async function getPdfAsBase64(data: FormData): Promise<string> {
  const buffer = await generatePdf(data);
  return buffer.toString("base64");
}
