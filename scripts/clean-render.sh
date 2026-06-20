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

echo "Done."
