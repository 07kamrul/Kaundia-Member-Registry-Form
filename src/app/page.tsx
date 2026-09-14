import Image from "next/image";
import RegistrationForm from "@/components/RegistrationForm";

export default function Home() {
  return (
    <div className="relative min-h-screen">
      <Image
        src="/images/banner.jpeg"
        alt=""
        fill
        priority
        aria-hidden="true"
        className="fixed inset-0 -z-10 object-cover opacity-10 pointer-events-none select-none"
      />
      <RegistrationForm />
      <footer className="text-center text-xs text-gray-400 py-4 border-t border-gray-200 mt-8">
        &copy; {new Date().getFullYear()} উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ পরিষদ
      </footer>
    </div>
  );
}
