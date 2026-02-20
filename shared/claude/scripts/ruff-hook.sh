#!/bin/bash
# PostToolUse hook: run ruff check on edited Python files
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only check .py files
case "$FILE_PATH" in
  *.py) ;;
  *) exit 0 ;;
esac

# Skip if ruff is not installed
command -v ruff >/dev/null 2>&1 || exit 0

# Run ruff check on the file
LINT_OUTPUT=$(ruff check "$FILE_PATH" 2>&1)
LINT_EXIT=$?

if [ $LINT_EXIT -ne 0 ] && [ -n "$LINT_OUTPUT" ]; then
  # Feed lint errors back to Claude as context
  jq -n --arg lint "$LINT_OUTPUT" --arg file "$FILE_PATH" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: ("ruff found lint errors in " + $file + ":\n" + $lint)
    }
  }'
fi

exit 0
