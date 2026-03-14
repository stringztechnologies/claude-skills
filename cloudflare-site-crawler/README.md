---
name: cloudflare-site-crawler
description: "Crawl any website and extract design tokens (colors, fonts, spacing, shadows, border-radius) with visual brand verification. Use this skill when you need to match a client's existing website branding, extract a design system from a live site, or analyze a competitor's visual design."
---

# Cloudflare Site Crawler — Design Token Extractor

## When to Use
- Matching a client's existing website branding for a new app
- Extracting a design system from a live site
- Comparing two designs for brand alignment
- Auditing CSS consistency across properties

## Extraction Strategy

### Step 1: Fetch HTML and Discover CSS Files
```bash
curl -sL -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
  "https://TARGET_SITE/" | grep -oE 'href="[^"]*\.css[^"]*"'
```

### Step 2: Fetch Each CSS File
```bash
curl -sL -A "Mozilla/5.0 ..." "https://TARGET_SITE/_next/static/chunks/HASH.css" > /tmp/site-styles.css
```

### Step 3: Extract Design Tokens

#### Colors (hex, rgb, hsl)
```bash
grep -oE '#[0-9a-fA-F]{3,8}' /tmp/site-styles.css | sort -u
```

#### CSS Custom Properties
```bash
grep -oE '\-\-[a-zA-Z0-9_-]+:[^;}]+' /tmp/site-styles.css | grep -v '^--tw-' | sort -u
```

#### Fonts
```bash
grep -oE 'font-family:[^;}]+' /tmp/site-styles.css | sort -u
```

#### Border Radius
```bash
grep -oE 'border-radius:[^;}]+' /tmp/site-styles.css | sort -u
```

#### Box Shadows
```bash
grep -oE 'box-shadow:[^;}]+' /tmp/site-styles.css | sort -u
```

### Step 4: Visual Brand Verification (CRITICAL — don't skip)

CSS extraction alone is NOT sufficient for brand matching. Automated crawling captures every color in the stylesheet but cannot determine which colors are the DOMINANT brand identity vs. secondary/utility colors.

After extracting CSS tokens, ALWAYS do a visual verification:

1. Take a screenshot of the site's homepage (use WebFetch, Stitch, or vision API)
2. Identify the TOP 3 visually dominant colors by looking at:
   - Hero section background
   - Primary CTA button color
   - Navigation highlight/active color
   - Logo colors
   - Overall photography tone (warm/cool)
3. Compare these visual dominants against the extracted CSS colors
4. If there's a mismatch (e.g., CSS shows green but the site LOOKS gold), trust the visual over the CSS
5. Document the brand as: "Primary: [visual dominant], Secondary: [visual secondary], Accent: [CTA color]"

#### Common Pitfalls This Prevents
- Site has utility colors (success green, error red) that the CSS parser picks up as "the accent"
- Photography and imagery create a warm/cool tone that pure hex values don't capture
- The actual brand color might be in an image or SVG, not in CSS variables
- Dark mode / light mode variants can confuse automated extraction

#### Output should include
- **CSS-extracted palette** (raw data)
- **Visually-verified palette** (human/AI judgment)
- **Recommendation**: which colors to use for the portal
- **Brand assets**: any logo/wordmark/crest that should be incorporated

### Step 5: Cloudflare Browser Rendering API (Optional)

For JS-rendered sites where curl can't capture computed styles:

```bash
# Initiate crawl
curl -X POST "https://api.cloudflare.com/client/v4/accounts/{account_id}/browser-rendering/crawl" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://TARGET_SITE/"}'

# Retrieve results
curl "https://api.cloudflare.com/client/v4/accounts/{account_id}/browser-rendering/crawl/{job_id}" \
  -H "Authorization: Bearer $CF_API_TOKEN"
```

### Step 6: Run the Extraction Script

```bash
~/.claude/skills/cloudflare-site-crawler/scripts/crawl-and-extract.sh "https://TARGET_SITE/"
```

### Step 7: Generate Brand Alignment Report

Compare extracted tokens against the target app's `globals.css` / `tailwind.config.ts`:
- Map each extracted `--variable` to the app's equivalent
- Note mismatches in color, font, radius, spacing
- Output actionable CSS changes

## Output Format

The script outputs `design-tokens.json` with colors, fonts, radius, shadows, and custom properties.

## Fallback Approaches

If the site blocks direct fetching:
1. Try `WebFetch` tool with detailed extraction prompt
2. Check `web.archive.org/web/*/TARGET_SITE`
3. Use Google cache
4. Use Cloudflare Browser Rendering API (requires account setup)
