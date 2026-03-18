## -----------------------------------------------------------------------------
# load required libraries
library("ggplot2") # Plotting environment
if (requireNamespace("hvtiPlotR", quietly = TRUE)) {
  library("hvtiPlotR") # Use installed package when available
} else {
  pkgload::load_all(export_all = FALSE, helpers = FALSE, quiet = TRUE)
}

# Load the example datasets
data(parametric, package = "hvtiPlotR")
data(nonparametric, package = "hvtiPlotR")

# Set a default hvtiPlotR plotting theme
theme_set(hvtiPlotR::hvti_theme("manuscript")) 


## -----------------------------------------------------------------------------
## To reproduce the plot.sas function, line by line.
###-------------
## There are SAS options we will not use here.
#
# %plot(goptions gsfmode=replace, device=pscolor, gaccess=gsasfile end;
ccf_plot <- ggplot()


## -----------------------------------------------------------------------------
###-------------
## Labels are a single command, scales control the axis
#
# labelx l="Years After Randomization", end;
# labely l="Percent in Each Category (ST)", end;
ccf_plot <- ccf_plot +
  labs(x = "Years After Randomization", y = "Percent in Each Category (ST)")


## -----------------------------------------------------------------------------
###-------------
## Labels are a single command, scales control the axis
#
# axisx order=(0 to 5 by 1), minor=none, end;
# axisy order=(0 to 100 by 10), minor=none, end;
ccf_plot <- ccf_plot +
  scale_x_continuous(breaks = seq(0, 5, 1)) +
  scale_y_continuous(breaks = seq(0, 100, 10))



## -----------------------------------------------------------------------------
#| label: fig_4
#| caption: Point Plot
###-------------
## /******NON-PARAMETRIC: SYMBOLS AND CONFIDENCE BARS *******/
##
## Each tuple statement corresponds to one or more geom_ statements
# tuple set=green, symbol=dot, symbsize=1/2, linepe=0, linecl=0,
# ebarsize=3/4, ebar=1,
# x=iv_state, y=sginit, cll=stlinit, clu=stuinit, color=black, end;
ccf_plot <- ccf_plot +
  geom_point(data = nonparametric, aes(x = iv_state, y = sginit))

show(ccf_plot)


## -----------------------------------------------------------------------------
#| label: error_bar_ci
#| caption: Error Bar Plot
# tuple set=green, symbol=circle, symbsize=1/2, linepe=0, linecl=0,
# ebarsize=3/4, ebar=1,
# x=iv_state, y=sgdead1, cll=stldead1, clu=studead1, color=blue, end;
ccf_plot <- ccf_plot +
  geom_point(
    data = nonparametric,
    aes(x = iv_state, y = sgdead1),
    color = "blue",
    shape = 1
  ) +
  geom_errorbar(
    data = nonparametric,
    aes(x = iv_state, ymin = stldead1, ymax = studead1),
    color = "blue",
    width = .1
  )
# tuple set=green, symbol=square, symbsize=1/2, linepe=0, linecl=0,
# ebarsize=3/4, ebar=1,
# x=iv_state, y=sgstrk1, cll=stlstrk1, clu=stustrk1, color=blue, end;
ccf_plot <- ccf_plot +
  geom_point(
    data = nonparametric,
    aes(x = iv_state, y = sgstrk1),
    color = "blue",
    shape = 0
  ) +
  geom_errorbar(
    data = nonparametric,
    aes(x = iv_state, ymin = stlstrk1, ymax = stustrk1),
    color = "blue",
    width = .1
  )
show(ccf_plot)


## -----------------------------------------------------------------------------
#| label: error_lines_ci
#| caption: Line Plot with confidence bands
# /**********PARAMETRIC : SOLID LINES AND CONFIDENCE INTERVALS**********/
# tuple set=all, x=years, y=noinit, cll=clinit, clu=cuinit,
# width=0.5,color=black, end;
ccf_plot <- ccf_plot +
  geom_line(data = parametric, aes(x = years, y = noinit)) +
  geom_line(data = parametric, aes(x = years, y = clinit), linetype = "dashed") +
  geom_line(data = parametric, aes(x = years, y = cuinit), linetype = "dashed")
