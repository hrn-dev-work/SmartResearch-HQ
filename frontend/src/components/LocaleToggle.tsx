"use client";

import { useRouter } from "next/navigation";

import { useLocale } from "@/components/LocaleProvider";
import { type Locale, writeLocaleCookie } from "@/lib/locale";

export function LocaleToggle() {
  const router = useRouter();
  const { locale, messages } = useLocale();
  const t = messages.localeToggle;

  function onSelect(next: Locale) {
    if (next === locale) return;
    writeLocaleCookie(next);
    router.refresh();
  }

  return (
    <div
      className="flex items-center gap-0.5 border border-rule bg-paper p-0.5 text-xs font-medium"
      role="group"
      aria-label="Language"
    >
      {(["ja", "en"] as const).map((code) => (
        <button
          key={code}
          type="button"
          aria-pressed={locale === code}
          aria-label={code === "ja" ? t.switchToJa : t.switchToEn}
          onClick={() => onSelect(code)}
          className={`rounded-sm px-2 py-1 transition-colors duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ink/25 focus-visible:ring-offset-2 focus-visible:ring-offset-paper ${
            locale === code
              ? "bg-surface text-ink"
              : "text-ink-muted hover:text-ink"
          }`}
        >
          {code === "ja" ? t.ja : t.en}
        </button>
      ))}
    </div>
  );
}
