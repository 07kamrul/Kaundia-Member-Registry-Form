"use client";

import React, { useState, useRef } from "react";
import Image from "next/image";
import SignatureCanvas from "react-signature-canvas";

const PROPERTY_TYPES = ["জমি", "বাড়ি", "ফ্ল্যাট", "প্লট", "অন্যান্য"];
const OWNERSHIP_TYPES = ["একক", "যৌথ"];
const DOCUMENT_OPTIONS = [
  "খতিয়ান/পর্চা",
  "নামজারি/মিউটেশন",
  "খাজনা/কর রশিদ",
  "উত্তরাধিকার সনদ",
];
const PAYMENT_METHODS = ["নগদ", "ব্যাংক", "MFS (বিকাশ/নগদ/রকেট)", "অন্যান্য"];

interface Nominee {
  name: string;
  relation: string;
  mobile: string;
  address: string;
}

interface FormData {
  fullName: string;
  fatherOrHusband: string;
  mother: string;
  dob: string;
  nationality: string;
  occupation: string;
  nid: string;
  mobile: string;
  whatsapp: string;
  email: string;
  permanentAddress: string;
  currentAddress: string;
  propertyType: string;
  propertyTypeOther: string;
  khatianNo: string;
  dagNo: string;
  landQuantity: string;
  ownership: string;
  applicableDocs: string[];
  urgentContactName: string;
  urgentContactRelation: string;
  urgentContactMobile: string;
  urgentContactAddress: string;
  nominees: Nominee[];
  admissionFee: string;
  subscription: string;
  receiptNo: string;
  paymentMethod: string;
  memberSignature: string;
  submissionDate: string;
  declarationAccepted: boolean;
  website: string;
}

const initialFormData: FormData = {
  fullName: "",
  fatherOrHusband: "",
  mother: "",
  dob: "",
  nationality: "বাংলাদেশী",
  occupation: "",
  nid: "",
  mobile: "",
  whatsapp: "",
  email: "",
  permanentAddress: "",
  currentAddress: "",
  propertyType: "",
  propertyTypeOther: "",
  khatianNo: "",
  dagNo: "",
  landQuantity: "",
  ownership: "",
  applicableDocs: [],
  urgentContactName: "",
  urgentContactRelation: "",
  urgentContactMobile: "",
  urgentContactAddress: "",
  nominees: [{ name: "", relation: "", mobile: "", address: "" }],
  admissionFee: "",
  subscription: "",
  receiptNo: "",
  paymentMethod: "",
  memberSignature: "",
  submissionDate: new Date().toISOString().split("T")[0],
  declarationAccepted: false,
  website: "",
};

