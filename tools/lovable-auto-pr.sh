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
if git diff --cached --quiet; then
  echo "No changes in export; exiting."
  git checkout "$BASE_BRANCH"
  git branch -d "$PR_BRANCH"
  exit 0
fi

git commit -m "chore(lovable): auto-export Lovable build → $PR_BRANCH

- Source export dir: $EXPORT_DIR
- Automated via tools/lovable-auto-pr.sh
- DO NOT MERGE WITHOUT REVIEW"

git push -f origin "$PR_BRANCH"

# Create PR via GitHub API using git-credentials token
CRED_LINE=$(grep -oP 'https://[^:]+:[^@]+@github\.com' ~/.git-credentials | head -1 || true)
if [ -z "$CRED_LINE" ]; then
  echo "WARNING: no GitHub token found in ~/.git-credentials; PR not created."
  git checkout "$BASE_BRANCH"
  exit 0
fi
TOKEN=$(echo "$CRED_LINE" | sed -E 's/.*:\/\/(.*?):(.*)@.*/\2/')

REPO=$(git remote get-url origin | sed -E 's#https://[^/]+/([^/]+/[^/.]+)(\.git)?#\1#')

PR_URL=$(curl -s -o /tmp/pr_response.txt -w "%{http_code}" -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "Content-Type: application/json" \
  "https://api.github.com/repos/$REPO/pulls" \
  -d "{\"title\": \"Lovable export → $BASE_BRANCH\", \"head\": \"$PR_BRANCH\", \"base\": \"$BASE_BRANCH\", \"body\": \"Automated PR from Lovable export.\n\nSource: $EXPORT_DIR\nBranch: $PR_BRANCH\n\nReview site-temp/ contents before merging.\"}")

echo "PR response: $PR_URL"
if [ -f /tmp/pr_response.txt ]; then
  cat /tmp/pr_response.txt
  rm -f /tmp/pr_response.txt
fi
