#!/usr/bin/env bash
# gh helpers for older CLI (no `gh pr view --head`). Source: . scripts/gh-pr-branch.sh
# PR body updates: gh_api_patch_pr_body uses python3 JSON (REST). Never gh api -f body=@file.

gh_pr_number_for_branch() {
  local branch="$1" repo="${2:-}" owner repo_slug num
  if [[ -n "$repo" ]]; then
    repo_slug="$repo"; owner="${repo%%/*}"
  else
    repo_slug="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
    owner="$(gh repo view --json owner -q .owner.login 2>/dev/null || true)"
  fi
  [[ -z "$repo_slug" || -z "$owner" ]] && return 0
  num="$(gh api "repos/${repo_slug}/pulls?state=open&head=${owner}:${branch}" --jq '.[0].number' 2>/dev/null || true)"
  [[ "$num" == "null" ]] && num=""
  echo "$num"
}

gh_pr_url_for_branch() {
  local branch="$1" repo="${2:-}" url=""
  if [[ -n "$repo" ]]; then
    url="$(gh pr list --repo "$repo" --head "$branch" --state open --limit 1 --json url -q '.[0].url' 2>/dev/null || true)"
  else
    url="$(gh pr list --head "$branch" --state open --limit 1 --json url -q '.[0].url' 2>/dev/null || true)"
  fi
  [[ -n "$url" && "$url" != "null" ]] && { echo "$url"; return; }
  local owner
  owner="$(gh repo view ${repo:+--repo "$repo"} --json owner -q .owner.login 2>/dev/null || true)"
  if [[ -n "$owner" ]]; then
    if [[ -n "$repo" ]]; then
      url="$(gh pr list --repo "$repo" --head "${owner}:${branch}" --state open --limit 1 --json url -q '.[0].url' 2>/dev/null || true)"
    else
      url="$(gh pr list --head "${owner}:${branch}" --state open --limit 1 --json url -q '.[0].url' 2>/dev/null || true)"
    fi
  fi
  [[ "$url" == "null" ]] && url=""
  echo "$url"
}

gh_api_patch_pr_body() {
  local pr_num="$1" body="$2" repo="${3:-}" input_file url
  input_file="$(mktemp)"
  BODY="$body" python3 -c "import json, os; print(json.dumps({'body': os.environ['BODY']}))" >"$input_file"
  local api_args=(api --method PATCH --input "$input_file")
  if [[ -n "$repo" ]]; then
    api_args+=(repos/"${repo}"/pulls/"$pr_num")
  else
    api_args+=(repos/{owner}/{repo}/pulls/"$pr_num")
  fi
  url="$(gh "${api_args[@]}" --jq .html_url 2>/dev/null || true)"
  rm -f "$input_file"
  [[ -n "$url" && "$url" != "null" ]] && echo "$url"
}

gh_pr_create_rest() {
  local base="$1" branch="$2" title="$3" body="$4" repo="${5:-}" input_file url
  input_file="$(mktemp)"
  TITLE="$title" HEAD="$branch" BASE="$base" BODY="$body" python3 -c "
import json, os
print(json.dumps({'title': os.environ['TITLE'], 'head': os.environ['HEAD'], 'base': os.environ['BASE'], 'body': os.environ['BODY']}))
" >"$input_file"
  local api_args=(api --method POST --input "$input_file")
  [[ -n "$repo" ]] && api_args+=(--repo "$repo")
  api_args+=(repos/{owner}/{repo}/pulls)
  url="$(gh "${api_args[@]}" --jq .html_url 2>/dev/null || true)"
  rm -f "$input_file"
  [[ -n "$url" && "$url" != "null" ]] && echo "$url"
}

gh_pr_create_safe() {
  local base="$1" branch="$2" title="$3" body="$4" repo="${5:-}"
  local err_file url; err_file="$(mktemp)"; trap 'rm -f "$err_file"' RETURN
  if [[ -n "$repo" ]]; then
    gh pr create --repo "$repo" --base "$base" --head "$branch" --title "$title" --body "$body" 2>"$err_file" && return 0
  else
    gh pr create --base "$base" --head "$branch" --title "$title" --body "$body" 2>"$err_file" && return 0
  fi
  if grep -qE 'projectCards|Projects \(classic\)' "$err_file" 2>/dev/null; then
    url="$(gh_pr_create_rest "$base" "$branch" "$title" "$body" "$repo")"
    [[ -n "$url" ]] && { echo "PR created (REST API)" >&2; echo "$url"; return 0; }
  fi
  cat "$err_file" >&2; return 1
}

gh_pr_edit_body_safe() {
  local pr_num="$1" body="$2" repo="${3:-}" url
  url="$(gh_api_patch_pr_body "$pr_num" "$body" "$repo")"
  [[ -n "$url" ]] && { echo "PR #${pr_num} body updated (REST API)" >&2; return 0; }
  local err_file body_file; err_file="$(mktemp)"; body_file="$(mktemp)"
  trap 'rm -f "$err_file" "$body_file"' RETURN
  printf '%s' "$body" >"$body_file"
  if [[ -n "$repo" ]]; then
    gh pr edit "$pr_num" --repo "$repo" --body-file "$body_file" 2>"$err_file" && return 0
  else
    gh pr edit "$pr_num" --body-file "$body_file" 2>"$err_file" && return 0
  fi
  cat "$err_file" >&2; return 1
}
