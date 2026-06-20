---
jupytext:
  formats: ipynb,md:myst
  text_representation:
    extension: .md
    format_name: myst
    format_version: 0.13
    jupytext_version: 1.19.1
kernelspec:
  display_name: Project 2025s (Python 3.10)
  language: python
  name: project2025s
---

<a href="https://colab.research.google.com/github/quarcs-lab/project2025s/blob/master/notebooks/c04_spillover_modeling_6nn.ipynb"><img src="https://colab.research.google.com/assets/colab-badge.svg" alt="Open In Colab" /></a>

+++

This notebook estimates **8 econometric models** to analyze convergence in nighttime light intensity across 520 Indian districts (1996–2010). It compares standard OLS regressions with **Spatial Durbin Models (SDM)** that account for spatial spillovers between neighboring districts. The models follow a 2×2×2 design: OLS vs SDM, unconditional vs conditional, without vs with state fixed effects. Results are presented as four model columns, each estimated by OLS and by SDM. For details on the model design and spatial weights, see the Background & Context section below.

+++

## Running the analysis in Python

This notebook runs on the `project2025s` Python kernel managed by [uv](https://docs.astral.sh/uv/). The spatial econometrics rely on the open-source [PySAL](https://pysal.org/) ecosystem:

- **`geopandas`** — reads the district geometries (`india520.geojson`) used to build the spatial weights.
- **`libpysal`** — constructs the row-standardized 6-nearest-neighbor (6NN) spatial weights matrix from district centroids.
- **`spreg`** — estimates the Spatial Durbin Model via `ML_Lag(slx_lags=1)`, the maximum-likelihood spatial-lag model augmented with spatially lagged regressors (SLX). This is the Python analogue of Stata's `spregress y x, ml dvarlag(W) ivarlag(W: x)`.
- **`statsmodels`** — estimates the OLS benchmarks with heteroskedasticity-robust (HC1) standard errors, equivalent to Stata's `regress ..., robust`.

All dependencies are declared in `pyproject.toml`; run `uv sync` to install them. On Google Colab, the install cell below pulls the spatial packages into the default environment.

```{code-cell} ipython3
# Google Colab: install packages not included in the default environment
try:
    import google.colab
    !pip install geopandas libpysal spreg -q
except ImportError:
    pass  # Local environment — packages already installed
```

## 1. Background & Context

- **Research question:** Does nighttime light growth (a proxy for economic activity) converge across Indian districts, and do neighboring districts generate spatial spillovers?
- **Dependent variable:** `light_growth96_10rcr_cap` — growth in per-capita nighttime light intensity (1996--2010).
- **Key regressor:** `log_light96_rcr_cap` — log of initial (1996) per-capita light intensity. A negative coefficient indicates **convergence** (initially brighter districts grow more slowly).
- **Controls:** 16 variables capturing terrain, climate, demographics, infrastructure, and human capital.
- **Spatial weights:** `W6nn` — a row-standardized 6-nearest-neighbor matrix recomputed from district centroids (`india520.geojson`).

**Theoretical framework.** The Spatial Durbin Model (SDM) lets both the dependent variable and the explanatory variables have spatial lags (i.e., influence from neighbors). For the key regressor it follows Ertur & Koch (2007, eq. 7 of the paper):

$$g_t = \beta_1 x_{t-1} + X_t \alpha + \beta_2 W x_{t-1} + W X_t \gamma + \lambda\, W g_t + \varepsilon.$$

## 2. Setup

We load the district variables (`india520.dta`) and geometries (`india520.geojson`), build the 6NN row-standardized spatial weights, and prepare the state fixed-effect dummies.

```{code-cell} ipython3
# Configuration
import os
import math
import warnings
import urllib.request
from contextlib import redirect_stdout

import numpy as np
import pandas as pd
import geopandas as gpd
import statsmodels.api as sm
from libpysal.weights import KNN
from spreg import ML_Lag

warnings.filterwarnings("ignore")
np.random.seed(20250620)

DV   = "light_growth96_10rcr_cap"   # dependent variable: per-capita NTL growth 1996-2010
XKEY = "log_light96_rcr_cap"        # main regressor: initial (log) per-capita NTL, 1996
KEY  = "statedist"                  # 1:1 merge key between geometry and data
K_NN = 6                            # 6 nearest neighbours
N_MC = 10_000                       # Monte-Carlo draws for impact inference

# 16 conditional controls (geo-climatic + demographic + infrastructure)
CONTROLS = [
    "suit_mean_snd", "rain_mean_snd", "mala_mean_snd", "temp_mean_snd",
    "rug_mean_snd", "distance", "latitude", "rur_percent96_rcr",
    "log_tot_density_rcr", "sc_percent96", "st_percent96", "workp_percent96",
    "lit_percent96", "higheredu_percent96", "elechh_percent96", "log_puccaroads",
]

RAW = "https://raw.githubusercontent.com/quarcs-lab/project2025s/master/data"
```

```{code-cell} ipython3
# Load data (local ../data first, else download from the public repo)
def _resolve(fname):
    for cand in (os.path.join("..", "data", fname), os.path.join("data", fname), fname):
        if os.path.exists(cand):
            return cand
    url = "{}/{}".format(RAW, fname)
    print("Downloading {} from {}".format(fname, url))
    urllib.request.urlretrieve(url, fname)
    return fname


def load_data():
    gdf = gpd.read_file(_resolve("india520.geojson"))
    dta = pd.read_stata(_resolve("india520.dta"))
    keep = [KEY, DV, XKEY, "state"] + CONTROLS
    merged = gdf[[KEY, "geometry"]].merge(dta[keep], on=KEY)
    merged = gpd.GeoDataFrame(merged, geometry="geometry", crs=gdf.crs)
    assert len(merged) == 520, "expected 520 districts, got {}".format(len(merged))
    return merged


m = load_data()
y = m[[DV]].values

# 6-nearest-neighbour weights from centroids, row-standardised
w = KNN.from_dataframe(m, k=K_NN)
w.transform = "r"
Wd = w.full()[0]

# Spatial-multiplier ingredients reused by the impact computations
EIGS_W = np.linalg.eigvals(Wd)          # eigenvalues of W (for the 'full' method)
N_W = Wd.shape[0]
_P_POW = 30                             # truncation order for the 'power' series
TR_WP = np.array([np.trace(np.linalg.matrix_power(Wd, p)) for p in range(1, _P_POW + 1)])

# State fixed-effect dummies
fe = pd.get_dummies(m["state"], prefix="st", drop_first=True).astype(float)

print("Districts: {} | neighbours: {} | weights: row-standardised".format(len(m), K_NN))
```

```{code-cell} ipython3
# Estimation helpers
def stars(est, se):
    if se <= 0 or not np.isfinite(se):
        return ""
    z = abs(est / se)
    p = 2 * (1 - 0.5 * (1 + math.erf(z / math.sqrt(2))))
    return "***" if p < 0.01 else "**" if p < 0.05 else "*" if p < 0.10 else ""


def _adi(method, rho):
    """Average direct-impact multiplier at spatial parameter(s) rho (scalar or
    array). 'simple' = 1.0; 'full' = mean of diag((I - rho W)^-1) via the
    eigenvalues of W; 'power' = truncated series 1 + sum_p rho^p tr(W^p)/n.
    """
    rho = np.atleast_1d(np.asarray(rho, dtype=float))
    if method == "simple":
        return np.ones_like(rho)
    if method == "full":
        return (1.0 / (1.0 - np.outer(rho, EIGS_W))).real.mean(axis=1)
    if method == "power":
        powers = rho[:, None] ** np.arange(1, _P_POW + 1)
        return 1.0 + (powers * TR_WP).sum(axis=1) / N_W
    raise ValueError("unknown impact method: {}".format(method))


def full_rank_lag_mask(Xv, Wd):
    """Boolean mask over X columns indicating which to spatially lag.

    Greedily keeps only those W*X columns that add rank to [1, X, W*X],
    dropping redundant spatial lags. This reproduces Stata's automatic
    omission of collinear lagged terms (e.g. the lag of a small-state FE
    dummy whose neighbour structure makes its spatial lag collinear).
    """
    n, k = Xv.shape
    WX = Wd @ Xv
    design = np.hstack([np.ones((n, 1)), Xv])      # constant + X always kept
    rank = np.linalg.matrix_rank(design)
    mask = [True] * k
    for j in range(k):
        test = np.hstack([design, WX[:, [j]]])
        if np.linalg.matrix_rank(test) > rank:
            design, rank = test, rank + 1
        else:
            mask[j] = False                         # redundant lag -> do not lag
    return mask


def run_ols(y, Xdf):
    """OLS with heteroskedasticity-robust (HC1 = Stata 'robust') errors."""
    XX = sm.add_constant(Xdf.astype(float))
    res = sm.OLS(y.ravel(), XX).fit(cov_type="HC1")
    return {
        "direct": res.params[XKEY], "direct_se": res.bse[XKEY],
        "indirect": None, "indirect_se": None,
        "total": res.params[XKEY], "total_se": res.bse[XKEY],
        "aic": res.aic,
    }


def run_sdm(y, Xdf, w, Wd):
    """Spatial Durbin Model via ML_Lag(slx_lags=1); impacts use the 'full'
    (LeSage-Pace) method based on the exact spatial multiplier matrix
    (I - rho W)^-1 -- the same decomposition Stata's `estat impact` reports.

    For the key regressor with own coefficient b, spatial-lag coefficient g,
    spatial parameter rho, and average direct-impact multiplier adi:
        Direct   = adi * b
        Total    = (b + g) / (1 - rho)
        Indirect = Total - Direct
    Because the weights are row-standardised the Total impact is invariant to
    the multiplier method (ati = 1 / (1 - rho)); only the Direct/Indirect split
    depends on adi. Inference is obtained by Monte-Carlo simulation from the ML
    parameter covariance matrix, with adi recomputed for each rho draw.
    """
    Xv = Xdf.astype(float).values
    mask = full_rank_lag_mask(Xv, Wd)
    slx_vars = "All" if all(mask) else mask
    with redirect_stdout(open(os.devnull, "w")):
        mod = ML_Lag(y=y, x=Xv, w=w, slx_lags=1, slx_vars=slx_vars,
                     spat_impacts="full")

    b = mod.betas.flatten()
    k = Xv.shape[1]
    i_b = 1                       # const at 0; XKEY is first X column -> index 1
    i_g = 1 + k                   # first W*X column (XKEY is always lagged)
    i_r = len(b) - 1              # rho is last
    rho = b[i_r]
    direct = _adi("full", rho)[0] * b[i_b]
    total = (b[i_b] + b[i_g]) / (1 - rho)
    indirect = total - direct

    draws = np.random.multivariate_normal(b, mod.vm, size=N_MC)
    D, G, R = draws[:, i_b], draws[:, i_g], draws[:, i_r]
    Deff = _adi("full", R) * D
    T = (D + G) / (1 - R)
    I = T - Deff
    return {
        "direct": direct, "direct_se": Deff.std(),
        "indirect": indirect, "indirect_se": I.std(),
        "total": total, "total_se": T.std(),
        "aic": mod.aic, "rho": rho,
    }
```

## 3. Main Analysis

We estimate **four specifications**, each by OLS and by the Spatial Durbin Model (SDM) — eight estimates in a 2×2×2 design:

- **Estimator:** OLS vs. SDM
- **Specification:** Unconditional (only initial light) vs. Conditional (with 16 controls)
- **Fixed effects:** None vs. State FE

| Column | Controls | State FE |
|--------|----------|----------|
| Model 1 | No | No |
| Model 2 | No | Yes |
| Model 3 | Yes | No |
| Model 4 | Yes | Yes |

For each SDM the marginal effect of `log_light96_rcr_cap` is decomposed into:

- **Direct effect:** the impact of a district's own initial light on its own growth.
- **Indirect effect:** the spillover impact from neighbors' initial light.
- **Total effect:** Direct + Indirect.

For OLS the coefficient *is* the direct (and total) effect; indirect effects are not applicable.

```{code-cell} ipython3
# Estimate the four model specifications (each by OLS and SDM)
specs = {
    "Model 1": dict(cols=[XKEY],            fe=False),  # unconditional, no state FE
    "Model 2": dict(cols=[XKEY],            fe=True),   # unconditional, + state FE
    "Model 3": dict(cols=[XKEY] + CONTROLS, fe=False),  # conditional, no state FE
    "Model 4": dict(cols=[XKEY] + CONTROLS, fe=True),   # conditional, + state FE
}

results = {}
for tag, sp in specs.items():
    Xdf = m[sp["cols"]].copy()
    if sp["fe"]:
        Xdf = pd.concat([Xdf, fe], axis=1)
    results[tag] = {
        "ols": run_ols(y, Xdf),
        "sdm": run_sdm(y, Xdf, w, Wd),
        "controls": "Yes" if len(sp["cols"]) > 1 else "No",
        "fe": "Yes" if sp["fe"] else "No",
    }
    print("{}: estimated (OLS + SDM)".format(tag))
```

## 4. Results Table

The table below reports the convergence estimates. Each model column shows the OLS benchmark beside the SDM. SDM rows give the Direct, Indirect, and Total spatial impacts of initial luminosity, computed with the full (LeSage–Pace) method from the exact spatial multiplier matrix $(I-\rho W)^{-1}$, with Monte-Carlo standard errors in parentheses; OLS reports the coefficient as both Direct and Total. Significance stars are derived from z-statistics (`***` p<0.01, `**` p<0.05, `*` p<0.10), and AIC is reported for model comparison.

```{code-cell} ipython3
#| label: tbl-models
#| tbl-cap: "Unconditional and conditional convergence across districts."
from IPython.display import Markdown

cols = ["Model 1", "Model 2", "Model 3", "Model 4"]


def _est(est, se):
    return "{:.3f}{}".format(est, stars(est, se))


def _se(se):
    return "({:.3f})".format(se)


lines = [
    "|          | Model 1 |       | Model 2 |         | Model 3 |       | Model 4 |         |",
    "|----------|---------|-------|---------|---------|---------|-------|---------|---------|",
    "|          | OLS     | SDM   | OLS     | SDM     | OLS     | SDM   | OLS     | SDM     |",
]

# Direct effect (+ SE row)
row, se_row = "| Direct   |", "|          |"
for c in cols:
    o, s = results[c]["ols"], results[c]["sdm"]
    row += " {} | {} |".format(_est(o["direct"], o["direct_se"]), _est(s["direct"], s["direct_se"]))
    se_row += " {} | {} |".format(_se(o["direct_se"]), _se(s["direct_se"]))
lines += [row, se_row]

# Indirect effect (OLS = --, no SE; + SE row for SDM)
row, se_row = "| Indirect |", "|          |"
for c in cols:
    s = results[c]["sdm"]
    row += " -- | {} |".format(_est(s["indirect"], s["indirect_se"]))
    se_row += "  | {} |".format(_se(s["indirect_se"]))
lines += [row, se_row]

# Total effect (+ SE row)
row, se_row = "| Total    |", "|          |"
for c in cols:
    o, s = results[c]["ols"], results[c]["sdm"]
    row += " {} | {} |".format(_est(o["total"], o["total_se"]), _est(s["total"], s["total_se"]))
    se_row += " {} | {} |".format(_se(o["total_se"]), _se(s["total_se"]))
lines += [row, se_row]

# Controls / State FE / AIC
ctrl, fe_row, aic = "| Controls |", "| State FE |", "| AIC      |"
for c in cols:
    ctrl += " {0} | {0} |".format(results[c]["controls"])
    fe_row += " {0} | {0} |".format(results[c]["fe"])
    aic += " {:.0f} | {:.0f} |".format(results[c]["ols"]["aic"], results[c]["sdm"]["aic"])
lines += [ctrl, fe_row, aic]

Markdown("\n".join(lines))
```

## 5. Robustness: alternative spatial-impact methods

Table 1 reports the spatial impacts using the **full** (LeSage–Pace) method, which builds the average direct, indirect, and total effects from the exact spatial multiplier matrix $(I-\rho W)^{-1}$.
As a robustness check, the table below recomputes the impacts of initial luminosity for the preferred Model 4 (conditional + state FE) under three alternative computations of that multiplier:

- **full** — exact average of the diagonal of $(I-\rho W)^{-1}$ (the main result reported in Table 1).
- **simple** — the Kim–Phipps–Anselin scalar approximation (average direct impact fixed at 1).
- **power** — a power-series approximation of $(I-\rho W)^{-1}$.

Because the weights are row-standardised, the **Total** impact is invariant to the method ($\text{ATI}=1/(1-\rho)$); only the split between Direct and Indirect can move.

```{code-cell} ipython3
#| label: tbl-impacts-robustness
#| tbl-cap: "Robustness of the Model 4 spatial impacts of initial luminosity to the impact-computation method (Monte-Carlo standard errors in parentheses)."
# Re-estimate the preferred Model 4 (conditional + state FE) and compare the
# three spreg impact methods for the key regressor (log_light96_rcr_cap).
Xdf4 = pd.concat([m[[XKEY] + CONTROLS], fe], axis=1)
Xv4 = Xdf4.astype(float).values
mask4 = full_rank_lag_mask(Xv4, Wd)
slx4 = "All" if all(mask4) else mask4
with redirect_stdout(open(os.devnull, "w")):
    mod4 = ML_Lag(y=y, x=Xv4, w=w, slx_lags=1, slx_vars=slx4,
                  spat_impacts=["simple", "full", "power"])

b4 = mod4.betas.flatten()
k4 = Xv4.shape[1]
i_b, i_g, i_r = 1, 1 + k4, len(b4) - 1
rho4 = b4[i_r]

np.random.seed(20250620)
draws4 = np.random.multivariate_normal(b4, mod4.vm, size=N_MC)
D4, G4, R4 = draws4[:, i_b], draws4[:, i_g], draws4[:, i_r]
T4 = (D4 + G4) / (1 - R4)            # Total is identical across methods

rob = [
    "| Method | Direct | Indirect | Total |",
    "|--------|--------|----------|-------|",
]
for method in ["full", "simple", "power"]:
    direct = _adi(method, rho4)[0] * b4[i_b]
    total = (b4[i_b] + b4[i_g]) / (1 - rho4)
    indirect = total - direct
    Deff = _adi(method, R4) * D4
    Ieff = T4 - Deff
    label = method + (" (main)" if method == "full" else "")
    rob.append("| {} | {}<br>{} | {}<br>{} | {}<br>{} |".format(
        label,
        _est(direct, Deff.std()), _se(Deff.std()),
        _est(indirect, Ieff.std()), _se(Ieff.std()),
        _est(total, T4.std()), _se(T4.std()),
    ))
Markdown("\n".join(rob))
```

The three methods agree to within about 0.0002 on the Direct and Indirect impacts and give an identical Total impact, confirming that the estimated spillovers are not an artifact of the impact-computation method.
