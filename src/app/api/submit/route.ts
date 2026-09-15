import { NextRequest, NextResponse } from "next/server";
import { processSubmission } from "@/lib/submit";
import { generatePdf } from "@/lib/pdf";
import { createEmptyProperty, type FormData } from "@/lib/types";

function validate(data: FormData): string[] {
  const errors: string[] = [];

  if (!data.fullName?.trim()) errors.push("পূর্ণ নাম আবশ্যক");
  if (!data.fatherOrHusband?.trim()) errors.push("পিতা/স্বামী আবশ্যক");
  if (!data.mother?.trim()) errors.push("মাতা আবশ্যক");
  if (!data.dob) errors.push("জন্ম তারিখ আবশ্যক");
  if (!data.nationality?.trim()) data.nationality = "বাংলাদেশী";

  if (!data.mobile?.trim()) {
    errors.push("মোবাইল আবশ্যক");
  } else if (!/^01[3-9]\d{8}$/.test(data.mobile.trim())) {
    errors.push("মোবাইল নম্বর সঠিক নয় (01XXXXXXXXX)");
  }

  if (data.email?.trim() && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data.email.trim())) {
    errors.push("ই-মেইল সঠিক নয়");
  }

  if (data.nid?.trim() && !/^\d{10,17}$/.test(data.nid.trim())) {
    errors.push("NID নম্বর ১০-১৭ সংখ্যার হতে হবে");
  }

  if (!data.properties?.length) {
    errors.push("অন্তত একটি সম্পত্তি যোগ করুন");
  } else {
    data.properties.forEach((property, i) => {
      const label = `সম্পত্তি #${i + 1}`;
      if (!property.propertyType?.length) errors.push(`${label}: সম্পত্তির ধরন আবশ্যক`);
      if (!property.ownership?.trim()) errors.push(`${label}: মালিকানা আবশ্যক`);
    });
  }

  if (!data.admissionFee && data.admissionFee !== "0") errors.push("ভর্তি ফি আবশ্যক");
  if (!data.subscription && data.subscription !== "0") errors.push("চাঁদা আবশ্যক");
  if (!data.paymentMethod?.trim()) errors.push("পেমেন্ট মাধ্যম আবশ্যক");

  return errors;
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json() as FormData;

    // Server-side validation
    const errors = validate(body);
    if (errors.length > 0) {
      return NextResponse.json(
        { success: false, error: errors.join("; ") },
        { status: 400 }
      );
    }

    // Set default nationality
    if (!body.nationality?.trim()) {
      body.nationality = "বাংলাদেশী";
    }

    const result = await processSubmission(body);

    if (!result.success) {
      return NextResponse.json(
        { success: false, error: result.error },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      formNo: result.formNo,
      driveFileLink: result.driveFileLink,
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : "Unknown error";
    console.error("[API] Unhandled:", msg);
    return NextResponse.json(
      { success: false, error: "সার্ভারে সমস্যা হয়েছে। পরে আবার চেষ্টা করুন।" },
      { status: 500 }
    );
  }
}

// PDF download endpoint
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const fullName = searchParams.get("name") || "member";
    const formNo = searchParams.get("formNo") || "KK-0000";

    // Generate a demo PDF
    const data: FormData = {
      fullName,
      fatherOrHusband: "",
      mother: "",
      dob: "",
      nationality: "বাংলাদেশী",
      occupation: "",
      nid: "",
      mobile: "",
      whatsapp: "",
      email: "",
      propertyCount: 1,
      properties: [createEmptyProperty()],
      nominees: [],
      admissionFee: "",
      subscription: "",
      receiptNo: "",
      paymentMethod: "",
      memberSignature: "",
      submissionDate: new Date().toISOString().split("T")[0],
      website: "",
    };

    const pdfBuffer = await generatePdf(data);

    return new NextResponse(new Uint8Array(pdfBuffer), {
      headers: {
        "Content-Type": "application/pdf",
        "Content-Disposition": `attachment; filename="${fullName}_${formNo}.pdf"`,
      },
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : "Unknown error";
    console.error("[PDF Download] Error:", msg);
    return NextResponse.json(
      { error: "PDF ডাউনলোডে সমস্যা হয়েছে" },
      { status: 500 }
    );
  }
}