#
# tuple set=all, x=years, y=nodeath, cll=cldeath, clu=cudeath,
# width=0.5,color=blue, end;
ccf_plot <- ccf_plot +
  geom_line(data = parametric,
            aes(x = years, y = nodeath),
            color = "blue") +
  geom_line(
    data = parametric,
    aes(x = years, y = cldeath),
    linetype = "dashed",
    color = "blue"
  ) +
  geom_line(
    data = parametric,
    aes(x = years, y = cudeath),
    linetype = "dashed",
    color = "blue"
  )
#
# tuple set=all, x=years, y=nostrk, cll=clstrk, clu=custrk,
# linecl=2, width=0.5,color=blue, end;
ccf_plot <- ccf_plot +
  geom_line(data = parametric,
            aes(x = years, y = nostrk),
            color = "blue") +
  geom_line(
    data = parametric,
    aes(x = years, y = clstrk),
    linetype = "dashed",
    color = "blue"
  ) +
  geom_line(
    data = parametric,
    aes(x = years, y = custrk),
    linetype = "dashed",
    color = "blue"
  )
show(ccf_plot)


## -----------------------------------------------------------------------------
# Special commands to force origin to 0,0
ccf_plot <- ccf_plot +
  coord_cartesian(xlim = c(0, 5.1), ylim = c(0, 101))
show(ccf_plot)


## -----------------------------------------------------------------------------
#| label: powerpoint_fig1
#| caption: PowerPoint Figures
# %plot(goptions gsfmode=replace, device=cgmmppa, ftext=hwcgm001, end;
#   axisx order=(0 to 5 by 1), minor=none, value=(height=2.4), end;
#   axisy order=(0 to 100 by 20), minor=none, value=(height=2.4),
#   value=(height=2.4 j=r 20 40 60 80 100 ), end;
#   tuple set=all, x=years, y=noinit, width=3, color=gray, end;
#   tuple set=all, x=years, y=nostrk, width=3, color=red, end;
#   tuple set=all, x=years, y=nodeath, width=3, color=blue, end;
# );
ccf_pptPlot <- ggplot() +
  scale_x_continuous(breaks = seq(0, 5, 1)) +
  scale_y_continuous(breaks = seq(0, 100, 20)) +
  geom_line(
    data = parametric,
    aes(x = years, y = noinit),
    color = "grey",
    size = 1.5
  ) +
  geom_line(
    data = parametric,
    aes(x = years, y = nostrk),
    color = "red",
    size = 1.5
  ) +
  geom_line(
    data = parametric,
    aes(x = years, y = nodeath),
    color = "blue",
    size = 1.5
  )
show(ccf_pptPlot)


## -----------------------------------------------------------------------------
#| label: man_theme
#| caption: Theme for Manuscripts
# Set the theme for manuscripts,
theme_set(hvti_theme("manuscript"))
# show the figure.
ccf_plot


## -----------------------------------------------------------------------------
#| label: powerpoint_fig2
#| caption: PowerPoint theme
# Update the PowerPoint Figure to include the PPT Theme, and remove axis labels. 
# Axis labels will be added manually in powerpoint. 
ccf_pptPlot <- ccf_pptPlot + 
  hvti_theme("ppt")
ccf_pptPlot


## -----------------------------------------------------------------------------
#| label: powerpoint_fig3
#| caption: Theme for Presentations
# Show the figure... the theme statement is used so the axis tick marks and values 
# are visible in this document. 
ccf_pptPlot + theme(plot.background = element_rect(fill='blue', colour='blue')) 


## -----------------------------------------------------------------------------
#| label: mirror_histogram
#| caption: Mirrored Propensity Score Histogram
# Generate sample data for the mirrored histogram
mirror_dta <- sample_mirror_histogram_data(n = 2000)

# Generate the mirrored histogram
mhist <- mirror_histogram(
  data = mirror_dta,
  score_col = "prob_t",
  group_col = "tavr",
  match_col = "match",
  group_levels = c(0, 1),
  group_labels = c("SAVR", "TF-TAVR"),
  matched_value = 1,
  score_multiplier = 100,
  binwidth = 5,
  alpha = 0.8
)

