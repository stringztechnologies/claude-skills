#!/usr/bin/env bash
set -euo pipefail

# Crawl a website and extract design tokens (colors, fonts, spacing, radius, shadows)
# Usage: ./crawl-and-extract.sh "https://example.com" [output-dir]

URL="${1:?Usage: crawl-and-extract.sh <url> [output-dir]}"
OUTPUT_DIR="${2:-.}"
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "==> Fetching $URL ..."
curl -sL -A "$UA" "$URL" > "$TMPDIR/index.html"

# Find CSS file URLs
echo "==> Discovering CSS files..."
CSS_PATHS=$(grep -oE 'href="[^"]*\.css[^"]*"' "$TMPDIR/index.html" | sed 's/href="//;s/"//' || true)

# Determine base URL
BASE_URL=$(echo "$URL" | grep -oE 'https?://[^/]+')

# Download CSS files
CSS_COMBINED="$TMPDIR/combined.css"
: > "$CSS_COMBINED"

for css_path in $CSS_PATHS; do
  if [[ "$css_path" == http* ]]; then
    css_url="$css_path"
  else
    css_url="${BASE_URL}${css_path}"
  fi
  echo "    Fetching: $css_url"
  curl -sL -A "$UA" "$css_url" >> "$CSS_COMBINED" 2>/dev/null || true
  echo "" >> "$CSS_COMBINED"
done

echo "==> Extracting design tokens..."

# Extract colors
echo "--- Colors (hex) ---"
COLORS=$(grep -oE '#[0-9a-fA-F]{3,8}' "$CSS_COMBINED" "$TMPDIR/index.html" 2>/dev/null | sort -u)
echo "$COLORS" > "$TMPDIR/colors.txt"
echo "  Found $(echo "$COLORS" | wc -l | tr -d ' ') unique hex colors"

# Extract CSS custom properties (non-Tailwind internal)
echo "--- CSS Custom Properties ---"
VARS=$(grep -oE '\-\-[a-zA-Z0-9_-]+:[^;}]+' "$CSS_COMBINED" 2>/dev/null | grep -v '^--tw-' | sort -u)
echo "$VARS" > "$TMPDIR/variables.txt"
echo "  Found $(echo "$VARS" | wc -l | tr -d ' ') custom properties"

# Extract font families
echo "--- Font Families ---"
FONTS=$(grep -oE 'font-family:[^;}]+' "$CSS_COMBINED" 2>/dev/null | sort -u)
echo "$FONTS" > "$TMPDIR/fonts.txt"
echo "  Found $(echo "$FONTS" | wc -l | tr -d ' ') font declarations"

# Extract border-radius
echo "--- Border Radius ---"
RADII=$(grep -oE 'border-radius:[^;}]+' "$CSS_COMBINED" 2>/dev/null | sort -u)
echo "$RADII" > "$TMPDIR/radii.txt"
echo "  Found $(echo "$RADII" | wc -l | tr -d ' ') radius values"

# Extract box-shadows
echo "--- Box Shadows ---"
SHADOWS=$(grep -oE 'box-shadow:[^;}]+' "$CSS_COMBINED" 2>/dev/null | sort -u)
echo "$SHADOWS" > "$TMPDIR/shadows.txt"
echo "  Found $(echo "$SHADOWS" | wc -l | tr -d ' ') shadow values"

# Extract font weights
echo "--- Font Weights ---"
WEIGHTS=$(grep -oE '\-\-font-weight-[a-z]+:[0-9]+' "$CSS_COMBINED" 2>/dev/null | sort -u)
echo "$WEIGHTS" > "$TMPDIR/weights.txt"

# Extract inline colors from HTML
echo "--- Inline Colors ---"
INLINE_COLORS=$(grep -oE '(rgba?\([^)]+\)|hsla?\([^)]+\))' "$TMPDIR/index.html" 2>/dev/null | sort -u)
echo "$INLINE_COLORS" >> "$TMPDIR/colors.txt"

# Build JSON output
OUTPUT_FILE="$OUTPUT_DIR/design-tokens.json"
cat > "$OUTPUT_FILE" << 'JSONEOF'
{
  "source_url": "PLACEHOLDER_URL",
  "extracted_at": "PLACEHOLDER_DATE",
  "colors": {},
  "fonts": {},
  "radius": {},
  "shadows": [],
  "custom_properties": {},
  "font_weights": {}
}
JSONEOF

# Replace placeholders
if [[ "$(uname)" == "Darwin" ]]; then
  sed -i '' "s|PLACEHOLDER_URL|$URL|" "$OUTPUT_FILE"
  sed -i '' "s|PLACEHOLDER_DATE|$(date -u +%Y-%m-%dT%H:%M:%SZ)|" "$OUTPUT_FILE"
else
  sed -i "s|PLACEHOLDER_URL|$URL|" "$OUTPUT_FILE"
  sed -i "s|PLACEHOLDER_DATE|$(date -u +%Y-%m-%dT%H:%M:%SZ)|" "$OUTPUT_FILE"
fi

echo ""
echo "==> Raw token files saved to $TMPDIR/"
echo "==> JSON output: $OUTPUT_FILE"
echo ""
echo "==> Summary:"
echo "  Colors:     $(cat "$TMPDIR/colors.txt" | sort -u | wc -l | tr -d ' ')"
echo "  Variables:  $(wc -l < "$TMPDIR/variables.txt" | tr -d ' ')"
echo "  Fonts:      $(wc -l < "$TMPDIR/fonts.txt" | tr -d ' ')"
echo "  Radii:      $(wc -l < "$TMPDIR/radii.txt" | tr -d ' ')"
echo "  Shadows:    $(wc -l < "$TMPDIR/shadows.txt" | tr -d ' ')"

# Also dump the key findings to stdout for easy copy
echo ""
echo "========================================="
echo "KEY DESIGN TOKENS"
echo "========================================="
echo ""
echo "## Custom Properties (semantic tokens)"
grep -E '\-\-(primary|secondary|accent|background|foreground|border|radius|font|destructive|muted|card|popover|sidebar|ring|chart|gold|success|warning|danger|info)' "$TMPDIR/variables.txt" 2>/dev/null | head -60 || true
echo ""
echo "## Font Families"
cat "$TMPDIR/fonts.txt"
echo ""
echo "## Border Radius Values"
cat "$TMPDIR/radii.txt"
echo ""
echo "## Font Weights"
cat "$TMPDIR/weights.txt"
