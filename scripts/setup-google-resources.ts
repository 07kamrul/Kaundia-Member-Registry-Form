/**
 * One-shot setup: creates the Google Sheet and Drive folder this app needs,
 * pre-formats the Sheet header row, shares both back to your personal
 * Google account, and writes the resulting IDs into .env.
 *
 * Usage: npm run setup:google
 */
import "dotenv/config";
import fs from "fs";
import path from "path";
import readline from "readline";
import { google } from "googleapis";
import { getAuth } from "../src/lib/google";

const ENV_PATH = path.resolve(process.cwd(), ".env");
const ENV_EXAMPLE_PATH = path.resolve(process.cwd(), ".env.example");

const SHEET_TITLE = "কাউন্দিয়া রেজিস্ট্রেশন";
const FOLDER_NAME = "কাউন্দিয়া রেজিস্ট্রেশন PDF";

// Must match README.md's header row exactly.
const HEADER_ROW = [
  "ফর্ম নং", "তারিখ", "পূর্ণ নাম", "পিতা/স্বামী", "মাতা", "জন্ম তারিখ",
  "জাতীয়তা", "পেশা", "NID নং", "মোবাইল", "WhatsApp", "ই-মেইল",
  "সম্পত্তির ধরন", "খতিয়ান নং", "দাগ নং", "জমির পরিমাণ", "মালিকানা",
  "প্রযোজ্য কাগজ", "নমিনি১-নাম", "নমিনি১-সম্পর্ক", "নমিনি১-মোবাইল",
  "নমিনি১-ঠিকানা", "নমিনি২-নাম", "নমিনি২-সম্পর্ক", "নমিনি২-মোবাইল",
  "নমিনি২-ঠিকানা", "ভর্তি ফি", "চাঁদা", "রসিদ নং", "পেমেন্ট মাধ্যম",
  "স্বাক্ষর", "Drive লিংক",
];

