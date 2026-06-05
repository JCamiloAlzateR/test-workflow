#!/usr/bin/env bash
# Hermes Autonomous PR Reviewer
# Usage: ./scripts/pr-review.sh <pr-number> <repo> [branch]

set -e

PR_NUMBER="${1:-}"
REPO="${2:-}"
BRANCH="${3:-master}"

if [ -z "$PR_NUMBER" ] || [ -z "$REPO" ]; then
  echo "Usage: $0 <pr-number> <repo> [branch]"
  echo "Example: $0 1 JCamiloAlzateR/test-workflow"
  exit 1
fi

echo "🔍 Running Hermes autonomous review on PR #$PR_NUMBER"

# Build the review prompt
REVIEW_PROMPT="You are a senior code reviewer. Analyze the code changes in PR #$PR_NUMBER of $REPO.
Focus on:
1. Logic errors and bugs
2. Security vulnerabilities
3. Performance issues
4. Code quality and best practices
5. Missing tests

Provide a detailed review with specific suggestions. Format your response as:
## Summary
<Brief summary of changes>

## Issues Found
<List each issue with file:line reference>

## Suggestions
<Specific improvement suggestions>

Be thorough but constructive."

# Run Hermes review via CLI
echo "🤖 Invoking Hermes..."
hermes chat -q "$REVIEW_PROMPT" --cli -m MiniMax-M3 -Q 2>&1 | while IFS= read -r line; do
  echo "  $line"
done

echo ""
echo "✅ Hermes review complete"
echo "📝 Review comments should be posted manually or via GH CLI"
