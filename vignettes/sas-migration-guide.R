## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(
  echo    = TRUE,
  message = FALSE,
  warning = FALSE,
  fig.width  = 7,
  fig.height = 5
)
library(hvtiPlotR)
library(ggplot2)


## ----np-binary-avg-example----------------------------------------------------
dat <- sample_nonparametric_curve_data(
  n            = 500,
  time_max     = 12,
  outcome_type = "probability"
)

# Minimal plot
nonparametric_curve_plot(dat$curve) +
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


## ----np-binary-avg-ci---------------------------------------------------------
nonparametric_curve_plot(
  dat$curve,
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


## ----np-binary-avg-points-----------------------------------------------------
nonparametric_curve_plot(
  dat$curve,
  lower_col   = "lower",
  upper_col   = "upper",
  data_points = dat$data_points
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


## ----np-continuous-example----------------------------------------------------
dat_cont <- sample_nonparametric_curve_data(
  n            = 400,
  time_max     = 10,
  outcome_type = "continuous"
)

nonparametric_curve_plot(
  dat_cont$curve,
  lower_col   = "lower",
  upper_col   = "upper",
  data_points = dat_cont$data_points
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


## ----np-multigroup-example----------------------------------------------------
dat_grp <- sample_nonparametric_curve_data(
  n        = 600,
  time_max = 12,
  groups   = c("Ozaki" = 0.7, "CE-Pericardial" = 1.1, "Homograft" = 1.4)
)

nonparametric_curve_plot(
  dat_grp$curve,
  group_col   = "group",
  lower_col   = "lower",
  upper_col   = "upper",
  data_points = dat_grp$data_points,
  dp_group_col = "group"
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


## ----np-phases-example--------------------------------------------------------
dat_phase <- sample_nonparametric_curve_data(
  n      = 500,
  groups = c("Early phase" = 1.5, "Late phase" = 0.6, "Overall" = 1.0)
)

nonparametric_curve_plot(
  dat_phase$curve,
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


## ----np-bmi-xaxis-------------------------------------------------------------
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


## ----np-ordinal-example-------------------------------------------------------
dat_ord <- sample_nonparametric_ordinal_data(
  n           = 1000,
  time_max    = 5,
  grade_labels = c("None", "Mild", "Moderate", "Severe")
)

nonparametric_ordinal_plot(
  dat_ord$curve,
  grade_col   = "grade",
  data_points = dat_ord$data_points
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


## ----np-ordinal-multi-example-------------------------------------------------
dat_ar1 <- sample_nonparametric_ordinal_data(seed = 1)
dat_ar2 <- sample_nonparametric_ordinal_data(seed = 99)

dat_ar1$curve$scenario <- "Before repair"
dat_ar2$curve$scenario <- "After repair"
combined <- rbind(dat_ar1$curve, dat_ar2$curve)

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


## ----np-ordinal-independence-example------------------------------------------
dat_ind  <- sample_nonparametric_ordinal_data(n = 800)
grade_2  <- dat_ind$curve[dat_ind$curve$grade == "Grade 2", ]
dp_grade_2 <- dat_ind$data_points[dat_ind$data_points$grade == "Grade 2", ]

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


## ----np-ordinal-phases-example------------------------------------------------
dat_ph <- sample_nonparametric_ordinal_data(n = 800, seed = 7)

nonparametric_ordinal_plot(dat_ph$curve, grade_col = "grade") +
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


## ----session-info-------------------------------------------------------------
sessionInfo()