function ask(question: string): Promise<string> {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

function readEnvFile(): string {
  if (fs.existsSync(ENV_PATH)) return fs.readFileSync(ENV_PATH, "utf-8");
  if (fs.existsSync(ENV_EXAMPLE_PATH)) return fs.readFileSync(ENV_EXAMPLE_PATH, "utf-8");
  return "";
}

function upsertEnvVar(content: string, key: string, value: string): string {
  const line = `${key}=${value}`;
  const pattern = new RegExp(`^${key}=.*$`, "m");
  if (pattern.test(content)) {
    return content.replace(pattern, line);
  }
  const withNewline = content.endsWith("\n") || content === "" ? content : content + "\n";
  return `${withNewline}${line}\n`;
}

async function ensureCredentials(): Promise<void> {
  if (process.env.GOOGLE_SERVICE_ACCOUNT_JSON) return;

  const answer = await ask(
    "GOOGLE_SERVICE_ACCOUNT_JSON সেট করা নেই। Service Account JSON ফাইলের পাথ দিন: "
  );
  if (!answer) {
    throw new Error("Service Account JSON পাথ ছাড়া এগোনো যাবে না।");
  }
  process.env.GOOGLE_SERVICE_ACCOUNT_JSON = answer;
}

async function confirmOverwrite(envContent: string): Promise<void> {
  const hasSheetId = /^GOOGLE_SHEET_ID=(?!your-sheet-id-here\s*$).+$/m.test(envContent);
  const hasFolderId = /^GOOGLE_DRIVE_FOLDER_ID=(?!your-folder-id-here\s*$).+$/m.test(envContent);
  if (!hasSheetId && !hasFolderId) return;

  const answer = await ask(
    ".env এ ইতিমধ্যে GOOGLE_SHEET_ID/GOOGLE_DRIVE_FOLDER_ID আছে। নতুন Sheet ও Folder তৈরি করে ওভাররাইট করবেন? (yes/no): "
  );
  if (answer.toLowerCase() !== "yes" && answer.toLowerCase() !== "y") {
    throw new Error("বাতিল করা হয়েছে — বিদ্যমান রিসোর্স অক্ষত রাখা হলো।");
  }
}

async function createSheet(auth: ReturnType<typeof getAuth>) {
  const sheets = google.sheets({ version: "v4", auth });

  const created = await sheets.spreadsheets.create({
    requestBody: {
      properties: { title: SHEET_TITLE },
      sheets: [{ properties: { title: "Sheet1" } }],
    },
  });
  const spreadsheetId = created.data.spreadsheetId;
  if (!spreadsheetId) throw new Error("Sheet তৈরি ব্যর্থ হয়েছে — spreadsheetId পাওয়া যায়নি।");

  await sheets.spreadsheets.values.update({
    spreadsheetId,
    range: "Sheet1!A1",
    valueInputOption: "RAW",
    requestBody: { values: [HEADER_ROW] },
  });

  // Bold + freeze the header row.
  await sheets.spreadsheets.batchUpdate({
    spreadsheetId,
    requestBody: {
      requests: [
        {
          repeatCell: {
            range: { sheetId: 0, startRowIndex: 0, endRowIndex: 1 },
            cell: { userEnteredFormat: { textFormat: { bold: true } } },
            fields: "userEnteredFormat.textFormat.bold",
          },
        },
        {
          updateSheetProperties: {
            properties: { sheetId: 0, gridProperties: { frozenRowCount: 1 } },
            fields: "gridProperties.frozenRowCount",
          },
        },
      ],
    },
  });

  return spreadsheetId;
}

async function createFolder(auth: ReturnType<typeof getAuth>): Promise<string> {
  const drive = google.drive({ version: "v3", auth });
  const created = await drive.files.create({
    requestBody: {
      name: FOLDER_NAME,
      mimeType: "application/vnd.google-apps.folder",
    },
    fields: "id",
  });
  const folderId = created.data.id;
  if (!folderId) throw new Error("Folder তৈরি ব্যর্থ হয়েছে — folder id পাওয়া যায়নি।");
  return folderId;
}

async function shareWithOwner(
  auth: ReturnType<typeof getAuth>,
  fileId: string,
  ownerEmail: string,
  label: string
): Promise<void> {
  const drive = google.drive({ version: "v3", auth });
  try {
    await drive.permissions.create({
      fileId,
      sendNotificationEmail: false,
      requestBody: { type: "user", role: "writer", emailAddress: ownerEmail },
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.warn(`⚠️  ${label} শেয়ার করা যায়নি (${ownerEmail}): ${msg}`);
  }
}

async function main() {
  console.log("== কাউন্দিয়া রেজিস্ট্রেশন — Google Sheet ও Drive Folder সেটআপ ==\n");

  await ensureCredentials();

  const envContent = readEnvFile();
  await confirmOverwrite(envContent);

  const ownerEmail = await ask("আপনার ব্যক্তিগত Gmail (Editor অ্যাক্সেসের জন্য): ");

  const auth = getAuth();

  console.log("\n📄 Sheet তৈরি হচ্ছে...");
  const spreadsheetId = await createSheet(auth);
  console.log(`✅ Sheet তৈরি হয়েছে: https://docs.google.com/spreadsheets/d/${spreadsheetId}/edit`);

  console.log("\n📁 Drive Folder তৈরি হচ্ছে...");
  const folderId = await createFolder(auth);
  console.log(`✅ Folder তৈরি হয়েছে: https://drive.google.com/drive/folders/${folderId}`);

  if (ownerEmail) {
    console.log(`\n🔗 ${ownerEmail} কে Editor হিসেবে শেয়ার করা হচ্ছে...`);
    await shareWithOwner(auth, spreadsheetId, ownerEmail, "Sheet");
    await shareWithOwner(auth, folderId, ownerEmail, "Folder");
  }

  let updatedEnv = readEnvFile();
  updatedEnv = upsertEnvVar(updatedEnv, "GOOGLE_SHEET_ID", spreadsheetId);
  updatedEnv = upsertEnvVar(updatedEnv, "GOOGLE_DRIVE_FOLDER_ID", folderId);
  fs.writeFileSync(ENV_PATH, updatedEnv);

  console.log("\n✅ .env আপডেট হয়েছে GOOGLE_SHEET_ID ও GOOGLE_DRIVE_FOLDER_ID দিয়ে।");
  console.log("\nসম্পন্ন! এখন `npm run dev` চালিয়ে একটি টেস্ট ফর্ম সাবমিট করুন।");
}

main().catch((err) => {
  const msg = err instanceof Error ? err.message : String(err);
  console.error(`\n❌ সেটআপ ব্যর্থ হয়েছে: ${msg}`);
  process.exit(1);
});
