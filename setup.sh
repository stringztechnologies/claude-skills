#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo ""
echo "======================================================"
echo "  Stringz Workflow v2 — Level 5 Agent-First Engineering"
echo "======================================================"
echo ""

# ─── 1. Check prerequisites ──────────────────────────────

echo "Checking prerequisites..."
echo ""

MISSING=0

# Claude Code
if command -v claude &>/dev/null; then
  echo "  ✅ Claude Code: $(claude --version 2>/dev/null || echo 'installed')"
else
  echo "  ❌ Claude Code: not found"
  echo "     Install: npm install -g @anthropic-ai/claude-code"
  MISSING=$((MISSING + 1))
fi

# Node.js
if command -v node &>/dev/null; then
  NODE_VERSION=$(node --version)
  NODE_MAJOR=$(echo "$NODE_VERSION" | sed 's/v//' | cut -d. -f1)
  if [ "$NODE_MAJOR" -ge 20 ]; then
    echo "  ✅ Node.js: $NODE_VERSION"
  else
    echo "  ⚠️  Node.js: $NODE_VERSION (need 20+)"
    echo "     Upgrade: brew install node@20"
    MISSING=$((MISSING + 1))
  fi
else
  echo "  ❌ Node.js: not found"
  echo "     Install: brew install node@20"
  MISSING=$((MISSING + 1))
fi

# Git
if command -v git &>/dev/null; then
  echo "  ✅ Git: $(git --version | sed 's/git version //')"
else
  echo "  ❌ Git: not found"
  echo "     Install: brew install git"
  MISSING=$((MISSING + 1))
fi

# AionUI
if [ -d "/Applications/AionUi.app" ] || command -v aionui &>/dev/null; then
  echo "  ✅ AionUI: installed"
else
  echo "  ⚠️  AionUI: not found (optional but recommended)"
  echo "     Install: brew install aionui"
fi

echo ""
if [ "$MISSING" -gt 0 ]; then
  echo "  $MISSING required tool(s) missing — install them before using the workflow."
  echo ""
fi

# ─── 2. Set up global STRINGZ.md ─────────────────────────

echo "Setting up global context..."
mkdir -p "$CLAUDE_DIR"

if [ -f "$CLAUDE_DIR/STRINGZ.md" ]; then
  echo "  ~/.claude/STRINGZ.md already exists."
  read -rp "  Overwrite with template? (y/N) " OVERWRITE
  if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
    cp "$REPO_DIR/templates/STRINGZ.md.template" "$CLAUDE_DIR/STRINGZ.md"
    echo "  ✅ STRINGZ.md overwritten with template"
  else
    echo "  ⏭️  Keeping existing STRINGZ.md"
  fi
else
  cp "$REPO_DIR/templates/STRINGZ.md.template" "$CLAUDE_DIR/STRINGZ.md"
  echo "  ✅ STRINGZ.md copied to ~/.claude/"
fi
echo "  📝 Edit ~/.claude/STRINGZ.md and fill in YOUR values (name, company, stack)"
echo ""

# ─── 3. Symlink skills ───────────────────────────────────

echo "Linking skills..."
mkdir -p "$CLAUDE_DIR/skills"

SKILLS_LINKED=0
SKILLS_SKIPPED=0

