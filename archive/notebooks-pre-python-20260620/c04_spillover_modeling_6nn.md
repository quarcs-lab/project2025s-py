---
jupytext:
  formats: ipynb,md:myst
  text_representation:
    extension: .md
    format_name: myst
    format_version: 0.13
    jupytext_version: 1.19.1
kernelspec:
  display_name: Stata
  language: stata
  name: stata
---

<a href="https://colab.research.google.com/github/quarcs-lab/project2025s/blob/master/notebooks/c04_spillover_modeling_6nn.ipynb"><img src="https://colab.research.google.com/assets/colab-badge.svg" alt="Open In Colab" /></a>

+++

This notebook estimates **8 econometric models** to analyze convergence in nighttime light intensity across 520 Indian districts (1996–2010). It compares standard OLS regressions with **Spatial Durbin Models (SDM)** that account for spatial spillovers between neighboring districts. The models follow a 2×2×2 design: OLS vs SDM, unconditional vs conditional, without vs with state fixed effects. For details on the model design and spatial weights, see the Background & Context section below.

+++

## Running Stata in Jupyter Notebooks


This notebook uses the [**stata_kernel**](https://kylebarron.dev/stata_kernel/) package, which lets you run Stata code natively inside Jupyter notebooks. Each code cell works like the Stata command window --- the kernel maintains a live Stata session in the background, so variables, datasets, and estimation results persist across cells.

#### Prerequisites

- **Stata** installed on your machine (SE, MP, or BE --- version 14 or later recommended)
- **Python 3.6+** with **Jupyter** (`pip install jupyter` or via Anaconda)
- A valid Stata license activated on your system

#### Installation

Install the `stata_kernel` package and register it with Jupyter:

```bash
pip install stata_kernel
python -m stata_kernel.install
```

If you use **conda**, you can install from conda-forge instead:

```bash
conda install -c conda-forge stata_kernel
```

#### Configuration

After installation, edit (or create) the configuration file `~/.stata_kernel.conf` to point to your Stata executable:

```ini
[stata_kernel]

# Path to Stata executable (adjust for your system)
# macOS examples:
stata_path = /Applications/Stata/StataSE.app/Contents/MacOS/StataSE
# stata_path = /Applications/Stata/StataMP.app/Contents/MacOS/StataMP

# Windows examples:
# stata_path = C:\Program Files\Stata18\StataSE-64.exe

# Linux examples:
# stata_path = /usr/local/stata18/stata-se
```

#### Verify the installation

Run the following in a terminal to confirm the kernel is registered:

```bash
jupyter kernelspec list
```

You should see `stata` in the output. Then open a new Jupyter notebook, select the **Stata** kernel, and run a simple command like `display "Hello from Stata!"` to confirm it works.

#### Basic usage tips

| Feature | Description |
|---|---|
| **State persistence** | Variables, datasets, and scalars carry over from cell to cell (like a live Stata session) |
| **Graphics** | Stata graphs display inline automatically |
| **`%help` magic** | Type `%help regress` to display Stata help in the notebook |
| **`%browse` magic** | Type `%browse` to view the current dataset |
| **`%head` / `%tail`** | Preview the first or last rows of the dataset |
| **Long commands** | Use `///` for line continuation, just as in a `.do` file |

#### Troubleshooting

| Problem | Solution |
|---|---|
| **Kernel not found** | Re-run `python -m stata_kernel.install` and restart Jupyter |
| **"Stata not found" error** | Check that `stata_path` in `~/.stata_kernel.conf` points to the correct executable |
| **License error** | Ensure Stata is activated --- try launching Stata normally first |
| **Slow startup** | The first cell may take a few seconds while Stata initializes; subsequent cells run faster |
| **`graph export` fails** | Stata requires a display server on Linux; use `xvfb-run jupyter notebook` if running headless |


+++

## 1. Background & Context

The cell below documents the research context as inline Stata comments. Key points:

- **Research question:** Does nighttime light growth (a proxy for economic activity) converge across Indian districts, and do neighboring districts generate spatial spillovers?
- **Dependent variable:** `light_growth96_10rcr_cap` — annualized growth in per-capita nighttime light intensity (1996--2010)
- **Key regressor:** `log_light96_rcr_cap` — log of initial (1996) per-capita light intensity. A negative coefficient indicates **convergence** (initially brighter districts grow more slowly)
- **Controls:** 16 variables capturing terrain, climate, demographics, infrastructure, and human capital
- **Spatial weights:** `W6nn` — the row-normalized 6NN matrix loaded from `W_matrix.dta`

```{code-cell}
/*==============================================================================
   Spatial Convergence Analysis of NTL in India
   -------------------------------------------
   Purpose:
   This do-file explores regional convergence across Indian regions 
   between 1996 and 2010. It compares OLS and Spatial Durbin Model (SDM) 
   specifications (both unconditional and conditional), as well as models 
   with and without state fixed effects (FE). We use a spatial weights matrix 
   (W6nn) to construct spatial lags.

   Key Features/Outcomes:
   1) OLS vs. SDM estimates with and without state FE.
   2) Extraction of AIC values for model comparison.
   3) Calculation of direct and indirect spatial impacts.
==============================================================================*/


/*------------------------------------------------------------------------------
   1. BACKGROUND & CONTEXT
   ----------------------------------------
   - Research Motivation:
     Investigate how local characteristics and neighboring regions' values 
     affect light growth (a proxy for economic activity).

   - Theoretical Framework:
     Spatial Durbin Model (SDM) allows both the dependent variable and 
     explanatory variables to have spatial lags (i.e., influence from neighbors).

   - Data Description:
     1) "W_matrix.dta": Contains a 520×520 matrix constructed using a 6 nearest neighbors approach, row-normalized to create W6nn.
     2) "india520.dta": Dataset with 520 observations representing regions/districts.
        Variables include:
         • light_growth96_10rcr_cap: Dependent variable (light-based growth).
         • log_light96_rcr_cap: Logged initial light measure.
         • Controls (terrain, climate, demographics, etc.): 
           suit_mean_snd, rain_mean_snd, mala_mean_snd, temp_mean_snd,
           rug_mean_snd, distance, latitude, rur_percent96_rcr,
           log_tot_density_rcr, sc_percent96, st_percent96, 
           workp_percent96, lit_percent96, higheredu_percent96, 
           elechh_percent96, log_puccaroads
         • state: Categorical variable for Indian states.

   - Key Variables:
     • light_growth96_10rcr_cap
     • log_light96_rcr_cap
     • W6nn: Spatial weights matrix (row-normalized)
------------------------------------------------------------------------------*/
```

```{code-cell}
/*==============================================================================
   2. SETUP
   ======================================
   Purpose: 
   - Initialize Stata environment
   - Load required datasets
   - Define spatial settings and IDs
   - Prepare for regression analysis
==============================================================================*/

clear all
macro drop _all
capture log close


* Basic environment settings
version 15
set more off

* Ensure working directory is notebooks/
* The Stata kernel may retain its directory from previous sessions
local _nb_found 0

* (1) Already in notebooks/?
capture confirm file "c04_spillover_modeling_6nn.ipynb"
if _rc == 0  local _nb_found 1

* (2) In project root? Try cd notebooks
if !`_nb_found' {
    quietly capture cd "notebooks"
    capture confirm file "c04_spillover_modeling_6nn.ipynb"
    if _rc == 0  local _nb_found 1
}

