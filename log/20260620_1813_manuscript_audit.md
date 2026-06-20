# Final Pre-Submission Audit — Manuscript & Results

**Date:** 2026-06-20 18:13
**Manuscript:** `index.qmd` (REGION journal format) + notebooks c01–c06
**Method:** Exhaustive multi-agent audit (4 dimension auditors → independent adversarial verification of every finding → Python-vs-original consistency comparison). 25 agents; **20 raw findings → 16 confirmed, 4 rejected** as false positives.
**Scope:** results integrity · methodological soundness · reproducibility & build · references & writing.

---

## Executive summary

The manuscript is in **strong, submission-ready shape**: all quantitative claims match the computed
outputs, the build is reproducible, all embeds resolve, and the bibliography is essentially complete.
**No critical issues.** One **major** item (the "speed of convergence" wording is an overclaim that is
never actually computed) and a set of minor/nit polish items are worth addressing before submission.
The Python results are **largely consistent** with the original R/Stata `project2025s` (see §Provenance).

---

## Confirmed findings (severity-ranked)

### MAJOR

1. **"Speed of convergence" is asserted but never computed** — `index.qmd:14, 67, 70, 405, 522`.
   The abstract/intro/conclusion say spillovers "increase the estimated **speed**" / "**accelerate**"
   convergence, but no notebook converts a β coefficient into a convergence speed (`-ln(1+T·b)/T`) or
   half-life. The only quantification (48% / 64%) is a ratio of **total-effect coefficients**, not a speed.
   **Fix:** either (a) compute and report the implied speed/half-life, or (b) soften "speed/acceleration"
   to "the **magnitude of the total convergence effect**" throughout. *(Scientific wording — your call.)*

### MINOR

2. **README "~36%" contradicts the manuscript (48% / 64%)** — `README.md:71`. "~36%" appears nowhere in
   `index.qmd` and matches no Table 1 quantity (the only "36" in results is the Model 4 AIC drop of 36).
   **Fix:** change README to "~48% larger in the preferred Model 4 (up to 64% in Model 3)."
3. **Indirect/spillover effect is significant only at the 10% level** — `index.qmd:399, 400`. Text calls
   it "statistically significant"; the stars are `*` (p<0.10). **Fix:** say "significant at the 10% level."
4. **Monte-Carlo SEs in Table 1 are reproducible only under strict top-to-bottom execution** —
   `notebooks/c04_spillover_modeling_6nn.md:75, 228`. Seed is set once, far from the estimation loop.
   **Fix:** re-seed immediately before the model loop (as the robustness cell already does).
5. **Kernel `project2025s` lives in the global Jupyter dir, not the uv venv** — c01/c02/c04/c06 metadata.
   A clean clone would fail to re-execute these (the venv ships a `python3` kernel; c03/c05 already use it).
   **Fix:** re-pin all six notebooks to the venv `python3` kernel, then re-render.
6. **`c05_spatial_culture.ipynb` is unregistered, stale, and superseded by c06** — `_quarto.yml`.
   **Fix:** leave a header note that c06 supersedes it, or archive it (do not delete, per CLAUDE.md).
7. **`glawe_mendez_china_luminosity` missing volume/pages** — `references.bib` (cited `index.qmd:480`).
   **Fix:** add `volume = {57}`, `pages = {10677--10693}` (DOI already present; verify issue number on the
   publisher page before adding it).
8. **`chakravarty_dehejia_gst` missing pages** — `references.bib` (cited `index.qmd:104`).
   **Fix:** add `pages = {97--102}` (EPW has no DOI; the `url` is the correct locator). Then complete.
9. **`SDM` acronym used before definition** — first at `index.qmd:404`. **Fix:** expand "spatial Durbin
   model (SDM)" at first substantive use (~line 251/278), then use SDM consistently.

### NIT
10. **M4 "preferred" vs M3's larger 64% gap** — `index.qmd:402–404`. Keep AIC-based preference for M4;
    avoid implying M3's larger gap strengthens the case (M3/M4 spillovers are statistically indistinguishable).
11. **`OLS` not expanded at first estimator use** — `index.qmd:383` (collides with the DMSP/OLS sensor name).
12. **Inconsistent `DMSP/OLS` vs `DMSP-OLS`** — `index.qmd:109` (DMSP/OLS) vs 7× `DMSP-OLS` elsewhere → standardize.
13. **"rate of approximately 2%"** — `index.qmd:315`. Call it "a β-convergence coefficient of about −0.02," or compute the annual speed.
14. **"spatial autoregressive parameter … around 0.8 in Model 1" not traceable** — `index.qmd:392`. Surface ρ in Table 1 notes, or soften to "large."
15. **Mild echoed/boilerplate phrasing** — `index.qmd:76, 515, 538` ("transparent, verifiable, and …" repeated).

## Rejected by adversarial verification (not real issues)
- Impact-decomposition method is described correctly and consistently with the code.
- Model 1 positive-indirect handling is already defensible as written.
- Cross-format "mismatches" were `pdftotext` layout artifacts — numbers are identical across HTML/PDF/REGION/DOCX.
- The reworked Model-1 paragraph is acceptable as-is.

---

