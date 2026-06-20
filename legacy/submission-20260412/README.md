# Submission bundle — April 12, 2026

Self-contained submission bundle for the manuscript "Regional growth, convergence, and spatial spillovers in India: A reproducible view from outer space".
Target venue: REGION — The Journal of ERSA.

This directory contains a frozen snapshot of all reviewer-facing submission artifacts.
Author identity has been removed from every file in this directory except `CoverLetter.md`, which is addressed to the editor and contains corresponding-author contact information.

## Contents

| File | Size | Purpose |
|---|---|---|
| `CoverLetter.md` | — | Correspondence to the editor (non-blinded). Contains author info; intended only for editorial reading. |
| `manuscript-REGION.pdf` | ~14 MB | Primary submission PDF, typeset with the REGION journal template (A4, author-year citations, line numbers). Blinded. |
| `manuscript.docx` | ~12 MB | Microsoft Word version of the manuscript. Blinded. |
| `manuscript-standalone.html` | ~20 MB | Single-file HTML version with all figures, math, CSS, and MathJax embedded. Opens in any browser without internet. Blinded. |
| `latex-manuscript/` | — | Self-contained LaTeX source tree. A reviewer can recompile the REGION PDF using only the files in this subdirectory. See `latex-manuscript/README.md` for compile instructions. Blinded. |

Bundle summary: 26 files, total ~58 MB. Generated from source commit `c61a87e`.

## What this bundle does not contain

- **Computational notebooks.** The analysis notebooks are not duplicated here because the single-file HTML already embeds their rendered outputs. Reviewers who wish to inspect or re-execute the notebooks can follow the links inside `manuscript-standalone.html`, which point to the public repository from which this bundle was generated.
- **Raw data files.** Nighttime lights rasters and shapefiles are hosted alongside the notebooks at the original repository.
- **Quarto project configuration.** The `_quarto.yml`, `scripts/`, and `_extensions/` files that drive the build are not copied here; only the outputs they produce are.

## Verification performed before this bundle was committed

1. The standalone LaTeX tree was compiled from scratch using `lualatex` and `bibtex`. The resulting PDF matched the page count of `manuscript-REGION.pdf`.
2. A recursive grep over all reviewer-facing files (every file except `CoverLetter.md`) confirmed zero matches for author-identifying strings, grant numbers, author-owned URLs, or institutional affiliations.
3. PDF metadata fields (`/Author`, `/Title`, `/Subject`, `/Keywords`, `/Creator`) on `manuscript-REGION.pdf` were checked and confirmed not to contain identifying information.