# Display the plot
mhist$plot


## -----------------------------------------------------------------------------
#| label: mirror_histogram_diagnostics
#| caption: Mirrored Histogram Diagnostics
# Standardized mean difference before matching
mhist$diagnostics$smd_before

# Standardized mean difference after matching
mhist$diagnostics$smd_matched

# Group counts before matching
mhist$diagnostics$group_counts_before

# Group counts after matching
mhist$diagnostics$group_counts_matched


## -----------------------------------------------------------------------------
#| label: stacked_histogram_data
# Generate sample data
hist_dta <- sample_stacked_histogram_data(n_years = 20, start_year = 2000,
                                           n_categories = 3)
head(hist_dta)


## -----------------------------------------------------------------------------
#| label: stacked_histogram_count
# Build the bare plot
p_count <- stacked_histogram(hist_dta, x_col = "year", group_col = "category")

# Layer on colour scales, labels, and a theme
p_count +
  scale_fill_brewer(palette = "Set1", name = "Category") +
  scale_color_brewer(palette = "Set1", name = "Category") +
  labs(x = "Year", y = "Count") +
  hvti_theme("manuscript")


## -----------------------------------------------------------------------------
#| label: stacked_histogram_fill
# Build the proportional variant
p_fill <- stacked_histogram(hist_dta, x_col = "year", group_col = "category",
                             position = "fill")

# Use manual colours and custom legend labels
p_fill +
  scale_fill_manual(
    values = c("1" = "pink", "2" = "cyan", "3" = "orangered"),
    labels = c("1" = "Group A", "2" = "Group B", "3" = "Group C"),
    name   = "Category"
  ) +
  scale_color_manual(
    values = c("1" = "pink", "2" = "cyan", "3" = "orangered"),
    guide  = "none"
  ) +
  labs(x = "Year", y = "Proportion") +
  hvti_theme("manuscript")


## -----------------------------------------------------------------------------
#| label: stacked_histogram_save
#| eval: false
# p_final <- p_fill +
#   scale_fill_manual(
#     values = c("1" = "pink", "2" = "cyan", "3" = "orangered"),
#     name   = "Category"
#   ) +
#   scale_color_manual(
#     values = c("1" = "pink", "2" = "cyan", "3" = "orangered"),
#     guide  = "none"
#   ) +
#   labs(x = "Year", y = "Proportion") +
#   hvti_theme("manuscript")
# 
# ggsave(
#   filename = "../graphs/stacked_histogram.pdf",
#   plot     = p_final,
#   width    = 11,
#   height   = 8
# )


## -----------------------------------------------------------------------------
#| label: gfup_data
gfup_dta <- sample_goodness_followup_data(n = 300, seed = 42)
head(gfup_dta)


## -----------------------------------------------------------------------------
#| label: gfup_basic
gfup <- goodness_followup(
  data        = gfup_dta,
  origin_year = 1990,
  study_start = as.Date("1990-01-01"),
  study_end   = as.Date("2019-12-31"),
  close_date  = as.Date("2021-08-06"),
  alpha       = 0.8
)

# Bare plot — no scales or labels yet
gfup$death_plot


## -----------------------------------------------------------------------------
#| label: gfup_styled
library(RColorBrewer)

gfup$death_plot +
  # Colour alive = blue, dead = red (Set1 palette positions 2 and 1)
  scale_color_manual(
    values   = brewer.pal(3, "Set1")[c(2, 1)],
    labels   = c("Alive", "Dead"),
    na.value = "black",
    drop     = FALSE
  ) +
  scale_shape_manual(
    values = c(1, 4),
    labels = c("Alive", "Dead")
  ) +
  # Axis tick placement
  scale_x_continuous(breaks = seq(1990, 2020, 3)) +
  scale_y_continuous(breaks = seq(0, 33,   3)) +
  # Clip the panel to the study window
  coord_cartesian(ylim = c(0, 33), xlim = c(1990, 2020)) +
  # Axis and legend labels
  labs(
    x     = "Operation Date",
    y     = "Follow-up (years)",
    color = "Status",
    shape = "Status"
  ) +
  # Annotate directly on the panel
  annotate("text", x = 1993, y = 31, label = "Alive at close",
           hjust = 0, size = 3.5) +
  annotate("text", x = 1993, y = 28, label = "Deceased",
           hjust = 0, size = 3.5, color = brewer.pal(3, "Set1")[1]) +
  theme(legend.position = "none")


