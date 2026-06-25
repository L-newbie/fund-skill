#!/usr/bin/env bash
#
# fund-skill minimal scanner (zero-dependency fallback)
#
# Only scans api/*/ structure and prints a summary.
# For full maintenance (update downstream files, validate APIs),
# use Claude Code with the Project Maintenance rules in SKILL.md.
#
# Usage: bash scripts/sync.sh

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API_DIR="$ROOT/api"

echo "🔍 Scanning api/ directory structure..."
echo "────────────────────────────────────────────────────────────"

total_apis=0

# Scan language board subdirectories
for lang_dir in "$API_DIR"/*/; do
    lang=$(basename "$lang_dir")
    echo ""
    echo "📂 $lang/"

    for board_file in "$lang_dir"*.md; do
        [ -f "$board_file" ] || continue
        board=$(basename "$board_file" .md)

        # Skip profiles.md (not a board file)
        [ "$board" = "profiles" ] && continue

        # Count ## N. headings
        count=$(grep '^## [0-9]' "$board_file" 2>/dev/null | wc -l)
        total_apis=$((total_apis + count))

        echo "  📄 ${board}.md — ${count} APIs"
    done
done

echo ""
echo "────────────────────────────────────────────────────────────"
echo "📊 Total: ${total_apis} APIs"
echo ""
echo "💡 For full maintenance (update references, validate APIs),"
echo "   use Claude Code Project Maintenance rules in SKILL.md."
