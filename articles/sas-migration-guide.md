# SAS Template Migration Guide: Finding Your Plot in R

## Overview

This guide maps every SAS template in the HVTI statistics group template
library to its R equivalent in the **hvtiPlotR** package. If you know
the SAS template name (e.g.,
`tp.np.afib.ivwristm.avrg_curv.binary.sas`), look it up in the table
below and jump to the corresponding section for a working R example.

The guide is organized by template family (the two-letter prefix after
`tp.`). New ports are added to this document as they become available.

### Key concepts for SAS users

**ggplot2 builds plots in layers.** Instead of one macro call with many
`color=`, `xaxis=`, and `footnote=` options, you chain `+` operations:

``` r
nonparametric_curve_plot(dat, ...) +
  scale_colour_manual(values = c("black", "gray40")) +
  scale_x_continuous(breaks = 0:12) +
  labs(x = "Years after Operation", y = "Prevalence (%)") +
  hvti_theme("manuscript")
```

**[`hvti_theme()`](https://ehrlinger.github.io/hvtiPlotR/reference/hvti_theme.md)
replaces SAS `device=` / style options.** Use `"dark_ppt"` / `"ppt"` for
PowerPoint slides, `"light_ppt"` for light-background slides,
`"manuscript"` for journal figures, and `"poster"` for conference
posters.

**Functions return a ggplot object; they do not display it.** Call the
plot object at the top level (or use
[`print()`](https://rdrr.io/r/base/print.html)) to render it, or save
with [`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html) /
[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md).

**Pre-fitted models, not raw data.** Most functions accept the *output*
of a statistical model (curve datasets, probability estimates) rather
than individual patient records — mirroring the SAS workflow where
`%decompos()` or `%kaplan` computes estimates and a separate template
step produces the figure.

------------------------------------------------------------------------

## Template lookup table

| SAS Template                                        | Family | R Function                                                                                                      | Section                                              |
|-----------------------------------------------------|--------|-----------------------------------------------------------------------------------------------------------------|------------------------------------------------------|
| `tp.np.afib.ivwristm.avrg_curv.binary.sas`          | np     | [`nonparametric_curve_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_curve_plot.md)     | [Average curve — binary](#np-binary-avg)             |
| `tp.np.afib.ivwristm.pt_spec_phases.binary.sas`     | np     | [`nonparametric_curve_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_curve_plot.md)     | [Phase decomposition](#np-phases)                    |
| `tp.np.afib.ivwristm.pt_specific.binary.sas`        | np     | [`nonparametric_curve_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_curve_plot.md)     | [Average curve — binary](#np-binary-avg)             |
| `tp.np.afib.mult.avrg_curv.binary.sas`              | np     | [`nonparametric_curve_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_curve_plot.md)     | [Multi-group comparison](#np-multigroup)             |
| `tp.np.afib.mult.pt_spec.binary.sas`                | np     | [`nonparametric_curve_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_curve_plot.md)     | [Multi-group comparison](#np-multigroup)             |
| `tp.np.avpkgrad_ozak_ind_mtwt.sas`                  | np     | [`nonparametric_curve_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_curve_plot.md)     | [Multi-group comparison](#np-multigroup)             |
| `tp.np.fev.double.univariate.continuous.sas`        | np     | [`nonparametric_curve_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_curve_plot.md)     | [Continuous outcome](#np-continuous)                 |
| `tp.np.fev.multivariate.continuous.sas`             | np     | [`nonparametric_curve_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_curve_plot.md)     | [Multi-group comparison](#np-multigroup)             |
| `tp.np.fev.u.trend.continuous.sas`                  | np     | [`nonparametric_curve_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_curve_plot.md)     | [Continuous outcome](#np-continuous)                 |
| `tp.np.tr.icdpr.avg_curv.sas`                       | np     | [`nonparametric_curve_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_curve_plot.md)     | [Average curve — binary](#np-binary-avg)             |
| `tp.np.tr.ivecho.average_curv.ordinal.sas`          | np     | [`nonparametric_ordinal_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_ordinal_plot.md) | [Ordinal outcomes](#np-ordinal)                      |
| `tp.np.tr.ivecho.independence.sas`                  | np     | [`nonparametric_ordinal_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_ordinal_plot.md) | [Ordinal independence](#np-ordinal-independence)     |
| `tp.np.tr.ivecho.u.phases.sas`                      | np     | [`nonparametric_ordinal_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_ordinal_plot.md) | [Ordinal phases](#np-ordinal-phases)                 |
| `tp.np.po_ar.u_multi.ordinal.sas`                   | np     | [`nonparametric_ordinal_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_ordinal_plot.md) | [Ordinal multi-scenario](#np-ordinal-multi)          |
| `tp.np.z0axdpo.continuous.bmi_xaxis.sas`            | np     | [`nonparametric_curve_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_curve_plot.md)     | [Covariate x-axis](#np-covariate-xaxis)              |
| `tp.ac.dead.sas` (via `%kaplan` / `%nelsont`)       | ac     | [`survival_curve()`](https://ehrlinger.github.io/hvtiPlotR/reference/survival_curve.md)                         | [Kaplan–Meier survival](#ac-dead)                    |
| `tp.cp.dead.sas`                                    | cp     | [`survival_curve()`](https://ehrlinger.github.io/hvtiPlotR/reference/survival_curve.md)                         | [Kaplan–Meier survival](#ac-dead)                    |
| `tp.dp.gfup.R`                                      | dp     | [`goodness_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/goodness_followup.md)                   | [Goodness of follow-up](#dp-gfup)                    |
| `tp.lp.propen.cov_balance.R`                        | lp     | [`covariate_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/covariate_balance.md)                   | [Covariate balance](#lp-covbal)                      |
| `tp.dp.female_bicus_preAR_sankey.R`                 | dp     | [`alluvial_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/alluvial_plot.md)                           | [Alluvial](#dp-sankey)                               |
| PAM cluster stability analysis                      | dp     | [`cluster_sankey_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/cluster_sankey_plot.md)               | [Cluster stability Sankey](#dp-cluster-sankey)       |
| `tp.complexUpset.R`                                 | dp     | [`upset_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/upset_plot.md)                                 | [UpSet plot](#dp-upset)                              |
| `tp.dp.spaghetti.echo.R`                            | dp     | [`spaghetti_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/spaghetti_plot.md)                         | [Spaghetti / individual trajectories](#dp-spaghetti) |
| `tp.rp.trends.sas`                                  | rp     | [`trends_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/trends_plot.md)                               | [Trends over time](#dp-trends)                       |
| `tp.lp.trends.sas`                                  | lp     | [`trends_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/trends_plot.md)                               | [Trends over time](#dp-trends)                       |
| `tp.lp.trends.age.sas`                              | lp     | [`trends_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/trends_plot.md)                               | [Trends over time](#dp-trends)                       |
| `tp.lp.trends.polytomous.sas`                       | lp     | [`trends_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/trends_plot.md)                               | [Trends over time](#dp-trends)                       |
| `tp.dp.trends.R`                                    | dp     | [`trends_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/trends_plot.md)                               | [Trends over time](#dp-trends)                       |
| `tp.dp.longitudinal_patients_measures.R`            | dp     | [`longitudinal_counts_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/longitudinal_counts_plot.md)     | [Longitudinal counts](#dp-long-counts)               |
| `tp.lp.mirror-histogram_SAVR-TF-TAVR.R`             | lp     | [`mirror_histogram()`](https://ehrlinger.github.io/hvtiPlotR/reference/mirror_histogram.md)                     | [Mirror histogram — binary-match](#dp-mirror)        |
| `tp.lp.mirror_histo_before_after_wt.R`              | lp     | `mirror_histogram(weight_col = ...)`                                                                            | [Mirror histogram — weighted IPTW](#dp-mirror)       |
| Stacked histogram                                   | dp     | [`stacked_histogram()`](https://ehrlinger.github.io/hvtiPlotR/reference/stacked_histogram.md)                   | [Stacked histogram](#dp-stacked)                     |
| `tp.hs.dead.setup.sas`                              | hs     | [`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md)                               | [Parametric hazard/survival](#hs-dead)               |
| `tp.hs.dead_uses_setup.sas`                         | hs     | [`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md)                               | [Parametric hazard/survival](#hs-dead)               |
| `tp.hs.dead.procedure.tdepth.sas`                   | hs     | [`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md)                               | [Parametric hazard/survival](#hs-dead)               |
| `tp.hs.dead.conditional.setup.sas`                  | hs     | [`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md)                               | [Conditional survival](#hs-dead)                     |
| `tp.hs.dead.conditional.uses_setup.sas`             | hs     | [`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md)                               | [Conditional survival](#hs-dead)                     |
| `tp.hs.dead.compare_benefit.setup.sas`              | hs     | [`survival_difference_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/survival_difference_plot.md)     | [Treatment benefit distribution](#hs-dead)           |
| `tp.hs.uslife_estimates_generate_stratify_.age.sas` | hs     | [`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md)                               | [US life-table overlay](#hs-dead)                    |
| `tp.hs.uslife_generates_matched_estimates.sas`      | hs     | [`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md)                               | [US life-table overlay](#hs-dead)                    |

------------------------------------------------------------------------

## Nonparametric temporal trends (`tp.np.*`)

All `tp.np.*` templates share a common SAS workflow:

1.  Fit patient-specific temporal profiles with `%decompos()`.
2.  Average profiles across patients with `PROC SUMMARY` → `mean_curv`
    dataset.
3.  Optionally compute bootstrap confidence intervals → `boots_ci`
    dataset.
4.  Compute binned patient-level summaries (deciles/quintiles) → `means`
    dataset.
5.  Call the plotting template.

The R port replaces step 5. Steps 1–4 still run in SAS; export the
resulting datasets to CSV and read them into R:

``` r
curve_data <- read.csv("mean_curv.csv")   # or boots_ci if CI bands are needed
data_pts   <- read.csv("means.csv")       # optional binned data points
```

### SAS column name mapping

| SAS column                          | R argument     | Notes                 |
|-------------------------------------|----------------|-----------------------|
| `iv_echo` / `iv_wristm` / `iv_fyrs` | `x_col`        | Time variable         |
| `prev` / `mnprev` / `_p_` / `est`   | `estimate_col` | Curve estimate        |
| `cll_p68` / `cll_p95`               | `lower_col`    | CI lower band         |
| `clu_p68` / `clu_p95`               | `upper_col`    | CI upper band         |
| Grouping variable (e.g., `group`)   | `group_col`    | NULL for single curve |
| `mtime` / `mmtime` (means dataset)  | `dp_x_col`     | Binned point x        |
| `mprev` / `mnprev` (means dataset)  | `dp_y_col`     | Binned point y        |

### Average curve — binary outcome

**Ports:** `tp.np.afib.ivwristm.avrg_curv.binary.sas`,
`tp.np.afib.ivwristm.pt_specific.binary.sas`,
`tp.np.tr.icdpr.avg_curv.sas`

``` r
dat     <- sample_nonparametric_curve_data(
  n            = 500,
  time_max     = 12,
  outcome_type = "probability"
)
dat_pts <- sample_nonparametric_curve_points(n = 500, time_max = 12)

# Minimal plot
nonparametric_curve_plot(dat) +
  scale_x_continuous(breaks = seq(0, 12, 2)) +
  scale_y_continuous(
    limits = c(0, 1),
    breaks = seq(0, 1, 0.2),
    labels = scales::percent
  ) +
  labs(
    x     = "Years after operation",
    y     = "Prevalence (%)",
    title = "Atrial Fibrillation Prevalence"
  ) +
  hvti_theme("manuscript")
```

![](sas-migration-guide_files/figure-html/np-binary-avg-example-1.png)

Add 68% CI bands (one standard error; matches SAS `boots_ci` with
`cll_p68` / `clu_p68`):

``` r
nonparametric_curve_plot(
  dat,
  lower_col = "lower",
  upper_col = "upper"
) +
  scale_x_continuous(breaks = seq(0, 12, 2)) +
  scale_y_continuous(
    limits = c(0, 1),
    breaks = seq(0, 1, 0.2),
    labels = scales::percent
  ) +
  labs(
    x     = "Years after operation",
    y     = "Prevalence (%)",
    title = "Atrial Fibrillation — 68% CI"
  ) +
  hvti_theme("manuscript")
```

![](sas-migration-guide_files/figure-html/np-binary-avg-ci-1.png)

Add binned data summary points (matches the SAS `means` dataset):

``` r
nonparametric_curve_plot(
  dat,
  lower_col   = "lower",
  upper_col   = "upper",
  data_points = dat_pts
) +
  scale_x_continuous(breaks = seq(0, 12, 2)) +
  scale_y_continuous(
    limits = c(0, 1),
    breaks = seq(0, 1, 0.2),
    labels = scales::percent
  ) +
  labs(
    x     = "Years after operation",
    y     = "Prevalence (%)",
    title = "Atrial Fibrillation with Binned Observations"
  ) +
  hvti_theme("manuscript")
```

![](sas-migration-guide_files/figure-html/np-binary-avg-points-1.png)

### Continuous outcome

**Ports:** `tp.np.fev.double.univariate.continuous.sas`,
`tp.np.fev.u.trend.continuous.sas`

For continuous outcomes (FEV1, AV peak gradient) set
`outcome_type = "continuous"`. The y-axis label and scale change
accordingly; everything else is identical.

``` r
dat_cont     <- sample_nonparametric_curve_data(
  n            = 400,
  time_max     = 10,
  outcome_type = "continuous"
)
dat_cont_pts <- sample_nonparametric_curve_points(
  n            = 400,
  time_max     = 10,
  outcome_type = "continuous"
)

nonparametric_curve_plot(
  dat_cont,
  lower_col   = "lower",
  upper_col   = "upper",
  data_points = dat_cont_pts
) +
  scale_x_continuous(breaks = seq(0, 10, 2)) +
  scale_y_continuous(limits = c(0, 4)) +
  labs(
    x     = "Years after operation",
    y     = expression(FEV[1] ~ (L)),
    title = "FEV\u2081 Temporal Trend"
  ) +
  annotate("text",
    x = 9, y = 3.5,
    label = "68% CI band",
    hjust = 1, size = 3
  ) +
  hvti_theme("manuscript")
```

![](sas-migration-guide_files/figure-html/np-continuous-example-1.png)

### Multi-group comparison

**Ports:** `tp.np.afib.mult.avrg_curv.binary.sas`,
`tp.np.afib.mult.pt_spec.binary.sas`,
`tp.np.avpkgrad_ozak_ind_mtwt.sas`,
`tp.np.fev.multivariate.continuous.sas`

Provide a named vector to `groups` when generating sample data, or set
`group_col` when supplying your own curve data.

``` r
grp_def <- c("Ozaki" = 0.7, "CE-Pericardial" = 1.1, "Homograft" = 1.4)
dat_grp     <- sample_nonparametric_curve_data(
  n        = 600,
  time_max = 12,
  groups   = grp_def
)
dat_grp_pts <- sample_nonparametric_curve_points(
  n        = 600,
  time_max = 12,
  groups   = grp_def
)

nonparametric_curve_plot(
  dat_grp,
  group_col   = "group",
  lower_col   = "lower",
  upper_col   = "upper",
  data_points = dat_grp_pts
) +
  scale_colour_manual(
    values = c("Ozaki" = "#003087", "CE-Pericardial" = "#CC0000", "Homograft" = "#666666")
  ) +
  scale_fill_manual(
    values = c("Ozaki" = "#003087", "CE-Pericardial" = "#CC0000", "Homograft" = "#666666")
  ) +
  scale_x_continuous(breaks = seq(0, 12, 2)) +
  scale_y_continuous(
    limits = c(0, 1),
    breaks = seq(0, 1, 0.2),
    labels = scales::percent
  ) +
  labs(
    x      = "Years after operation",
    y      = "Prevalence (%)",
    colour = "Valve type",
    fill   = "Valve type",
    title  = "Atrial Fibrillation by Valve Type"
  ) +
  hvti_theme("manuscript")
```

![](sas-migration-guide_files/figure-html/np-multigroup-example-1.png)

### Phase decomposition

**Ports:** `tp.np.afib.ivwristm.pt_spec_phases.binary.sas`,
`tp.np.tr.ivecho.u.phases.sas`

Phase plots separate the early (bell-shaped, incomplete hazard) and late
(Weibull CDF, complete hazard) components. Supply a `group_col` whose
levels label the phases.

``` r
dat_phase <- sample_nonparametric_curve_data(
  n      = 500,
  groups = c("Early phase" = 1.5, "Late phase" = 0.6, "Overall" = 1.0)
)

nonparametric_curve_plot(
  dat_phase,
  group_col = "group"
) +
  scale_colour_manual(
    values = c("Early phase" = "#CC0000",
               "Late phase"  = "#003087",
               "Overall"     = "black")
  ) +
  scale_linetype_manual(
    values = c("Early phase" = "dashed",
               "Late phase"  = "dashed",
               "Overall"     = "solid")
  ) +
  scale_x_continuous(breaks = seq(0, 12, 2)) +
  scale_y_continuous(
    limits = c(0, 1),
    breaks = seq(0, 1, 0.2),
    labels = scales::percent
  ) +
  labs(
    x      = "Years after operation",
    y      = "Prevalence (%)",
    colour = NULL,
    title  = "AF — Early and Late Phase Decomposition"
  ) +
  hvti_theme("manuscript")
```

![](sas-migration-guide_files/figure-html/np-phases-example-1.png)

### Covariate on the x-axis

**Port:** `tp.np.z0axdpo.continuous.bmi_xaxis.sas`

When BMI or another continuous covariate (rather than time) is on the
x-axis, the function signature is identical — simply pass the covariate
column name to `x_col`.

``` r
# Simulate covariate (BMI) x-axis data
set.seed(42)
n_pts  <- 300
bmi    <- seq(18, 45, length.out = n_pts)
est    <- plogis(-3 + 0.08 * bmi)
se     <- sqrt(est * (1 - est) / 50)
bmi_curve <- data.frame(
  bmi   = bmi,
  est   = est,
  lower = pmax(0, est - qnorm(0.84) * se),
  upper = pmin(1, est + qnorm(0.84) * se)
)

nonparametric_curve_plot(
  bmi_curve,
  x_col        = "bmi",
  estimate_col = "est",
  lower_col    = "lower",
  upper_col    = "upper"
) +
  scale_x_continuous(
    breaks = seq(18, 45, 3),
    limits = c(18, 45)
  ) +
  scale_y_continuous(
    limits = c(0, 1),
    breaks = seq(0, 1, 0.1),
    labels = scales::percent
  ) +
  labs(
    x     = expression(BMI ~ (kg/m^2)),
    y     = "Estimated Probability",
    title = "Outcome Probability vs. BMI at Operation"
  ) +
  hvti_theme("manuscript")
```

![](sas-migration-guide_files/figure-html/np-bmi-xaxis-1.png)

### Ordinal outcomes

**Port:** `tp.np.tr.ivecho.average_curv.ordinal.sas`

Ordinal templates (TR grade, AR grade) use
[`nonparametric_ordinal_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/nonparametric_ordinal_plot.md).
The critical migration step is reshaping the SAS wide-format `predict`
dataset (one column per grade) to long format.

**SAS reshape (do this before reading into R):**

``` sas
/* SAS wide format: p0, p1, p2, p3 */
data predict_wide;
  set predict;
run;
```

**R reshape:**

``` r
library(tidyr)
long <- pivot_longer(
  predict_wide,
  cols      = c(p0, p1, p2, p3),
  names_to  = "grade",
  values_to = "estimate"
)
```

``` r
ord_labels <- c("None", "Mild", "Moderate", "Severe")
dat_ord     <- sample_nonparametric_ordinal_data(
  n            = 1000,
  time_max     = 5,
  grade_labels = ord_labels
)
dat_ord_pts <- sample_nonparametric_ordinal_points(
  n            = 1000,
  time_max     = 5,
  grade_labels = ord_labels
)

nonparametric_ordinal_plot(
  dat_ord,
  grade_col   = "grade",
  data_points = dat_ord_pts
) +
  scale_colour_manual(
    values = c(
      "None"     = "#003087",
      "Mild"     = "#55A51C",
      "Moderate" = "#FFA500",
      "Severe"   = "#CC0000"
    )
  ) +
  scale_x_continuous(breaks = 0:5) +
  scale_y_continuous(
    limits = c(0, 1),
    breaks = seq(0, 1, 0.2),
    labels = scales::percent
  ) +
  labs(
    x      = "Years after operation",
    y      = "Grade probability",
    colour = "TR Grade",
    title  = "Tricuspid Regurgitation Grade"
  ) +
  hvti_theme("manuscript")
```

![](sas-migration-guide_files/figure-html/np-ordinal-example-1.png)

#### Ordinal multi-scenario comparison

**Port:** `tp.np.po_ar.u_multi.ordinal.sas`

``` r
dat_ar1 <- sample_nonparametric_ordinal_data(seed = 1)
dat_ar2 <- sample_nonparametric_ordinal_data(seed = 99)

dat_ar1$scenario <- "Before repair"
dat_ar2$scenario <- "After repair"
combined <- rbind(dat_ar1, dat_ar2)

nonparametric_ordinal_plot(combined, grade_col = "grade") +
  facet_wrap(~scenario) +
  scale_x_continuous(breaks = 0:5) +
  scale_y_continuous(
    limits = c(0, 1),
    labels = scales::percent
  ) +
  labs(
    x      = "Years",
    y      = "Grade probability",
    colour = "AR Grade",
    title  = "AR Grade — Before vs. After Repair"
  ) +
  hvti_theme("manuscript")
```

![](sas-migration-guide_files/figure-html/np-ordinal-multi-example-1.png)

#### Ordinal phase independence

**Port:** `tp.np.tr.ivecho.independence.sas`

To examine a single grade in isolation, filter the long-format curve
before passing it to the function:

``` r
dat_ind    <- sample_nonparametric_ordinal_data(n = 800)
pts_ind    <- sample_nonparametric_ordinal_points(n = 800)
grade_2    <- dat_ind[dat_ind$grade == "Grade 2", ]
dp_grade_2 <- pts_ind[pts_ind$grade == "Grade 2", ]

nonparametric_ordinal_plot(
  grade_2,
  grade_col   = "grade",
  data_points = dp_grade_2
) +
  scale_colour_manual(values = c("Grade 2" = "#CC0000")) +
  scale_x_continuous(breaks = seq(0, 5, 1)) +
  scale_y_continuous(
    limits = c(0, 0.5),
    labels = scales::percent
  ) +
  labs(
    x     = "Years after operation",
    y     = "Probability",
    title = "Probability of TR Grade 2"
  ) +
  hvti_theme("manuscript")
```

![](sas-migration-guide_files/figure-html/np-ordinal-independence-example-1.png)

#### Ordinal phases

**Port:** `tp.np.tr.ivecho.u.phases.sas`

Phase-decomposed ordinal plots combine phase labels with grade colours.
Create the figure by plotting grade-specific curves and annotating early
vs. late phase regions:

``` r
dat_ph <- sample_nonparametric_ordinal_data(n = 800, seed = 7)

nonparametric_ordinal_plot(dat_ph, grade_col = "grade") +
  annotate("rect",
    xmin = 0, xmax = 2,  ymin = -Inf, ymax = Inf,
    fill = "steelblue", alpha = 0.07
  ) +
  annotate("text",
    x = 1, y = 0.95, label = "Early\nphase",
    size = 3, colour = "steelblue", fontface = "italic"
  ) +
  annotate("rect",
    xmin = 2, xmax = 5, ymin = -Inf, ymax = Inf,
    fill = "tomato", alpha = 0.07
  ) +
  annotate("text",
    x = 3.5, y = 0.95, label = "Late\nphase",
    size = 3, colour = "tomato", fontface = "italic"
  ) +
  scale_x_continuous(breaks = 0:5) +
  scale_y_continuous(labels = scales::percent) +
  labs(
    x      = "Years after operation",
    y      = "Grade probability",
    colour = "TR Grade",
    title  = "TR Grade — Early and Late Phase"
  ) +
  hvti_theme("manuscript")
```

![](sas-migration-guide_files/figure-html/np-ordinal-phases-example-1.png)

------------------------------------------------------------------------

## Survival analysis (`tp.ac.dead.*`, `tp.cp.dead.*`)

**Ports:** `tp.ac.dead.sas`, `tp.cp.dead.sas`

**R equivalent:**
[`survival_curve()`](https://ehrlinger.github.io/hvtiPlotR/reference/survival_curve.md)

[`survival_curve()`](https://ehrlinger.github.io/hvtiPlotR/reference/survival_curve.md)
wraps `survfit()` from the **survival** package and returns a single
bare ggplot for the selected `plot_type` (default `"survival"`). All
five plots matching the SAS `%kaplan` / `%nelsont` macro output flags
(`PLOTS`, `PLOTC`, `PLOTH`, `PLOTL`) plus tidy data frames are attached
as attributes (e.g., `attr(result, "km_data")`).

``` r
dta    <- sample_survival_data(n = 500, seed = 42)
result <- survival_curve(dta)

# Kaplan–Meier survival (PLOTS) — result IS the bare ggplot
result +
  scale_y_continuous(
    breaks = seq(0, 100, 20),
    labels = function(x) paste0(x, "%")
  ) +
  scale_x_continuous(breaks = seq(0, 20, 5)) +
  coord_cartesian(xlim = c(0, 20), ylim = c(0, 100)) +
  labs(
    x     = "Years after operation",
    y     = "Survival (%)",
    title = "Freedom from Death"
  ) +
  hvti_theme("manuscript")

# Cumulative hazard (PLOTC)
survival_curve(dta, plot_type = "cumhaz") +
  labs(x = "Years", y = "Cumulative Hazard") +
  hvti_theme("manuscript")

# Hazard rate (PLOTH)
survival_curve(dta, plot_type = "hazard") +
  labs(x = "Years", y = "Instantaneous Hazard") +
  hvti_theme("manuscript")

# Log-log survival (PH check)
survival_curve(dta, plot_type = "loglog") +
  labs(x = "log(Years)", y = "log(-log S(t))") +
  hvti_theme("manuscript")

# Integrated survivorship (PLOTL)
survival_curve(dta, plot_type = "life") +
  labs(x = "Years", y = "Restricted Mean Survival (years)") +
  hvti_theme("manuscript")

# Access the KM data, risk table, and report table via attr()
attr(result, "km_data")
attr(result, "risk_table")
attr(result, "report_table")
```

#### SAS → R argument mapping

| SAS `%kaplan` option | R argument                | Notes                              |
|----------------------|---------------------------|------------------------------------|
| `data=`              | `data`                    | Patient-level data frame           |
| `time=`              | `time_col`                | Time-to-event column name          |
| `event=`             | `event_col`               | Event indicator column (1 = event) |
| `group=`             | `group_col`               | Stratification variable            |
| `method=kaplan`      | `method = "kaplan-meier"` | Default                            |
| `method=nelsont`     | `method = "nelson-aalen"` | Fleming–Harrington                 |
| `alpha=0.05`         | `conf_level = 0.95`       | Default is 0.95                    |
| `tp=0 1 2 3 5 7 10`  | `report_times`            | Table time points                  |

------------------------------------------------------------------------

## Goodness of follow-up (`tp.dp.gfup.R`)

**Port:** `tp.dp.gfup.R`

**R equivalent:**
[`goodness_followup()`](https://ehrlinger.github.io/hvtiPlotR/reference/goodness_followup.md)

``` r
dta <- sample_goodness_followup_data(n = 300)

goodness_followup(dta) +
  labs(title = "Goodness of Follow-Up") +
  hvti_theme("manuscript")
```

------------------------------------------------------------------------

## Covariate balance (`tp.lp.propen.cov_balance.R`)

**Port:** `tp.lp.propen.cov_balance.R`

**R equivalent:**
[`covariate_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/covariate_balance.md)

The SAS export arrives wide (one column per time-point). Reshape to long
format before calling
[`covariate_balance()`](https://ehrlinger.github.io/hvtiPlotR/reference/covariate_balance.md).
Pass `var_levels` to control the bottom-to-top display order of
covariates (matches `ylabel` in the original script).

``` r
# Reshape wide → long (mirrors the original script)
ylabel <- c(
  "Cardiac Output", "BAV", "Cardiac Index", "NYHA -Functional Class",
  "COPD-Oxy", "Date of Surg", "Creatinine", "Age", "CAD",
  "Female", "LV PWT", "Mismatch", "HTN", "PVD", "Sinitibular Jcn: diam"
)

names(dta) <- c("variable", "Before match", "After match")

dta_long <- reshape(
  dta,
  direction = "long",
  varying   = c("Before match", "After match"),
  v.names   = "std_diff",
  timevar   = "group",
  times     = c("Before match", "After match"),
  idvar     = "variable"
)

n_vars <- length(ylabel)

stdifPlot <- covariate_balance(
  data         = dta_long,
  variable_col = "variable",
  group_col    = "group",
  std_diff_col = "std_diff",
  var_levels   = ylabel
) +
  scale_color_manual(
    values = c("Before match" = "red4", "After match" = "blue3"),
    name   = NULL
  ) +
  scale_shape_manual(
    values = c("Before match" = 17L, "After match" = 15L),
    name   = NULL
  ) +
  scale_x_continuous(limits = c(-40, 30), breaks = seq(-40, 30, 10)) +
  labs(x = "Standardized difference: SAVR - TF:TAVR (%)", y = "") +
  annotate("text", x = -30, y = 0,      label = "More likely TF-TAVR", size = 4.5) +
  annotate("text", x =  22, y = n_vars, label = "More likely SAVR",    size = 4.5) +
  theme(legend.position = c(0.20, 0.935)) +
  hvti_theme("manuscript")

ggsave(here::here("graphs", "lp_cov-balance-SAVR_TF-TAVR.pdf"),
       plot = stdifPlot, height = 7, width = 8)
```

------------------------------------------------------------------------

## Alluvial flow (`tp.dp.female_bicus_preAR_sankey.R`)

**Port:** `tp.dp.female_bicus_preAR_sankey.R`

**R equivalent:**
[`alluvial_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/alluvial_plot.md)

``` r
dta <- sample_alluvial_data(n = 200)

alluvial_plot(dta, show_labels = TRUE) +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Patient Flow Between States") +
  hvti_theme("manuscript")
```

------------------------------------------------------------------------

## Cluster stability Sankey (PAM analysis)

**Source:** PAM clustering analysis pipeline (R script using `ggsankey`)

**R equivalent:**
[`cluster_sankey_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/cluster_sankey_plot.md)

[`cluster_sankey_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/cluster_sankey_plot.md)
draws a Sankey diagram showing how patients flow between letter-labelled
clusters as the number of clusters K increases from 2 to 9. Each column
is one K; flow bands show assignment changes between consecutive K
values; node labels show cluster letter + patient count.

The original code used
[`ggsankey::make_long()`](https://rdrr.io/pkg/ggsankey/man/make_long.html)
with hard-coded column names and ordering vectors. The R port accepts
any cluster columns and ordering via `cluster_cols` and `node_levels`
arguments.

**Requires `ggsankey`** (install from GitHub):

``` r
remotes::install_github("davidsjoberg/ggsankey")
```

#### SAS/R workflow → R equivalent

| Original step                                         | R equivalent                                                                                      |
|-------------------------------------------------------|---------------------------------------------------------------------------------------------------|
| `sid_dta$C2 <- factor(...)` with `gr2_names` ordering | Factor levels set by `node_levels` argument                                                       |
| `make_long(C2, …, C9)`                                | `.make_sankey_long()` (internal)                                                                  |
| `geom_sankey()` + `geom_sankey_label()`               | [`cluster_sankey_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/cluster_sankey_plot.md) |
| `brewer.pal(9, "Set1")[c(2,6,8,4,3,5,7,1,9)]`         | Default `node_colours`                                                                            |

``` r
dta_san <- sample_cluster_sankey_data(n = 300, seed = 42)

cluster_sankey_plot(dta_san) +
  labs(title = "Cluster Stability: K = 2 to 9") +
  hvti_theme("manuscript")
```

To reproduce the original analysis with patient-level cluster
assignments:

``` r
# Build a data frame with one row per patient, columns C2..C9 (factor)
grp_dta <- data.frame(
  C2 = factor(pm2clusters_labels, levels = gr2_names),
  C3 = factor(pm3clusters_labels, levels = gr3_names),
  # ... etc.
  C9 = factor(pm9clusters_labels, levels = gr9_names)
)

cluster_sankey_plot(
  grp_dta,
  cluster_cols = paste0("C", 2:9),
  node_levels  = gr9_names
) +
  labs(x = NULL) +
  hvti_theme("manuscript")
```

------------------------------------------------------------------------

## UpSet plot (`tp.complexUpset.R`)

**Port:** `tp.complexUpset.R`

**R equivalent:**
[`upset_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/upset_plot.md)

``` r
sets <- c("CABG", "Valve", "MAZE", "Aorta")
dta  <- sample_upset_data(n = 300, sets = sets)

upset_plot(data = dta, intersect = sets)
```

------------------------------------------------------------------------

## Spaghetti / individual trajectories (`tp.dp.spaghetti.echo.R`)

**Port:** `tp.dp.spaghetti.echo.R`

**R equivalent:**
[`spaghetti_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/spaghetti_plot.md)

The template covers nine figures across three echo outcomes (AV mean
gradient, AV area, DVI) in unstratified and sex-stratified variants,
plus an ordinal MV regurgitation grade plot (plot_9).

### Unstratified — AV mean gradient full range (plot_1)

``` r
dta <- sample_spaghetti_data(n_patients = 150, max_obs = 6)

spaghetti_plot(dta) +
  scale_x_continuous(breaks = seq(0, 5, 1)) +
  scale_y_continuous(breaks = seq(0, 80, 20)) +
  coord_cartesian(xlim = c(0, 5), ylim = c(0, 80)) +
  labs(x = "Years", y = "AV Mean Gradient (mmHg)") +
  hvti_theme("manuscript")
```

### Unstratified — zoomed y-axis (plot_3)

``` r
spaghetti_plot(dta) +
  scale_x_continuous(breaks = seq(0, 5, 1)) +
  scale_y_continuous(breaks = seq(0, 30, 10)) +
  coord_cartesian(xlim = c(0, 5), ylim = c(0, 30)) +
  labs(x = "Years", y = "AV Mean Gradient (mmHg)") +
  hvti_theme("manuscript")
```

### Stratified by sex (plot_2 / plot_4)

Template uses `values=c("red", "blue")`; modernised equivalents below.

``` r
spaghetti_plot(dta, colour_col = "group") +
  scale_colour_manual(
    values = c(Female = "firebrick", Male = "steelblue"),
    name   = NULL
  ) +
  scale_x_continuous(breaks = seq(0, 5, 1)) +
  scale_y_continuous(breaks = seq(0, 80, 20)) +
  coord_cartesian(xlim = c(0, 5), ylim = c(0, 80)) +
  labs(x = "Years", y = "AV Mean Gradient (mmHg)") +
  hvti_theme("manuscript")
```

### AV area y-scale (plot_5 / plot_6)

``` r
spaghetti_plot(dta, colour_col = "group") +
  scale_colour_manual(
    values = c(Female = "firebrick", Male = "steelblue"),
    name   = NULL
  ) +
  scale_x_continuous(breaks = seq(0, 5, 1)) +
  scale_y_continuous(breaks = seq(0, 5, 1)) +
  coord_cartesian(xlim = c(0, 5), ylim = c(0, 5)) +
  labs(x = "Years", y = "AV Area (EOA) (cm\u00b2)") +
  hvti_theme("manuscript")
```

### DVI y-scale (plot_7 / plot_8)

``` r
spaghetti_plot(dta, colour_col = "group") +
  scale_colour_manual(
    values = c(Female = "firebrick", Male = "steelblue"),
    name   = NULL
  ) +
  scale_x_continuous(breaks = seq(0, 5, 1)) +
  scale_y_continuous(breaks = seq(0, 1.25, 0.25)) +
  coord_cartesian(xlim = c(0, 5), ylim = c(0, 1.25)) +
  labs(x = "Years", y = "DVI") +
  hvti_theme("manuscript")
```

### Ordinal y-axis — MV regurgitation grade (plot_9)

``` r
dta_ord       <- dta
dta_ord$value <- round(pmin(3, pmax(0, dta$value / 12)))
levels(dta_ord$group) <- c("Early", "Late")

spaghetti_plot(
  dta_ord,
  colour_col = "group",
  y_labels   = c(None = 0, Mild = 1, Moderate = 2, Severe = 3)
) +
  scale_colour_manual(
    values = c(Early = "steelblue", Late = "red2"),
    name   = NULL
  ) +
  scale_x_continuous(breaks = seq(0, 6, 1)) +
  coord_cartesian(xlim = c(0, 6), ylim = c(0, 3)) +
  labs(x = "Years after Procedure", y = "MV Regurgitation Grade") +
  hvti_theme("manuscript")
```

------------------------------------------------------------------------

## Trends over time (`tp.*.trends.*`)

**Ports:** `tp.rp.trends.sas`, `tp.lp.trends.sas`,
`tp.lp.trends.age.sas`, `tp.lp.trends.polytomous.sas`, `tp.dp.trends.R`

**R equivalent:**
[`trends_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/trends_plot.md)

### tp.rp.trends.sas — cases/year and age (1968–2000 by 4)

``` r
one <- sample_trends_data(n = 600, year_range = c(1968L, 2000L), groups = NULL)

# Cases/year: axisy order=(0 to 10 by 2)
trends_plot(one, group_col = NULL) +
  scale_x_continuous(limits = c(1968, 2000), breaks = seq(1968, 2000, 4)) +
  scale_y_continuous(limits = c(0, 10),      breaks = seq(0, 10, 2)) +
  labs(x = "Year", y = "Cases/year") +
  hvti_theme("manuscript")

# Age: axisy order=(30 to 70 by 10)
trends_plot(one, group_col = NULL) +
  scale_x_continuous(limits = c(1968, 2000), breaks = seq(1968, 2000, 4)) +
  scale_y_continuous(limits = c(30, 70),     breaks = seq(30, 70, 10)) +
  labs(x = "Year", y = "Age (years)") +
  hvti_theme("manuscript")
```

### tp.lp.trends.sas — binary % outcomes (1970–2000 by 10, y 0–100 by 10)

Multiple outcomes on one figure. CGM version:
`axisx order=(1970 to 2000 by 10)`, `axisy order=(0 to 100 by 20)`.

``` r
dta_lp <- sample_trends_data(
  n = 800, year_range = c(1970L, 2000L),
  groups = c("Shock %", "Pre-op IABP %", "Inotropes %"))

trends_plot(dta_lp) +
  scale_colour_manual(
    values = c("Shock %" = "steelblue", "Pre-op IABP %" = "firebrick",
               "Inotropes %" = "forestgreen"), name = NULL) +
  scale_shape_manual(
    values = c("Shock %" = 16L, "Pre-op IABP %" = 15L, "Inotropes %" = 17L),
    name = NULL) +
  scale_x_continuous(limits = c(1970, 2000), breaks = seq(1970, 2000, 10)) +
  scale_y_continuous(limits = c(0, 100),     breaks = seq(0, 100, 10)) +
  coord_cartesian(xlim = c(1970, 2000), ylim = c(0, 100)) +
  labs(x = "Year", y = "Percent (%)") +
  hvti_theme("manuscript")
```

### tp.lp.trends.age.sas — age on x-axis (25–85 by 10, y 0–100 by 20)

``` r
dta_age <- sample_trends_data(
  n = 600, year_range = c(25L, 85L),
  groups = c("Repair %", "Bioprosthesis %"), seed = 7L)

trends_plot(dta_age) +
  scale_colour_manual(
    values = c("Repair %" = "steelblue", "Bioprosthesis %" = "firebrick"),
    name = NULL) +
  scale_x_continuous(limits = c(25, 85), breaks = seq(25, 85, 10)) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20)) +
  coord_cartesian(xlim = c(25, 85), ylim = c(0, 100)) +
  labs(x = "Age (years)", y = "Percent (%)") +
  hvti_theme("manuscript")
```

### tp.lp.trends.polytomous.sas — repair types (1990–1999 by 1, y 0–100 by 10)

``` r
dta_poly <- sample_trends_data(
  n = 800, year_range = c(1990L, 1999L),
  groups = c("CE", "Cosgrove", "Periguard", "DeVega"), seed = 5L)

trends_plot(dta_poly) +
  scale_colour_manual(
    values = c(CE = "steelblue", Cosgrove = "firebrick",
               Periguard = "forestgreen", DeVega = "goldenrod3"),
    name = "Repair type") +
  scale_shape_manual(
    values = c(CE = 15L, Cosgrove = 19L, Periguard = 17L, DeVega = 18L),
    name = "Repair type") +
  scale_x_continuous(limits = c(1990, 1999), breaks = seq(1990, 1999, 1)) +
  scale_y_continuous(limits = c(0, 100),     breaks = seq(0, 100, 10)) +
  coord_cartesian(xlim = c(1990, 1999), ylim = c(0, 100)) +
  labs(x = "Year", y = "Percent (%)") +
  hvti_theme("manuscript")
```

### tp.dp.trends.R — LV mass index (1995–2015 by 5, y 0–200 by 50)

``` r
dta_lv <- sample_trends_data(n = 800, year_range = c(1995L, 2015L),
                              groups = NULL, seed = 3L)

trends_plot(dta_lv, group_col = NULL) +
  scale_x_continuous(limits = c(1995, 2015), breaks = seq(1995, 2015, 5)) +
  scale_y_continuous(limits = c(0, 200),     breaks = seq(0, 200, 50)) +
  coord_cartesian(xlim = c(1995, 2015), ylim = c(0, 200)) +
  labs(x = "Years", y = "LV Mass Index") +
  hvti_theme("manuscript")
```

### tp.dp.trends.R — hospital LOS with annotation (1985–2015 by 5, y 0–20 by 5)

``` r
dta_los <- sample_trends_data(n = 800, year_range = c(1985L, 2015L),
                               groups = NULL, seed = 11L)

trends_plot(dta_los, group_col = NULL) +
  scale_x_continuous(limits = c(1985, 2015), breaks = seq(1985, 2015, 5)) +
  scale_y_continuous(limits = c(0, 20),      breaks = seq(0, 20, 5)) +
  coord_cartesian(xlim = c(1985, 2015), ylim = c(0, 20)) +
  annotate("text", x = 1995, y = 18,
           label = "Trend: Hospital Length of Stay", size = 4.5) +
  labs(x = "Years", y = "Hospital LOS (Days)") +
  hvti_theme("manuscript")
```

------------------------------------------------------------------------

## Longitudinal patient counts (`tp.dp.longitudinal_patients_measures.R`)

**Port:** `tp.dp.longitudinal_patients_measures.R`

**R equivalent:**
[`longitudinal_counts_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/longitudinal_counts_plot.md)

``` r
dta <- sample_longitudinal_counts_data(n_patients = 150)

longitudinal_counts_plot(dta) +
  scale_x_continuous(breaks = 0:10) +
  labs(
    x     = "Years after operation",
    y     = "Patients with measurement",
    title = "Follow-Up Echocardiogram Availability"
  ) +
  hvti_theme("manuscript")
```

------------------------------------------------------------------------

## Mirror histogram (propensity score)

**R equivalents:** `tp.lp.mirror-histogram_SAVR-TF-TAVR.R`
(binary-match), `tp.lp.mirror_histo_before_after_wt.R` (weighted IPTW)

Both scripts are superseded by
[`mirror_histogram()`](https://ehrlinger.github.io/hvtiPlotR/reference/mirror_histogram.md).
The function returns a bare ggplot object directly. Diagnostics are
printed as a message and attached as `attr(mhist, "diagnostics")`;
working data as `attr(mhist, "data")`. Compose scales, annotations, and
theme with the usual `+` operator.

### Binary-match mode (`tp.lp.mirror-histogram_SAVR-TF-TAVR.R`)

``` r
dta   <- sample_mirror_histogram_data(n = 400, separation = 1.5)
mhist <- mirror_histogram(dta)   # defaults: prob_t / tavr / match

mhist +
  scale_fill_manual(
    values = c(
      before_g0  = "white",  matched_g0 = "green1",
      before_g1  = "white",  matched_g1 = "green4"
    ),
    guide = "none"
  ) +
  scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, 10)) +
  annotate("text", x = 20, y =  100, label = "SAVR",    size = 7) +
  annotate("text", x = 20, y = -100, label = "TF-TAVR", size = 7) +
  labs(x = "Propensity Score (%)", y = "Number of Patients") +
  hvti_theme("manuscript")
```

### Weighted IPTW mode (`tp.lp.mirror_histo_before_after_wt.R`)

``` r
dta      <- sample_mirror_histogram_data(n = 400, add_weights = TRUE)
mhist_wt <- mirror_histogram(
  dta,
  group_labels = c("Limited", "Extended"),
  weight_col   = "mt_wt"
)

mhist_wt +
  scale_fill_manual(
    values = c(
      before_g0   = "white", weighted_g0 = "blue",
      before_g1   = "white", weighted_g1 = "red"
    ),
    guide = "none"
  ) +
  scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, 10)) +
  annotate("text", x = 30, y =  150, label = "Limited",  color = "blue", size = 5) +
  annotate("text", x = 30, y = -70,  label = "Extended", color = "red",  size = 5) +
  labs(x = "Propensity Score (%)", y = "#") +
  hvti_theme("manuscript")
```

------------------------------------------------------------------------

## Stacked histogram

**R equivalent:**
[`stacked_histogram()`](https://ehrlinger.github.io/hvtiPlotR/reference/stacked_histogram.md)

``` r
dta <- sample_stacked_histogram_data()

stacked_histogram(dta) +
  scale_fill_brewer(palette = "Set1") +
  labs(
    x     = "Operation year",
    y     = "Count",
    fill  = "Group",
    title = "Annual Case Volume by Group"
  ) +
  hvti_theme("manuscript")
```

------------------------------------------------------------------------

## Using themes

All plot functions return an unstyled ggplot object. Add a theme as the
final layer:

| Context                | Call                       | Equivalent SAS device              |
|------------------------|----------------------------|------------------------------------|
| Dark PowerPoint slide  | `hvti_theme("dark_ppt")`   | `device=ppt`                       |
| Light PowerPoint slide | `hvti_theme("light_ppt")`  | `device=ppt` with white background |
| Journal manuscript     | `hvti_theme("manuscript")` | `device=eps` / PDF                 |
| Conference poster      | `hvti_theme("poster")`     | Large-font poster                  |

You can pass `base_size` to any theme to scale all text simultaneously:

``` r
p + hvti_theme("manuscript", base_size = 10)   # smaller text for double-column
p + hvti_theme("poster",     base_size = 24)   # larger text for A0 poster
```

------------------------------------------------------------------------

## Saving figures

### PowerPoint

[`save_ppt()`](https://ehrlinger.github.io/hvtiPlotR/reference/save_ppt.md)
inserts ggplot objects into a PowerPoint file as **editable DrawingML
vector graphics** via the `officer` and `rvg` packages — shapes, lines,
and text remain individually selectable in PowerPoint after export. The
first argument is `object` (not `plot`); the output path is `powerpoint`
(not `file` or `filename`).

``` r
# Locate the bundled Cleveland Clinic slide template
template <- system.file("ClevelandClinic.pptx", package = "hvtiPlotR")

# Single slide — apply a PPT theme before saving
p_ppt <- p +
  scale_colour_manual(values = c("steelblue"), guide = "none") +
  scale_fill_manual(values   = c("steelblue"), guide = "none") +
  labs(x = "Years", y = "Prevalence (%)") +
  hvti_theme("dark_ppt")

save_ppt(
  object       = p_ppt,
  template     = template,
  powerpoint   = "figures/afib_prevalence.pptx",
  slide_titles = "AF Prevalence over Time"
)

# Multiple plots — one slide per figure in a single call
save_ppt(
  object       = list(fig1 = p_binary, fig2 = p_multi),
  template     = template,
  powerpoint   = "figures/np_curves.pptx",
  slide_titles = c("Binary Outcome", "Multi-group Comparison")
)
```

### PDF / TIFF for journals

``` r
ggsave("figures/afib_prevalence.pdf",  p, width = 3.5, height = 3.5, units = "in")
ggsave("figures/afib_prevalence.tiff", p, width = 3.5, height = 3.5,
       units = "in", dpi = 600)
```

------------------------------------------------------------------------

## Parametric hazard/survival (`tp.hs.*`)

**Ports:** `tp.hs.dead.setup.sas`, `tp.hs.dead_uses_setup.sas`,
`tp.hs.dead.procedure.tdepth.sas`, `tp.hs.dead.conditional.setup.sas`,
`tp.hs.dead.conditional.uses_setup.sas`,
`tp.hs.dead.compare_benefit.setup.sas`,
`tp.hs.uslife_estimates_generate_stratify_.age.sas`,
`tp.hs.uslife_generates_matched_estimates.sas`

**R equivalents:**
[`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md),
[`survival_difference_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/survival_difference_plot.md)

The `tp.hs.*` family extends `tp.hp.dead.*` by using the `%hazpred`
macro to generate patient-specific parametric survival predictions from
a fitted multivariable hazard model. The *setup* templates compute and
store:

- **Cumulative hazard per patient** at last follow-up (for observed vs.
  expected goodness-of-fit tests via `%chisqgf`).
- **Individual survivorship curves** on a fine time grid (for mean-curve
  aggregation with `PROC SUMMARY`).

Subsequent *use* templates stratify the aggregated mean curves by a
covariate and overlay Kaplan-Meier estimates from `%kaplan`. The
resulting SAS datasets map directly to
[`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md)
in R:

| SAS dataset                                  | Columns used                       | R source                                                                                                  |
|----------------------------------------------|------------------------------------|-----------------------------------------------------------------------------------------------------------|
| `means` (from `PROC SUMMARY` over `predict`) | `SSURVIV`, `SCLLSURV`, `SCLUSURV`  | [`sample_hazard_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_data.md)           |
| `plout` (from `%kaplan`)                     | `CUM_SURV`, `CL_LOWER`, `CL_UPPER` | [`sample_hazard_empirical()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_empirical.md) |
| `est.uslife_*` (from `%usmatchd`)            | `SMATCHED`                         | [`sample_life_table()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_life_table.md)             |

### Parametric survival with KM overlay

Reproduces the core figure from `tp.hs.dead_uses_setup.sas` and
`tp.hs.dead.procedure.tdepth.sas`: a mean parametric survival curve
(solid line with confidence band) overlaid with Kaplan-Meier empirical
estimates (symbols with error bars).

``` r
dat_hp <- sample_hazard_data(n = 500, time_max = 10)
emp_hp <- sample_hazard_empirical(n = 500, time_max = 10, n_bins = 6)

hazard_plot(
  dat_hp,
  estimate_col  = "survival",
  lower_col     = "surv_lower",
  upper_col     = "surv_upper",
  empirical     = emp_hp,
  emp_lower_col = "lower",
  emp_upper_col = "upper"
) +
  scale_colour_manual(values = c("steelblue"), guide = "none") +
  scale_fill_manual(values = c("steelblue"), guide = "none") +
  scale_x_continuous(limits = c(0, 10), breaks = 0:10) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 10),
                     labels = function(x) paste0(x, "%")) +
  labs(x = "Years after Operation", y = "Survival (%)") +
  hvti_theme("manuscript")
```

### Stratified by covariate

`tp.hs.dead.procedure.tdepth.sas` overlays curves for depth-of-invasion
groups (`tdepth = 1, 2, 3`). Pass `group_col` to
[`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md)
and supply matched
[`sample_hazard_data()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_data.md)
/
[`sample_hazard_empirical()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_hazard_empirical.md)
calls with a `groups` vector whose names become the legend labels.

``` r
dat_strat <- sample_hazard_data(
  n = 500, time_max = 10,
  groups = c("pT1" = 0.4, "pT2" = 1.0, "pT3" = 1.8)
)
emp_strat <- sample_hazard_empirical(
  n = 500, time_max = 10, n_bins = 5,
  groups = c("pT1" = 0.4, "pT2" = 1.0, "pT3" = 1.8)
)

hazard_plot(
  dat_strat,
  estimate_col  = "survival",
  lower_col     = "surv_lower",
  upper_col     = "surv_upper",
  group_col     = "group",
  empirical     = emp_strat,
  emp_lower_col = "lower",
  emp_upper_col = "upper"
) +
  scale_colour_manual(
    values = c("pT1" = "steelblue", "pT2" = "forestgreen", "pT3" = "firebrick"),
    name   = NULL
  ) +
  scale_fill_manual(
    values = c("pT1" = "steelblue", "pT2" = "forestgreen", "pT3" = "firebrick"),
    guide  = "none"
  ) +
  scale_x_continuous(limits = c(0, 10), breaks = 0:10) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 10),
                     labels = function(x) paste0(x, "%")) +
  labs(x = "Years after Operation", y = "Survival (%)") +
  hvti_theme("manuscript")
```

### Conditional survival after hospital discharge

`tp.hs.dead.conditional.setup.sas` computes individual survivorship
curves starting from the time of hospital discharge rather than the
operation date. The conditional survival `S(t | discharge)` is
`S(t) / S(t_discharge)` for each patient. In R, the same
[`hazard_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/hazard_plot.md)
call is used; only the x-axis label and data preparation differ.

``` r
dat_cond <- sample_hazard_data(n = 500, time_max = 10)
emp_cond <- sample_hazard_empirical(n = 500, time_max = 10, n_bins = 6)

hazard_plot(
  dat_cond,
  estimate_col  = "survival",
  lower_col     = "surv_lower",
  upper_col     = "surv_upper",
  empirical     = emp_cond,
  emp_lower_col = "lower",
  emp_upper_col = "upper"
) +
  scale_colour_manual(values = c("steelblue"), guide = "none") +
  scale_fill_manual(values = c("steelblue"), guide = "none") +
  scale_x_continuous(limits = c(0, 10), breaks = 0:10) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 10),
                     labels = function(x) paste0(x, "%")) +
  labs(x = "Years after Discharge", y = "Survival after Discharge (%)") +
  hvti_theme("manuscript")
```

### US life-table overlay

`tp.hs.uslife_*` templates call `%usmatchd` to generate age-, sex-, and
race-matched US population life-table survival curves for each patient.
[`sample_life_table()`](https://ehrlinger.github.io/hvtiPlotR/reference/sample_life_table.md)
provides representative matched curves stratified by age group for use
in R examples.

``` r
dat_age <- sample_hazard_data(
  n = 600, time_max = 10,
  groups = c("<60" = 0.4, "60\u201385" = 1.0, "\u226585" = 2.0)
)
emp_age <- sample_hazard_empirical(
  n = 600, time_max = 10, n_bins = 6,
  groups = c("<60" = 0.4, "60\u201385" = 1.0, "\u226585" = 2.0)
)
lt <- sample_life_table(
  age_groups = c("<60", "60\u201385", "\u226585"),
  age_mids   = c(50, 72, 88),
  time_max   = 10
)

hazard_plot(
  dat_age,
  estimate_col     = "survival",
  lower_col        = "surv_lower",
  upper_col        = "surv_upper",
  group_col        = "group",
  empirical        = emp_age,
  emp_lower_col    = "lower",
  emp_upper_col    = "upper",
  reference        = lt,
  ref_estimate_col = "survival",
  ref_group_col    = "group"
) +
  scale_colour_manual(
    values = c("<60" = "steelblue", "60\u201385" = "forestgreen",
               "\u226585" = "firebrick"),
    name   = "Age group"
  ) +
  scale_fill_manual(
    values = c("<60" = "steelblue", "60\u201385" = "forestgreen",
               "\u226585" = "firebrick"),
    guide  = "none"
  ) +
  scale_x_continuous(limits = c(0, 10), breaks = 0:10) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20),
                     labels = function(x) paste0(x, "%")) +
  labs(x = "Years after Operation", y = "Survival (%)",
       caption = "Dashed lines: US population life table") +
  hvti_theme("manuscript")
```

### Treatment benefit distribution

`tp.hs.dead.compare_benefit.setup.sas` computes, for each patient, the
difference in predicted survival at a fixed time point (5 years) under
two treatment arms (e.g. ASA vs. no ASA). The distribution of these
individual differences shows who benefits and by how much. Use
[`survival_difference_plot()`](https://ehrlinger.github.io/hvtiPlotR/reference/survival_difference_plot.md)
to plot the mean curve over time.

``` r
diff_dat <- sample_survival_difference_data(
  n      = 500,
  groups = c("No ASA" = 1.0, "ASA" = 0.75)
)

survival_difference_plot(
  diff_dat,
  lower_col = "diff_lower",
  upper_col = "diff_upper"
) +
  scale_colour_manual(values = c("steelblue"), guide = "none") +
  scale_fill_manual(values = c("steelblue"), guide = "none") +
  ggplot2::geom_hline(yintercept = 0, linetype = "dashed",
                      colour = "grey50") +
  scale_x_continuous(limits = c(0, 10), breaks = 0:10) +
  scale_y_continuous(limits = c(-5, 40),
                     labels = function(x) paste0(x, "%")) +
  labs(x = "Years", y = "Survival Difference (%)") +
  hvti_theme("manuscript")
```

------------------------------------------------------------------------

## Adding new ports

As additional SAS templates are ported to R, update this guide:

1.  **Add a row** to the lookup table at the top of this file with the
    SAS template name, family prefix, R function, and section anchor.

2.  **Add a section** following the existing pattern: name the port,
    describe the SAS workflow, show the R equivalent with a runnable
    example, and document any column name mapping differences.

3.  **Export the new R function** by adding `@export` to its roxygen
    block and running
    [`devtools::document()`](https://devtools.r-lib.org/reference/document.html)
    to regenerate `NAMESPACE`.

4.  **Update `DESCRIPTION`** if a new package dependency is required.

Templates currently planned for porting:

- `tp.ce.states.*` competing-events / state-occupancy → (pending)
- `tp.gp.*` grouped longitudinal ordinal models → (pending)

------------------------------------------------------------------------

## Session info

``` r
sessionInfo()
```

    R version 4.5.3 (2026-03-11)
    Platform: x86_64-pc-linux-gnu
    Running under: Ubuntu 24.04.3 LTS

    Matrix products: default
    BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3
    LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0

    locale:
     [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8
     [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8
     [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C
    [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C

    time zone: UTC
    tzcode source: system (glibc)

    attached base packages:
    [1] stats     graphics  grDevices utils     datasets  methods   base

    other attached packages:
    [1] ggplot2_4.0.2        hvtiPlotR_2.0.0.9002

    loaded via a namespace (and not attached):
     [1] generics_0.1.4          tidyr_1.3.2             fontLiberation_0.1.0
     [4] xml2_1.5.2              lattice_0.22-9          digest_0.6.39
     [7] magrittr_2.0.4          evaluate_1.0.5          grid_4.5.3
    [10] RColorBrewer_1.1-3      fastmap_1.2.0           Matrix_1.7-4
    [13] jsonlite_2.0.0          zip_2.3.3               survival_3.8-6
    [16] purrr_1.2.1             scales_1.4.0            fontBitstreamVera_0.1.1
    [19] textshaping_1.0.5       cli_3.6.5               rlang_1.1.7
    [22] fontquiver_0.2.1        splines_4.5.3           withr_3.0.2
    [25] yaml_2.3.12             otel_0.2.0              gdtools_0.5.0
    [28] tools_4.5.3             officer_0.7.3           uuid_1.2-2
    [31] dplyr_1.2.0             colorspace_2.1-2        ComplexUpset_1.3.3
    [34] vctrs_0.7.2             R6_2.6.1                lifecycle_1.0.5
    [37] ragg_1.5.2              pkgconfig_2.0.3         pillar_1.11.1
    [40] gtable_0.3.6            glue_1.8.0              Rcpp_1.1.1
    [43] systemfonts_1.3.2       xfun_0.57               rvg_0.4.1
    [46] tibble_3.3.1            tidyselect_1.2.1        knitr_1.51
    [49] farver_2.1.2            htmltools_0.5.9         patchwork_1.3.2
    [52] labeling_0.4.3          rmarkdown_2.30          ggalluvial_0.12.6
    [55] compiler_4.5.3          S7_0.2.1                askpass_1.2.1
    [58] openssl_2.3.5          
