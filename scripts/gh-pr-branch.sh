#!/usr/bin/env bash
# gh helpers for older CLI (no `gh pr view --head`). Source: . scripts/gh-pr-branch.sh

# PR number for a head branch, or empty.
gh_pr_number_for_branch() {
  local branch="$1"
  local repo="${2:-}"
  if [[ -n "$repo" ]]; then
    gh pr list --repo "$repo" --head "$branch" --state all --limit 1 --json number -q '.[0].number' 2>/dev/null || true
  else
    gh pr list --head "$branch" --state all --limit 1 --json number -q '.[0].number' 2>/dev/null || true
  fi
}

gh_pr_url_for_branch() {
  local branch="$1"
  local repo="${2:-}"
  if [[ -n "$repo" ]]; then
    gh pr list --repo "$repo" --head "$branch" --state all --limit 1 --json url -q '.[0].url' 2>/dev/null || true
  else
    gh pr list --head "$branch" --state all --limit 1 --json url -q '.[0].url' 2>/dev/null || true
  fi
}
