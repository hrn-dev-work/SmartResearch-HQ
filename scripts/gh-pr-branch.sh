#!/usr/bin/env bash
# gh helpers for older CLI (no `gh pr view --head`). Source: . scripts/gh-pr-branch.sh

# PR number for a head branch, or empty.
gh_pr_number_for_branch() {
  local branch="$1"
  local repo="${2:-}"
  local num=""

  if [[ -n "$repo" ]]; then
    num="$(gh pr list --repo "$repo" --head "$branch" --state open --limit 1 --json number -q '.[0].number' 2>/dev/null || true)"
  else
    num="$(gh pr list --head "$branch" --state open --limit 1 --json number -q '.[0].number' 2>/dev/null || true)"
  fi
  if [[ -n "$num" && "$num" != "null" ]]; then
    echo "$num"
    return
  fi

  # Fallback: owner:branch (fork-style head ref)
  local owner
  owner="$(gh repo view ${repo:+--repo "$repo"} --json owner -q .owner.login 2>/dev/null || true)"
  if [[ -n "$owner" ]]; then
    if [[ -n "$repo" ]]; then
      num="$(gh pr list --repo "$repo" --head "${owner}:${branch}" --state open --limit 1 --json number -q '.[0].number' 2>/dev/null || true)"
    else
      num="$(gh pr list --head "${owner}:${branch}" --state open --limit 1 --json number -q '.[0].number' 2>/dev/null || true)"
    fi
  fi
  [[ "$num" == "null" ]] && num=""
  echo "$num"
}

gh_pr_url_for_branch() {
  local branch="$1"
  local repo="${2:-}"
  local url=""

  if [[ -n "$repo" ]]; then
    url="$(gh pr list --repo "$repo" --head "$branch" --state open --limit 1 --json url -q '.[0].url' 2>/dev/null || true)"
  else
    url="$(gh pr list --head "$branch" --state open --limit 1 --json url -q '.[0].url' 2>/dev/null || true)"
  fi
  if [[ -n "$url" && "$url" != "null" ]]; then
    echo "$url"
    return
  fi

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

# Create PR via REST (avoids GraphQL projectCards deprecation on some gh versions).
gh_pr_create_rest() {
  local base="$1"
  local branch="$2"
  local title="$3"
  local body="$4"
  local repo="${5:-}"

  local body_file
  body_file="$(mktemp)"
  trap 'rm -f "$body_file"' RETURN
  printf '%s' "$body" >"$body_file"

  local api_args=(api)
  [[ -n "$repo" ]] && api_args+=(--repo "$repo")
  api_args+=(
    repos/{owner}/{repo}/pulls
    -f "title=$title"
    -f "head=$branch"
    -f "base=$base"
    -f "body=@${body_file}"
  )

  gh "${api_args[@]}" --jq .html_url 2>/dev/null
}

gh_pr_create_safe() {
  local base="$1"
  local branch="$2"
  local title="$3"
  local body="$4"
  local repo="${5:-}"

  local err_file url
  err_file="$(mktemp)"
  trap 'rm -f "$err_file"' RETURN

  if [[ -n "$repo" ]]; then
    gh pr create --repo "$repo" --base "$base" --head "$branch" --title "$title" --body "$body" 2>"$err_file" && return 0
  else
    gh pr create --base "$base" --head "$branch" --title "$title" --body "$body" 2>"$err_file" && return 0
  fi

  if grep -q projectCards "$err_file" 2>/dev/null; then
    url="$(gh_pr_create_rest "$base" "$branch" "$title" "$body" "$repo")"
    if [[ -n "$url" ]]; then
      echo "PR created (REST API; skipped classic Projects GraphQL)" >&2
      echo "$url"
      return 0
    fi
  fi

  cat "$err_file" >&2
  return 1
}
