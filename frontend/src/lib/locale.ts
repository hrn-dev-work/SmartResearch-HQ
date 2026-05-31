export const LOCALES = ["ja", "en"] as const;
export type Locale = (typeof LOCALES)[number];

export const LOCALE_COOKIE = "locale";
export const LOCALE_COOKIE_MAX_AGE = 60 * 60 * 24 * 365;

export const DEFAULT_LOCALE: Locale = "en";

export function isLocale(value: string | undefined | null): value is Locale {
  return value === "ja" || value === "en";
}

export function normalizeLocale(value: string | undefined | null): Locale {
  return isLocale(value) ? value : DEFAULT_LOCALE;
}

/** IP country code (ISO 3166-1 alpha-2): Japan → ja, else en. */
export function geoToLocale(country: string | null | undefined): Locale {
  return country?.toUpperCase() === "JP" ? "ja" : "en";
}
