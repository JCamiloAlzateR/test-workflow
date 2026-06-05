#!/usr/bin/env bash
# Hermes-style PR Review via MiniMax API
# Usage: ./scripts/pr-review.sh <pr-number> <repo>

set -e

PR_NUMBER="${1:-}"
REPO="${2:-}"

if [ -z "$PR_NUMBER" ] || [ -z "$REPO" ]; then
  echo "Usage: $0 <pr-number> <repo>"
  echo "Example: $0 1 JCamiloAlzateR/test-workflow"
  exit 1
fi

if [ -z "$MINIMAX_API_KEY" ]; then
  echo "Error: MINIMAX_API_KEY not set"
  exit 1
fi

echo "🔍 Fetching PR diff for #$PR_NUMBER..."

# Fetch PR details
PR_DATA=$(gh api "repos/$REPO/pulls/$PR_NUMBER" --jq '{title: .title, body: .body, base: .base.ref, head: .head.ref}')

PR_TITLE=$(echo "$PR_DATA" | jq -r '.title')
PR_BODY=$(echo "$PR_DATA" | jq -r '.body')
BASE_BRANCH=$(echo "$PR_DATA" | jq -r '.base')
HEAD_BRANCH=$(echo "$PR_DATA" | jq -r '.head')

echo "📋 PR #$PR_NUMBER: $PR_TITLE"
echo "   Base: $BASE_BRANCH <- Head: $HEAD_BRANCH"

# Get the diff
DIFF=$(gh api "repos/$REPO/pulls/$PR_NUMBER" --jq '.diff_url' 2>/dev/null)

# Fetch commits to build change list
COMMITS=$(gh api "repos/$REPO/pulls/$PR_NUMBER/commits" --jq '.[].commit.message' 2>/dev/null | head -10)

echo ""
echo "📝 Building review prompt..."

# Build the system prompt
SYSTEM_PROMPT="You are an expert code reviewer. Analyze the code changes in this pull request and provide a thorough code review.
Focus on:
1. Logic errors and bugs
2. Security vulnerabilities (injection, auth issues, secrets exposure)
3. Performance problems
4. Code quality and best practices
5. Missing error handling
6. Missing tests

Format your response in markdown with these sections:
## Summary
<Brief summary of what changed>

## Issues Found
<List each issue with: file, line (if applicable), severity (Critical/High/Medium/Low), and description>

## Suggestions
<Specific improvement suggestions>

## Approved
<Yes or No, with reasoning>

Be thorough but constructive. Critical issues should block approval."

# Build the user prompt with diff content
USER_PROMPT="## Pull Request
Title: $PR_TITLE
$PR_BODY

## Commits
$COMMITS

## Code Changes
Please review the code changes in this PR. The diff is available at: $DIFF

Provide a detailed code review."

# Call MiniMax API
echo ""
echo "🤖 Invoking MiniMax for code review..."

RESPONSE=$(curl -s --max-time 120 \
  -X POST "https://api.minimax.io/v1/openai/chat/completions" \
  -H "Authorization: Bearer $MINIMAX_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg system "$SYSTEM_PROMPT" --arg user "$USER_PROMPT" '{
    model: "MiniMax-M3",
    messages: [
      {role: "system", content: $system},
      {role: "user", content: $user}
    ],
    temperature: 0.3,
    max_tokens: 4000
  }')" 2>&1)

# Check if curl succeeded
if [ $? -ne 0 ]; then
  echo "❌ Failed to call MiniMax API"
  exit 1
fi

# Parse the response
REVIEW_CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null)

if [ -z "$REVIEW_CONTENT" ] || [ "$REVIEW_CONTENT" = "null" ]; then
  ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message // "Unknown error"' 2>/dev/null)
  echo "❌ API Error: $ERROR_MSG"
  exit 1
fi

# Post review as PR comment
echo ""
echo "📤 Posting review as PR comment..."

gh pr comment "$PR_NUMBER" --repo "$REPO" --body "## 🤖 Hermes Autonomous Review

$REVIEW_CONTENT

---
*Review generated via MiniMax-M3*"

echo ""
echo "✅ Review complete! Comment posted to PR #$PR_NUMBER"