for skill_dir in "$REPO_DIR"/skills/*/; do
  skill_name=$(basename "$skill_dir")
  target="$CLAUDE_DIR/skills/$skill_name"
  if [ -L "$target" ] || [ -d "$target" ]; then
    SKILLS_SKIPPED=$((SKILLS_SKIPPED + 1))
  else
    ln -s "$skill_dir" "$target"
    SKILLS_LINKED=$((SKILLS_LINKED + 1))
  fi
done

echo "  ✅ $SKILLS_LINKED skills linked ($SKILLS_SKIPPED already existed)"
echo ""

# ─── 4. Symlink agents ───────────────────────────────────

echo "Linking agents..."
mkdir -p "$CLAUDE_DIR/agents"

AGENTS_LINKED=0
AGENTS_SKIPPED=0

for agent_file in "$REPO_DIR"/agents/*.md; do
  agent_name=$(basename "$agent_file")
  target="$CLAUDE_DIR/agents/$agent_name"
  if [ -L "$target" ] || [ -f "$target" ]; then
    AGENTS_SKIPPED=$((AGENTS_SKIPPED + 1))
  else
    ln -s "$agent_file" "$target"
    AGENTS_LINKED=$((AGENTS_LINKED + 1))
  fi
done

echo "  ✅ $AGENTS_LINKED agents linked ($AGENTS_SKIPPED already existed)"
echo ""

# ─── 5. Check for hooks blocking .md files ───────────────

echo "Checking for hooks that block .md file creation..."

HOOKS_FOUND=0
PLUGINS_DIR="$HOME/.claude/plugins"

if [ -d "$PLUGINS_DIR" ]; then
  while IFS= read -r hooks_file; do
    if grep -q '\.md' "$hooks_file" 2>/dev/null; then
      HOOKS_FOUND=$((HOOKS_FOUND + 1))
      plugin_name=$(echo "$hooks_file" | sed "s|$PLUGINS_DIR/||" | cut -d/ -f1-2)
      echo ""
      echo "  ⚠️  Found .md blocking hook in: $plugin_name"
      echo ""
      echo "  Stringz Workflow needs to create these .md files:"
      echo "    KNOWLEDGE.md, REVIEW.md, TASKS.md, PREFLIGHT.md, SPEC.md"
      echo ""
      echo "  If the hook's allowlist regex looks like this:"
      echo "    !/(README|CLAUDE|AGENTS|CONTRIBUTING)\\.md\$/.test(p)"
      echo ""
      echo "  Update it to:"
      echo "    !/(README|CLAUDE|AGENTS|CONTRIBUTING|KNOWLEDGE|REVIEW|TASKS|PREFLIGHT|SPEC)\\.md\$/.test(p)"
      echo ""
      echo "  File to edit: $hooks_file"
    fi
  done < <(find "$PLUGINS_DIR" -name "hooks.json" -type f 2>/dev/null)
fi

if [ "$HOOKS_FOUND" -eq 0 ]; then
  echo "  ✅ No blocking hooks detected"
fi
echo ""

# ─── 6. Summary ──────────────────────────────────────────

TOTAL_SKILLS=$(ls -d "$REPO_DIR"/skills/*/ 2>/dev/null | wc -l | tr -d ' ')
TOTAL_AGENTS=$(ls "$REPO_DIR"/agents/*.md 2>/dev/null | wc -l | tr -d ' ')

echo "======================================================"
echo "  ✅ Setup complete!"
echo "======================================================"
echo ""
echo "  Installed:"
echo "  - ~/.claude/STRINGZ.md (edit this with your personal details)"
echo "  - $TOTAL_SKILLS skills linked to ~/.claude/skills/"
echo "  - $TOTAL_AGENTS agents linked to ~/.claude/agents/"
echo ""
echo "  Next steps:"
echo "  1. Edit ~/.claude/STRINGZ.md with your name, company, and stack"
echo "  2. Install any missing prerequisites listed above"
echo "  3. Open Claude Code in any project — the workflow activates automatically"
echo ""
echo "  Usage:"
echo "  - New project:      mkdir my-project && cd my-project && claude"
echo "  - Existing project:  cd my-project && claude"
echo "  - Claude will detect if workflow files are missing and guide you through setup"
echo "  - To update later:  ./update.sh"
echo ""
VERSION=$(grep -o 'version: [0-9.]*' "$REPO_DIR/WORKFLOW.md" 2>/dev/null | grep -o '[0-9.]*' || echo "unknown")
echo "  Framework version: $VERSION"
echo ""