* (3) Kernel is somewhere else entirely — reset to home, walk to project
if !`_nb_found' {
    quietly cd "~"
    foreach p in "Documents/GitHub/project2025s" "GitHub/project2025s" "project2025s" {
        quietly capture cd "~"
        quietly capture cd "`p'/notebooks"
        capture confirm file "c04_spillover_modeling_6nn.ipynb"
        if _rc == 0 {
            local _nb_found 1
            continue, break
        }
    }
}

* (4) Give up with a helpful error
if !`_nb_found' {
    display as error "Could not find notebooks/ directory."
    display as error "Current directory: `c(pwd)'"
    display as error "Run this in the first cell:  cd ~/path/to/project2025s/notebooks"
}
*display "Working directory: `c(pwd)'"

* Start logging
capture log using "c04_spillover_modeling.log", replace


*------------------------------------------------------------------------------
* (2.1) Define a global macro for repeated control variables
*     Multi-line approach without quotes
*------------------------------------------------------------------------------
global controls suit_mean_snd rain_mean_snd ///
    mala_mean_snd temp_mean_snd ///
    rug_mean_snd distance ///
    latitude rur_percent96_rcr ///
    log_tot_density_rcr sc_percent96 ///
    st_percent96 workp_percent96 ///
    lit_percent96 higheredu_percent96 ///
    elechh_percent96 log_puccaroads

