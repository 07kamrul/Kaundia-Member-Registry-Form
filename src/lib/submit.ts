import { appendRow, uploadFile, uploadPdf, getRowCount } from "./google";
import { generatePdf } from "./pdf";
import {
  MAX_PROPERTY_COUNT,
  MAX_CO_OWNER_COUNT,
  DOCUMENT_OPTIONS,
  type ApplicableDocEntry,
  type FormData,
  type PropertyItem,
  type SubmissionResult,
} from "./types";
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

// Flattens one property's co-owners into a fixed set of columns
// (coOwner1_name, coOwner1_phone, ..coOwner{MAX_CO_OWNER_COUNT}_*), leaving
// unused co-owner columns blank. Only meaningful when ownership === "যৌথ".
function buildCoOwnerColumns(property: PropertyItem | undefined): string[] {
  const columns: string[] = [];
  for (let i = 0; i < MAX_CO_OWNER_COUNT; i++) {
    const coOwner = property?.ownership === "যৌথ" ? property.coOwners[i] : undefined;
    columns.push(coOwner?.ownerName ?? "", coOwner?.ownerPhone ?? "");
  }
  return columns;
}

// Flattens one property's applicable-doc uploads into a fixed set of
// columns (property{n}_doc_<type>_url), one per DOCUMENT_OPTIONS entry, in
// a stable order. Blank when the doc type wasn't checked or its upload
// hasn't completed.
function buildDocColumns(property: PropertyItem | undefined): string[] {
  return DOCUMENT_OPTIONS.map(
    (type) => property?.applicableDocs.find((d) => d.type === type)?.driveUrl ?? ""
  );
}

// Flattens the properties array into a fixed set of columns
// (property1_*..property{MAX_PROPERTY_COUNT}_*), leaving unused
// property columns blank when propertyCount is lower than the max.
function buildPropertyColumns(properties: PropertyItem[]): string[] {
  const columns: string[] = [];
  for (let i = 0; i < MAX_PROPERTY_COUNT; i++) {
    const property = properties[i];
    if (!property) {
      columns.push(
        "",
        "",
        "",
        "",
        "",
        "",
        ...buildCoOwnerColumns(undefined),
        ...buildDocColumns(undefined)
      );
      continue;
    }
    columns.push(
      formatPropertyType(property),
      property.khatianNo,
      property.dagNo,
      property.landQuantity,
      property.ownership,
      property.applicableDocs.map((d) => d.type).join(", "),
      ...buildCoOwnerColumns(property),
      ...buildDocColumns(property)
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

const DATA_URL_RE = /^data:([a-zA-Z0-9.+-]+\/[a-zA-Z0-9.+-]+);base64,(.+)$/;
const MIME_TO_EXT: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/jpg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
  "application/pdf": "pdf",
};

function decodeDataUrl(
  dataUrl: string
): { buffer: Buffer; mimeType: string; ext: string } | null {
  const match = DATA_URL_RE.exec(dataUrl.trim());
  if (!match) return null;

  const [, mimeType, base64] = match;
  const ext = MIME_TO_EXT[mimeType] ?? "bin";

  try {
    return { buffer: Buffer.from(base64, "base64"), mimeType, ext };
  } catch {
    return null;
  }
}

// Sanitizes a doc type label (may contain "/" e.g. "খতিয়ান/পর্চা") for use in
// a filename, keeping Bengali script and alphanumerics.
function safeFileSegment(value: string): string {
  return value.replace(/[^a-zA-Z0-9ঀ-৿]/g, "_");
}

// Uploads every attached প্রযোজ্য কাগজ file to Drive and returns a new
// properties array (immutable copy) with each entry's `driveUrl` populated.
// Throws with a message naming the specific failed item so submission can
// be blocked without silently dropping a mandatory attachment.
async function uploadApplicableDocs(
  properties: PropertyItem[],
  formNo: string,
  safeName: string
): Promise<PropertyItem[]> {
  const uploaded: PropertyItem[] = [];

  for (let i = 0; i < properties.length; i++) {
    const property = properties[i];
    const applicableDocs: ApplicableDocEntry[] = [];

    for (const doc of property.applicableDocs) {
      if (!doc.fileDataUrl) {
        throw new Error(
          `সম্পত্তি #${i + 1}: "${doc.type}" এর ফাইল সংযুক্ত করা হয়নি`
        );
      }
      const decoded = decodeDataUrl(doc.fileDataUrl);
      if (!decoded) {
        throw new Error(
          `সম্পত্তি #${i + 1}: "${doc.type}" এর ফাইল পড়া যায়নি`
        );
      }
      try {
        const fileName = `${safeName}_${formNo}_property${i + 1}_${safeFileSegment(
          doc.type
        )}.${decoded.ext}`;
        const result = await uploadFile(fileName, decoded.buffer, decoded.mimeType);
        applicableDocs.push({ ...doc, driveUrl: result.fileLink });
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        throw new Error(`সম্পত্তি #${i + 1}: "${doc.type}" আপলোড ব্যর্থ হয়েছে (${msg})`);
      }
    }

    uploaded.push({ ...property, applicableDocs });
  }

  return uploaded;
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
  const safeName = data.fullName.replace(/[^a-zA-Z0-9ঀ-৿]/g, "_");

  // Upload each checked প্রযোজ্য কাগজ attachment before building the row/PDF,
  // so their Drive links can be written in the same pass. Any failed or
  // missing mandatory attachment blocks the whole submission.
  let properties: PropertyItem[];
  try {
    properties = await uploadApplicableDocs(data.properties, formNo, safeName);
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error(`[Drive] Applicable doc upload failed: ${msg}`);
    logSubmission(formNo, { error: "Applicable doc upload failed", details: msg });
    return { success: false, formNo, error: msg };
  }
  data = { ...data, properties };

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
    const decoded = decodeDataUrl(data.memberPhoto);
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