## -----------------------------------------------------------------------------
#| label: gfup_save
#| eval: false
# gfup_final <- gfup$death_plot +
#   scale_color_manual(
#     values   = brewer.pal(3, "Set1")[c(2, 1)],
#     labels   = c("Alive", "Dead"),
#     na.value = "black",
#     drop     = FALSE
#   ) +
#   scale_shape_manual(values = c(1, 4), labels = c("Alive", "Dead")) +
#   scale_x_continuous(breaks = seq(1990, 2020, 3)) +
#   scale_y_continuous(breaks = seq(0, 33, 3)) +
#   coord_cartesian(ylim = c(0, 33), xlim = c(1990, 2020)) +
#   labs(x = "Operation Date", y = "Follow-up (years)",
#        color = "Status", shape = "Status") +
#   annotate("text", x = 1993, y = 31, label = "Alive at close",
#            hjust = 0, size = 3.5) +
#   annotate("text", x = 1993, y = 28, label = "Deceased",
#            hjust = 0, size = 3.5, color = brewer.pal(3, "Set1")[1]) +
#   theme(legend.position = "none")
# 
# ggsave(
#   filename = "../graphs/dp_goodness-of-followup.pdf",
#   plot     = gfup_final,
#   height   = 6,
#   width    = 6
# )


## -----------------------------------------------------------------------------
#| label: gfup_event_data
gfup_event_dta <- sample_goodness_followup_data(n = 300, seed = 42)


## -----------------------------------------------------------------------------
#| label: gfup_event_panel
gfup2 <- goodness_followup(
  gfup_event_dta,
  origin_year         = 1990,
  study_start         = as.Date("1990-01-01"),
  study_end           = as.Date("2019-12-31"),
  close_date          = as.Date("2021-08-06"),
  event_col           = "ev_event",
  event_time_col      = "iv_event",
  death_for_event_col = "deads",
  event_levels        = c("No event", "Relapse", "Death"),
  alpha               = 0.8
)

gfup2$event_plot +
  scale_color_manual(
    values = c("No event" = "blue", "Relapse" = "green3", "Death" = "red"),
    name   = NULL
  ) +
  scale_shape_manual(
    values = c("No event" = 1L, "Relapse" = 2L, "Death" = 4L),
    name   = NULL
  ) +
  scale_x_continuous(breaks = seq(1990, 2020, 3)) +
  scale_y_continuous(breaks = seq(0, 33, 3)) +
  coord_cartesian(ylim = c(0, 33), xlim = c(1990, 2020)) +
  labs(
    x = "Operation Date",
    y = "Follow-up (years)",
    color = "Event", shape = "Event"
  ) +
  annotate("text", x = 1993, y = 31,
           label = "Systematic follow-up", hjust = 0, size = 3.5) +
  theme(legend.position = c(0.85, 0.15))


## -----------------------------------------------------------------------------
#| label: cov_balance_data
dta_cb <- sample_covariate_balance_data(n_vars = 12)
head(dta_cb)


## -----------------------------------------------------------------------------
#| label: cov_balance_bare
covariate_balance(dta_cb, alpha = 0.8)


## -----------------------------------------------------------------------------
#| label: cov_balance_scales
library(RColorBrewer)

covariate_balance(dta_cb, alpha = 0.8) +
  scale_color_manual(
    values = c("Before match" = "red4", "After match" = "blue3"),
    name   = NULL
  ) +
  scale_shape_manual(
    values = c("Before match" = 17L, "After match" = 15L),
    name   = NULL
  ) +
  scale_x_continuous(
    limits = c(-45, 35),
    breaks = seq(-40, 30, 10)
  ) +
  labs(
    x = "Standardized difference (%)",
    y = ""
  ) +
  theme(legend.position = c(0.20, 0.95))


