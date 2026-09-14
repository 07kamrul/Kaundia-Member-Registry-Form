# উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ পরিষদ — সদস্য নিবন্ধন অ্যাপ

## সেটআপ

### ১. Google Cloud Service Account তৈরি

1. [Google Cloud Console](https://console.cloud.google.com/) এ যান
2. নতুন প্রজেক্ট তৈরি করুন অথবা বিদ্যমান প্রজেক্ট সিলেক্ট করুন
3. **APIs & Services > Library** এ গিয়ে **Google Sheets API** এবং **Google Drive API** enable করুন
4. **APIs & Services > Credentials** এ গিয়ে **Create Credentials > Service Account** সিলেক্ট করুন
5. নাম দিন (যেমন: `kaundia-registration`) এবং **Create and Continue** ক্লিক করুন
6. **Roles** সিলেক্ট করুন: `Editor` (অথবা নির্দিষ্ট পারমিশন দিন)
7. **Done** ক্লিক করুন
8. তৈরি করা Service Account এ ক্লিক করুন > **Keys** ট্যাব > **Add Key > Create new key > JSON**
9. JSON ফাইল ডাউনলোড হবে — এটি `credentials/` ফোল্ডারে রাখুন

### ২ ও ৩. Google Sheet ও Drive ফোল্ডার প্রস্তুত (স্বয়ংক্রিয়)

Service Account JSON ফাইল রেডি থাকলে একটি কমান্ডেই Sheet এবং Drive ফোল্ডার তৈরি হয়ে যাবে —
হেডার রো, বোল্ড/ফ্রিজ ফরম্যাটিং, এবং আপনার ব্যক্তিগত Gmail-এ Editor অ্যাক্সেস শেয়ার সহ:

```bash
npm run setup:google
```

স্ক্রিপ্টটি জিজ্ঞেস করবে:
- Service Account JSON ফাইলের পাথ (যদি `GOOGLE_SERVICE_ACCOUNT_JSON` আগে থেকে সেট না থাকে)
- আপনার ব্যক্তিগত Gmail (Sheet ও ফোল্ডার Editor হিসেবে শেয়ার করার জন্য)

সম্পন্ন হলে `.env` ফাইলে `GOOGLE_SHEET_ID` ও `GOOGLE_DRIVE_FOLDER_ID` স্বয়ংক্রিয়ভাবে যোগ হয়ে যাবে।

<details>
<summary>ম্যানুয়ালি করতে চাইলে (ফলব্যাক)</summary>

**Sheet:**
1. একটি নতুন Google Sheet তৈরি করুন
2. **প্রথম রো (Header)** এ নিম্নলিখিত কলাম যোগ করুন:

```
ফর্ম নং | তারিখ | পূর্ণ নাম | পিতা/স্বামী | মাতা | জন্ম তারিখ | জাতীয়তা | পেশা | NID নং | মোবাইল | WhatsApp | ই-মেইল | সম্পত্তির ধরন | খতিয়ান নং | দাগ নং | জমির পরিমাণ | মালিকানা | প্রযোজ্য কাগজ | নমিনি১-নাম | নমিনি১-সম্পর্ক | নমিনি১-মোবাইল | নমিনি১-ঠিকানা | নমিনি২-নাম | নমিনি২-সম্পর্ক | নমিনি২-মোবাইল | নমিনি২-ঠিকানা | ভর্তি ফি | চাঁদা | রসিদ নং | পেমেন্ট মাধ্যম | স্বাক্ষর | Drive লিংক
```

3. Sheet URL থেকে ID কপি করুন: `https://docs.google.com/spreadsheets/d/{**এই ID**}/edit`

**Drive ফোল্ডার:**
1. Google Drive এ একটি নতুন ফোল্ডার তৈরি করুন (যেমন: "কাউন্দিয়া রেজিস্ট্রেশন PDF")
2. ফোল্ডার URL থেকে ID কপি করুন: `https://drive.google.com/drive/folders/{**এই ID**}`

</details>

> **এই প্রজেক্টের শেয়ার্ড ফোল্ডার**: সব অ্যাটাচমেন্ট এবং শীট এখানে রাখা হবে —
> https://drive.google.com/drive/folders/1ytpkU-J-1rCSqUJrB9B25ljO5YhD-ywP?usp=sharing

### ৪. Service Account কে অ্যাক্সেস দিন

> `npm run setup:google` ব্যবহার করলে এই ধাপের প্রয়োজন নেই — Service Account নিজেই রিসোর্স তৈরি করে এবং আপনার Gmail-এ Editor অ্যাক্সেস শেয়ার করে দেয়। শুধু ম্যানুয়াল ফলব্যাকে (উপরের ধাপ ২-৩) এই ধাপ প্রয়োজন।

**গুরুত্বপূর্ণ**: Service Account কে শুধুমাত্র যে রিসোর্স ব্যবহার করতে হবে সেগুলোর সাথে শেয়ার করুন:

1. Google Sheet খুলুন > **Share** বাটন > Service Account এর email যোগ করুন (Editor permission)
2. Google Drive ফোল্ডার > **Share** > Service Account এর email যোগ করুন

Service Account email পাবেন JSON ফাইলে: `client_email` field

### ৫. এনভায়রনমেন্ট ভেরিয়েবল সেট করুন

`.env.example` ফাইলটি কপি করে `.env` তৈরি করুন:

```bash
cp .env.example .env
```

`.env` ফাইলে প্রয়োজনীয় মান পূরণ করুন।

### ৬. অ্যাপ চালু করুন

```bash
# ডেভেলপমেন্ট
npm run dev

# প্রোডাকশন
npm run build
npm start
```

ব্রাউজারে `http://localhost:3000` খুলুন।

## ফিচার

- **বাংলায় ফর্ম** — সম্পূর্ণ বাংলা ইন্টারফেস
- **মোবাইল রেসপন্সিভ** — সব ডিভাইসে কাজ করে
- **সার্ভার ভ্যালিডেশন** — ফোন, NID, ইমেইল ফরম্যাট চেক
- **Honeypot স্প্যাম প্রোটেকশন** — রোবট সাবমিশন ব্লক করে
- **PDF জেনারেশন** — সাবমিটের পর সাথে সাথে PDF ডাউনলোড
- **Google Sheets** — স্বয়ংক্রিয়ভাবে ডাটা সেভ
- **Google Drive** — PDF অটোমেটিক আপলোড
- **এরর হ্যান্ডলিং** — স্পষ্ট বাংলা এরর মেসেজ

## গুরুত্বপূর্ণ নোট

- Service Account JSON ফাইল `.gitignore` এ আছে — কখনো commit করবেন না
- প্রথমবার চালানোর আগে Sheet এব় Drive ফোল্ডারে Service Account কে শেয়ার করুন
- PDF তে বাংলা টেক্সট সঠিকভাবে দেখাতে Bengali font embed করতে হবে (pdf-lib দিয়ে সীমিত সাপোর্ট আছে, প্রোডাকশনের জন্য Puppeteer ব্যবহার করার পরামর্শ দেওয়া হচ্ছে)
