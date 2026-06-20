# Session Log — 2026-02-13 16:00

## Summary

Diagnosed and fixed notebook display problems caused by stale Quarto intermediate files (`.out.ipynb` and `*-preview.html`). Added prevention measures and verified clean rebuild of all manuscript formats.

## Problem

All 4 notebooks had display problems — the latest `.ipynb` content was not being generated in the `.out.ipynb` and `*-preview.html` files. Quarto reused stale intermediates instead of processing the current source notebooks.

**Root cause:** `scripts/clean-render.sh` cleaned `_freeze/`, `.quarto/embed/`, and `*.embed-preview.html`, but did NOT clean two types of Quarto intermediate files:

1. `*.out.ipynb` — Quarto's executed notebook outputs (stale copies had no `#| label:` directives, causing embed failures)
2. `*-preview.html` — notebook preview HTML pages

**Evidence:**
- Source `c03.ipynb`: 33 cells, labels at cells 14, 23, 31
- Stale `c03.out.ipynb`: 26 cells, zero `#| label:` directives (from older notebook version)
- Source `c02.ipynb`: has `#| label: fig-convergence` but no `.out.ipynb` existed at all

## Fix Applied

### 1. Updated `scripts/clean-render.sh` (lines 29-30)

Added two cleanup lines:
```bash
rm -f notebooks/*.out.ipynb
rm -f notebooks/*-preview.html
```

### 2. Added to `.gitignore`

```gitignore
notebooks/*.out.ipynb
notebooks/*-preview.html
```

Prevents stale intermediates from ever being committed to git.

### 3. Updated `CLAUDE.md` cache documentation

Expanded from 3 to 5 documented cache layers:
1. `_freeze/` — execution results
2. `.quarto/embed/` — internal embed cache
3. `notebooks/*.embed-preview.html` — embed preview artifacts
4. `notebooks/*.out.ipynb` — executed notebook outputs (NEW)
5. `notebooks/*-preview.html` — preview HTML pages (NEW)

## Verification

| Check | Result |
|-------|--------|
| REGION PDF | 13 MB, A4 (842 x 595), article, 4 lualatex passes, region.bst |
| Standard PDF | 13 MB, Letter (792 x 612), scrartcl, 2 lualatex passes |
| HTML | 401 KB, all 4 figures embedded |
| DOCX | 10 MB |
| JATS XML | 217 KB, 4 notebook sub-articles |
| MECA bundle | 100 MB, uploaded to GitHub Release |
| BibTeX warnings | 0 |
| fig-convergence | Embedded in both PDFs |
| fig-Wmatrix6nn | Embedded in both PDFs |
| fig-dependence-initial | Embedded in both PDFs |
| fig-dependence-growth | Embedded in both PDFs |

## Files Modified

| File | Change |
|------|--------|
| `scripts/clean-render.sh` | Added cleanup of `*.out.ipynb` and `*-preview.html` |
| `.gitignore` | Added `notebooks/*.out.ipynb` and `notebooks/*-preview.html` |
| `CLAUDE.md` | Documented 5 cache layers (was 3) |

## Key Discovery

Quarto's `.out.ipynb` files are intermediate executed notebooks. When they exist and are stale (from an older notebook version), Quarto may reuse them instead of reprocessing the current `.ipynb` source. The `clean-render.sh` script must clean these files to guarantee a fresh build.
