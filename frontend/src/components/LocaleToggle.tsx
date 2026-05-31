"use client";

import { useRouter } from "next/navigation";

import { useLocale } from "@/components/LocaleProvider";
import {
  LOCALE_COOKIE,
  LOCALE_COOKIE_MAX_AGE,
  type Locale,
} from "@/lib/locale";

export function LocaleToggle() {
  const router = useRouter();
  const { locale, messages } = useLocale();
  const t = messages.localeToggle;

  function setLocale(next: Locale) {
    if (next === locale) return;
    document.cookie = `${LOCALE_COOKIE}=${next}; path=/; max-age=${LOCALE_COOKIE_MAX_AGE}; SameSite=Lax`;
    router.refresh();
  }

  return (
    <div
      className="flex items-center gap-0.5 rounded-md border border-slate-200 bg-slate-50 p-0.5 text-xs font-medium"
      role="group"
      aria-label="Language"
    >
      {(["ja", "en"] as const).map((code) => (
        <button
          key={code}
          type="button"
          aria-pressed={locale === code}
          aria-label={code === "ja" ? t.switchToJa : t.switchToEn}
          onClick={() => setLocale(code)}
          className={`rounded px-2 py-1 transition-colors duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400 focus-visible:ring-offset-2 ${
            locale === code
              ? "bg-white text-slate-900 shadow-sm"
              : "text-slate-500 hover:text-slate-900"
          }`}
        >
          {code === "ja" ? t.ja : t.en}
        </button>
      ))}
    </div>
  );
}
