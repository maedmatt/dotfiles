#!/bin/sh
# Unwrap soft line breaks then copy to system clipboard.
# Joins lines where the next line starts with a lowercase letter or number,
# preserving intentional breaks (bullets, blank lines, headings, code).

perl -0777 -pe 's/\n\s*([a-z0-9])/ $1/g' | {
  if command -v pbcopy >/dev/null 2>&1; then
    pbcopy
  elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard
  else
    cat
  fi
}