## -----------------------------------------------------------------------------
#| label: cov_balance_annotated
n_vars <- length(unique(dta_cb$variable))

covariate_balance(dta_cb, alpha = 0.8) +
  scale_color_manual(
    values = c("Before match" = "red4", "After match" = "blue3"),
    name   = NULL
  ) +
  scale_shape_manual(
    values = c("Before match" = 17L, "After match" = 15L),
    name   = NULL
  ) +
  scale_x_continuous(
    limits = c(-45, 35),
    breaks = seq(-40, 30, 10)
  ) +
  labs(
    x = "Standardized difference: Group A \u2013 Group B (%)",
    y = ""
  ) +
  # Directional labels at fixed panel positions
  annotate("text", x = -32, y = 0.4,        label = "More likely Group B", size = 4) +
  annotate("text", x =  22, y = n_vars + 1, label = "More likely Group A", size = 4) +
  theme(legend.position = c(0.20, 0.95)) +
  hvti_theme("manuscript")


## -----------------------------------------------------------------------------
#| label: cov_balance_order
# Reverse the default order so the first covariate appears at the top
covariate_balance(
  dta_cb,
  var_levels = rev(unique(dta_cb$variable)),
  alpha      = 0.8
) +
  scale_color_manual(
    values = c("Before match" = "red4", "After match" = "blue3"),
    name   = NULL
  ) +
  scale_shape_manual(
    values = c("Before match" = 17L, "After match" = 15L),
    name   = NULL
  ) +
  labs(x = "Standardized difference (%)", y = "") +
  hvti_theme("manuscript")


## -----------------------------------------------------------------------------
#| label: cov_balance_save
#| eval: false
# cb_final <- covariate_balance(dta_cb, alpha = 0.8) +
#   scale_color_manual(
#     values = c("Before match" = "red4", "After match" = "blue3"),
#     name   = NULL
#   ) +
#   scale_shape_manual(
#     values = c("Before match" = 17L, "After match" = 15L),
#     name   = NULL
#   ) +
#   scale_x_continuous(limits = c(-45, 35), breaks = seq(-40, 30, 10)) +
#   labs(x = "Standardized difference (%)", y = "") +
#   annotate("text", x = -32, y = 0.4,        label = "More likely Group B", size = 4) +
#   annotate("text", x =  22, y = n_vars + 1, label = "More likely Group A", size = 4) +
#   theme(legend.position = c(0.20, 0.95)) +
#   hvti_theme("manuscript")
# 
# ggsave(
#   filename = "../graphs/lp_cov-balance.pdf",
#   plot     = cb_final,
#   height   = 7,
#   width    = 8
# )


## -----------------------------------------------------------------------------
#| label: km_data
dta_km <- sample_survival_data(n = 500, seed = 42)
head(dta_km)


## -----------------------------------------------------------------------------
#| label: km_result
km <- survival_curve(dta_km, alpha = 0.8)

# Bare plot — no scales or labels yet
km$survival_plot


## -----------------------------------------------------------------------------
#| label: km_styled
km$survival_plot +
  scale_color_manual(values = c(All = "steelblue"), guide = "none") +
  scale_fill_manual(values  = c(All = "steelblue"), guide = "none") +
  scale_y_continuous(
    breaks = seq(0, 100, 20),
    labels = function(x) paste0(x, "%")
  ) +
  scale_x_continuous(breaks = seq(0, 20, 5)) +
  coord_cartesian(xlim = c(0, 20), ylim = c(0, 100)) +
  labs(
    x     = "Years after Operation",
    y     = "Freedom from Death (%)",
    title = "Overall Survival"
  ) +
  annotate("text", x = 1, y = 5,
           label = paste0("n = ", nrow(dta_km)),
           hjust = 0, size = 3.5) +
  hvtiPlotR::hvti_theme("manuscript")


## -----------------------------------------------------------------------------
#| label: km_tables
km$risk_table
km$report_table


