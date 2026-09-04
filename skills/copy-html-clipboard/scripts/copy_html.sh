#!/usr/bin/env bash
# Copy HTML to the macOS clipboard as raw text/html.
# Pastes into Gmail / Docs / Notion using the destination's default font
# (no embedded font/style, unlike textutil RTF conversion).
#
# Strips em-dashes (U+2014) before copying so output doesn't look AI-generated:
#   " - " replaces " - " (em-dash with surrounding spaces)
#   "-"    replaces bare em-dash
#
# Usage:
#   copy_html.sh <path-to-html-file>
#   echo "<ul><li>hi</li></ul>" | copy_html.sh
#   copy_html.sh -                     # explicit stdin

set -euo pipefail

clean() {
  perl -CSDA -pe 's/ \x{2014} / - /g; s/\x{2014}/-/g'
}

if [[ $# -eq 1 && "$1" != "-" ]]; then
  src="$1"
  [[ -f "$src" ]] || { echo "error: file not found: $src" >&2; exit 1; }
  hex=$(clean < "$src" | hexdump -ve '1/1 "%.2x"')
else
  hex=$(clean | hexdump -ve '1/1 "%.2x"')
fi

if [[ -z "$hex" ]]; then
  echo "error: no HTML input" >&2
  exit 1
fi

osascript -e "set the clipboard to «data HTML${hex}»"
echo "Copied $(( ${#hex} / 2 )) bytes of HTML to clipboard."