export default function RegistrationForm() {
  const [formData, setFormData] = useState<FormData>(initialFormData);
  const [errors, setErrors] = useState<string[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState<{ formNo: string; driveFileLink: string } | null>(null);
  const sigRef = useRef<SignatureCanvas>(null);

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>
  ) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleDocToggle = (doc: string) => {
    setFormData((prev) => {
      const docs = prev.applicableDocs.includes(doc)
        ? prev.applicableDocs.filter((d) => d !== doc)
        : [...prev.applicableDocs, doc];
      return { ...prev, applicableDocs: docs };
    });
  };

  const handleNomineeChange = (
    index: number,
    field: keyof Nominee,
    value: string
  ) => {
    setFormData((prev) => {
      const nominees = [...prev.nominees];
      nominees[index] = { ...nominees[index], [field]: value };
      return { ...prev, nominees };
    });
  };

  const addNominee = () => {
    if (formData.nominees.length < 5) {
      setFormData((prev) => ({
        ...prev,
        nominees: [...prev.nominees, { name: "", relation: "", mobile: "", address: "" }],
      }));
    }
  };

  const removeNominee = (index: number) => {
    if (formData.nominees.length > 1) {
      setFormData((prev) => ({
        ...prev,
        nominees: prev.nominees.filter((_, i) => i !== index),
      }));
    }
  };

  const clearSignature = () => {
    sigRef.current?.clear();
    setFormData((prev) => ({ ...prev, memberSignature: "" }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrors([]);

    // Client-side validation
    const clientErrors: string[] = [];
    if (!formData.fullName.trim()) clientErrors.push("পূর্ণ নাম আবশ্যক");
    if (!formData.fatherOrHusband.trim()) clientErrors.push("পিতা/স্বামী আবশ্যক");
    if (!formData.mother.trim()) clientErrors.push("মাতা আবশ্যক");
    if (!formData.dob) clientErrors.push("জন্ম তারিখ আবশ্যক");
    if (!formData.mobile.trim()) clientErrors.push("মোবাইল আবশ্যক");
    else if (!/^01[3-9]\d{8}$/.test(formData.mobile.trim()))
      clientErrors.push("মোবাইল নম্বর সঠিক নয় (01XXXXXXXXX)");
    if (formData.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email))
      clientErrors.push("ই-মেইল সঠিক নয়");
    if (formData.nid && !/^\d{10,17}$/.test(formData.nid))
      clientErrors.push("NID নম্বর ১০-১৭ সংখ্যার হতে হবে");
    if (!formData.propertyType) clientErrors.push("সম্পত্তির ধরন আবশ্যক");
    if (!formData.ownership) clientErrors.push("মালিকানা আবশ্যক");
    if (!formData.admissionFee) clientErrors.push("ভর্তি ফি আবশ্যক");
    if (!formData.subscription) clientErrors.push("চাঁদা আবশ্যক");
    if (!formData.paymentMethod) clientErrors.push("পেমেন্ট মাধ্যম আবশ্যক");
    if (!formData.declarationAccepted)
      clientErrors.push("অঙ্গীকারনামায় সম্মতি প্রদান আবশ্যক");

    if (clientErrors.length > 0) {
      setErrors(clientErrors);
      window.scrollTo({ top: 0, behavior: "smooth" });
      return;
    }

    // Capture signature
    if (sigRef.current && !sigRef.current.isEmpty()) {
      const sigData = sigRef.current.toDataURL();
      setFormData((prev) => ({ ...prev, memberSignature: sigData }));
    }

    setSubmitting(true);

    try {
      const payload = {
        ...formData,
        memberSignature: sigRef.current && !sigRef.current.isEmpty()
          ? sigRef.current.toDataURL()
          : "",
      };

      const res = await fetch("/api/submit", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      const data = await res.json();

      if (data.success) {
        setSuccess({ formNo: data.formNo, driveFileLink: data.driveFileLink });
      } else {
        setErrors([data.error || "সাবমিটে সমস্যা হয়েছে"]);
        window.scrollTo({ top: 0, behavior: "smooth" });
      }
    } catch {
      setErrors(["নেটওয়ার্কে সমস্যা। অনুগ্রহ করে আবার চেষ্টা করুন।"]);
      window.scrollTo({ top: 0, behavior: "smooth" });
    } finally {
      setSubmitting(false);
    }
  };

  // Success screen
  if (success) {
    const total =
      (Number(formData.admissionFee) || 0) + (Number(formData.subscription) || 0);

    return (
      <div className="max-w-3xl mx-auto p-4 sm:p-6">
        <div className="bg-emerald-50 border border-emerald-200 rounded-lg p-8 text-center mb-6">
          <div className="text-4xl mb-4">✓</div>
          <h2 className="text-xl font-bold text-emerald-900 mb-2">
            সাবমিট সফল হয়েছে!
          </h2>
          <p className="text-emerald-800 mb-4">
            আপনার ফর্ম নং: <strong>{success.formNo}</strong>
          </p>
          <div className="space-y-3 max-w-sm mx-auto">
            <a
              href={`/api/submit?name=${encodeURIComponent(formData.fullName)}&formNo=${success.formNo}`}
              download
              className="block w-full bg-emerald-800 text-white py-3 rounded-lg font-medium hover:bg-emerald-900 transition"
            >
              PDF ডাউনলোড করুন
            </a>
            {success.driveFileLink && (
              <a
                href={success.driveFileLink}
                target="_blank"
                rel="noopener noreferrer"
                className="block w-full bg-white border border-gray-300 text-gray-700 py-3 rounded-lg font-medium hover:bg-gray-50 transition"
              >
                Drive-এ দেখুন
              </a>
            )}
            <button
              onClick={() => {
                setSuccess(null);
                setFormData(initialFormData);
                sigRef.current?.clear();
              }}
              className="block w-full bg-white border border-gray-300 text-gray-700 py-3 rounded-lg font-medium hover:bg-gray-50 transition"
            >
              নতুন ফর্ম পূরণ করুন
            </button>
          </div>
        </div>

        {/* Member Receipt preview */}
        <ReceiptSlip
          formNo={success.formNo}
          receiptNo={formData.receiptNo}
          date={formData.submissionDate}
          memberName={formData.fullName}
          admissionFee={formData.admissionFee}
          subscription={formData.subscription}
          total={total}
          paymentMethod={formData.paymentMethod}
        />
      </div>
    );
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="max-w-3xl mx-auto my-6 bg-white rounded-xl shadow-lg overflow-hidden border border-gray-200"
    >
      {/* Honeypot - hidden from real users */}
      <div className="absolute opacity-0 pointer-events-none h-0 overflow-hidden">
        <input
          type="text"
          name="website"
          tabIndex={-1}
          autoComplete="off"
          value={formData.website}
          onChange={handleChange}
        />
      </div>

      <div className="p-4 sm:p-8">
        {/* Error display */}
        {errors.length > 0 && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
            <h3 className="text-red-800 font-bold mb-2">
              নিম্নলিখিত সমস্যা দূর করুন:
            </h3>
            <ul className="list-disc list-inside text-red-700 space-y-1">
              {errors.map((err, i) => (
                <li key={i}>{err}</li>
              ))}
            </ul>
          </div>
        )}

        {/* Header */}
        <div className="relative flex flex-col items-center text-center mb-4">
          <p className="text-sm text-emerald-900 mb-1" dir="rtl">
            بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
          </p>
          <div className="flex items-center gap-3">
            <div className="relative w-16 h-16 shrink-0">
              <Image
                src="/images/logo.jpeg"
                alt="উত্তর কাউন্দিয়া লোগো"
                fill
                sizes="64px"
                className="object-contain rounded-full"
              />
            </div>
            <div>
              <h1 className="text-xl sm:text-2xl font-bold text-emerald-900">
                উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ পরিষদ
              </h1>
              <p className="text-xs sm:text-sm text-gray-600 mt-1">
                (সকল জমি, বাড়ি ও ফ্ল্যাট মালিকদের ঐক্যবদ্ধ অরাজনৈতিক আবাসন সংগঠন)
              </p>
              <p className="text-xs sm:text-sm text-gray-600">
                উত্তর কাউন্দিয়া, সাভার, ঢাকা। | স্থাপিত : ২০২৬ ইং
              </p>
            </div>
          </div>

          {/* Photo placeholder box */}
          <div className="hidden sm:flex absolute right-0 top-0 w-20 h-24 border-2 border-dashed border-emerald-700/60 items-center justify-center text-center text-[10px] text-emerald-800 leading-tight p-1">
            সদস্যের ছবি
            <br />
            ২&quot;×২&quot;
          </div>

          <div className="mt-3 bg-emerald-800 text-white text-sm sm:text-base font-bold px-4 py-2 rounded-md">
            সদস্য নিবন্ধন ও মালিকানা তথ্য ফরম
          </div>
        </div>

        {/* Form No / Member No / Reg date */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-sm mb-6 border-b border-gray-200 pb-4">
          <div className="flex gap-2 items-center">
            <span className="font-medium text-gray-700">ফরম নং:</span>
            <span className="flex-1 border-b border-dotted border-gray-400 h-5" />
          </div>
          <div className="flex gap-2 items-center">
            <span className="font-medium text-gray-700">সদস্য নং:</span>
            <span className="flex-1 border-b border-dotted border-gray-400 h-5" />
          </div>
          <div className="flex gap-2 items-center sm:col-span-2">
            <span className="font-medium text-gray-700 whitespace-nowrap">
              নিবন্ধনের তারিখ:
            </span>
            <Input
              name="submissionDate"
              type="date"
              value={formData.submissionDate}
              onChange={handleChange}
            />
          </div>
        </div>

        {/* Section 1: Member Info */}
        <Section number="১" title="সদস্যের ব্যক্তিগত তথ্য">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Field label="পূর্ণ নাম" required>
              <Input name="fullName" value={formData.fullName} onChange={handleChange} />
            </Field>
            <Field label="পিতা/স্বামী" required>
              <Input
                name="fatherOrHusband"
                value={formData.fatherOrHusband}
                onChange={handleChange}
              />
            </Field>
            <Field label="মাতা" required>
              <Input name="mother" value={formData.mother} onChange={handleChange} />
            </Field>
            <Field label="জন্ম তারিখ" required>
              <Input
                name="dob"
                type="date"
                value={formData.dob}
                onChange={handleChange}
              />
            </Field>
            <Field label="জাতীয়তা">
              <Input
                name="nationality"
                value={formData.nationality}
                onChange={handleChange}
              />
            </Field>
            <Field label="পেশা">
              <Input
                name="occupation"
                value={formData.occupation}
                onChange={handleChange}
              />
            </Field>
            <Field label="NID নং">
              <Input
                name="nid"
                value={formData.nid}
                onChange={handleChange}
                placeholder="১০-১৭ সংখ্যা"
              />
            </Field>
            <Field label="মোবাইল" required>
              <Input
                name="mobile"
                value={formData.mobile}
                onChange={handleChange}
                placeholder="01XXXXXXXXX"
              />
            </Field>
            <Field label="WhatsApp">
              <Input
                name="whatsapp"
                value={formData.whatsapp}
                onChange={handleChange}
              />
            </Field>
            <Field label="ই-মেইল">
              <Input
                name="email"
                type="email"
                value={formData.email}
                onChange={handleChange}
              />
            </Field>
          </div>
        </Section>

        {/* Section 2: Address */}
        <Section number="২" title="ঠিকানার তথ্য">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Field label="স্থায়ী ঠিকানা">
              <Textarea
                name="permanentAddress"
                value={formData.permanentAddress}
                onChange={handleChange}
              />
            </Field>
            <Field label="বর্তমান ঠিকানা">
              <Textarea
                name="currentAddress"
                value={formData.currentAddress}
                onChange={handleChange}
              />
            </Field>
          </div>
        </Section>

        {/* Section 3: Property Info */}
        <Section number="৩" title="আবাসন / সম্পত্তির মালিকানা তথ্য">
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              সম্পত্তির ধরন <span className="text-red-500">*</span>
            </label>
            <div className="flex flex-wrap gap-x-5 gap-y-2">
              {PROPERTY_TYPES.map((t) => (
                <Checkbox
                  key={t}
                  label={t}
                  checked={formData.propertyType === t}
                  onChange={() =>
                    setFormData((prev) => ({ ...prev, propertyType: t }))
                  }
                />
              ))}
              {formData.propertyType === "অন্যান্য" && (
                <Input
                  name="propertyTypeOther"
                  value={formData.propertyTypeOther}
                  onChange={handleChange}
                  placeholder="বিস্তারিত লিখুন"
                />
              )}
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <Field label="খতিয়ান নং">
              <Input
                name="khatianNo"
                value={formData.khatianNo}
                onChange={handleChange}
              />
            </Field>
            <Field label="দাগ নং">
              <Input name="dagNo" value={formData.dagNo} onChange={handleChange} />
            </Field>
            <Field label="জমির পরিমাণ">
              <Input
                name="landQuantity"
                value={formData.landQuantity}
                onChange={handleChange}
                placeholder="যেমন: ২ শতক"
              />
            </Field>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                মালিকানা <span className="text-red-500">*</span>
              </label>
              <div className="flex gap-5">
                {OWNERSHIP_TYPES.map((t) => (
                  <Checkbox
                    key={t}
                    label={t}
                    checked={formData.ownership === t}
                    onChange={() =>
                      setFormData((prev) => ({ ...prev, ownership: t }))
                    }
                  />
                ))}
              </div>
            </div>
          </div>

          {/* Applicable Documents */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              প্রযোজ্য কাগজ
            </label>
            <div className="flex flex-wrap gap-x-5 gap-y-2">
              {DOCUMENT_OPTIONS.map((doc) => (
                <Checkbox
                  key={doc}
                  label={doc}
                  checked={formData.applicableDocs.includes(doc)}
                  onChange={() => handleDocToggle(doc)}
                />
              ))}
            </div>
          </div>
        </Section>

        {/* Section 4 & 5: Urgent contact + Nominee, side by side */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
          <div className="border border-gray-200 rounded overflow-hidden">
            <h2 className="text-sm font-bold text-white bg-emerald-800 px-3 py-2">
              ৪. জরুরি যোগাযোগ
            </h2>
            <div className="p-3 space-y-3">
              <Field label="নাম">
                <Input
                  name="urgentContactName"
                  value={formData.urgentContactName}
                  onChange={handleChange}
                />
              </Field>
              <Field label="সম্পর্ক">
                <Input
                  name="urgentContactRelation"
                  value={formData.urgentContactRelation}
                  onChange={handleChange}
                />
              </Field>
              <Field label="মোবাইল">
                <Input
                  name="urgentContactMobile"
                  value={formData.urgentContactMobile}
                  onChange={handleChange}
                />
              </Field>
              <Field label="ঠিকানা">
                <Input
                  name="urgentContactAddress"
                  value={formData.urgentContactAddress}
                  onChange={handleChange}
                />
              </Field>
            </div>
          </div>

          <div className="border border-gray-200 rounded overflow-hidden">
            <h2 className="text-sm font-bold text-white bg-emerald-800 px-3 py-2">
              ৫. মনোনীত ব্যক্তি (Nominee)
            </h2>
            <div className="p-3 space-y-3">
              <Field label="নাম">
                <Input
                  value={formData.nominees[0]?.name || ""}
                  onChange={(e) => handleNomineeChange(0, "name", e.target.value)}
                />
              </Field>
              <Field label="পিতা/স্বামী / সম্পর্ক">
                <Input
                  value={formData.nominees[0]?.relation || ""}
                  onChange={(e) => handleNomineeChange(0, "relation", e.target.value)}
                />
              </Field>
              <Field label="মোবাইল">
                <Input
                  value={formData.nominees[0]?.mobile || ""}
                  onChange={(e) => handleNomineeChange(0, "mobile", e.target.value)}
                />
              </Field>
              <Field label="ঠিকানা">
                <Input
                  value={formData.nominees[0]?.address || ""}
                  onChange={(e) => handleNomineeChange(0, "address", e.target.value)}
                />
              </Field>
            </div>
          </div>
        </div>

        {/* Additional nominees */}
        {formData.nominees.length > 1 && (
          <section className="mb-8">
            <h3 className="text-sm font-medium text-gray-700 mb-3">
              অতিরিক্ত মনোনীত ব্যক্তি
            </h3>
            {formData.nominees.slice(1).map((nominee, i) => {
              const index = i + 1;
              return (
                <div key={index} className="border border-gray-200 rounded p-4 mb-4">
                  <div className="flex justify-between items-center mb-3">
                    <h4 className="font-medium text-gray-700">
                      মনোনীত ব্যক্তি {index + 1}
                    </h4>
                    <button
                      type="button"
                      onClick={() => removeNominee(index)}
                      className="text-red-600 text-sm hover:underline"
                    >
                      মুছুন
                    </button>
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <Field label="নাম">
                      <Input
                        value={nominee.name}
                        onChange={(e) =>
                          handleNomineeChange(index, "name", e.target.value)
                        }
                      />
                    </Field>
                    <Field label="সম্পর্ক">
                      <Input
                        value={nominee.relation}
                        onChange={(e) =>
                          handleNomineeChange(index, "relation", e.target.value)
                        }
                      />
                    </Field>
                    <Field label="মোবাইল">
                      <Input
                        value={nominee.mobile}
                        onChange={(e) =>
                          handleNomineeChange(index, "mobile", e.target.value)
                        }
                      />
                    </Field>
                    <Field label="ঠিকানা">
                      <Input
                        value={nominee.address}
                        onChange={(e) =>
                          handleNomineeChange(index, "address", e.target.value)
                        }
                      />
                    </Field>
                  </div>
                </div>
              );
            })}
          </section>
        )}
        {formData.nominees.length < 5 && (
          <button
            type="button"
            onClick={addNominee}
            className="text-emerald-800 text-sm hover:underline mb-8 -mt-4 block"
          >
            + আরও মনোনীত ব্যক্তি যোগ করুন
          </button>
        )}

        {/* Section 6: Payment */}
        <Section number="৬" title="সদস্যপদ ও চাঁদা">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <Field label="ভর্তি ফি (টাকা)" required>
              <Input
                name="admissionFee"
                type="number"
                value={formData.admissionFee}
                onChange={handleChange}
              />
            </Field>
            <Field label="চাঁদা (টাকা)" required>
              <Input
                name="subscription"
                type="number"
                value={formData.subscription}
                onChange={handleChange}
              />
            </Field>
            <Field label="রসিদ নং">
              <Input
                name="receiptNo"
                value={formData.receiptNo}
                onChange={handleChange}
              />
            </Field>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              মাধ্যম <span className="text-red-500">*</span>
            </label>
            <div className="flex flex-wrap gap-x-5 gap-y-2">
              {PAYMENT_METHODS.map((m) => (
                <Checkbox
                  key={m}
                  label={m}
                  checked={formData.paymentMethod === m}
                  onChange={() =>
                    setFormData((prev) => ({ ...prev, paymentMethod: m }))
                  }
                />
              ))}
            </div>
          </div>
        </Section>

        {/* Declaration */}
        <div className="bg-amber-50 border border-amber-200 rounded-lg p-4 mb-8 text-sm text-gray-800 leading-relaxed">
          <p className="mb-3">
            <strong>অঙ্গীকারনামা:</strong> আমি অঙ্গীকার করছি যে, উত্তর কাউন্দিয়া
            আবাসন মালিক কল্যাণ পরিষদের গঠনতন্ত্র, নিয়ম-শৃঙ্খলা ও বিধি সংক্রান্ত
            সিদ্ধান্তসমূহ মেনে চলবো এবং সংগঠনের উদ্দেশ্য ও স্বার্থবিরোধী কোনো
            কর্মকাণ্ডে অংশগ্রহণ করবো না। সংগঠনের সিদ্ধান্তসমূহে সদস্যদের অধিকার,
            সম্পত্তির নিরাপত্তা, পারস্পরিক সহযোগিতা, সামাজিক কল্যাণ ও এলাকার
            উন্নয়নে দায়িত্বশীলভাবে সহযোগিতা করবো। উপরোক্ত তথ্যসমূহ আমার জ্ঞান ও
            বিশ্বাস অনুযায়ী সঠিক।
          </p>
          <Checkbox
            label="আমি সকল শর্তাবলীতে সম্মতি প্রদান করছি।"
            checked={formData.declarationAccepted}
            onChange={() =>
              setFormData((prev) => ({
                ...prev,
                declarationAccepted: !prev.declarationAccepted,
              }))
            }
          />
        </div>

        {/* Section 7: Signature */}
        <Section number="৭" title="স্বাক্ষর ও তারিখ">
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              সদস্যের স্বাক্ষর (ঐচ্ছিক — শুধু অনলাইনে স্বাক্ষর করতে চাইলে)
            </label>
            <div className="border border-gray-300 rounded-lg overflow-hidden bg-white">
              <SignatureCanvas
                ref={sigRef}
                canvasProps={{
                  className: "w-full h-32 cursor-crosshair",
                }}
                backgroundColor="rgb(255,255,255)"
              />
            </div>
            <button
              type="button"
              onClick={clearSignature}
              className="mt-2 text-sm text-red-600 hover:underline"
            >
              স্বাক্ষর মুছুন
            </button>
          </div>
        </Section>

        {/* Submit */}
        <div className="text-center">
          <button
            type="submit"
            disabled={submitting}
            className="bg-emerald-800 text-white px-8 py-3 rounded-lg font-bold text-lg hover:bg-emerald-900 disabled:bg-gray-400 disabled:cursor-not-allowed transition"
          >
            {submitting ? "সাবমিট হচ্ছে..." : "ফর্ম সাবমিট করুন"}
          </button>
        </div>
      </div>

      {/* Office-use-only section, matches printed form template */}
      <OfficeUseSection />
    </form>
  );
}

function Section({
  number,
  title,
  children,
}: {
  number: string;
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="mb-8">
      <h2 className="text-sm sm:text-base font-bold text-white bg-emerald-800 px-3 py-2 rounded mb-4">
        {number}. {title}
      </h2>
      {children}
    </section>
  );
}

function Field({
  label,
  required,
  children,
}: {
  label: string;
  required?: boolean;
  children: React.ReactNode;
}) {
  return (
    <div>
      <label className="block text-sm font-medium text-gray-700 mb-1">
        {label}
        {required && <span className="text-red-500 ml-1">*</span>}
      </label>
      {children}
    </div>
  );
}

function Input({
  name,
  value,
  onChange,
  type = "text",
  placeholder = "",
}: {
  name?: string;
  value: string;
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  type?: string;
  placeholder?: string;
}) {
  return (
    <input
      type={type}
      name={name}
      value={value}
      onChange={onChange}
      placeholder={placeholder}
      className="w-full border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
    />
  );
}

function Textarea({
  name,
  value,
  onChange,
  placeholder = "",
}: {
  name?: string;
  value: string;
  onChange: (e: React.ChangeEvent<HTMLTextAreaElement>) => void;
  placeholder?: string;
}) {
  return (
    <textarea
      name={name}
      value={value}
      onChange={onChange}
      placeholder={placeholder}
      rows={3}
      className="w-full border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent resize-none"
    />
  );
}

function Checkbox({
  label,
  checked,
  onChange,
}: {
  label: string;
  checked: boolean;
  onChange: () => void;
}) {
  return (
    <label className="flex items-center gap-2 text-sm text-gray-800 cursor-pointer">
      <input
        type="checkbox"
        checked={checked}
        onChange={onChange}
        className="w-4 h-4 rounded border-gray-400 text-emerald-700 focus:ring-emerald-600"
      />
      <span>{label}</span>
    </label>
  );
}

function OfficeUseSection() {
  return (
    <div className="border-t-2 border-dashed border-gray-300 bg-gray-50 p-4 sm:p-8 text-sm text-gray-600">
      <h3 className="text-center font-bold text-gray-700 bg-gray-200 py-2 rounded mb-4">
        শুধুমাত্র অফিস ব্যবহারের জন্য
      </h3>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 mb-4">
        <p>গ্রহণের তারিখ: ______________</p>
        <p>মালিকানা যাচাই: ☐ সম্পন্ন ☐ অসম্পূর্ণ ☐ পুনরায়</p>
        <p>সদস্যপদ অনুমোদন: ☐ অনুমোদিত ☐ স্থগিত</p>
        <p>ডাটাবেজ ভুক্তি: ☐ হ্যাঁ ☐ না</p>
        <p className="sm:col-span-2">চূড়ান্ত সদস্য নং: ______________</p>
      </div>
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 text-center pt-6">
        <p className="border-t border-gray-400 pt-1">যাচাইকারী</p>
        <p className="border-t border-gray-400 pt-1">কোষাধ্যক্ষ</p>
        <p className="border-t border-gray-400 pt-1">সাধারণ সম্পাদক</p>
        <p className="border-t border-gray-400 pt-1">সভাপতি</p>
      </div>
    </div>
  );
}

function ReceiptSlip({
  formNo,
  receiptNo,
  date,
  memberName,
  admissionFee,
  subscription,
  total,
  paymentMethod,
}: {
  formNo: string;
  receiptNo: string;
  date: string;
  memberName: string;
  admissionFee: string;
  subscription: string;
  total: number;
  paymentMethod: string;
}) {
  return (
    <div>
      <div className="flex items-center justify-center gap-2 text-xs text-gray-400 mb-4">
        <span>✂</span>
        <span>এখান থেকে কেটে সদস্যকে রসিদ প্রদান করুন (Member Receipt)</span>
        <span>✂</span>
      </div>
      <div className="border-2 border-dashed border-emerald-700/40 rounded-lg p-4 sm:p-6">
        <div className="text-center mb-4">
          <h3 className="font-bold text-emerald-900">
            উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ পরিষদ
          </h3>
          <p className="text-xs text-gray-600">উত্তর কাউন্দিয়া, সাভার, ঢাকা।</p>
          <div className="inline-block mt-2 bg-emerald-800 text-white text-xs font-bold px-3 py-1 rounded">
            সদস্য প্রাপ্তিস্বীকার রসিদ (Member Receipt)
          </div>
        </div>
        <div className="grid grid-cols-2 gap-y-2 text-sm">
          <p>রসিদ নং: {receiptNo || "—"}</p>
          <p>ফরম নং: {formNo}</p>
          <p>তারিখ: {date}</p>
          <p>সদস্যের নাম: {memberName}</p>
          <p>ভর্তি ফি: {admissionFee || 0} টাকা</p>
          <p>চাঁদা: {subscription || 0} টাকা</p>
          <p>মোট জমা: {total} টাকা</p>
          <p>মাধ্যম: {paymentMethod || "—"}</p>
        </div>
        <div className="grid grid-cols-3 gap-4 text-center text-xs mt-8">
          <p className="border-t border-gray-400 pt-1">আবেদনকারীর স্বাক্ষর</p>
          <p className="border-t border-gray-400 pt-1">আদায়কারীর স্বাক্ষর</p>
          <p className="border-t border-gray-400 pt-1">
            অনুমোদনকারীর স্বাক্ষর
            <br />
            (কোষাধ্যক্ষ/সম্পাদক)
          </p>
        </div>
      </div>
    </div>
  );
}