## -----------------------------------------------------------------------------
#| label: km_save
#| eval: false
# km_final <- km$survival_plot +
#   scale_color_manual(values = c(All = "steelblue"), guide = "none") +
#   scale_fill_manual(values  = c(All = "steelblue"), guide = "none") +
#   scale_y_continuous(breaks = seq(0, 100, 20),
#                      labels = function(x) paste0(x, "%")) +
#   scale_x_continuous(breaks = seq(0, 20, 5)) +
#   coord_cartesian(xlim = c(0, 20), ylim = c(0, 100)) +
#   labs(x = "Years after Operation", y = "Freedom from Death (%)") +
#   hvtiPlotR::hvti_theme("manuscript")
# 
# ggsave("../graphs/km_survival.pdf", km_final, width = 8, height = 6)


## -----------------------------------------------------------------------------
#| label: km_strata_data
dta_km_s <- sample_survival_data(
  n             = 500,
  strata_levels = c("Type A", "Type B"),
  hazard_ratios = c(1, 1.4),
  seed          = 42
)

km_s <- survival_curve(dta_km_s, strata_col = "valve_type", alpha = 0.8)

km_s$survival_plot +
  scale_color_manual(
    values = c("Type A" = "steelblue", "Type B" = "firebrick"),
    name   = "Valve Type"
  ) +
  scale_fill_manual(
    values = c("Type A" = "steelblue", "Type B" = "firebrick"),
    name   = "Valve Type"
  ) +
  scale_y_continuous(breaks = seq(0, 100, 20),
                     labels = function(x) paste0(x, "%")) +
  scale_x_continuous(breaks = seq(0, 20, 5)) +
  coord_cartesian(xlim = c(0, 20), ylim = c(0, 100)) +
  labs(x = "Years after Operation", y = "Freedom from Death (%)",
       title = "Survival by Valve Type") +
  theme(legend.position = c(0.15, 0.20)) +
  hvtiPlotR::hvti_theme("manuscript")


## -----------------------------------------------------------------------------
#| label: km_cumhaz
km$cumhaz_plot +
  scale_x_continuous(breaks = seq(0, 20, 5)) +
  labs(x = "Years after Operation", y = "Cumulative Hazard H(t)",
       title = "Nelson-Aalen Cumulative Hazard") +
  scale_color_manual(values = c(All = "steelblue"), guide = "none") +
  hvtiPlotR::hvti_theme("manuscript")


## -----------------------------------------------------------------------------
#| label: km_loglog
km_s$loglog_plot +
  scale_color_manual(
    values = c("Type A" = "steelblue", "Type B" = "firebrick"),
    name   = "Valve Type"
  ) +
  labs(x = "log(Years after Operation)", y = "log(-log S(t))",
       title = "Log-Log Survival — Proportional-Hazards Check") +
  hvtiPlotR::hvti_theme("manuscript")


## -----------------------------------------------------------------------------
#| label: km_hazard
# Raw points from the SAS %kaplan HAZARD formula
km$hazard_plot +
  geom_smooth(
    aes(x = mid_time, y = hazard, color = strata),
    method = "loess", se = FALSE, span = 0.6
  ) +
  scale_color_manual(values = c(All = "steelblue"), guide = "none") +
  scale_x_continuous(breaks = seq(0, 20, 5)) +
  labs(x = "Years after Operation", y = "Instantaneous Hazard",
       title = "Hazard Rate") +
  hvtiPlotR::hvti_theme("manuscript")


## -----------------------------------------------------------------------------
#| label: km_life
km$life_plot +
  scale_color_manual(values = c(All = "steelblue"), guide = "none") +
  scale_x_continuous(breaks = seq(0, 20, 5)) +
  labs(x = "Years after Operation",
       y = "Restricted Mean Survival (years)",
       title = "Integral of Survivorship") +
  hvtiPlotR::hvti_theme("manuscript")


## -----------------------------------------------------------------------------
#| label: eda_data
dta_eda <- sample_eda_data(n = 300, seed = 42)
head(dta_eda)

# Inspect auto-detected types for each column
sapply(dta_eda, eda_classify_var)


