---
name: refined-saas-workflow
description: >-
  Two-step workflow for SmartResearch-HQ: polish docs/requirements.md against
  docs/design.md, then implement de-AI refined SaaS UI. Use when fixing
  requirements, reducing AI-slop in copy/UI, building research or review screens,
  WBS docs tasks, scoped UI work, or when the user mentions 脱AI感, requirements清書,
  UI mock, agent efficiency, or minimizing Cursor token usage.
summary: requirements を design と突合して清書したあと、脱AI 感の UI（リサーチ開始・レビュー画面）を実装する。
user-prompt: 先に requirements.md を design.md §11 と突合して清書して。そのあとレビュー画面の UI を脱AI 感で実装して。
category: UI・要件
---

# Refined SaaS Workflow（要件清書 → 脱AI UI）

## When to use

- `docs/requirements.md` の未消化・WBS タスクがある
- UI / 文言の「AI感」を減らしたい
- リサーチ開始 or レビュー画面のモック・実装

## Workflow（必ずこの順）

```
- [ ] Step 1: 要件定義書の清書
- [ ] Step 2: 脱AI感 UI の実装
```

**Step 2 は Step 1 完了後のみ。** 要件が固まってから UI に入る。

---

## Step 1: 要件定義書の清書

1. 読む: `docs/wbs-roadmap.md`, `docs/requirements.md`, `docs/design.md`, `docs/architecture.md`
2. `docs/requirements.md` を更新:
   - §3.1 に Gemini 応答時間: **「実測後に確定するが、UXを考慮し暫定で5秒以内を目標とする」**
   - §4 MVP（7決定）は要約のみ。詳細は `design.md` §11 に置き、重複を削除
3. `docs/design.md` §11 と突合し、矛盾があれば design を正として requirements を修正
4. README のドキュメント一覧に requirements / design が無ければ追記

### Step 1 完了条件

- requirements §3.1 / §4 が存在し design §11 と一致
- WBS の「要件清書」が解消されている

---

## Step 2: 脱AI感 UI

`docs/requirements.md` と `docs/design.md` §2 に従い、対象画面を実装する。

**本プロジェクトの画面**

| 画面 | パス |
|------|------|
| リサーチ開始 | `frontend/src/app/page.tsx` |
| レビュー | `frontend/src/app/review/[jobId]/page.tsx` |

### デザイン要件（厳守）

**脱AI感**: 安易なカードレイアウト（border, shadow-md の多用）を禁止。余白（8px単位）とタイポグラフィのジャンプ率で情報階層を表現すること。

**カラースキーム**: 背景はわずかに色付き（bg-slate-50等）、コンテンツエリアは白。文字色は text-slate-900 と text-slate-500 で濃淡をつける。

**手ざわり**: ドラッグ＆ドロップエリアやボタンなど、すべてのクリッカブル要素に hover/focus のトランジション（duration-200, 微細なscale変化や色変化）を設定すること。

**密度**: 要素を詰め込まず、セクション間には十分な余白を取ること。VercelやLinearのようなクリーンなモダンUIを目指してください。

### コピー（脱AI文）

- 使わない: seamless, innovative, comprehensive, ワンストップ, 革新的
- 使う: 短い述語形、具体的数値、製品名（Shopee / Amazon）

### Step 2 完了条件

- 既存 API 連携を壊さない（`@/lib/api`）
- ライトテーマ（slate）で Header / 両ページが統一
- リンタエラーなし

---

## 検証

```bash
cd frontend && npm run build
```

---

## 関連ファイル

- [design.md](../../../docs/design.md) — UI 原則・MVP §11
- [requirements.md](../../../docs/requirements.md) — 機能・非機能要件
