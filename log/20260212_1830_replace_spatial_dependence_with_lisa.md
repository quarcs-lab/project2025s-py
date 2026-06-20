# 2026-02-12 — Replace spatial dependence notebook with Python LISA analysis

## Summary

Replaced the R-based spatial dependence notebook (`c03_spatial_dependence.qmd`) with a new Python Jupyter notebook (`c03_spatial_dependence_lisa.ipynb`) that uses PySAL/ESDA for Local Indicators of Spatial Association (LISA) analysis. Also updated workflow documentation and fixed the embed cache issue from earlier in the session.

## Work completed

### 1. Workflow improvements (earlier in session)

- Changed `freeze: true` to `freeze: auto` in `_quarto.yml`
- Created `scripts/clean-render.sh` to clear all three Quarto cache layers
- Updated README.md and CLAUDE.md to recommend `clean-render.sh` after notebook edits
- Renamed `c02_scatterplots.qmd` to `c02_regional_convergence_sc.qmd` with explanatory text

### 2. New LISA notebook

- Created `notebooks/c03_spatial_dependence_lisa.ipynb` (Python, geo2 environment)
- Analysis includes:
  - Data loading from GeoPackage (`india_2001_520.gpkg`) with district geometries
  - KNN spatial weights (k=6), row-normalized
  - Interactive choropleth map (Folium) of luminosity growth
  - Interactive Moran scatterplots (Plotly) for both variables
  - Global Moran's I: 0.73 (initial luminosity), 0.60 (growth rate), both p=0.001
  - Local Moran's I (LISA) with cluster maps using splot and contextily basemaps
  - Two embedded figures: `fig-dependence-initial` and `fig-dependence-growth`
- Added explanatory markdown cells throughout the notebook

### 3. Notebook replacement

- Removed old `c03_spatial_dependence.qmd` (R-based, used ggscatterstats)
- Removed intermediate `c03b_spatial_dependence_lisa.ipynb`
- Final name: `c03_spatial_dependence_lisa.ipynb`
- Updated all references in `_quarto.yml`, `index.qmd`, `CLAUDE.md`, `README.md`
- Cleared all old caches and re-compiled manuscript

### 4. Manuscript updates

- `index.qmd` updated with new embed shortcodes for LISA figures
- Manuscript text updated for spatial dependence section
- All outputs re-rendered (HTML, PDF, REGION PDF, DOCX, XML)

## Current notebook structure

| Notebook | Title | Language | Embedded |
| --- | --- | --- | --- |
| `c01_view_from_space.qmd` | View from outer space | GEE/JavaScript | No |
| `c02_regional_convergence_sc.qmd` | Regional convergence | R | Yes |
| `c03_spatial_dependence_lisa.ipynb` | Spatial dependence | Python | Yes |
| `c04_spillover_modeling.ipynb` | Econometric models | Stata | No |

## Files modified/created/removed

### Modified
- `_quarto.yml`, `index.qmd`, `CLAUDE.md`, `README.md`
- All manuscript outputs (index.html, index.pdf, index-REGION.pdf, index.docx, index.xml)
- `data/W_matrix.dta`

### Created
- `notebooks/c03_spatial_dependence_lisa.ipynb` — new LISA notebook
- `figures/lisaMAP1.png`, `figures/lisaMAP2.png` — LISA cluster map figures
- `data/W_matrix.csv` — CSV export of weights matrix
- `scripts/clean-render.sh` — cache-clearing render script
- `legacy/Wqueen.dta`, `legacy/project2025s-v20260212.zip` — legacy archive

### Removed
- `notebooks/c03_spatial_dependence.qmd` — old R notebook
- `notebooks/c03b_spatial_dependence_lisa.ipynb` — intermediate version
- Old freeze/embed caches for both removed notebooks

## Current state

- All notebooks compile and embed correctly
- Manuscript renders cleanly in all formats with no warnings
- Project uses `clean-render.sh` as the standard render command after notebook changes
- Python environment: `geo2` (conda, Python 3.10)

## Next steps

- Continue refining manuscript text
- Review and update c04_spillover_modeling notebook if needed
- Submit manuscript to REGION journal
