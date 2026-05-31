import { en } from "@/lib/messages/en";
import { ja } from "@/lib/messages/ja";
import type { Messages } from "@/lib/messages/types";
import type { Locale } from "@/lib/locale";

const catalogs: Record<Locale, Messages> = { ja, en };

export function getMessages(locale: Locale): Messages {
  return catalogs[locale];
}
