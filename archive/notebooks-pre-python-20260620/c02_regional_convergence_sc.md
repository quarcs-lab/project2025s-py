---
jupytext:
  formats: ipynb,md:myst
  text_representation:
    extension: .md
    format_name: myst
    format_version: 0.13
    jupytext_version: 1.19.1
kernelspec:
  display_name: R
  language: R
  name: ir
---

<a href="https://colab.research.google.com/github/quarcs-lab/project2025s/blob/master/notebooks/c02_regional_convergence_sc.ipynb"><img src="https://colab.research.google.com/assets/colab-badge.svg" alt="Open In Colab" /></a>

+++

This notebook examines absolute $\beta$-convergence in nighttime luminosity across 520 Indian districts (1996--2010). We regress per capita luminosity growth on initial luminosity levels and visualize the relationship in an annotated scatterplot. This analysis corresponds to the first set of results discussed in the main manuscript.

+++

## Setup

```{code-cell} r
---
vscode:
  languageId: r
---
# Setup
library(haven)
library(ggplot2)
```

## Data

We use district-level radiance-calibrated nighttime lights data from the DMSP-OLS satellites, covering 520 districts.

```{code-cell} r
---
vscode:
  languageId: r
---
# Load dataset from GitHub
url <- "https://raw.githubusercontent.com/quarcs-lab/project2025s/master/data/india520.dta"
temp <- tempfile(fileext = ".dta")
download.file(url, temp, mode = "wb")
data <- read_dta(temp)
```

## Convergence regression

A negative slope on initial luminosity indicates $\beta$-convergence: districts with lower initial luminosity grew faster over the period.

```{code-cell} r
---
vscode:
  languageId: r
---
# Basic OLS Regression
model1 <- lm(light_growth96_10rcr_cap ~ log_light96_rcr_cap, data = data)
summary(model1)
```

```{code-cell} r
---
vscode:
  languageId: r
---
# Compute regression model for scatterplot annotation
model <- lm(light_growth96_10rcr_cap ~ log_light96_rcr_cap, data = data)
slope <- round(coef(model)[2], 3)
rsq   <- round(summary(model)$r.squared, 3)
```

## Convergence scatterplot

The scatterplot below visualizes the convergence relationship. Outlier districts are labeled to highlight cases that deviate notably from the overall trend---either bright districts that declined or dim districts that grew unusually fast.

```{code-cell} r
---
vscode:
  languageId: r
---
#| label: fig-convergence
#| fig-cap: "Regional luminosity convergence across districts in India <br> Notes: Each point represents one of the 520 districts. The regression line shows the estimated beta-convergence relationship. Outlier districts are labeled. <br> Source: Data from Chanda and Kabiraj (2020). See [Regional convergence](notebooks/c02_regional_convergence_sc.ipynb) notebook for source code."

# Identify outlier districts for labeling
outliers <- data[
  (data$log_light96_rcr_cap > -3 & data$light_growth96_10rcr_cap < 0) |
  (data$log_light96_rcr_cap < -7 & data$light_growth96_10rcr_cap > 0.2),
]

# Annotated scatterplot
p1 <- ggplot(data, aes(x = log_light96_rcr_cap, y = light_growth96_10rcr_cap)) +
  geom_point(alpha = 0.5, color = "steelblue") +
  geom_smooth(method = "lm", color = "black", se = TRUE, linewidth = 0.8) +
  geom_label(data = outliers, aes(label = district),
             size = 3, alpha = 0.7, nudge_y = 0.005) +
  annotate("label",
           x = Inf, y = Inf,
           label = paste("Slope =", slope, "\nR\u00b2 =", rsq),
           hjust = 1.1, vjust = 1.5, size = 4) +
  labs(x = "Log of luminosity per capita in 1996",
       y = "Growth of luminosity per capita 1996-2010") +
  theme_minimal()
p1
```
