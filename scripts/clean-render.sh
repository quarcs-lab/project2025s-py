#!/usr/bin/env bash
# clean-render.sh — Clear all Quarto caches and re-render the manuscript
#
# Pipeline:
#   1. Clear all Quarto caches and intermediates
#   2. Strip notebook execution metadata
#   3. Render the manuscript website (HTML + notebook previews + assets)
#   4. Re-render the REGION PDF (4 LaTeX passes for natbib/region.bst)
#   5. Re-render the standard PDF and the Word version
#   6. Publish the web outputs to the repository root for GitHub Pages
#   7. Verify that nothing the HTML references is missing
#
# Why output-dir is "_manuscript" and not ".":
#   With output-dir ".", Quarto silently fails to materialize the HTML supporting
#   files. It never creates site_libs/ or index_files/figure-html/, and a
#   single-file render actively deletes site_libs/. The article then renders with
#   no styling and with every embedded notebook figure broken, both locally and on
#   GitHub Pages. Rendering into a separate directory makes Quarto generate all of
#   it correctly, so this script renders there and then publishes to the root,
#   which is where GitHub Pages serves from.
#
# Why the formats are rendered separately:
#   A whole-project "quarto render" crashes in Quarto's manuscript tex bundler
#   ("No such file or directory ... _manuscript/_tex/index.tex") whenever
#   output-dir is not ".". Rendering each format with --to avoids that, and it also
#   gives the REGION PDF the 4 LaTeX passes it needs; a project render gives it 2.
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="_manuscript"

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
rm -rf "$OUT"
rm -f notebooks/*.embed-preview.html
rm -rf notebooks/*.embed_files/
rm -f notebooks/*.out.ipynb

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

echo "  [1/5] Website (HTML article, notebook previews, site_libs, index_files)..."
quarto render --to html

echo "  [2/5] REGION journal PDF (4 passes)..."
quarto render index.qmd --to region-ersa/REGION-pdf
# Quarto writes keep-tex output into a single submission bundle at $OUT/_tex/,
# which the next LaTeX render overwrites. Capture each format's source now.
[ -f "$OUT/_tex/index.tex" ] && cp -f "$OUT/_tex/index.tex" ./index-REGION.tex

echo "  [3/5] Standard PDF..."
quarto render index.qmd --to pdf
[ -f "$OUT/_tex/index.tex" ] && cp -f "$OUT/_tex/index.tex" ./index.tex

echo "  [4/5] Word..."
quarto render index.qmd --to docx

# Publish to the repository root. GitHub Pages serves this repo from the root of
# main, so the web outputs have to live there. The list below is an explicit
# whitelist: it must never include index.qmd, notebooks/*.ipynb or anything else
# that is a source file, because this step overwrites what it copies.
echo "  [5/5] Publishing web outputs to the repository root..."
for f in index.html index-preview.html index.pdf index-REGION.pdf index.docx; do
  [ -f "$OUT/$f" ] && cp -f "$OUT/$f" "./$f"
done
if [ -d "$OUT/site_libs" ]; then
  rm -rf ./site_libs
  cp -R "$OUT/site_libs" ./site_libs
fi
# index_files must MERGE two sources: figure-html comes from the website render,
# figure-latex from the LaTeX submission bundle. The committed index.tex and
# index-REGION.tex reference index_files/figure-latex/, so dropping it would leave
# them uncompilable from the repository root.
rm -rf ./index_files
mkdir -p ./index_files
[ -d "$OUT/index_files" ] && cp -R "$OUT/index_files/." ./index_files/
[ -d "$OUT/_tex/index_files" ] && cp -R "$OUT/_tex/index_files/." ./index_files/
for f in "$OUT"/notebooks/*-preview.html; do
  [ -e "$f" ] && cp -f "$f" "notebooks/$(basename "$f")"
done
for d in "$OUT"/notebooks/*_files; do
  if [ -d "$d" ]; then
    rm -rf "notebooks/$(basename "$d")"
    cp -R "$d" "notebooks/$(basename "$d")"
  fi
done
# Verify that everything the published HTML references is actually present.
# This is what catches a silently broken site before it is committed.
echo "Verifying published output..."
missing=0
while IFS= read -r asset; do
  [ -f "$asset" ] || { echo "  MISSING asset: $asset" >&2; missing=$((missing + 1)); }
done < <(grep -oE '(href|src)="site_libs[^"]*"' index.html | sed 's/.*="//;s/"//' | sort -u)
while IFS= read -r img; do
  [ -f "$img" ] || { echo "  MISSING image: $img" >&2; missing=$((missing + 1)); }
done < <(grep -oE '<img[^>]+src="[^"]+"' index.html | sed 's/.*src="//;s/"//' \
         | grep -vE '^(data:|https?:)' | sort -u)
for tex in index.tex index-REGION.tex; do
  [ -f "$tex" ] || continue
  while IFS= read -r fig; do
    [ -f "$fig" ] || { echo "  MISSING figure for $tex: $fig" >&2; missing=$((missing + 1)); }
  done < <(grep -oE 'index_files/[^}]*\.(png|pdf|jpg)' "$tex" | sort -u)
done
if [ "$missing" -ne 0 ]; then
  echo "ERROR: $missing file(s) referenced by the published outputs are missing." >&2
  exit 1
fi
echo "  All referenced assets, images and figures present."

echo "Done."
