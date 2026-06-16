# Git hooks — local pre-commit setup

This repository ships tracked hooks under \.githooks/\. They are **optional** for read-only clones but recommended for anyone who commits from WSL.

## Install (once per clone)

\\ash
bash scripts/install-git-hooks.sh
\
The installer sets:

| Git config | Value | Why |
|------------|-------|-----|
| \core.hooksPath\ | \.githooks\ | Use repo hooks instead of \~/.git-hooks\ |
| \core.filemode\ | \alse\ | Ignore chmod noise when Windows (UNC) and WSL share one working tree |

\ash scripts/bootstrap-local.sh\ prints the same install hint at the end.

## What runs on \git\commit
| Hook | Script | Purpose |
|------|--------|---------|
| **pre-commit** | \.githooks/pre-commit\ | Secret scan, WBS/README checkbox sync, public-doc validation when md is staged |
| **post-push** | \.githooks/post-push\ | Sync open PR body checkboxes (existing PR only; create PR with \git-pr-complete.sh\) |

Pre-commit steps (in order):

1. \scripts/pre-commit-secret-check.sh\ — blocks likely secrets in staged files  
2. \scripts/sync-wbs-roadmap.sh --stage\ — keeps roadmap/README phase boxes aligned  
3. When public markdown is staged: \scripts/validate-public-docs.sh\ (bilingual EN → \---\ → JA), except \docs/adr/\ (English-only; \scripts/validate-adrs.sh\ instead)

See [doc-conventions.md](doc-conventions.md) for public markdown rules.

## Agent / ship workflow

| Goal | Command |
|------|---------|
| Push | \ash scripts/git-ship.sh push\ |
| Open or update PR | \ash scripts/git-pr-complete.sh\ |
| Safe \git add\ | \ash scripts/git-add-safe.sh\ |

Details: [agent-git-playbook.md](agent-git-playbook.md).

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Hook not running | Run \ash scripts/install-git-hooks.sh\; verify \git config core.hooksPath\ → \.githooks\ |
| \pre-commit\ fails on docs | Run \ash scripts/validate-public-docs.sh\; add Japanese mirror after \---\ |
| Phantom file mode diffs on UNC | Installer sets \core.filemode false\; stay in WSL path \~/workspace/...\ |
| Stuck \index.lock\ | \
m -f .git/index.lock\ (no other git process running) |
| Skip hooks (emergency only) | User must request explicitly; do not use \--no-verify\ in agent automation |

## Uninstall

\\ash
git config --unset core.hooksPath
git config --unset core.filemode
\
---

# Git フック — ローカル pre-commit 設定

コミット用フックは \.githooks/\ に同梱されています。**閲覧だけ**なら不要ですが、WSL からコミットする場合はインストールを推奨します。

## インストール（clone ごとに 1 回）

\\ash
bash scripts/install-git-hooks.sh
\
| Git 設定 | 値 | 理由 |
|----------|-----|------|
| \core.hooksPath\ | \.githooks\ | グローバルではなくリポジトリのフックを使う |
| \core.filemode\ | \alse\ | Windows（UNC）と WSL で同一作業ツリーを共有するときの chmod 差分を無視 |

\ash scripts/bootstrap-local.sh\ の末尾にも同じ案内があります。

## \git\commit\ で動くもの

| フック | スクリプト | 目的 |
|--------|------------|------|
| **pre-commit** | \.githooks/pre-commit\ | シークレット検査、WBS/README チェック同期、public md の検証 |
| **post-push** | \.githooks/post-push\ | 既存 PR のチェックボックス同期（新規 PR は \git-pr-complete.sh\） |

pre-commit の順序:

1. \scripts/pre-commit-secret-check.sh\ — ステージ済みファイルのシークレット疑いをブロック  
2. \scripts/sync-wbs-roadmap.sh --stage\ — ロードマップと README のフェーズチェックを整合  
3. public Markdown を stage したとき \scripts/validate-public-docs.sh\（英語 → \---\ → 日本語）。\docs/adr/\ は例外（英語のみ → \scripts/validate-adrs.sh\）

公開 md の規約: [doc-conventions.md](doc-conventions.md)。

## エージェント向け ship

| 目的 | コマンド |
|------|----------|
| push | bash scripts/git-ship.sh push |
| PR 作成・更新 | bash scripts/git-pr-complete.sh |
| 安全な add | bash scripts/git-add-safe.sh |

詳細: agent-git-playbook.md。

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| フックが動かない | bash scripts/install-git-hooks.sh で core.hooksPath=.githooks を確認 |
| pre-commit が docs で失敗 | bash scripts/validate-public-docs.sh（--- 以降に日本語全文） |
| index.lock が残る | rm -f .git/index.lock |

## アンインストール

    git config --unset core.hooksPath
    git config --unset core.filemode
