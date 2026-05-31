# Security Scanning

This document defines security scanning guardrails for SmartResearch-HQ.

## Scope

- CI secret scanning in .github/workflows/ci.yml
- CodeQL scanning in .github/workflows/codeql.yml
- Workflow drift validator in scripts/validate-security-workflows.sh

## CodeQL monorepo guardrails

SmartResearch-HQ is a monorepo with backend and frontend. CodeQL guardrails:

- Do not use autobuild.
- Do not set source-root.
- Keep build-mode: none in language matrix entries.
- Keep explicit frontend build step with npm ci and npm run build.

## CI secret scanning guardrails

In ci.yml secret-audit job:

- Pin gitleaks action to a full 40-char SHA.
- Pin trivy action to a full 40-char SHA.
- Keep checks required by failing on findings.

## Validate guardrails

Run this command to validate workflow guardrails:

bash scripts/validate-security-workflows.sh

This command is also called from scripts/ci-check.sh.

---

# Security Scanning（日本語）

このドキュメントは SmartResearch-HQ のセキュリティスキャン運用ガードレールを定義します。

## 対象範囲

- .github/workflows/ci.yml の secret scanning
- .github/workflows/codeql.yml の CodeQL scanning
- scripts/validate-security-workflows.sh によるワークフロードリフト検証

## CodeQL モノレポ運用ルール

SmartResearch-HQ は backend と frontend を含むモノレポです。CodeQL は次を必須とします。

- autobuild を使用しないこと
- source-root を指定しないこと
- language matrix の各要素で build-mode: none を維持すること
- JavaScript/TypeScript 側で npm ci と npm run build を明示実行すること

## CI secret scanning ルール

ci.yml の secret-audit ジョブでは次を必須とします。

- gitleaks action を 40 文字 SHA で pin すること
- trivy action を 40 文字 SHA で pin すること
- 検知時に失敗する必須チェックとして維持すること

## ガードレールの検証

次のコマンドでワークフロー設定逸脱を検証します。

bash scripts/validate-security-workflows.sh

このコマンドは scripts/ci-check.sh からも実行されます。
