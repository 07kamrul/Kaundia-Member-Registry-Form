import { appendRow, uploadFile, uploadPdf, getRowCount } from "./google";
import { generatePdf } from "./pdf";
import { MAX_PROPERTY_COUNT, type FormData, type PropertyItem, type SubmissionResult } from "./types";
import fs from "fs";
import path from "path";

function formatPropertyType(property: PropertyItem): string {
  const types = property.propertyType.includes("অন্যান্য")
    ? property.propertyType.map((t) =>
        t === "অন্যান্য" && property.propertyTypeOther
          ? `${t} (${property.propertyTypeOther})`
          : t
      )
    : property.propertyType;
  return types.join(", ");
}

// Flattens the properties array into a fixed set of columns
// (property1_*..property{MAX_PROPERTY_COUNT}_*), leaving unused
// property columns blank when propertyCount is lower than the max.
function buildPropertyColumns(properties: PropertyItem[]): string[] {
  const columns: string[] = [];
  for (let i = 0; i < MAX_PROPERTY_COUNT; i++) {
    const property = properties[i];
    if (!property) {
      columns.push("", "", "", "", "", "");
      continue;
    }
    columns.push(
      formatPropertyType(property),
      property.khatianNo,
      property.dagNo,
      property.landQuantity,
      property.ownership,
      property.applicableDocs.join(", ")
    );
  }
  return columns;
}

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
    // Property Info (flattened, property1_*..property9_*)
    ...buildPropertyColumns(data.properties),
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

const PHOTO_DATA_URL_RE = /^data:(image\/[a-zA-Z0-9.+-]+);base64,(.+)$/;
const MIME_TO_EXT: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/jpg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
};

function decodePhotoDataUrl(
  dataUrl: string
): { buffer: Buffer; mimeType: string; ext: string } | null {
  const match = PHOTO_DATA_URL_RE.exec(dataUrl.trim());
  if (!match) return null;

  const [, mimeType, base64] = match;
  const ext = MIME_TO_EXT[mimeType] ?? "jpg";

  try {
    return { buffer: Buffer.from(base64, "base64"), mimeType, ext };
  } catch {
    return null;
  }
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

  const safeName = data.fullName.replace(/[^a-zA-Z0-9\u0980-\u09FF]/g, "_");

  // Upload to Drive
  let driveFileId: string;
  let driveFileLink: string;
  try {
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

  // Upload member photo to the same Drive folder (best-effort \u2014 a photo
  // problem shouldn't block a submission that already has its PDF saved).
  let photoFileId: string | undefined;
  let photoFileLink: string | undefined;
  if (data.memberPhoto) {
    const decoded = decodePhotoDataUrl(data.memberPhoto);
    if (!decoded) {
      console.error(`[Drive] Photo skipped: invalid image data for ${formNo}`);
      logSubmission(formNo, { warning: "Invalid member photo data, skipped upload" });
    } else {
      try {
        const photoFileName = `${safeName}_${formNo}_photo.${decoded.ext}`;
        const result = await uploadFile(photoFileName, decoded.buffer, decoded.mimeType);
        photoFileId = result.fileId;
        photoFileLink = result.fileLink;
        console.log(`[Drive] Photo uploaded: ${photoFileId}`);
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        console.error(`[Drive] Photo upload failed: ${msg}`);
        logSubmission(formNo, { warning: "Photo upload failed", details: msg });
      }
    }
  }

  logSubmission(formNo, {
    sheetRow: rowCount + 2,
    driveFileId,
    driveFileLink,
    photoFileId,
    photoFileLink,
  });

  return {
    success: true,
    formNo,
    driveFileId,
    driveFileLink,
    photoFileId,
    photoFileLink,
  };
}