## -----------------------------------------------------------------------------
#| label: eda_binary_count
eda_plot(dta_eda, x_col = "year", y_col = "male",
         y_label = "Sex") +
  scale_fill_manual(
    values = c("0" = "steelblue", "1" = "firebrick", "(Missing)" = "grey80"),
    labels = c("0" = "Female", "1" = "Male", "(Missing)" = "Missing"),
    name   = NULL
  ) +
  scale_x_discrete(breaks = seq(2005, 2020, 5)) +
  labs(x = "Surgery Year", y = "Count") +
  hvti_theme("manuscript")


## -----------------------------------------------------------------------------
#| label: eda_binary_percent
eda_plot(dta_eda, x_col = "year", y_col = "cabg",
         y_label = "Concomitant CABG", show_percent = TRUE) +
  scale_fill_manual(
    values = c("0" = "grey70", "1" = "steelblue", "(Missing)" = "grey90"),
    labels = c("0" = "No CABG", "1" = "CABG", "(Missing)" = "Missing"),
    name   = NULL
  ) +
  scale_x_discrete(breaks = seq(2005, 2020, 5)) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Surgery Year", y = "Proportion") +
  hvti_theme("manuscript")


## -----------------------------------------------------------------------------
#| label: eda_ordinal
eda_plot(dta_eda, x_col = "year", y_col = "nyha",
         y_label = "Preoperative NYHA Class") +
  scale_fill_brewer(
    palette = "RdYlGn", direction = -1,
    labels  = c("1" = "I", "2" = "II", "3" = "III", "4" = "IV",
                "(Missing)" = "Missing"),
    name    = "NYHA"
  ) +
  scale_x_discrete(breaks = seq(2005, 2020, 5)) +
  labs(x = "Surgery Year", y = "Count") +
  hvti_theme("manuscript")


## -----------------------------------------------------------------------------
#| label: eda_char_cat
eda_plot(dta_eda, x_col = "year", y_col = "valve_morph",
         y_label = "Valve Morphology") +
  scale_fill_manual(
    values = c(Bicuspid   = "steelblue",
               Tricuspid  = "firebrick",
               Unicuspid  = "goldenrod3",
               "(Missing)" = "grey80"),
    name = "Morphology"
  ) +
  scale_x_discrete(breaks = seq(2005, 2020, 5)) +
  labs(x = "Surgery Year", y = "Count") +
  hvti_theme("manuscript")


## -----------------------------------------------------------------------------
#| label: eda_continuous
eda_plot(dta_eda, x_col = "op_years", y_col = "ef",
         y_label = "Ejection Fraction (%)") +
  scale_colour_manual(values = c("firebrick"), guide = "none") +
  scale_x_continuous(breaks = seq(0, 15, 5)) +
  scale_y_continuous(limits = c(20, 80), breaks = seq(20, 80, 20)) +
  labs(x = "Years from First Surgery Year",
       caption = "Tick marks on x-axis: observations with missing EF") +
  hvti_theme("manuscript")


## -----------------------------------------------------------------------------
#| label: eda_varnames_binary
# Binary variables — matches Var_CatList with Max/Min_Categories = 2
bin_vars <- c(male = "Sex (Male)", cabg = "Concomitant CABG")
sub_bin  <- eda_select_vars(dta_eda, names(bin_vars))

p_bin <- lapply(names(bin_vars), function(cn) {
  eda_plot(sub_bin, x_col = "year", y_col = cn,
           y_label = bin_vars[[cn]]) +
    scale_fill_brewer(palette = "Set1", direction = -1, name = NULL) +
    scale_x_discrete(breaks = seq(2005, 2020, 5)) +
    labs(x = "Surgery Year", y = "Count") +
    hvti_theme("manuscript")
})
p_bin[[1]]
p_bin[[2]]


## -----------------------------------------------------------------------------
#| label: eda_varnames_ordinal
# Multi-level categorical — matches Var_CatList with Min=3, Max=7
cat_vars <- c(nyha        = "NYHA Class",
              valve_morph = "Valve Morphology")