## Reproducibility & build (clean)
- All 8 `{{< embed >}}` / `{{< include >}}` targets resolve (label is first line of the cell).
- No stale `_freeze`; `notebooks/*.out.ipynb` are gitignored; no leftover execution metadata.
- Key numbers (Table 1, Moran's I, 48%/64%) are **identical across HTML, PDF, REGION-PDF, DOCX**.
- (See finding #5 re: kernel portability — the one real reproducibility nit.)

---

## Provenance & consistency with the original R/Stata `project2025s`

This manuscript is the **Python reproduction** of the original `project2025s`, whose computational
notebooks were written in **R** (c02, regional convergence) and **Stata** (c04, spillover modeling);
c01/c03/c05/c06 were already Python and the Google Earth Engine app remains JavaScript. The Python
results are **largely consistent** with the original notebooks:

| Quantity | Python | Original (R/Stata) | Verdict |
|---|---|---|---|
| c02 β-convergence slope | −0.0199 | −0.019881 | **match** |
| c02 R² | 0.255 | 0.2547 | **match** |
| c04 M1 SDM Direct / Indirect / Total | −0.026 / **+0.004** / −0.022 | −0.021 / **−0.001** / −0.022 | **differs** (Direct/Indirect); Total matches |
| c04 M1 AIC (OLS/SDM) | −1945 / −2292 | −1945 / −2290 | close |
| c04 M2 SDM D/I/T | −0.021 / −0.001 / −0.022 | −0.021 / −0.001 / −0.022 | **match** |
| c04 M3 SDM D/I/T | −0.026 / −0.015 / −0.041 | −0.026 / −0.015 / −0.041 | **match** |
| c04 M4 SDM D/I/T | −0.025 / −0.013 / −0.037 | −0.025 / −0.012 / −0.037 | close |
| c04 AIC (M2/M3/M4) | within a few points | Stata table | close |

**The single caveat is Model 1 (unconditional SDM):** with a high spatial autoregressive parameter
(ρ ≈ 0.80), the Python full LeSage–Pace decomposition splits the multiplier matrix `(I−ρW)⁻¹`
differently from Stata's `estat impact`, shifting Direct (−0.026 vs −0.021) and flipping the sign of the
(insignificant) Indirect effect (+0.004 vs −0.001). The **Total impact (−0.022) is identical**, because
the total is invariant to the multiplier method (ATI = 1/(1−ρ)). All other models, the OLS columns, c02,
and c03 reproduce the originals to the reported precision; small AIC differences (≤4) reflect the
`pysal/spreg` ML estimator vs Stata `spregress`.

**Acknowledgment:** This is the Python edition of the original `project2025s` (R + Stata). The Python
pipeline reproduces the original results, with the one caveat above (Model 1's unconditional spatial
impact split); all substantive conclusions are unchanged.

---

## Recommended fix plan (pending approval)
- **A. Safe doc/metadata fixes:** README 36%→48/64% (#2); complete the 2 bib entries (#7, #8); kernel
  re-pin for portability (#5); c05 header note (#6).
- **B. Prose precision:** 10%-significance wording (#3); define SDM/OLS (#9, #11); DMSP-OLS (#12); "2%" /
  ρ wording (#13, #14); trim echoed phrasing (#15); M3/M4 framing (#10).
- **C. Scientific wording (your decision):** the "speed of convergence" overclaim (#1) — soften vs compute speed/half-life.
- **D. Reproducibility hardening:** re-seed Monte-Carlo before the c04 loop (#4).
- **E. Acknowledgment:** add a blind-safe reproducibility sentence to `index.qmd`.
Any code/notebook/prose change is followed by `bash scripts/clean-render.sh` + re-verification.

---

## Fixes applied (approved: A, B, D, E + compute-speed)

- **Speed/half-life computed (was the major overclaim):** added a Barro–Sala-i-Martin
  `λ = −ln(1+βT)/T` (T=14) + half-life computation to **c02** (β=−0.0199 → **2.3%/yr, ~30 yr**) and a
  per-model OLS-vs-SDM speed table `tbl-speed` to **c04** (Model 4: OLS **3.0%** → SDM **5.2%**, half-life
  **23 → 13 yr**; Model 3 SDM **6.2%**). Manuscript "speed of convergence" language is now substantiated;
  `index.qmd` updated at the c02 (~315) and spillover (~403) discussions.
- **Prose precision (B):** indirect effects now stated as significant **at the 10% level**;
  defined **OLS** and **SDM** at first use; standardized **DMSP-OLS**; tempered the M3/M4 framing
  (estimates statistically indistinguishable → anchor on M4); trimmed echoed boilerplate; removed
  remaining "R" notebook references.
- **Doc/metadata (A):** README "~36%" → "~3%→~5% speed; ~48% (up to 64%) larger total effect";
  completed `references.bib` (`chakravarty_dehejia_gst` pages 97–102; `glawe_mendez_china_luminosity`
  vol 57, pages 10677–10693); added a supersession note to c05.
- **Reproducibility (D):** re-seeded the Monte-Carlo before the c04 model loop; **re-pinned all six
  notebooks to the venv `python3` kernel** (portable on a fresh clone); print ρ per model (Model 1 ≈ 0.80,
  making the "around 0.8" claim traceable).
- **Acknowledgment (E):** added a blind-safe reproducibility sentence to `index.qmd`'s Data and Code
  Availability appendix (Python reproduction of an earlier R/Stata implementation; results largely
  consistent; sole caveat = Model 1's unconditional SDM impact split).

Re-rendered (`clean-render.sh`, exit 0); all four formats rebuilt; speed numbers, acknowledgment, OLS/SDM
definitions, and 10%-level wording confirmed in `index.html`/`index.pdf`; Table 1 unchanged; c02 speed and
c04 `tbl-speed` confirmed on the notebook preview pages.
