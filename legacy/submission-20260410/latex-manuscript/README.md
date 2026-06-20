# Standalone LaTeX source

This directory contains a self-contained LaTeX source tree for the manuscript "Regional growth, convergence, and spatial spillovers in India: A reproducible view from outer space".
Everything needed to recompile the REGION journal PDF is present in this folder.
No files from outside this directory are required at compile time.

## Contents

| File / directory | Purpose |
|---|---|
| `manuscript.tex` | Main LaTeX source. |
| `references.bib` | BibTeX bibliography. |
| `regart.cls` | REGION journal document class. |
| `region.sty` | REGION journal style package. |
| `region.bst` | REGION bibliography style. Renamed from `REGION.bst` to match `\bibliographystyle{region}` on case-sensitive filesystems. |
| `titlepage_21.pdf`, `titlepage_22.pdf` | Title page graphics referenced by `regart.cls`. Renamed from uppercase `Titlepage_*.pdf` for case-sensitive filesystems. |
| `ERSA_logo.png`, `wutext.pdf`, `fwf.pdf` | Publisher, university, and funder logos referenced by `regart.cls`. |
| `figures/` | All figures included in the manuscript body. |

## How to compile

Requires a TeX Live Full distribution (or equivalent) with these packages installed: `parnotes`, `lineno`, `fancyhdr`, `draftwatermark`, `natbib`, `hyperref`, `multirow`, `longtable`, `booktabs`, `graphicx`, `amsmath`, `amssymb`, `lmodern`.
All of these ship with TeX Live Full.

From inside this directory, run:

    lualatex manuscript.tex
    bibtex manuscript
    lualatex manuscript.tex
    lualatex manuscript.tex
    lualatex manuscript.tex

The REGION template requires four `lualatex` passes (not the usual three) because the format uses line numbers and marginal cross-references that take an extra pass to stabilize.
The output is `manuscript.pdf`.

`pdflatex` also works if you prefer it over `lualatex`; the preamble detects the engine automatically.

## Troubleshooting

- **Missing package errors**: install TeX Live Full, or `tlmgr install <package>` for the specific missing package.
- **Missing figure errors**: confirm the `figures/` directory is present and contains every image referenced in `manuscript.tex`. The paths are relative; do not rename the directory.
- **Missing `regart.cls`**: the document class begins with `\documentclass[...]{article}` and then loads `regart` via `\usepackage{region,...}`. Both `regart.cls` and `region.sty` must be present in the same directory as `manuscript.tex`.
- **Bibliography style errors**: confirm `region.bst` (lowercase) is present.

## Provenance

This tree is a frozen snapshot of the source manuscript at the point of submission.
The figures were produced by computational notebooks that accompany the manuscript in its original repository, and then embedded into the Quarto manuscript via `{{< embed >}}` shortcodes.
This standalone tree contains only the pre-rendered images.