sub_cat <- eda_select_vars(dta_eda, names(cat_vars))

p_cat <- lapply(names(cat_vars), function(cn) {
  eda_plot(sub_cat, x_col = "year", y_col = cn,
           y_label = cat_vars[[cn]]) +
    scale_fill_brewer(palette = "Set2", name = NULL) +
    scale_x_discrete(breaks = seq(2005, 2020, 5)) +
    labs(x = "Surgery Year", y = "Count") +
    hvti_theme("manuscript")
})
p_cat[[1]]
p_cat[[2]]


## -----------------------------------------------------------------------------
#| label: eda_varnames_continuous
# Continuous variables — matches Var_ContList
cont_vars <- c(ef        = "Ejection Fraction (%)",
               lv_mass   = "LV Mass Index (g/m\u00b2)",
               peak_grad = "Peak Gradient (mmHg)")
sub_cont <- eda_select_vars(dta_eda, names(cont_vars))

p_cont <- lapply(names(cont_vars), function(cn) {
  eda_plot(sub_cont, x_col = "op_years", y_col = cn,
           y_label = cont_vars[[cn]]) +
    scale_colour_manual(values = c("steelblue"), guide = "none") +
    scale_x_continuous(breaks = seq(0, 15, 5)) +
    labs(x = "Years from First Surgery Year") +
    hvti_theme("manuscript")
})
p_cont[[1]]
p_cont[[2]]
p_cont[[3]]


## -----------------------------------------------------------------------------
#| label: eda_save
#| eval: false
# all_plots <- c(p_bin, p_cat, p_cont)
# per_page  <- 9L  # 3 × 3 grid, matching N_Row = 3, N_Column = 3
# 
# for (pg in seq(1, length(all_plots), by = per_page)) {
#   idx  <- seq(pg, min(pg + per_page - 1L, length(all_plots)))
#   grob <- gridExtra::marrangeGrob(all_plots[idx], nrow = 3, ncol = 3)
#   ggsave(
#     filename = sprintf("../graphs/eda_page%02d.pdf", ceiling(pg / per_page)),
#     plot     = grob,
#     width    = 14,
#     height   = 14
#   )
# }


## -----------------------------------------------------------------------------
library("grid") 
library("gridExtra")
ccf_savePlot <- arrangeGrob(ccf_plot + hvti_theme("manuscript"),
                            sub = textGrob(
                              paste(getwd(), Sys.Date(), sep = " "),
                              x = 0,
                              hjust = -.1,
                              vjust = .01,
                              gp = gpar(fontface = "italic", fontsize = 6)
                            )) 
ccf_savePlot


## -----------------------------------------------------------------------------
# Install the latest ReporteRs package. 
# 
# The devtools package is installed on all our 
# jjnb-gen servers as well as other R instances. 
library("devtools") 
# To get the latest version. 
#install_github("davidgohel/ReporteRs") 


## -----------------------------------------------------------------------------

  # library("ReporteRs")
  # 
  # # Create a powerPoint document using ../inst/RDPresentation.pptx
  # # as a template document.
  # doc = pptx(template = paste("../inst/RDPresentation.pptx", sep = ""))
  # # Here we define powerpoint document filename to write
  # # the presentation. This will be overwritten
  # pptx.file = paste("RDExample.pptx", sep = "")
  # ##--------
  # # For each graph, addSlide. The graphs require the
  # # “Title and Content” template.
  # doc = addSlide(doc, "Title and Content")
  # # Place a title
  # doc = addTitle(doc, "Treatment Difference")
  # # Now add the graph into the powerPoint doc
  # doc = addPlot(
  #   doc = doc,
  #   fun = print,
  #   x = ccf_pptPlot + theme_ppt() ,
  #   editable = TRUE,
  #   offx = .75,
  #   offy = 1.1,
  #   width = 8,
  #   height = 6
  # )
  # ##--------
  # ##--------
  # ## IF you want to add more, just` repeat between the
  # ##-------- comments \# write the output powerpoint doc.
  # # This will not overwrite an open document, since open PPT files are locked.
  # writeDoc(doc, pptx.file)


