# Session Log: Spatial Culture Notebook — Name Harmonization & 32-Region Map

**Date:** 2026-04-07
**Session focus:** Created c05_spatial_culture notebook with region name harmonization, dissolved 36-region map to 32-region map, and produced choropleth maps of cultural participation variables.

---

## Work Completed

### 1. Region Name Compatibility Analysis

Compared region names between `data/Cultural_Data_India/Final_state_LC_CH.dta` (32 states, NSS 47th Round 1991-92) and `data/maps/india36.geojson` (36 regions, ~2014-2019 boundaries). Identified and verified via web research:

- **9 name mismatches** requiring mapping (abbreviations, `&` vs `and`, old/new names, typos)
- **4 GeoJSON-only regions** (Chhattisgarh, Jharkhand, Uttarakhand, Telangana) — states carved out after the survey period

Key mappings:
| Stata | GeoJSON | Issue |
|-------|---------|-------|
| A & N Islands | Andaman and Nicobar Islands | Abbreviation |
| Chandigarh | Chandigarth | Typo in GeoJSON |
| Lakshdweep | Lakshadweep | Typo in Stata |
| Orissa | Odisha | Renamed 2011 |
| Pondicherry | Puducherry | Renamed 2006 |
| Delhi | NCT of Delhi | Short vs official |
| 3 others | `&` vs `and` variants | Formatting |

### 2. Created 32-Region Dissolved Map

Dissolved 4 newer states back into their parent states using `geopandas.dissolve()`:
- Chhattisgarh → Madhya Pradesh (2000)
- Jharkhand → Bihar (2000)
- Uttarakhand → Uttar Pradesh (2000)
- Telangana → Andhra Pradesh (2014)

Result: `data/maps/india32.geojson` — 32 regions matching Stata data exactly.

### 3. Merged Data & Choropleth Maps

- Perfect 32/32 merge with zero NaN values
- Generated 6 choropleth maps (LC_Performance, LC_Telecast, SC, CH_relig, LC_shows, Sports)
- Side-by-side boundary comparison of 36-region vs 32-region maps

---

## Current State

- `notebooks/c05_spatial_culture.md` and `.ipynb` created and fully executed
- `data/maps/india32.geojson` generated (32-region dissolved map)
- All cells run without errors; all merges verified

## Decisions Made

- Harmonized names to Stata conventions (including preserving Stata typo "Lakshdweep" for merge consistency)
- Dissolved newer states into parent states rather than leaving them as NaN — provides a complete map for analysis

## Issues / Blockers

- None

## Next Steps

- Full ESDA analysis: spatial weights matrix, Global Moran's I, LISA cluster maps
- Register notebook in `_quarto.yml` under `manuscript.notebooks` if embedding figures in manuscript
- Consider whether to add embed shortcodes in `index.qmd`
