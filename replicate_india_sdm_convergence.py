#!/usr/bin/env python3
# =============================================================================
#  Replication of the spatial convergence model in:
#
#  "Regional growth, convergence, and spatial spillovers in India:
#   A reproducible view from outer space" (quarcs-lab/project2025s)
#
#  This script reproduces TABLE 1 ("Unconditional and conditional convergence
#  across districts") of the article. The original estimation notebook (c04)
#  is written in Stata and estimates a Spatial Durbin Model (SDM) via
#       spregress y x, ml dvarlag(W6nn) ivarlag(W6nn: x ...)
#  which is the maximum-likelihood spatial-lag model augmented with spatially
#  lagged regressors (SLX). In Python this maps exactly onto
#       spreg.ML_Lag(..., slx_lags=1)
#
#  Model (Ertur & Koch 2007; eq. 7 of the paper):
#     g_t = beta1 * x_{t-1} + X_t * alpha
#           + beta2 * W x_{t-1} + W X_t * gamma + lambda * W g_t + eps
#
#  Specifications (4 model pairs, OLS vs SDM):
#     Model 1: unconditional, no state FE
#     Model 2: unconditional, + state FE
#     Model 3: conditional (controls), no state FE
#     Model 4: conditional (controls), + state FE
#
#  Data (auto-downloaded from the public repo if not found locally):
#     india520.geojson : 520 district geometries (+ controls), EPSG:4326
#     india520.dta     : district-level variables (dependent var, regressors)
#
#  Spatial weights: 6-nearest-neighbour, rebuilt from district centroids and
#  row-standardised (matching the paper's W6nn).
#
#  Requirements:
#     pip install geopandas libpysal spreg statsmodels pandas numpy
# =============================================================================

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

# ---------------------------------------------------------------------------
# 0. Configuration
# ---------------------------------------------------------------------------
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


# ---------------------------------------------------------------------------
# 1. Load data (local ./data first, else download from the public repo)
# ---------------------------------------------------------------------------
def _resolve(fname):
    for cand in (os.path.join("data", fname), fname):
        if os.path.exists(cand):
            return cand
    url = f"{RAW}/{fname}"
    print(f"Downloading {fname} from {url}")
    urllib.request.urlretrieve(url, fname)
    return fname


def load_data():
    gdf = gpd.read_file(_resolve("india520.geojson"))
    dta = pd.read_stata(_resolve("india520.dta"))
    keep = [KEY, DV, XKEY, "state"] + CONTROLS
    merged = gdf[[KEY, "geometry"]].merge(dta[keep], on=KEY)
    merged = gpd.GeoDataFrame(merged, geometry="geometry", crs=gdf.crs)
    assert len(merged) == 520, f"expected 520 districts, got {len(merged)}"
    return merged


# ---------------------------------------------------------------------------
# 2. Helpers
# ---------------------------------------------------------------------------
def stars(est, se):
    if se <= 0 or not np.isfinite(se):
        return ""
    z = abs(est / se)
    p = 2 * (1 - 0.5 * (1 + math.erf(z / math.sqrt(2))))
    return "***" if p < 0.01 else "**" if p < 0.05 else "*" if p < 0.10 else ""


