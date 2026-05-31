# Security scanning (secrets & vulnerabilities)

Canonical CI and workflow guardrails for SmartResearch-HQ. Aligns with OWASP Secrets Management, CWE-798, and GitHub Code Scanning.

**Coding standards (OWASP Top 10 / IPA):** [docs/agents/security.md](agents/security.md) · ADR [0006](adr/0006-security-guardrails-public-standards.md)

## Defense in depth

| When | Mechanism | File |
|------|-----------|------|
| Pre-commit | Secret file rejection + gitleaks protect | `.githooks/pre-commit` → `scripts/pre-commit-secret-check.sh` |
| Pre-push (local) | Baseline + lint/test/build | `scripts/ci-check.sh` |
| Push / PR (CI) | gitleaks + trivy secret | `.github/workflows/ci.yml` → `secret-audit` job |
| Push / PR (CI) | CodeQL | `.github/workflows/codeql.yml` |
| Weekly | Dependabot | `.github/dependabot.yml` |
| GitHub platform | Secret Scanning + Push Protection | `scripts/enable-github-secret-scanning.sh` |

## Manual verification

```bash
bash scripts/secret-audit.sh
bash scripts/ci-check.sh
bash scripts/validate-security-workflows.sh
bash scripts/enable-github-secret-scanning.sh
```

## Before merging a PR

`gh pr checks <number>` must show **pass** for:

- `secret-audit`
- `backend` / `frontend`
- `Analyze (python)` / `Analyze (javascript-typescript)` (when CodeQL runs)

## CodeQL (monorepo) — recurrence prevention

**Forbidden** (root cause of PR #16 CI failure):

- Combining `source-root` with repo-root paths in `codeql-config.yml`
- `github/codeql-action/autobuild` (not needed for Python / JS here)

**Correct pattern:**

- `build-mode: none`
- Python: `pip install -r requirements.txt`
- JS/TS: `npm ci && npm run build` (under `frontend/`)
- After changes: `bash scripts/validate-security-workflows.sh`

## Values allowed in local dev

- `.env.example` (key names only)
- `docker-compose.yml` / `config.py` placeholder `smartresearch`
- Test fixtures such as `test-key`

Registered in `.gitleaks.toml` / `.trivyignore`.

## If a secret leaks

1. Rotate the key immediately
2. Remove from history (BFG / `git filter-repo`)
3. Re-run `bash scripts/secret-audit.sh`

---

# セキュリティスキャン（秘密情報・脆弱性）

SmartResearch-HQ の CI・ワークフロー運用の正本。OWASP Secrets Management / CWE-798 / GitHub Code Scanning に沿います。

**コーディング規約（OWASP Top 10 / IPA）:** [docs/agents/security.md](agents/security.md) · ADR [0006](adr/0006-security-guardrails-public-standards.md)

## 多層防御

| タイミング | 仕組み | ファイル |
|------------|--------|----------|
| commit 前 | secret ファイル拒否 + gitleaks protect | `.githooks/pre-commit` → `scripts/pre-commit-secret-check.sh` |
| push 前（ローカル） | baseline + lint/test/build | `scripts/ci-check.sh` |
| push / PR（CI） | gitleaks + trivy secret | `.github/workflows/ci.yml` → `secret-audit` job |
| push / PR（CI） | CodeQL | `.github/workflows/codeql.yml` |
| 週次 | Dependabot | `.github/dependabot.yml` |
| GitHub プラットフォーム | Secret Scanning + Push Protection | `scripts/enable-github-secret-scanning.sh` |

## 手動確認

```bash
bash scripts/secret-audit.sh
bash scripts/ci-check.sh
bash scripts/validate-security-workflows.sh
bash scripts/enable-github-secret-scanning.sh
```

## PR マージ前チェック

`gh pr checks <番号>` で以下が **pass**:

- `secret-audit`
- `backend` / `frontend`
- `Analyze (python)` / `Analyze (javascript-typescript)`（CodeQL 実行時）

## CodeQL（monorepo）— 再発防止

**禁止**（PR #16 で CI 失敗した原因）:

- `source-root` と `codeql-config.yml` の repo-root paths を併用
- `github/codeql-action/autobuild`（Python / JS では不要）

**正しいパターン**:

- `build-mode: none`
- Python: `pip install -r requirements.txt`
- JS/TS: `npm ci && npm run build`（`frontend/`）
- 変更後: `bash scripts/validate-security-workflows.sh`

## ローカル dev で許容される値

- `.env.example`（キー名のみ）
- `docker-compose.yml` / `config.py` の `smartresearch`
- テストの `test-key`

`.gitleaks.toml` / `.trivyignore` に登録済み。

## 漏洩時

1. キーを即ローテーション
2. 履歴から削除（BFG / `git filter-repo`）
3. `bash scripts/secret-audit.sh` で再確認
