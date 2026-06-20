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

<a href="https://colab.research.google.com/github/quarcs-lab/project2025s-py/blob/master/notebooks/c02_regional_convergence_sc.ipynb"><img src="https://colab.research.google.com/assets/colab-badge.svg" alt="Open In Colab" /></a>

+++

This notebook examines absolute $\beta$-convergence in nighttime luminosity across 520 Indian districts (1996--2010). We regress per capita luminosity growth on initial luminosity levels and visualize the relationship in an annotated scatterplot. This analysis corresponds to the first set of results discussed in the main manuscript.

+++

## Setup

```{code-cell} ipython3
# Google Colab: install packages not included in the default environment
try:
    import google.colab
    !pip install statsmodels seaborn -q
except ImportError:
    pass  # Local environment — packages already installed
```

```{code-cell} ipython3
# Setup
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import statsmodels.formula.api as smf

import warnings
warnings.filterwarnings("ignore")
```

## Data

We use district-level radiance-calibrated nighttime lights data from the DMSP-OLS satellites, covering 520 districts.

```{code-cell} ipython3
# Load dataset (local copy first, else download from GitHub)
import os
import urllib.request

fname = "india520.dta"
url = "https://raw.githubusercontent.com/quarcs-lab/project2025s-py/master/data/" + fname
local = os.path.join("..", "data", fname)
path = local if os.path.exists(local) else fname
if path == fname and not os.path.exists(fname):
    urllib.request.urlretrieve(url, fname)
data = pd.read_stata(path)
print("Districts: {}".format(len(data)))
```

## Convergence regression

A negative slope on initial luminosity indicates $\beta$-convergence: districts with lower initial luminosity grew faster over the period.

```{code-cell} ipython3
# Basic OLS Regression
model1 = smf.ols("light_growth96_10rcr_cap ~ log_light96_rcr_cap", data=data).fit()
print(model1.summary())
```

```{code-cell} ipython3
# Compute regression model for scatterplot annotation
model = smf.ols("light_growth96_10rcr_cap ~ log_light96_rcr_cap", data=data).fit()
slope = round(model.params["log_light96_rcr_cap"], 3)
rsq   = round(model.rsquared, 3)
```

## Convergence scatterplot

The scatterplot below visualizes the convergence relationship. Outlier districts are labeled to highlight cases that deviate notably from the overall trend---either bright districts that declined or dim districts that grew unusually fast.

```{code-cell} ipython3
#| label: fig-convergence
#| fig-cap: "Regional luminosity convergence across districts in India <br> Notes: Each point represents one of the 520 districts. The regression line shows the estimated beta-convergence relationship. Outlier districts are labeled. <br> Source: Data from Chanda and Kabiraj (2020). See [Regional convergence](notebooks/c02_regional_convergence_sc.ipynb) notebook for source code."

# Identify outlier districts for labeling
mask = (
    ((data["log_light96_rcr_cap"] > -3) & (data["light_growth96_10rcr_cap"] < 0))
    | ((data["log_light96_rcr_cap"] < -7) & (data["light_growth96_10rcr_cap"] > 0.2))
)
outliers = data[mask]

# Annotated scatterplot
fig, ax = plt.subplots(figsize=(8, 6))
sns.regplot(
    data=data,
    x="log_light96_rcr_cap",
    y="light_growth96_10rcr_cap",
    ci=95,
    scatter_kws={"alpha": 0.5, "color": "steelblue"},
    line_kws={"color": "black", "linewidth": 0.8},
    ax=ax,
)

# Label outlier districts
for _, r in outliers.iterrows():
    ax.annotate(
        r["district"],
        xy=(r["log_light96_rcr_cap"], r["light_growth96_10rcr_cap"]),
        xytext=(0, 6),
        textcoords="offset points",
        ha="center",
        fontsize=8,
        bbox=dict(boxstyle="round,pad=0.3", fc="white", ec="gray", alpha=0.7),
    )

# Slope / R-squared annotation box (top-right corner)
annotation = "Slope = {}\nR² = {}".format(slope, rsq)
ax.annotate(
    annotation,
    xy=(0.97, 0.97),
    xycoords="axes fraction",
    ha="right",
    va="top",
    fontsize=11,
    bbox=dict(boxstyle="round,pad=0.4", fc="white", ec="black", alpha=0.9),
)

ax.set_xlabel("Log of luminosity per capita in 1996")
ax.set_ylabel("Growth of luminosity per capita 1996-2010")
sns.despine(ax=ax)
plt.tight_layout()
plt.show()
```
