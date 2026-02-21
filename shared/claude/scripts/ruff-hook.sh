#!/bin/bash
# PostToolUse hook: format, auto-fix, then report remaining errors
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

case "$FILE_PATH" in
  *.py) ;;
  *) exit 0 ;;
esac

command -v ruff >/dev/null 2>&1 || exit 0

ruff format "$FILE_PATH" 2>/dev/null
ruff check --fix "$FILE_PATH" 2>/dev/null

# Report any remaining unfixable errors
LINT_OUTPUT=$(ruff check "$FILE_PATH" 2>&1)
LINT_EXIT=$?

if [ $LINT_EXIT -ne 0 ] && [ -n "$LINT_OUTPUT" ]; then
  jq -n --arg lint "$LINT_OUTPUT" --arg file "$FILE_PATH" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: ("ruff found lint errors in " + $file + ":\n" + $lint)
    }
  }'
fi

exit 0