def full_rank_lag_mask(Xv, Wd):
    """Return a boolean mask over X columns indicating which to spatially lag.

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
    """Spatial Durbin Model via ML_Lag(slx_lags=1); impacts use the 'simple'
    (Kim-Phipps-Anselin) method, which reproduces Stata's `estat impact`.

    For the key regressor with own coefficient b, spatial-lag coefficient g
    and spatial parameter rho:
        Direct   = b
        Total    = (b + g) / (1 - rho)
        Indirect = Total - Direct
    Inference on impacts is obtained by Monte-Carlo simulation from the ML
    parameter covariance matrix.
    """
    Xv = Xdf.astype(float).values
    mask = full_rank_lag_mask(Xv, Wd)
    slx_vars = "All" if all(mask) else mask
    with redirect_stdout(open(os.devnull, "w")):
        mod = ML_Lag(y=y, x=Xv, w=w, slx_lags=1, slx_vars=slx_vars,
                     spat_impacts="simple")

    b = mod.betas.flatten()
    k = Xv.shape[1]
    i_b = 1                       # const at 0; XKEY is first X column -> index 1
    i_g = 1 + k                   # first W*X column (XKEY is always lagged)
    i_r = len(b) - 1              # rho is last
    rho = b[i_r]
    direct = b[i_b]
    total = (b[i_b] + b[i_g]) / (1 - rho)
    indirect = total - direct

    draws = np.random.multivariate_normal(b, mod.vm, size=N_MC)
    D, G, R = draws[:, i_b], draws[:, i_g], draws[:, i_r]
    T = (D + G) / (1 - R)
    I = T - D
    return {
        "direct": direct, "direct_se": D.std(),
        "indirect": indirect, "indirect_se": I.std(),
        "total": total, "total_se": T.std(),
        "aic": mod.aic, "rho": rho,
    }


# ---------------------------------------------------------------------------
# 3. Estimate the four model pairs
# ---------------------------------------------------------------------------
def main():
    m = load_data()
    y = m[[DV]].values

    # 6-nearest-neighbour weights from centroids, row-standardised
    w = KNN.from_dataframe(m, k=K_NN)
    w.transform = "r"
    Wd = w.full()[0]

    fe = pd.get_dummies(m["state"], prefix="st", drop_first=True).astype(float)

    specs = {
        "Model 1": dict(cols=[XKEY],            fe=False),
        "Model 2": dict(cols=[XKEY],            fe=True),
        "Model 3": dict(cols=[XKEY] + CONTROLS, fe=False),
        "Model 4": dict(cols=[XKEY] + CONTROLS, fe=True),
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

    print_table(results)


# ---------------------------------------------------------------------------
# 4. Table 1 style output
# ---------------------------------------------------------------------------
def _cell(est, se):
    if est is None:
        return "–".center(14)
    return f"{est:+.3f}{stars(est, se)}".center(14)


def _se(se):
    return ("" if se is None else f"({se:.3f})").center(14)


def print_table(results):
    cols = ["Model 1", "Model 2", "Model 3", "Model 4"]
    print("\n" + "=" * 70)
    print("  REPLICATION OF TABLE 1")
    print("  Unconditional and conditional convergence across districts in India")
    print("  Dependent variable: per-capita NTL growth, 1996-2010")
    print("=" * 70)

    head = " " * 10 + "".join(c.center(29) for c in cols)
    sub  = " " * 10 + "".join(("OLS".center(14) + "SDM".center(15)) for _ in cols)
    print(head); print(sub); print("-" * len(sub))

    def row(label, key):
        line_est = f"{label:<10}"
        line_se  = " " * 10
        for c in cols:
            o, s = results[c]["ols"], results[c]["sdm"]
            line_est += _cell(o[key], o.get(key + "_se")) + " " + _cell(s[key], s.get(key + "_se"))[:14]
            line_se  += _se(o.get(key + "_se")) + " " + _se(s.get(key + "_se"))[:14]
        print(line_est); print(line_se)

    row("Direct",   "direct")
    row("Indirect", "indirect")
    row("Total",    "total")
    print("-" * len(sub))

    for label, fld in [("Controls", "controls"), ("State FE", "fe")]:
        line = f"{label:<10}"
        for c in cols:
            line += results[c][fld].center(14) + results[c][fld].center(15)
        print(line)

    line = f"{'AIC':<10}"
    for c in cols:
        line += f"{results[c]['ols']['aic']:.0f}".center(14) + f"{results[c]['sdm']['aic']:.0f}".center(15)
    print(line)
    print("=" * 70)
    print("Notes: *** p<0.01, ** p<0.05, * p<0.10. OLS uses HC1-robust SEs;")
    print("SDM impacts use the 'simple' method with Monte-Carlo inference.")
    print("Published Table 1 (for comparison):")
    print("  Direct  : -0.020/-0.021 | -0.022/-0.021 | -0.025/-0.026 | -0.025/-0.025")
    print("  Indirect:      –/-0.001 |      –/-0.001 |      –/-0.015* |      –/-0.012*")
    print("  Total   : -0.020/-0.022 | -0.022/-0.022 | -0.025/-0.041 | -0.025/-0.037")
    print("  AIC     :  -1945/-2290  |  -2413/-2466  |  -2211/-2356  |  -2469/-2499")


if __name__ == "__main__":
    main()