*------------------------------------------------------------------------------
* (2.2) Load Spatial Weights Matrix
*------------------------------------------------------------------------------

use "https://github.com/quarcs-lab/project2025s/raw/refs/heads/master/data/W_matrix.dta", clear

* Generate ID for each observation and set spatial data
gen id = _n
order id, first
spset id

* Create a row-normalized spatial weights matrix from data
spmatrix fromdata W6nn = _0 - _519, normalize(row) replace

* Summarize the spatial weights to ensure correctness
spmatrix summarize W6nn

*------------------------------------------------------------------------------
* (2.3) Load Main Dataset and Set Spatial IDs
*------------------------------------------------------------------------------
use "https://github.com/quarcs-lab/project2025s/raw/refs/heads/master/data/india520.dta", clear

encode state, generate(state_encoded)
gen id = _n
spset id
```

## 3. Main Analysis

We estimate 8 models in a systematic **2×2×2 design**:

- **Estimator:** OLS vs. Spatial Durbin Model (SDM)
- **Specification:** Unconditional (only initial light) vs. Conditional (with 16 controls)
- **Fixed effects:** None vs. State FE

For each model we store:
- The estimation results via `eststo` (for potential use with `esttab`)
- The AIC via `estat ic` for model comparison
- Scalar coefficients and standard errors for the summary table

For **SDM models**, `estat impact` decomposes the marginal effect of `log_light96_rcr_cap` into:
- **Direct effect:** The impact of a district's own initial light on its own growth
- **Indirect effect:** The spillover impact from neighbors' initial light
- **Total effect:** Direct + Indirect

For **OLS models**, the coefficient *is* the direct (and total) effect; indirect effects are not applicable.

```{code-cell}
/*==============================================================================
   3. MAIN ANALYSIS
   ======================================
   Purpose:
   - Estimate and compare multiple model specifications 
     (OLS vs. SDM, unconditional vs. conditional, with/without state FE).
   - Store AIC for model comparison.
   - Assess spatial impacts for SDM specifications.
==============================================================================*/

* We'll use eststo/estadd from the estout package to store results (e.g. AIC).
```

### 3.1 Unconditional Models

These models test for **unconditional (absolute) convergence** — whether initially poorer districts grow faster, without controlling for structural differences. The only regressor is `log_light96_rcr_cap`.

- **Model 1** (OLS): Baseline convergence regression
- **Model 2** (SDM): Adds spatial lags of both the dependent variable and the regressor
- **Model 3** (OLS + State FE): Controls for unobserved state-level heterogeneity
- **Model 4** (SDM + State FE): Full spatial model with state fixed effects

After each SDM estimation, `estat impact` computes the direct/indirect/total effects. These are saved into scalars for the summary table.

```{code-cell}
***************************************************************
* MODEL 1: Unconditional OLS
***************************************************************
regress light_growth96_10rcr_cap log_light96_rcr_cap, robust
eststo m1
estat ic
mat s = r(S)
quietly estadd scalar AIC = s[1,5]
scalar m1_d_b  = _b[log_light96_rcr_cap]
scalar m1_d_se = _se[log_light96_rcr_cap]
scalar m1_aic  = s[1,5]
```

```{code-cell}
***************************************************************
* MODEL 2: Unconditional SDM
***************************************************************
quietly spregress light_growth96_10rcr_cap ///
    log_light96_rcr_cap, ///
    ml vce(robust) ///
    dvarlag(W6nn) ///
    ivarlag(W6nn: log_light96_rcr_cap)

