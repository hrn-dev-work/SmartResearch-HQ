**Summary**

* Group Dependabot **patch/minor** version updates into one weekly PR per ecosystem (npm, pip, GitHub Actions)
* Keep **major** updates as separate PRs for breaking-change review
* Group **security** updates per ecosystem when multiple CVE fixes land together
* Run weekly on **Monday**; cap concurrent open PRs at 3 per ecosystem
* Document policy in `docs/security-scanning.md`

**Commits**

* `chore(deps): group Dependabot patch/minor updates weekly`

**Test plan**

* [x] `python3` YAML parse of `.github/dependabot.yml`
* [x] `bash scripts/validate-public-docs.sh`
* [ ] After merge, next Dependabot cycle uses grouped PRs for patch/minor

**Related**

* `.github/dependabot.yml`
* `docs/security-scanning.md`

---

**概要 (Summary)**

* **patch/minor** を ecosystem ごとに週1 PR にまとめる（npm / pip / GitHub Actions）
* **major** は破壊的変更のため個別 PR
* **セキュリティ** 修正は同一 ecosystem でまとめ可能
* **月曜** 実行、同時オープン上限は ecosystem ごと 3
* 方針は `docs/security-scanning.md` に記載

**コミット (Commits)**

* `chore(deps): group Dependabot patch/minor updates weekly`

**テスト計画 (Test plan)**

* [x] `dependabot.yml` の YAML 検証
* [x] `validate-public-docs.sh`
* [ ] マージ後の Dependabot で patch/minor がグループ PR になること

**関連 (Related)**

* `.github/dependabot.yml`
* `docs/security-scanning.md`
