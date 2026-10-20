#!/usr/bin/env bash
set -x  # Enable bash debug mode
set -euo pipefail

payload="$(cat)"
tool_name="$(printf '%s' "$payload" | jq -r '.toolName')"

# Only gate bash commands that are git commits
if [[ "$tool_name" != "bash" ]]; then exit 0; fi
command="$(printf '%s' "$payload" | jq -r '.toolArgs' | jq -r '.command // ""')"
if ! printf '%s' "$command" | grep -q "git commit"; then exit 0; fi

CWD="$(printf '%s' "$payload" | jq -r '.cwd')"
ERRORS=""

# 1. TypeScript type check
if [[ -f "$CWD/tsconfig.json" ]]; then
  TSC_OUT=$(cd "$CWD" && npx tsc --noEmit 2>&1) || ERRORS="${ERRORS}
=== TypeScript Errors ===
$(echo "$TSC_OUT" | head -30)"
fi

# 2. Lint
if [[ -f "$CWD/package.json" ]]; then
  HAS_LINT=$(jq -r '.scripts.lint // empty' "$CWD/package.json" 2>/dev/null)
  if [[ -n "$HAS_LINT" ]]; then
    LINT_OUT=$(cd "$CWD" && npm run lint --silent 2>&1) || ERRORS="${ERRORS}
=== Lint Errors ===
$(echo "$LINT_OUT" | tail -30)"
  fi

  # 3. Tests
  HAS_TEST=$(jq -r '.scripts.test // empty' "$CWD/package.json" 2>/dev/null)
  if [[ -n "$HAS_TEST" ]]; then
    TEST_OUT=$(cd "$CWD" && CI=true npm test -- --watchAll=false 2>&1) || ERRORS="${ERRORS}
=== Test Failures ===
$(echo "$TEST_OUT" | tail -30)"
  fi
fi

if [[ -n "$ERRORS" ]]; then
  jq -nc --arg reason "Cannot commit — fix these issues first:
$ERRORS" \
    '{permissionDecision:"deny",permissionDecisionReason:$reason}'
fi
exit 0