eststo m2
estat ic
mat s = r(S)
quietly estadd scalar AIC = s[1,5]
estat impact
matrix _bd = r(b_direct)
matrix _bi = r(b_indirect)
matrix _bt = r(b_total)
matrix _Vd = r(V_direct)
matrix _Vi = r(V_indirect)
matrix _Vt = r(V_total)
scalar m2_d_b  = _bd[1,1]
scalar m2_d_se = sqrt(_Vd[1,1])
scalar m2_i_b  = _bi[1,1]
scalar m2_i_se = sqrt(_Vi[1,1])
scalar m2_t_b  = _bt[1,1]
scalar m2_t_se = sqrt(_Vt[1,1])
scalar m2_aic  = s[1,5]
```

```{code-cell}
***************************************************************
* MODEL 3: Unconditional OLS with State FE
***************************************************************
regress light_growth96_10rcr_cap log_light96_rcr_cap i.state_encoded, robust
eststo m3
estat ic
mat s = r(S)
quietly estadd scalar AIC = s[1,5]
scalar m3_d_b  = _b[log_light96_rcr_cap]
scalar m3_d_se = _se[log_light96_rcr_cap]
scalar m3_aic  = s[1,5]
```

```{code-cell}
***************************************************************
* MODEL 4: Unconditional SDM with State FE
***************************************************************
quietly spregress light_growth96_10rcr_cap ///
    log_light96_rcr_cap i.state_encoded, ///
    ml vce(robust) ///
    dvarlag(W6nn) ///
    ivarlag(W6nn: log_light96_rcr_cap i.state_encoded)

eststo m4
estat ic
mat s = r(S)
quietly estadd scalar AIC = s[1,5]
estat impact
matrix _bd = r(b_direct)
matrix _bi = r(b_indirect)
matrix _bt = r(b_total)
matrix _Vd = r(V_direct)
matrix _Vi = r(V_indirect)
matrix _Vt = r(V_total)
scalar m4_d_b  = _bd[1,1]
scalar m4_d_se = sqrt(_Vd[1,1])
scalar m4_i_b  = _bi[1,1]
scalar m4_i_se = sqrt(_Vi[1,1])
scalar m4_t_b  = _bt[1,1]
scalar m4_t_se = sqrt(_Vt[1,1])
scalar m4_aic  = s[1,5]
```

### 3.2 Conditional Models

These models test for **conditional (beta) convergence** — whether districts converge *after controlling for* structural differences in terrain, climate, demographics, infrastructure, and human capital.

The 16 controls stored in `$controls` include:
- **Geography:** soil suitability, rainfall, malaria risk, temperature, ruggedness, distance to coast, latitude
- **Demographics:** rural share, population density, SC/ST shares, worker participation
- **Human capital:** literacy rate, higher education share
- **Infrastructure:** electrification rate, pucca (paved) road density

Models 5–8 mirror Models 1–4 but include these controls:
- **Model 5** (OLS): Conditional convergence
- **Model 6** (SDM): Conditional with spatial spillovers
- **Model 7** (OLS + State FE): Conditional with state fixed effects
- **Model 8** (SDM + State FE): Full model — the preferred specification

```{code-cell}
*------------------------------------------------------------------------------
* (3.2) Conditional Models
*     - Models that include the controls stored in $controls
*------------------------------------------------------------------------------

