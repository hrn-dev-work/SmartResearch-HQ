# Tech stack policy — agent guide

Operational companion to [docs/tech-stack-policy.md](../tech-stack-policy.md). Decision record: [ADR 0009](../adr/0009-layered-tech-stack-policy.md).

## When to read

- Bootstrapping a **new** repository
- User asks for “standard stack” or proposes Laravel / shadcn on **this** repo
- Choosing tests or layer boundaries on a greenfield Profile A app

## Profile selection (30 seconds)

| Signal | Profile |
|--------|---------|
| Playwright scrape, Redis queue, LLM/PA-API, job state machine | **B — FastAPI** |
| Users, roles, billing, CRUD admin, Laravel team velocity | **A — Laravel** |
| Unsure | Default **A** for internal business tools; **B** for automation pipelines |

Document the choice in the new repo’s `README.md` and `CONTEXT.md` (one table row + link to policy).

## This repository (SmartResearch-HQ)

**Always Profile B.** Do not:

- Add Laravel, PHP, or shadcn/ui without user explicitly reopening ADR 0009 + design §2
- Rewrite backend to match a Profile A template

**Do** align new work with:

- [backend-python.mdc](../../.cursor/rules/backend-python.mdc) — layers, `APP_MODE`, matchers
- [de-ai-ui.mdc](../../.cursor/rules/de-ai-ui.mdc) — no card stacks, no UI libraries
- [api-specification.md](../api-specification.md) — contract before code

## New Profile A repo (checklist)

1. `frontend/`: Next.js App Router, Tailwind, shadcn/ui, `messages/ja.ts` + `en.ts`, `middleware.ts` for locale
2. `backend/` or separate API repo: Laravel API-only, Sanctum/Passport when auth ships
3. `docs/api-specification.md` or OpenAPI export from Laravel (Scribe / OpenAPI generator)
4. `NEXT_PUBLIC_API_URL` on Vercel; CORS on API
5. CI: Pint/PHPStan or Larastan + Pest + one Playwright smoke
6. First ADR if auth provider or multi-tenant model is fixed early

## New Profile B repo (checklist)

1. Mirror SmartResearch-HQ layout: `frontend/`, `backend/`, `render.yaml` optional
2. `app/services/` for domain; scrapers/workers in infrastructure paths only
3. Env-driven mocks for public demo if portfolio matters (see ADR 0001 pattern)
4. CI: Ruff + pytest; sync-api-types script if TS client generated from OpenAPI
5. Document queue/Redis in architecture.md — not optional if async jobs exist

## Conflicts to escalate (do not improvise)

| User request | Response |
|--------------|----------|
| “Use Laravel on SmartResearch-HQ” | Cite ADR 0009 + policy §4; offer new Profile A repo or ADR reopen |
| “Add shadcn here” | Cite de-ai-ui + policy Profile B; offer Profile A project or custom components |
| “Unit tests only” | Cite testing-istqb + policy §6; add integration + E2E on critical path |
| “Full DDD with repositories everywhere” | Cite ADR 0007 Rule of Three; services layer only until third repetition |

## Links

| Doc | Role |
|-----|------|
| [tech-stack-policy.md](../tech-stack-policy.md) | Human-readable Must / Choose (EN/JA) |
| [ADR 0009](../adr/0009-layered-tech-stack-policy.md) | Why layered policy exists |
| [engineering-principles.md](./engineering-principles.md) | YAGNI, fail-fast, testability |
| [deployment-guide.md](../deployment-guide.md) | Vercel + Render env vars |

---

# 技術スタック方針 — エージェント向けガイド

運用補助: [docs/tech-stack-policy.md](../tech-stack-policy.md)。決定記録: [ADR 0009](../adr/0009-layered-tech-stack-policy.md)。

## いつ読むか

- **新規**リポジトリを立ち上げるとき
- ユーザーが「標準スタック」を求める、または **本リポ**に Laravel / shadcn を提案するとき
- グリーンフィールドの Profile A でテストやレイヤ境界を選ぶとき

## プロファイル選択（30 秒）

| シグナル | プロファイル |
|----------|--------------|
| Playwright スクレイプ、Redis キュー、LLM/PA-API、ジョブ状態機械 | **B — FastAPI** |
| ユーザー、ロール、課金、CRUD 管理、Laravel チーム速度 | **A — Laravel** |
| 迷う | 社内業務ツールは **A**、自動化パイプラインは **B** |

新規リポの `README.md` と `CONTEXT.md` に選択を記載（表 1 行 + 方針 doc へのリンク）。

## 本リポジトリ（SmartResearch-HQ）

**常に Profile B。** 次をしない:

- ユーザーが ADR 0009 + design §2 の再検討を明示しない限り Laravel / PHP / shadcn/ui を追加
- Profile A テンプレに合わせてバックエンドを書き換え

**次に合わせる:**

- [backend-python.mdc](../../.cursor/rules/backend-python.mdc) — レイヤ、`APP_MODE`、マッチャ
- [de-ai-ui.mdc](../../.cursor/rules/de-ai-ui.mdc) — カード乱用・UI ライブラリ禁止
- [api-specification.md](../api-specification.md) — 契約先行

## 新規 Profile A リポ（チェックリスト）

1. `frontend/`: Next.js App Router、Tailwind、shadcn/ui、`messages/ja.ts` + `en.ts`、`middleware.ts` で locale
2. `backend/` または別 API リポ: Laravel API のみ、認証時 Sanctum/Passport
3. `docs/api-specification.md` または Laravel から OpenAPI 出力（Scribe 等）
4. Vercel で `NEXT_PUBLIC_API_URL`、API で CORS
5. CI: Pint/PHPStan または Larastan + Pest + Playwright スモーク 1 本
6. 認証方式・マルチテナントを早めに固定するなら ADR を 1 本

## 新規 Profile B リポ（チェックリスト）

1. SmartResearch-HQ 構成を参考: `frontend/`、`backend/`、`render.yaml` は任意
2. ドメインは `app/services/`；スクレイパ/ワーカーは infrastructure のみ
3. 公開デモが重要なら env 駆動 Mock（ADR 0001 パターン）
4. CI: Ruff + pytest；OpenAPI から TS 型同期するなら sync スクリプト
5. 非同期ジョブがあるなら architecture.md に queue/Redis を必須として記載

## エスカレート（独断で進めない）

| ユーザー依頼 | 対応 |
|--------------|------|
| 「SmartResearch-HQ を Laravel に」 | ADR 0009 + 方針 §4 を引用；Profile A 新規リポまたは ADR 再検討を提案 |
| 「shadcn を入れて」 | de-ai-ui + Profile B；Profile A 別プロジェクトまたはカスタムコンポーネント |
| 「単体テストだけで」 | testing-istqb + 方針 §6；結合 + 重要 E2E を追加 |
| 「Repository だらけの本格 DDD」 | ADR 0007 Rule of Three；3 回目まで services 層のみ |

## リンク

| ドキュメント | 役割 |
|--------------|------|
| [tech-stack-policy.md](../tech-stack-policy.md) | Must/Choose 正本（英日） |
| [ADR 0009](../adr/0009-layered-tech-stack-policy.md) | 階層化方針の理由 |
| [engineering-principles.md](./engineering-principles.md) | YAGNI、フェイルファスト、テスト |
| [deployment-guide.md](../deployment-guide.md) | Vercel + Render 環境変数 |
