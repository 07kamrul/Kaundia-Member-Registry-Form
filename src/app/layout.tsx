import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ পরিষদ — সদস্য নিবন্ধন",
  description: "সদস্য নিবন্ধন ফর্ম — উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ পরিষদ",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="bn" className="h-full antialiased" style={{ colorScheme: "light" }}>
      <body className="min-h-full flex flex-col bg-gray-50">
        {children}
      </body>
    </html>
  );
}