***************************************************************
* MODEL 5: Conditional OLS
***************************************************************
regress light_growth96_10rcr_cap ///
    log_light96_rcr_cap ///
    $controls, robust

eststo m5
estat ic
mat s = r(S)
quietly estadd scalar AIC = s[1,5]
scalar m5_d_b  = _b[log_light96_rcr_cap]
scalar m5_d_se = _se[log_light96_rcr_cap]
scalar m5_aic  = s[1,5]
```

```{code-cell}
***************************************************************
* MODEL 6: Conditional SDM
***************************************************************
quietly spregress light_growth96_10rcr_cap ///
    log_light96_rcr_cap ///
    $controls, ///
    ml vce(robust) ///
    dvarlag(W6nn) ///
    ivarlag(W6nn: log_light96_rcr_cap $controls)

eststo m6
estat ic
mat s = r(S)
quietly estadd scalar AIC = s[1,5]
estat impact
matrix _bd = r(b_direct)
matrix _bi = r(b_indirect)
matrix _bt = r(b_total)
matrix _Vd = r(V_direct)
matrix _Vi = r(V_indirect)
matrix _Vt = r(V_total)
scalar m6_d_b  = _bd[1,1]
scalar m6_d_se = sqrt(_Vd[1,1])
scalar m6_i_b  = _bi[1,1]
scalar m6_i_se = sqrt(_Vi[1,1])
scalar m6_t_b  = _bt[1,1]
scalar m6_t_se = sqrt(_Vt[1,1])
scalar m6_aic  = s[1,5]
```

```{code-cell}
***************************************************************
* MODEL 7: Conditional OLS with State FE
***************************************************************
regress light_growth96_10rcr_cap ///
    log_light96_rcr_cap ///
    $controls ///
    i.state_encoded, robust

eststo m7
estat ic
mat s = r(S)
quietly estadd scalar AIC = s[1,5]
scalar m7_d_b  = _b[log_light96_rcr_cap]
scalar m7_d_se = _se[log_light96_rcr_cap]
scalar m7_aic  = s[1,5]
```

```{code-cell}
***************************************************************
* MODEL 8: Conditional SDM with State FE
***************************************************************
quietly spregress light_growth96_10rcr_cap ///
    log_light96_rcr_cap ///
    $controls ///
    i.state_encoded, ///
    ml vce(robust) ///
    dvarlag(W6nn) ///
    ivarlag(W6nn: ///
        log_light96_rcr_cap ///
        $controls ///
        i.state_encoded)

eststo m8
estat ic
mat s = r(S)
quietly estadd scalar AIC = s[1,5]
estat impact
matrix _bd = r(b_direct)
matrix _bi = r(b_indirect)
matrix _bt = r(b_total)
matrix _Vd = r(V_direct)
matrix _Vi = r(V_indirect)
matrix _Vt = r(V_total)
scalar m8_d_b  = _bd[1,1]
scalar m8_d_se = sqrt(_Vd[1,1])
scalar m8_i_b  = _bi[1,1]
scalar m8_i_se = sqrt(_Vi[1,1])
scalar m8_t_b  = _bt[1,1]
scalar m8_t_se = sqrt(_Vt[1,1])
scalar m8_aic  = s[1,5]
```

## 4. Compile Results Table

This section builds a formatted summary table from the scalars saved after each model estimation. The approach avoids re-running the computationally expensive `estat impact` commands.

**How it works:**

1. **`_fmt_coef` program** — A helper that takes a coefficient and its standard error, computes a z-statistic, and returns a formatted string with significance stars (`***` p<0.01, `**` p<0.05, `*` p<0.10)

2. **Cell formatting loops** — Iterates over OLS models (direct = coefficient, indirect = n/a) and SDM models (direct/indirect/total from `estat impact` results)

3. **Output** — The table is both displayed in the Stata log and written to a markdown file at `c04_spillover_modeling_table.md`

```{code-cell}
/*==============================================================================
   4. COMPILE RESULTS TABLE
   ======================================
   Purpose:
   - Build a formatted convergence table from stored scalars
   - Display in log and write to markdown file
   - Columns: 4 model pairs (OLS vs SDM)
   - Rows: Direct, Indirect, Total effects + Controls/FE/AIC
==============================================================================*/

