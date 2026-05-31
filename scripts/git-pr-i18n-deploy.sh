#!/usr/bin/env bash
# Deprecated one-off — use git-pr-complete.sh
echo "NOTE: git-pr-i18n-deploy.sh is deprecated; running git-pr-complete.sh" >&2
exec bash "$(dirname "$0")/git-pr-complete.sh" "$@"
