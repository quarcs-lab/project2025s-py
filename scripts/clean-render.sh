#!/usr/bin/env bash
# clean-render.sh — Clear all Quarto caches and re-render the manuscript
#
# Pipeline:
#   1. Clear all Quarto caches and intermediates
#   2. Full manuscript render (HTML + notebook previews + all formats)
#   3. Re-render REGION PDF (4 LaTeX passes for natbib/region.bst)
#   4. Re-render Standard PDF (restores index.tex as standard LaTeX)
#
# Use this when:
#   - Underlying data files changed but notebook source didn't
#   - Embed previews are stale despite source changes
#   - You want a guaranteed clean build
set -euo pipefail
cd "$(dirname "$0")/.."

# Pin Quarto's Jupyter engine to the project venv (created by `uv sync`).
# Without this, Quarto resolves the kernel named "python3" through the *user*
# kernelspec directory (~/Library/Jupyter/kernels), which on some machines
# points at an unrelated project's interpreter and fails on the first import.
export QUARTO_PYTHON="$PWD/.venv/bin/python"
export JUPYTER_PATH="$PWD/.venv/share/jupyter"
if [ ! -x "$QUARTO_PYTHON" ]; then
  echo "ERROR: $QUARTO_PYTHON not found. Run 'uv sync' first." >&2
  exit 1
fi

echo "Cleaning Quarto caches..."
rm -rf _freeze/
rm -rf .quarto/embed/
rm -rf .quarto/_freeze/
rm -f notebooks/*.embed-preview.html
rm -rf notebooks/*.embed_files/
rm -f notebooks/*.out.ipynb
rm -f notebooks/*-preview.html

echo "Stripping execution metadata from notebooks..."
python3 -c "
import json, glob
for path in glob.glob('notebooks/*.ipynb'):
    with open(path) as f:
        nb = json.load(f)
    changed = False
    for cell in nb['cells']:
        for key in list(cell.get('metadata', {}).keys()):
            if key in ('_sphinx_cell_id', 'execution', 'scrolled'):
                del cell['metadata'][key]
                changed = True
        if cell.get('execution_count') is not None:
            cell['execution_count'] = None
            changed = True
    if changed:
        with open(path, 'w') as f:
            json.dump(nb, f, indent=1)
        print(f'  Stripped: {path}')
"

echo "Rendering manuscript..."

# Step 1: Full manuscript render (generates notebook preview pages + all formats)
# In Quarto manuscript projects, notebook preview HTML pages (the rendered notebooks
# that readers click on) are ONLY generated during a full project render — not when
# using --to flags. This step produces everything but REGION PDF gets only 2 LaTeX
# passes (insufficient for natbib/region.bst), which is fixed in step 2.
echo "  [1/3] Full manuscript render (HTML + notebook previews + all formats)..."
quarto render index.qmd

# Step 2: Re-render REGION PDF with 4 LaTeX passes (fixes natbib/region.bst)
# The full render in step 1 only gives REGION 2 passes, breaking bibliography.
echo "  [2/3] REGION journal PDF (4 passes)..."
quarto render index.qmd --to region-ersa/REGION-pdf
mv index.tex index-REGION.tex

# Step 3: Re-render standard PDF to restore index.tex as standard LaTeX source
# Step 2 overwrote index.tex with REGION LaTeX; this restores it.
echo "  [3/3] Standard PDF (restore LaTeX source)..."
quarto render index.qmd --to pdf

# Step 4: restore the HTML asset directory.
# Quarto references site_libs/ from index.html but never creates it in this project
# (project type "manuscript" with output-dir "."), and a single-file render actively
# deletes it. A missing site_libs/ renders the article completely unstyled, both
# locally and on GitHub Pages. The committed copy in git is the source of truth.
echo "  [4/5] Restoring HTML assets from git..."
if git ls-files --error-unmatch site_libs >/dev/null 2>&1; then
  # Restore from the index, not from HEAD: this works both before and after the
  # assets are first committed. Note that "git restore --source=HEAD" exits 0
  # while restoring nothing when the path is staged but not yet in HEAD.
  git checkout -- site_libs 2>/dev/null || true
  if [ -d site_libs ]; then
    echo "    Restored $(find site_libs -type f | wc -l | tr -d ' ') files."
  else
    echo "    WARNING: could not restore site_libs from git" >&2
  fi
else
  echo "    WARNING: site_libs is not tracked in git; cannot restore it." >&2
fi

# Step 5: verify every asset index.html references is actually present.
# If the HTML theme changes, Quarto emits new hashed filenames and the committed
# assets go stale. Fail loudly rather than shipping a silently broken page.
echo "  [5/5] Verifying HTML assets..."
missing=0
while IFS= read -r asset; do
  if [ ! -f "$asset" ]; then
    echo "    MISSING: $asset" >&2
    missing=$((missing + 1))
  fi
done < <(grep -oE '(href|src)="site_libs[^"]*"' index.html | sed 's/.*="//;s/"//' | sort -u)
if [ "$missing" -ne 0 ]; then
  echo "ERROR: $missing site_libs asset(s) referenced by index.html are missing." >&2
  echo "       The HTML article will render unstyled. Regenerate site_libs/ and commit it." >&2
  exit 1
fi
echo "    All HTML assets present."

echo "Done."
