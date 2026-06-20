# Progress Log: Spillover Modeling Notebook and Table Externalization

**Date:** 2026-02-12 21:00
**Session:** Create c04 spillover modeling notebook, externalize table, rename W matrix

---

## Summary

Created a new Jupyter notebook for the Spatial Durbin Model (SDM) spillover analysis using Stata kernel, externalized the results table to a dedicated `tables/` directory, and renamed the spatial weights matrix variable from legacy `WqueenS_fromStata15` to `W6nn` throughout.

## Work Completed

### 1. Created `notebooks/c04_spillover_modeling_6nn.ipynb`

- Built from `code/c04_spillover_modeling.do` (Stata do-file)
- 21 cells: 7 markdown (explanatory) + 14 code (Stata)
- Uses `stata` kernel (StataSE via `stata_kernel` in conda env `pyStata37`)
- 8-model design: OLS/SDM x unconditional/conditional x no FE/state FE
- 6-nearest-neighbor spatial weights matrix (520 districts, row-normalized)
- `estat impact` for direct/indirect/total spatial effect decomposition
- Programmatic markdown table generation via Stata `file write`

### 2. Archived old notebook

- Moved `notebooks/c04_spillover_modeling.ipynb` to `legacy/notebooks/` (per CLAUDE.md rules)
- Updated `_quarto.yml` line 11: reference changed to `c04_spillover_modeling_6nn.ipynb`

### 3. Externalized results table

- Created `tables/` directory
- Notebook cell 19 writes table to `tables/c04_spillover_modeling_table.md`
- `index.qmd`: replaced hardcoded table (old lines 203-216) with `{{< include tables/c04_spillover_modeling_table.md >}}`
- Added Quarto cross-reference: `{#tbl-models}` caption and `@tbl-models` citation in text
- Updated prose values to match 6NN results:
  - Indirect effect: -0.012* (was -0.009)
  - Total SDM effect: -0.037*** (was -0.034)
  - SDM total 48% larger than OLS (was 36%)

### 4. Renamed W matrix variable

- Global replace: `WqueenS_fromStata15` -> `W6nn` in both notebook (15 occurrences) and do-file (14 occurrences)
- Safe rename: variable is created and used within single Stata session (no external data files reference it)

### 5. Verified all outputs

- Re-ran notebook with Stata kernel (all cells execute without error)
- Recompiled paper: all 5 formats generated successfully (HTML, PDF, REGION-PDF, DOCX, XML)

## Key Results (Model 4 SDM: conditional + state FE)

| Effect   | Coefficient | SE      |
|----------|-------------|---------|
| Direct   | -0.025***   | (0.002) |
| Indirect | -0.012*     | (0.007) |
| Total    | -0.037***   | (0.007) |

AIC: -2499 (best fit among all 8 models)

## Files Changed

| File | Action |
|------|--------|
| `notebooks/c04_spillover_modeling_6nn.ipynb` | Created |
| `code/c04_spillover_modeling.do` | New (extracted + updated) |
| `code/c04_spillover_modeling.log` | New (Stata execution log) |
| `tables/c04_spillover_modeling_table.md` | New (generated table) |
| `legacy/notebooks/c04_spillover_modeling.ipynb` | Archived |
| `_quarto.yml` | Updated notebook reference |
| `index.qmd` | Table include + prose updates |
| All output files | Recompiled |

## Technical Notes

- Stata kernel config: `~/.stata_kernel.conf` points to StataSE (not StataMP)
- jupyter-nbconvert path: `/Users/carlos/Library/Python/3.9/bin/jupyter-nbconvert`
- Quarto path: `/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto` (v1.5.57)

## Next Steps

- Review rendered outputs visually (PDF, HTML) to confirm table and cross-references
- Continue refining manuscript text
- Consider embedding additional figures from the spillover notebook
