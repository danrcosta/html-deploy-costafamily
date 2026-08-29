#!/usr/bin/env bash
# lovable-auto-pr.sh
# Usage: tools/lovable-auto-pr.sh [EXPORT_DIR] [BASE_BRANCH]
# - EXPORT_DIR: directory with Lovable exported files (default: ../lovable-export)
# - BASE_BRANCH: branch to PR into (default: main)

set -euo pipefail

EXPORT_DIR="${1:-../lovable-export}"
BASE_BRANCH="${2:-main}"
PR_BRANCH="lovable/auto-export-$(date +%Y%m%d-%H%M%S)"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -d "$EXPORT_DIR" ]; then
  echo "ERROR: export directory not found: $EXPORT_DIR"
  exit 1
fi

cd "$REPO_ROOT"

git fetch origin
git checkout "$BASE_BRANCH"
git pull origin "$BASE_BRANCH"

git checkout -B "$PR_BRANCH"

rm -rf site-temp
mkdir -p site-temp
cp -R "$EXPORT_DIR"/. site-temp/

git add site-temp/
git diff --cached --quiet && echo "No changes in export; exiting." && git checkout "$BASE_BRANCH" && git branch -d "$PR_BRANCH" && exit 0

git commit -m "chore(lovable): auto-export Lovable build → $PR_BRANCH

- Source export dir: $EXPORT_DIR
- Automated via tools/lovable-auto-pr.sh
- DO NOT MERGE WITHOUT REVIEW"

git push -f origin "$PR_BRANCH"

PR_URL=$(gh pr create \
  --base "$BASE_BRANCH" \
  --head "$PR_BRANCH" \
  --title "Lovable export → $BASE_BRANCH" \
  --body "Automated PR from Lovable export.

**Source:** \`$EXPORT_DIR\`
**Branch:** \`$PR_BRANCH\`

Review the \`site-temp/\` contents before merging." 2>&1) || PR_URL=""

if [ -n "$PR_URL" ]; then
  echo "PR created: $PR_URL"
else
  echo "PR creation failed or PR already exists."
fi
