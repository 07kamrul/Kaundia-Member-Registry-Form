import { appendRow, uploadPdf, getRowCount } from "./google";
import { generatePdf } from "./pdf";
import type { FormData, SubmissionResult } from "./types";
import fs from "fs";
import path from "path";

function buildRow(data: FormData, formNo: string): (string | number)[] {
  return [
    formNo,
    data.submissionDate,
    // Member Info
    data.fullName,
    data.fatherOrHusband,
    data.mother,
    data.dob,
    data.nationality,
    data.occupation,
    data.nid,
    data.mobile,
    data.whatsapp,
    data.email,
    // Property Info
    data.propertyType === "other" ? data.propertyTypeOther : data.propertyType,
    data.khatianNo,
    data.dagNo,
    data.landQuantity,
    data.ownership,
    data.applicableDocs.join(", "),
    // Nominee 1
    data.nominees[0]?.name ?? "",
    data.nominees[0]?.relation ?? "",
    data.nominees[0]?.mobile ?? "",
    data.nominees[0]?.address ?? "",
    // Nominee 2
    data.nominees[1]?.name ?? "",
    data.nominees[1]?.relation ?? "",
    data.nominees[1]?.mobile ?? "",
    data.nominees[1]?.address ?? "",
    // Payment
    data.admissionFee,
    data.subscription,
    data.receiptNo,
    data.paymentMethod,
    // Signature & Meta
    data.memberSignature ? "Yes" : "No",
    "", // Drive link (filled after upload)
  ];
}

function logSubmission(formNo: string, row: Record<string, unknown>) {
  const logDir = path.resolve(process.cwd(), "logs");
  if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
  }
  const logFile = path.join(logDir, "submissions.log");
  const entry = JSON.stringify({
    formNo,
    timestamp: new Date().toISOString(),
    ...row,
  });
  fs.appendFileSync(logFile, entry + "\n");
}

export async function processSubmission(data: FormData): Promise<SubmissionResult> {
  // Validate honeypot
  if (data.website) {
    return { success: false, formNo: "", error: "Spam detected" };
  }

  // Generate form number
  const rowCount = await getRowCount();
  const formNo = `KK-${String(rowCount + 1).padStart(4, "0")}`;

  // Build and insert row
  const rowValues = buildRow(data, formNo);

  try {
    const { updatedRange } = await appendRow(rowValues);
    console.log(`[Sheets] Appended row: ${updatedRange}`);
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error(`[Sheets] Failed: ${msg}`);
    logSubmission(formNo, { error: "Sheets append failed", details: msg });
    return {
      success: false,
      formNo,
      error: `Failed to save to Google Sheets: ${msg}`,
    };
  }

  // Generate PDF
  let pdfBuffer: Buffer;
  try {
    pdfBuffer = await generatePdf(data);
    console.log(`[PDF] Generated for ${formNo}`);
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error(`[PDF] Generation failed: ${msg}`);
    logSubmission(formNo, { error: "PDF generation failed", details: msg });
    return {
      success: false,
      formNo,
      error: `Failed to generate PDF: ${msg}`,
    };
  }

  // Upload to Drive
  let driveFileId: string;
  let driveFileLink: string;
  try {
    const safeName = data.fullName.replace(/[^a-zA-Z0-9\u0980-\u09FF]/g, "_");
    const fileName = `${safeName}_${formNo}.pdf`;
    const result = await uploadPdf(fileName, pdfBuffer);
    driveFileId = result.fileId;
    driveFileLink = result.fileLink;
    console.log(`[Drive] Uploaded: ${driveFileId}`);
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error(`[Drive] Upload failed: ${msg}`);
    logSubmission(formNo, { error: "Drive upload failed", details: msg });
    return {
      success: false,
      formNo,
      error: `Failed to upload PDF to Drive: ${msg}`,
    };
  }

  logSubmission(formNo, {
    sheetRow: rowCount + 2,
    driveFileId,
    driveFileLink,
  });

  return {
    success: true,
    formNo,
    driveFileId,
    driveFileLink,
  };
}