*----------------------------------------------------------------------
* (4.1) Helper program: format coefficient + significance stars
*----------------------------------------------------------------------
capture program drop _fmt_coef
program define _fmt_coef, rclass
    syntax, b(real) se(real)
    local z = abs(`b'/`se')
    local p = 2*(1 - normal(`z'))
    local stars ""
    if `p' < 0.01      local stars "***"
    else if `p' < 0.05 local stars "**"
    else if `p' < 0.10 local stars "*"
    local coef : display %6.3f `b'
    local coef = strtrim("`coef'")
    local se_f : display %5.3f `se'
    local se_f = strtrim("`se_f'")
    return local out   "`coef'`stars'"
    return local se_out "(`se_f')"
end

*----------------------------------------------------------------------
* (4.2) Format all table cells into local macros
*----------------------------------------------------------------------

* --- OLS models (m1, m3, m5, m7): direct = coefficient, no indirect ---
foreach m in 1 3 5 7 {
    local _b = scalar(m`m'_d_b)
    local _se = scalar(m`m'_d_se)
    _fmt_coef, b(`_b') se(`_se')
    local d`m'  "`r(out)'"
    local ds`m' "`r(se_out)'"
    * Total = Direct for OLS
    local t`m'  "`r(out)'"
    local ts`m' "`r(se_out)'"
    * Indirect not applicable
    local i`m'  "--"
    local is`m' ""
}

* --- SDM models (m2, m4, m6, m8): direct/indirect/total from impacts ---
foreach m in 2 4 6 8 {
    local _b = scalar(m`m'_d_b)
    local _se = scalar(m`m'_d_se)
    _fmt_coef, b(`_b') se(`_se')
    local d`m'  "`r(out)'"
    local ds`m' "`r(se_out)'"

    local _b = scalar(m`m'_i_b)
    local _se = scalar(m`m'_i_se)
    _fmt_coef, b(`_b') se(`_se')
    local i`m'  "`r(out)'"
    local is`m' "`r(se_out)'"

    local _b = scalar(m`m'_t_b)
    local _se = scalar(m`m'_t_se)
    _fmt_coef, b(`_b') se(`_se')
    local t`m'  "`r(out)'"
    local ts`m' "`r(se_out)'"
}

* --- AIC values (rounded to integer) ---
foreach m in 1 2 3 4 5 6 7 8 {
    local aic`m' : display %7.0f scalar(m`m'_aic)
    local aic`m' = strtrim("`aic`m''")
}

*----------------------------------------------------------------------
* (4.3) Display formatted table in log
*----------------------------------------------------------------------
display _n(2)
display "Table: Unconditional and conditional convergence across districts"
display "{hline 90}"
display %10s "Effect"   %11s "OLS" %11s "SDM" %11s "OLS" %11s "SDM" %11s "OLS" %11s "SDM" %11s "OLS" %11s "SDM"
display %10s ""         %11s "(1)" %11s "(2)" %11s "(3)" %11s "(4)" %11s "(5)" %11s "(6)" %11s "(7)" %11s "(8)"
display "{hline 90}"
display %10s "Direct"   %11s "`d1'" %11s "`d2'" %11s "`d3'" %11s "`d4'" %11s "`d5'" %11s "`d6'" %11s "`d7'" %11s "`d8'"
display %10s ""         %11s "`ds1'" %11s "`ds2'" %11s "`ds3'" %11s "`ds4'" %11s "`ds5'" %11s "`ds6'" %11s "`ds7'" %11s "`ds8'"
display %10s "Indirect" %11s "`i1'" %11s "`i2'" %11s "`i3'" %11s "`i4'" %11s "`i5'" %11s "`i6'" %11s "`i7'" %11s "`i8'"
display %10s ""         %11s "`is1'" %11s "`is2'" %11s "`is3'" %11s "`is4'" %11s "`is5'" %11s "`is6'" %11s "`is7'" %11s "`is8'"
display %10s "Total"    %11s "`t1'" %11s "`t2'" %11s "`t3'" %11s "`t4'" %11s "`t5'" %11s "`t6'" %11s "`t7'" %11s "`t8'"
display %10s ""         %11s "`ts1'" %11s "`ts2'" %11s "`ts3'" %11s "`ts4'" %11s "`ts5'" %11s "`ts6'" %11s "`ts7'" %11s "`ts8'"
display "{hline 90}"
display %10s "Controls" %11s "No" %11s "No" %11s "No" %11s "No" %11s "Yes" %11s "Yes" %11s "Yes" %11s "Yes"
display %10s "State FE" %11s "No" %11s "No" %11s "Yes" %11s "Yes" %11s "No" %11s "No" %11s "Yes" %11s "Yes"
display %10s "AIC"      %11s "`aic1'" %11s "`aic2'" %11s "`aic3'" %11s "`aic4'" %11s "`aic5'" %11s "`aic6'" %11s "`aic7'" %11s "`aic8'"
display "{hline 90}"
display "Note: Robust SE in parentheses. ***p<0.01, **p<0.05, *p<0.10."
display "SDM = Spatial Durbin Model (ML). OLS Indirect = not applicable."

*----------------------------------------------------------------------
* (4.4) Write markdown table to file
*----------------------------------------------------------------------
capture noisily {
local tbl "c04_spillover_modeling_table.md"

tempname fh
file open `fh' using "`tbl'", write replace

file write `fh' "|          | Model 1 |       | Model 2 |         | Model 3 |       | Model 4 |         |" _n
file write `fh' "|----------|---------|-------|---------|---------|---------|-------|---------|---------|" _n
file write `fh' "|          | OLS     | SDM   | OLS     | SDM     | OLS     | SDM   | OLS     | SDM     |" _n
file write `fh' "| Direct   | `d1' | `d2' | `d3' | `d4' | `d5' | `d6' | `d7' | `d8' |" _n
file write `fh' "|          | `ds1' | `ds2' | `ds3' | `ds4' | `ds5' | `ds6' | `ds7' | `ds8' |" _n
file write `fh' "| Indirect | `i1' | `i2' | `i3' | `i4' | `i5' | `i6' | `i7' | `i8' |" _n
file write `fh' "|          | `is1' | `is2' | `is3' | `is4' | `is5' | `is6' | `is7' | `is8' |" _n
file write `fh' "| Total    | `t1' | `t2' | `t3' | `t4' | `t5' | `t6' | `t7' | `t8' |" _n
file write `fh' "|          | `ts1' | `ts2' | `ts3' | `ts4' | `ts5' | `ts6' | `ts7' | `ts8' |" _n
file write `fh' "| Controls | No      | No    | No      | No      | Yes     | Yes   | Yes     | Yes     |" _n
file write `fh' "| State FE | No      | No    | Yes     | Yes     | No      | No    | Yes     | Yes     |" _n
file write `fh' "| AIC      | `aic1' | `aic2' | `aic3' | `aic4' | `aic5' | `aic6' | `aic7' | `aic8' |" _n

file write `fh' _n
file write `fh' ": Unconditional and conditional convergence across districts. {#tbl-models}" _n

file close `fh'
display _n "Table written to: `tbl'"
}
```
