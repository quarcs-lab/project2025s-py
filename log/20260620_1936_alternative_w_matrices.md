# Session Log — 2026-06-20 19:36

## Goal
Add a new notebook re-evaluating the preferred **Model 4** (conditional SDM + state FE) under
**alternative spatial weight matrices**, as a robustness check, and embed it in the manuscript.

## Work done

### New notebook: `notebooks/c07_alternative_w_matrices.ipynb` (N5)
Python (paired `.md`, `python3` kernel). Re-estimates Model 4 as an SDM (full LeSage–Pace impacts,
Monte-Carlo SEs, seed 20250620) under seven row-standardized weight matrices:
- **4NN, 6NN (baseline), 8NN** — k-nearest neighbors on lat/lon centroids (same basis as the main table,
  so the 6NN row reproduces Table 1 Model 4 exactly).
- **Queen, Rook contiguity** — islands attached to their nearest neighbor (Queen had 1, Rook 2).
- **Inverse distance, inverse distance²** — applied within a **distance band** (smallest threshold with
  no isolated district), centroid distances in a metric projection (EPSG:7755), per the user's choice.
- Outputs: `tbl-altw` (Direct/Indirect/Total + AIC, MC SEs + stars) and `fig-altw` (forest plot of the
  three impacts with 95% CIs across the seven matrices, vs the 6NN baseline).

### Why the distance band (decision)
The first build used dense all-pairs inverse distance (1/d): every row of W → a global average, making
the spatial-lag/SLX terms near-collinear → unstable Total impact (−0.150, SE ≈ 2.9). On the user's
instruction, both inverse-distance variants were switched to a **distance band**, which is sparse
(~14 mean neighbours) and stable (ρ ≈ −0.002 for 1/d, 0.157 for 1/d²).

### Result — robust across all weight matrices
| W matrix | Direct | Indirect | Total | AIC |
|--|--|--|--|--|
| 4NN | −0.024*** | −0.008 | −0.032*** | −2468 |
| 6NN (baseline) | −0.025*** | −0.013* | −0.037*** | −2501 |
| 8NN | −0.025*** | −0.011 | −0.036*** | −2485 |
| Queen | −0.025*** | −0.010** | −0.035*** | −2463 |
| Rook | −0.025*** | −0.009** | −0.034*** | −2469 |
| Inverse distance (banded) | −0.025*** | −0.016** | −0.041*** | −2486 |
| Inverse distance² (banded) | −0.025*** | −0.012* | −0.037*** | −2485 |

Direct effect essentially constant (−0.024 to −0.026, all ***); Total negative and significant
throughout (−0.032 to −0.041); indirect negative everywhere and significant in 5 of 7. The 6NN
baseline reproduces Table 1 Model 4 exactly. Conclusion: the spillover evidence is not an artifact of
the neighbor definition.

### Manuscript integration
- `_quarto.yml`: registered c07 as **N5**; bumped Spatial culture (c06) to N6.
- `index.qmd`: new subsection **"Robustness to alternative spatial weight matrices"** in the spillover
  results, embedding `fig-altw` and `tbl-altw` with interpretation (`@fig-altw`, `@tbl-altw`).
- `CLAUDE.md`: added c07 to the notebook table and the embeds list; corrected c05's pairing row.

## Verification
- c07 executes cleanly (exit 0, no error cells); 6NN row == Table 1 Model 4.
- `bash scripts/clean-render.sh` exit 0; all four formats rebuilt; `fig-altw`/`tbl-altw` resolve in
  `index.html` and `index.pdf` (no embed errors); c07 preview page generated.

## Note for the author
Both inverse-distance variants use a distance band (not all-pairs) because the dense all-pairs 1/d
matrix is statistically unstable here; if you prefer the literal all-pairs form for 1/d², it can be
restored (it was well-behaved on its own), but the banded version keeps the two inverse-distance rows
consistent.
