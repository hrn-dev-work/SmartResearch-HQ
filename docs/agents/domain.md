# Domain documentation — consumer rules

## CONTEXT.md

- **Purpose:** Ubiquitous language, security guardrails, engineering principles, AI guardrails, `_Avoid_` traps.
- **Not for:** Implementation details, file-by-file specs, ticket backlogs.
- **Update when:** Grilling resolves a new term or kills an ambiguous synonym.
- **Location:** Repository root `CONTEXT.md`.
- **Bilingual:** English block → language-boundary `---` → `# SmartResearch-HQ（日本語）` mirror per [doc-conventions.md](../doc-conventions.md). **Agents read the English block only** (through the `---` immediately before the Japanese `#` heading).

## ADRs (`docs/adr/`)

Write an ADR only when **all three** are true:

1. Hard to reverse later
2. Surprising without context
3. Result of a real trade-off (alternatives existed)

Format: Context → Decision → Consequences → **Alternatives considered** (why other options were rejected).

Number files: `0001-short-title.md`. Index in `docs/adr/README.md`.

**Git:** Commit all `docs/adr/*.md` — they are public, tracked documentation (unlike `.cursor/`). Validated by `bash scripts/validate-adrs.sh`.

**Language:** English-only in ADRs. Bilingual mirrors belong in `docs/agents/` or top-level `docs/*.md` per [doc-conventions.md](../doc-conventions.md).

**Layering:** ADR = decision + why; `docs/agents/` = operational detail; `CONTEXT.md` = short summary + links. Do not duplicate ADR prose across files.

**Portfolio reviewers** read ADRs for *why* — not a prose duplicate of the code. See [engineering-principles.md](./engineering-principles.md) §4.

## Spec precedence

1. Accepted ADRs
2. Design / visual decisions (`docs/design.md`)
3. Requirements / acceptance criteria
4. Architecture
5. API / schema reference

When specs conflict, update the lower-priority doc— do not duplicate paragraphs across files.

---

# ドメイン文書 — 利用者向けルール

## CONTEXT.md

- **目的:** ユビキタス言語、セキュリティガードレール、工学原則、AI ガードレール、`_Avoid_` トラップ。
- **用途外:** 実装詳細、ファイル単位の仕様、チケットバックログ。
- **更新タイミング:** Grilling で新語が確定したとき、または曖昧な同義語を廃止したとき。
- **場所:** リポジトリルートの `CONTEXT.md`。
- **日英:** 英語ブロック → 言語境界の `---` → `# SmartResearch-HQ（日本語）` ミラー（[doc-conventions.md](../doc-conventions.md)）。**エージェントは英語ブロックのみ読む**（日本語 `#` 見出し直前の `---` まで）。

## ADR（`docs/adr/`）

次の **3 つすべて** に当てはまるときだけ ADR を書く:

1. 後から戻しにくい
2. 文脈なしでは驚く
3. 実際のトレードオフの結果（代替案があった）

形式: Context → Decision → Consequences → **Alternatives considered**（却下理由）。

ファイル名: `0001-short-title.md`。索引は `docs/adr/README.md`。

**Git:** `docs/adr/*.md` はすべてコミット対象（公開の追跡ドキュメント。`.cursor/` とは別）。`bash scripts/validate-adrs.sh` で検証。

**言語:** ADR は英語のみ。日英ミラーは [doc-conventions.md](../doc-conventions.md) に従い `docs/agents/` または `docs/*.md` へ。

**レイヤ:** ADR = 決定 + why、`docs/agents/` = 運用詳細、`CONTEXT.md` = 短い要約 + リンク。ADR 本文の二重記載はしない。

**Portfolio レビュアー** は ADR で *why* を読む — コードの言い換えではない。[engineering-principles.md](./engineering-principles.md) §4 参照。

## 仕様の優先順

1. Accepted ADR
2. デザイン / ビジュアル（`docs/design.md`）
3. 要件 / 受入条件
4. アーキテクチャ
5. API / スキーマ参照

仕様が矛盾するときは優先度の低い文書を更新する — 段落の二重記載はしない。
