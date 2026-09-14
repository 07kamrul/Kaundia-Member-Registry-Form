import { google } from "googleapis";
import type { GoogleAuth } from "googleapis-common";
import fs from "fs";
import path from "path";

let _auth: GoogleAuth | null = null;

function getAuth(): GoogleAuth {
  if (_auth) return _auth;

  const rawJson = process.env.GOOGLE_SERVICE_ACCOUNT_JSON;
  if (!rawJson) {
    throw new Error("GOOGLE_SERVICE_ACCOUNT_JSON is not set");
  }

  let credentials: Record<string, string>;
  try {
    // If it's a file path, read and parse
    const resolved = path.isAbsolute(rawJson)
      ? rawJson
      : path.resolve(/* turbopackIgnore: true */ process.cwd(), rawJson);
    if (fs.existsSync(resolved)) {
      credentials = JSON.parse(fs.readFileSync(resolved, "utf-8"));
    } else {
      // Try parsing as inline JSON
      credentials = JSON.parse(rawJson);
    }
  } catch {
    // Last resort: try parsing directly
    credentials = JSON.parse(rawJson);
  }

  _auth = new google.auth.GoogleAuth({
    credentials,
    scopes: [
      "https://www.googleapis.com/auth/spreadsheets",
      "https://www.googleapis.com/auth/drive.file",
    ],
  });

  return _auth;
}

export async function appendRow(
  values: (string | number)[]
): Promise<{ spreadsheetId: string; updatedRange: string }> {
  const auth = getAuth();
  const sheets = google.sheets({ version: "v4", auth });

  const sheetId = process.env.GOOGLE_SHEET_ID;
  if (!sheetId) throw new Error("GOOGLE_SHEET_ID is not set");

  const res = await sheets.spreadsheets.values.append({
    spreadsheetId: sheetId,
    range: "Sheet1!A:Z",
    valueInputOption: "RAW",
    insertDataOption: "INSERT_ROWS",
    requestBody: { values: [values] },
  });

  return {
    spreadsheetId: sheetId,
    updatedRange: res.data.updates?.updatedRange ?? "",
  };
}

export async function getRowCount(): Promise<number> {
  const auth = getAuth();
  const sheets = google.sheets({ version: "v4", auth });

  const sheetId = process.env.GOOGLE_SHEET_ID;
  if (!sheetId) throw new Error("GOOGLE_SHEET_ID is not set");

  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: sheetId,
    range: "Sheet1!A:A",
  });

  return (res.data.values?.length ?? 1) - 1; // minus header
}

export async function uploadPdf(
  fileName: string,
  pdfBuffer: Buffer
): Promise<{ fileId: string; fileLink: string }> {
  const auth = getAuth();
  const drive = google.drive({ version: "v3", auth });

  const folderId = process.env.GOOGLE_DRIVE_FOLDER_ID;
  if (!folderId) throw new Error("GOOGLE_DRIVE_FOLDER_ID is not set");

  const res = await drive.files.create({
    requestBody: {
      name: fileName,
      parents: [folderId],
    },
    media: {
      mimeType: "application/pdf",
      body: pdfBuffer,
    },
    fields: "id, webViewLink",
  });

  const fileId = res.data.id ?? "";
  const fileLink =
    res.data.webViewLink ?? `https://drive.google.com/file/d/${fileId}/view`;

  return { fileId, fileLink };
}

export { getAuth };
