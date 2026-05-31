import type { Messages } from "@/lib/messages";

/** ASIN format: B + 9 alphanumeric (Amazon standard). */
export const ASIN_PATTERN = /^B[A-Z0-9]{9}$/;

export function normalizeAsin(value: string): string {
  return value.trim().toUpperCase();
}

export function isValidAsin(value: string): boolean {
  return ASIN_PATTERN.test(normalizeAsin(value));
}

export function asinValidationMessage(
  value: string,
  asinMessages: Messages["asin"],
): string | null {
  const normalized = normalizeAsin(value);
  if (!normalized) return null;
  if (normalized.length !== 10) {
    return asinMessages.length;
  }
  if (!ASIN_PATTERN.test(normalized)) {
    return asinMessages.format;
  }
  return null;
}
