/** ASIN format: B + 9 alphanumeric (Amazon standard). */
export const ASIN_PATTERN = /^B[A-Z0-9]{9}$/;

export function normalizeAsin(value: string): string {
  return value.trim().toUpperCase();
}

export function isValidAsin(value: string): boolean {
  return ASIN_PATTERN.test(normalizeAsin(value));
}

export function asinValidationMessage(value: string): string | null {
  const normalized = normalizeAsin(value);
  if (!normalized) return null;
  if (normalized.length !== 10) {
    return "ASIN は 10 文字（B + 英数字 9 文字）です";
  }
  if (!ASIN_PATTERN.test(normalized)) {
    return "先頭 B のあと英数字 9 文字で入力してください";
  }
  return null;
}
