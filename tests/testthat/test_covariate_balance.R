# Test suite for covariate-balance.R

library(testthat)

# ---------------------------------------------------------------------------
# sample_covariate_balance_data
# ---------------------------------------------------------------------------

test_that("sample_covariate_balance_data returns a data frame", {
  dta <- sample_covariate_balance_data()
  expect_true(is.data.frame(dta))
})

test_that("sample_covariate_balance_data has required columns", {
  dta <- sample_covariate_balance_data()
  expect_true(all(c("variable", "group", "std_diff") %in% names(dta)))
})

test_that("sample_covariate_balance_data has 2 * n_vars rows", {
  dta <- sample_covariate_balance_data(n_vars = 8)
  expect_equal(nrow(dta), 16L)
})

test_that("sample_covariate_balance_data uses supplied group_levels", {
  dta <- sample_covariate_balance_data(group_levels = c("Unweighted", "IPTW"))
  expect_setequal(unique(dta$group), c("Unweighted", "IPTW"))
})

test_that("sample_covariate_balance_data is reproducible with same seed", {
  d1 <- sample_covariate_balance_data(seed = 7)
  d2 <- sample_covariate_balance_data(seed = 7)
  expect_identical(d1, d2)
})

test_that("sample_covariate_balance_data differs with different seeds", {
  d1 <- sample_covariate_balance_data(seed = 1)
  d2 <- sample_covariate_balance_data(seed = 2)
  expect_false(identical(d1, d2))
})

test_that("sample_covariate_balance_data errors on non-positive n_vars", {
  expect_error(sample_covariate_balance_data(n_vars = 0),  "positive integer")
  expect_error(sample_covariate_balance_data(n_vars = -1), "positive integer")
})

test_that("sample_covariate_balance_data errors when group_levels != 2", {
  expect_error(
    sample_covariate_balance_data(group_levels = c("A", "B", "C")),
    "length-2"
  )
})

test_that("sample_covariate_balance_data errors on non-positive n", {
  expect_error(sample_covariate_balance_data(n = 0),  "positive integer")
  expect_error(sample_covariate_balance_data(n = -1), "positive integer")
})

test_that("sample_covariate_balance_data errors on non-positive separation", {
  expect_error(sample_covariate_balance_data(separation = 0),  "positive number")
  expect_error(sample_covariate_balance_data(separation = -1), "positive number")
})

test_that("sample_covariate_balance_data errors on out-of-range caliper", {
  expect_error(sample_covariate_balance_data(caliper = 0),   "\\(0, 1\\]")
  expect_error(sample_covariate_balance_data(caliper = 1.1), "\\(0, 1\\]")
})

test_that("sample_covariate_balance_data extends past default names", {
  dta <- sample_covariate_balance_data(n_vars = 15)
  expect_equal(length(unique(dta$variable)), 15L)
})

test_that("sample_covariate_balance_data before-match SMDs are larger than after-match", {
  dta <- sample_covariate_balance_data(seed = 1)
  before <- dta$std_diff[dta$group == "Before match"]
  after  <- dta$std_diff[dta$group == "After match"]
  # Matching should reduce |SMD| on average
  expect_gt(mean(abs(before)), mean(abs(after)))
})

test_that("sample_covariate_balance_data higher separation increases before-match imbalance", {
  d_low  <- sample_covariate_balance_data(separation = 0.5, seed = 1)
  d_high <- sample_covariate_balance_data(separation = 3.0, seed = 1)
  before_low  <- mean(abs(d_low$std_diff[d_low$group  == "Before match"]))
  before_high <- mean(abs(d_high$std_diff[d_high$group == "Before match"]))
  expect_gt(before_high, before_low)
})

# ---------------------------------------------------------------------------
# hv_balance — return type
# ---------------------------------------------------------------------------

test_that("hv_balance returns an hv_data object", {
  dta <- sample_covariate_balance_data()
  cb  <- hv_balance(dta)
  expect_s3_class(cb, "hv_data")
})

test_that("plot(hv_balance) returns a ggplot object", {
  dta <- sample_covariate_balance_data()
  expect_s3_class(plot(hv_balance(dta)), "ggplot")
})

# ---------------------------------------------------------------------------
# hv_balance — input validation (errors in constructor)
# ---------------------------------------------------------------------------

test_that("hv_balance errors when data is not a data frame", {
  expect_error(
    hv_balance(list(variable = "x", group = "y", std_diff = 1)),
    "data.frame"
  )
})

test_that("hv_balance errors on missing variable_col", {
  dta <- sample_covariate_balance_data()
  dta$variable <- NULL
  expect_error(hv_balance(dta), "Missing required column")
})

test_that("hv_balance errors on missing group_col", {
  dta <- sample_covariate_balance_data()
  dta$group <- NULL
  expect_error(hv_balance(dta), "Missing required column")
})

test_that("hv_balance errors on missing std_diff_col", {
  dta <- sample_covariate_balance_data()
  dta$std_diff <- NULL
  expect_error(hv_balance(dta), "Missing required column")
})

test_that("hv_balance errors when std_diff_col is not numeric", {
  dta <- sample_covariate_balance_data()
  dta$std_diff <- as.character(dta$std_diff)
  expect_error(hv_balance(dta), "numeric")
})

test_that("hv_balance accepts non-default column names", {
  dta <- sample_covariate_balance_data()
  names(dta) <- c("cov", "grp", "smd")
  cb <- hv_balance(dta,
                     variable_col  = "cov",
                     group_col     = "grp",
                     std_diff_col  = "smd")
  expect_s3_class(plot(cb), "ggplot")
})

# ---------------------------------------------------------------------------
# plot(hv_balance) — plot structure
# ---------------------------------------------------------------------------

test_that("plot(hv_balance) has a geom_point layer", {
  p            <- plot(hv_balance(sample_covariate_balance_data()))
  geom_classes <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomPoint" %in% geom_classes)
})

test_that("plot(hv_balance) has geom_vline layers", {
  p            <- plot(hv_balance(sample_covariate_balance_data()))
  geom_classes <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomVline" %in% geom_classes)
})

test_that("plot(hv_balance) has geom_hline layers", {
  p            <- plot(hv_balance(sample_covariate_balance_data()))
  geom_classes <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomHline" %in% geom_classes)
})

test_that("plot(hv_balance) y scale has n breaks equal to n_vars", {
  n      <- 8L
  dta    <- sample_covariate_balance_data(n_vars = n)
  p      <- plot(hv_balance(dta))
  built  <- ggplot2::ggplot_build(p)
  breaks <- built$layout$panel_params[[1]]$y$breaks
  expect_equal(length(breaks), n)
})

test_that("hv_balance var_levels is respected in plot y labels", {
  dta          <- sample_covariate_balance_data(n_vars = 4)
  custom_order <- rev(unique(dta$variable))
  cb           <- hv_balance(dta, var_levels = custom_order)
  p            <- plot(cb)
  built        <- ggplot2::ggplot_build(p)
  labels       <- built$layout$panel_params[[1]]$y$get_labels()
  expect_equal(labels, custom_order)
})

test_that("hv_balance threshold vlines appear at correct x values", {
  dta       <- sample_covariate_balance_data()
  p         <- plot(hv_balance(dta, threshold = 15))
  built     <- ggplot2::ggplot_build(p)
  vline_idx <- which(vapply(
    p$layers,
    function(l) inherits(l$geom, "GeomVline"),
    logical(1)
  ))
  intercepts <- unlist(lapply(
    vline_idx, function(i) built$data[[i]]$xintercept
  ))
  expect_true(15 %in% intercepts)
  expect_true(-15 %in% intercepts)
})

# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# print.hv_balance coverage
# ---------------------------------------------------------------------------

test_that("print.hv_balance produces <hv_balance> header", {
  df  <- sample_covariate_balance_data(n = 200, seed = 1)
  bal <- hv_balance(df, group_col = "group")
  expect_output(print(bal), "<hv_balance>")
})

test_that("print.hv_balance returns x invisibly", {
  df  <- sample_covariate_balance_data(n = 200, seed = 1)
  bal <- hv_balance(df, group_col = "group")
  ret <- withVisible(print(bal))
  expect_false(ret$visible)
  expect_identical(ret$value, bal)
})

# ---------------------------------------------------------------------------
# hv_balance_height
# ---------------------------------------------------------------------------

test_that("hv_balance_height gives about 8 in for 38 rows at 12 pt", {
  expect_equal(hv_balance_height(38), 0.17 * 38 + 1.5)
  expect_equal(round(hv_balance_height(38), 2), 7.96)
})

test_that("hv_balance_height scales with base_size", {
  expect_equal(hv_balance_height(38, base_size = 18), 1.5 * hv_balance_height(38))
})

test_that("hv_balance_height adds rows and strip space per pair", {
  expect_equal(hv_balance_height(10, n_pairs = 3), 0.17 * 30 + 0.3 * 2 + 1.5)
})

test_that("hv_balance_height rejects non-positive input", {
  expect_error(hv_balance_height(0), "n_rows")
  expect_error(hv_balance_height(10, base_size = -1), "base_size")
  expect_error(hv_balance_height(10, n_pairs = 0), "n_pairs")
})

# ---------------------------------------------------------------------------
# hv_balance: stat / pair data model
# ---------------------------------------------------------------------------

cb_vline_by_panel <- function(p) {
  built <- ggplot2::ggplot_build(p)
  idx   <- which(vapply(p$layers, function(l) inherits(l$geom, "GeomVline"), logical(1)))
  do.call(rbind, lapply(idx, function(i) built$data[[i]][, c("PANEL", "xintercept")]))
}

cb_long_df <- function() {
  base <- sample_covariate_balance_data(n_vars = 4)
  ks <- transform(base, stat = "ks")
  ks$std_diff <- abs(ks$std_diff) / 100
  rbind(transform(base, stat = "smd"), ks)
}

test_that("hv_balance adds stat = smd and pair = NA for plain input", {
  cb <- hv_balance(sample_covariate_balance_data())
  expect_true(all(cb$data$stat == "smd"))
  expect_true(all(is.na(cb$data$pair)))
  expect_equal(cb$meta$stats, "smd")
  expect_identical(cb$meta$pairs, character(0))
  expect_equal(cb$meta$n_imputations, 1L)
})

test_that("hv_balance stores suggested_height from hv_balance_height", {
  cb <- hv_balance(sample_covariate_balance_data(n_vars = 12))
  expect_equal(cb$meta$suggested_height, hv_balance_height(12))
})

test_that("hv_balance keeps only the requested stats from stat_col", {
  cb <- hv_balance(cb_long_df(), stat_col = "stat")
  expect_equal(levels(cb$data$stat), "smd")
  expect_equal(nrow(cb$data), 8L)
  cb2 <- hv_balance(cb_long_df(), stat_col = "stat", stats = c("smd", "ks"))
  expect_equal(levels(cb2$data$stat), c("smd", "ks"))
  expect_equal(nrow(cb2$data), 16L)
})

test_that("hv_balance reads pair_col and records pairs in order", {
  d <- sample_covariate_balance_data(n_vars = 3)
  d <- rbind(transform(d, cmp = "B vs. A"), transform(d, cmp = "C vs. A"))
  cb <- hv_balance(d, pair_col = "cmp")
  expect_equal(cb$meta$pairs, c("B vs. A", "C vs. A"))
  expect_equal(levels(cb$data$pair), c("B vs. A", "C vs. A"))
  expect_equal(cb$meta$suggested_height, hv_balance_height(3, n_pairs = 2))
})

test_that("hv_balance errors when stats names a stat with no rows", {
  expect_error(
    hv_balance(sample_covariate_balance_data(), stats = c("smd", "ks")),
    "no rows"
  )
})

test_that("hv_balance de-duplicates repeated stats", {
  cb <- hv_balance(sample_covariate_balance_data(), stats = c("smd", "smd"))
  expect_equal(cb$meta$stats, "smd")
  expect_equal(levels(cb$data$stat), "smd")
})

test_that("hv_balance errors on an unknown stats value", {
  expect_error(hv_balance(sample_covariate_balance_data(), stats = "mean"), "should be one of")
})

test_that("hv_balance errors on unknown values in stat_col", {
  d <- transform(sample_covariate_balance_data(), stat = "ovl")
  expect_error(hv_balance(d, stat_col = "stat"), "unknown statistic")
})

test_that("a caller's own `pair` column is left alone and the plot is unfaceted", {
  d <- sample_covariate_balance_data(n_vars = 3)
  d$pair <- rep(c("junk1", "junk2"), length.out = nrow(d))
  cb <- hv_balance(d)
  expect_identical(cb$data$pair, d$pair)
  expect_equal(cb$meta$pair_var, ".cb_pair")
  expect_identical(cb$meta$pairs, character(0))
  p <- plot(cb)
  expect_s3_class(p$facet, "FacetNull")
  expect_plot_has_data(p, geoms = c("GeomPoint", "GeomVline", "GeomHline"))
})

test_that("a caller's own `stat` column is left alone and the plot is unfaceted", {
  d <- sample_covariate_balance_data(n_vars = 3)
  d$stat <- rep(c("junk1", "junk2"), length.out = nrow(d))
  cb <- hv_balance(d)
  expect_identical(cb$data$stat, d$stat)
  expect_equal(cb$meta$stat_var, ".cb_stat")
  expect_true(all(cb$data$.cb_stat == "smd"))
  p <- plot(cb)
  expect_s3_class(p$facet, "FacetNull")
  expect_plot_has_data(p, geoms = c("GeomPoint", "GeomVline", "GeomHline"))
})

test_that("a clashing `stat` column still facets by stat through stat_col", {
  d <- cb_long_df()
  names(d)[names(d) == "stat"] <- "kind"
  d$stat <- "junk"
  cb <- hv_balance(d, stat_col = "kind", stats = c("smd", "ks"))
  expect_equal(cb$meta$stat_var, ".cb_stat")
  expect_identical(unique(cb$data$stat), "junk")
  p <- plot(cb)
  expect_s3_class(p$facet, "FacetGrid")
  expect_equal(as.character(ggplot2::ggplot_build(p)$layout$layout$stat), c("smd", "ks"))
  v <- cb_vline_by_panel(p)
  expect_setequal(v$xintercept[v$PANEL == 2], 0)
})

test_that("hv_balance validates vr_threshold, ks_threshold and group_labels", {
  d <- sample_covariate_balance_data()
  expect_error(hv_balance(d, vr_threshold = c(0.5, 2, 3)), "vr_threshold")
  expect_error(hv_balance(d, vr_threshold = -1), "vr_threshold")
  expect_error(hv_balance(d, ks_threshold = 1.5), "ks_threshold")
  expect_error(hv_balance(d, group_labels = "x"), "group_labels")
})

test_that("print.hv_balance reports stats, pairs and height", {
  d <- sample_covariate_balance_data(n_vars = 3)
  d <- rbind(transform(d, cmp = "B vs. A"), transform(d, cmp = "C vs. A"))
  out <- capture.output(print(hv_balance(d, pair_col = "cmp")))
  expect_true(any(grepl("Stats", out)))
  expect_true(any(grepl("B vs. A, C vs. A", out)))
  expect_true(any(grepl("Height", out)))
  expect_true(any(grepl("Value col", out)))
  expect_false(any(grepl("SMD col", out)))
})

# ---------------------------------------------------------------------------
# plot(hv_balance): facets and reference lines
# ---------------------------------------------------------------------------

test_that("plain two-group plot keeps FacetNull and its reference lines", {
  p <- plot(hv_balance(sample_covariate_balance_data()))
  expect_s3_class(p$facet, "FacetNull")
  expect_plot_has_data(p, geoms = c("GeomPoint", "GeomVline", "GeomHline"))
  expect_setequal(cb_vline_by_panel(p)$xintercept, c(0, -10, 10))
})

test_that("two stats facet by stat with free x and labeled strips", {
  p <- plot(hv_balance(cb_long_df(), stat_col = "stat", stats = c("smd", "ks")))
  expect_s3_class(p$facet, "FacetGrid")
  expect_plot_has_data(p, min_groups = 2)
  layout <- ggplot2::ggplot_build(p)$layout$layout
  expect_equal(nrow(layout), 2L)
  expect_equal(as.character(layout$stat), c("smd", "ks"))
  lab <- p$facet$params$labeller(data.frame(stat = c("smd", "ks")))[[1]]
  expect_equal(lab, c("Standardized difference (%)", "KS statistic"))
})

test_that("reference lines land only in their own stat panel", {
  d <- rbind(cb_long_df(),
             transform(sample_covariate_balance_data(n_vars = 4), stat = "variance_ratio",
                       std_diff = 1))
  p <- plot(hv_balance(d, stat_col = "stat", stats = c("smd", "variance_ratio", "ks"),
                       ks_threshold = 0.1))
  v <- cb_vline_by_panel(p)
  expect_setequal(v$xintercept[v$PANEL == 1], c(0, -10, 10))
  expect_setequal(v$xintercept[v$PANEL == 2], c(1, 0.5, 2))
  expect_setequal(v$xintercept[v$PANEL == 3], c(0, 0.1))
})

test_that("no dotted KS line is drawn when ks_threshold is NULL", {
  p <- plot(hv_balance(cb_long_df(), stat_col = "stat", stats = c("smd", "ks")))
  v <- cb_vline_by_panel(p)
  expect_setequal(v$xintercept[v$PANEL == 2], 0)
})

test_that("pairs facet by row, one panel per pair, data in every panel", {
  d <- sample_covariate_balance_data(n_vars = 3)
  d <- rbind(transform(d, cmp = "B vs. A"), transform(d, cmp = "C vs. A"),
             transform(d, cmp = "C vs. B"))
  p <- plot(hv_balance(d, pair_col = "cmp"))
  expect_plot_has_data(p)
  built <- ggplot2::ggplot_build(p)
  expect_equal(nrow(built$layout$layout), 3L)
  pts <- built$data[[which(vapply(p$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1)))]]
  expect_setequal(unique(as.integer(pts$PANEL)), 1:3)
})

# ---------------------------------------------------------------------------
# hv_balance: bal.tab input
# ---------------------------------------------------------------------------

test_that("hv_balance reads a bal.tab: SMD x 100, VR and KS unscaled", {
  skip_if_not_installed("cobalt")
  bt <- balance_baltab(balance_cohort(n_terms = 6))
  cb <- hv_balance(bt, stats = c("smd", "variance_ratio", "ks"))
  b  <- bt$Balance
  smd_after <- cb$data[cb$data$stat == "smd" & cb$data$group == "After", ]
  expect_equal(smd_after$std_diff, b$Diff.Adj * 100)
  ks_before <- cb$data[cb$data$stat == "ks" & cb$data$group == "Before", ]
  expect_equal(ks_before$std_diff, b$KS.Un)
  expect_equal(cb$meta$group_col, "group")
  expect_setequal(unique(cb$data$group), c("Before", "After"))
})

test_that("hv_balance drops undefined variance ratios for binary covariates", {
  skip_if_not_installed("cobalt")
  bt <- balance_baltab(balance_cohort(n_terms = 6))
  cb <- expect_no_warning(hv_balance(bt, stats = c("smd", "variance_ratio")))
  vr <- cb$data[cb$data$stat == "variance_ratio", ]
  expect_setequal(unique(vr$variable), rownames(bt$Balance)[bt$Balance$Type != "Binary"])
  expect_equal(cb$meta$n_missing, 0L)
})

test_that("hv_balance applies group_labels to bal.tab input", {
  skip_if_not_installed("cobalt")
  cb <- hv_balance(balance_baltab(balance_cohort(n_terms = 4)),
                   group_labels = c("Unweighted", "Weighted"))
  expect_setequal(unique(cb$data$group), c("Unweighted", "Weighted"))
})

test_that("hv_balance refuses raw binary differences from bal.tab", {
  skip_if_not_installed("cobalt")
  bt <- balance_baltab(balance_cohort(n_terms = 4), binary = "raw")
  expect_error(hv_balance(bt), 'binary = "std"')
})

test_that("hv_balance refuses raw continuous differences from bal.tab", {
  skip_if_not_installed("cobalt")
  d  <- balance_cohort(n_terms = 4)
  bt <- cobalt::bal.tab(d[setdiff(names(d), "treat")], treat = d$treat, binary = "std",
                        continuous = "raw", s.d.denom = "pooled", un = TRUE)
  expect_error(hv_balance(bt), 'continuous = "std"')
})

test_that("hv_balance explains an all-binary bal.tab asked for variance ratios", {
  skip_if_not_installed("cobalt")
  bt <- balance_baltab_binary()
  expect_error(hv_balance(bt, stats = c("smd", "variance_ratio")),
               "undefined for binary covariates, and every covariate here is binary")
  expect_equal(nrow(hv_balance(bt)$data), 4L)
})

test_that("hv_balance says to re-run with un = TRUE when the unadjusted group is empty", {
  skip_if_not_installed("cobalt")
  d    <- balance_cohort(n_terms = 4)
  covs <- setdiff(names(d), "treat")
  w    <- stats::runif(nrow(d), 0.5, 2)
  bt   <- cobalt::bal.tab(d[covs], treat = d$treat, weights = w, binary = "std", s.d.denom = "pooled")
  expect_message(cb <- hv_balance(bt), "un = TRUE")
  expect_setequal(unique(cb$data$group), "After")
  expect_null(attr(cb$data, "no_unadjusted"))

  bt_un <- cobalt::bal.tab(d[covs], treat = d$treat, weights = w, binary = "std",
                           s.d.denom = "pooled", un = TRUE)
  expect_no_message(hv_balance(bt_un))
})

test_that("the un = TRUE message is emitted once per call, not per imputation or pair", {
  skip_if_not_installed("cobalt")
  d    <- balance_cohort(n_terms = 4)
  covs <- setdiff(names(d), "treat")
  bt   <- cobalt::bal.tab(d[covs], treat = d$treat, weights = stats::runif(nrow(d), 0.5, 2),
                          binary = "std", s.d.denom = "pooled")
  n_msg <- function(expr) {
    n <- 0L
    withCallingHandlers(expr, message = function(m) {
      n <<- n + 1L
      invokeRestart("muffleMessage")
    })
    n
  }
  expect_equal(n_msg(hv_balance(list(bt, bt, bt))), 1L)

  set.seed(5)
  g  <- sample(c("A", "B", "C"), nrow(d), replace = TRUE)
  bm <- cobalt::bal.tab(d[covs], treat = g, weights = stats::runif(nrow(d), 0.5, 2),
                        binary = "std", s.d.denom = "pooled")
  expect_equal(n_msg(hv_balance(bm)), 1L)
})

test_that("hv_balance names the missing stat when bal.tab lacks it", {
  skip_if_not_installed("cobalt")
  d  <- balance_cohort(n_terms = 4)
  bt <- cobalt::bal.tab(d[setdiff(names(d), "treat")], treat = d$treat,
                        binary = "std", s.d.denom = "pooled")
  expect_error(hv_balance(bt, stats = c("smd", "ks")), 'stats = c\\("m", "v", "ks"\\)')
})

test_that("hv_balance facets a three-group bal.tab.multi by pair", {
  skip_if_not_installed("cobalt")
  bm <- balance_baltab_multi()
  cb <- hv_balance(bm)
  expect_equal(cb$meta$pairs, names(bm$Pair.Balance))
  p <- plot(cb)
  built <- ggplot2::ggplot_build(p)
  expect_equal(nrow(built$layout$layout), 3L)
  expect_plot_has_data(p)
  pts <- built$data[[which(vapply(p$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1)))]]
  expect_setequal(unique(as.integer(pts$PANEL)), 1:3)
})

test_that("a weighted bal.tab.multi gives a 3 x 3 grid of panels, each with points", {
  skip_if_not_installed("cobalt")
  bm <- balance_baltab_multi_weighted()
  cb <- hv_balance(bm, stats = c("smd", "variance_ratio", "ks"))
  p  <- plot(cb)
  expect_s3_class(p$facet, "FacetGrid")
  expect_plot_has_data(p, min_groups = 2)
  built <- ggplot2::ggplot_build(p)
  expect_equal(nrow(built$layout$layout), 9L)
  pts <- built$data[[which(vapply(p$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1)))]]
  expect_setequal(unique(as.integer(pts$PANEL)), 1:9)
})

test_that("the KS panel shows what exact mean balance hides", {
  skip_if_not_installed("cobalt")
  cb <- hv_balance(balance_exact_mean(), stats = c("smd", "ks"))
  smd <- cb$data[cb$data$stat == "smd", "std_diff"]
  ks  <- cb$data[cb$data$stat == "ks" & cb$data$variable == "year", "std_diff"]
  expect_true(all(abs(smd) < 1e-6))
  expect_gt(ks, 0.2)
  p <- plot(cb)
  expect_plot_has_data(p)
  built <- ggplot2::ggplot_build(p)
  pts <- built$data[[which(vapply(p$layers, function(l) inherits(l$geom, "GeomPoint"), logical(1)))]]
  expect_gt(max(pts$x[pts$PANEL == 2]), 0.2)
  expect_lt(max(abs(pts$x[pts$PANEL == 1])), 1e-6)
})

# ---------------------------------------------------------------------------
# hv_balance: hvtiRpropensity ps_* input
# ---------------------------------------------------------------------------

ps_cov <- c("age", "female", "ef", "diabetes", "hypertension")

test_that("hv_balance reads ps_match SMDs x 100 as Before / After", {
  skip_if_not_installed("hvtiRpropensity")
  m  <- hvtiRpropensity::ps_match(hvtiRpropensity::sample_ps_data(),
                                  covariates = ps_cov, caliper = 0.05, seed = 1)
  cb <- hv_balance(m)
  after <- cb$data[cb$data$group == "After", ]
  expect_equal(after$std_diff, m$tables$smd_after$smd * 100)
  expect_equal(after$variable, as.character(m$tables$smd_after$variable))
  expect_plot_has_data(plot(cb), min_groups = 2)
})

test_that("hv_balance reads ps_weight unweighted / weighted SMDs", {
  skip_if_not_installed("hvtiRpropensity")
  w  <- hvtiRpropensity::ps_weight(hvtiRpropensity::sample_ps_data(), covariates = ps_cov)
  cb <- hv_balance(w)
  before <- cb$data[cb$data$group == "Before", ]
  expect_equal(before$std_diff, w$tables$smd_unweighted$smd * 100)
})

test_that("hv_balance points ps_* callers to bal.tab for VR and KS", {
  skip_if_not_installed("hvtiRpropensity")
  w <- hvtiRpropensity::ps_weight(hvtiRpropensity::sample_ps_data(), covariates = ps_cov)
  expect_error(hv_balance(w, stats = c("smd", "ks")), "standardized differences only")
})

# ---------------------------------------------------------------------------
# hv_balance: imputation lists
# ---------------------------------------------------------------------------

test_that("hv_balance averages 5 imputations of a 38-term bal.tab", {
  skip_if_not_installed("cobalt")
  imps <- lapply(1:5, function(i) balance_baltab(balance_cohort(n_terms = 38, seed = i)))
  cb   <- hv_balance(imps)
  expect_equal(cb$meta$n_imputations, 5L)
  expect_equal(cb$meta$n_vars, 38L)
  hand <- rowMeans(sapply(imps, function(b) b$Balance$Diff.Adj)) * 100
  after <- cb$data[cb$data$group == "After", ]
  expect_equal(after$std_diff, unname(hand))
  expect_equal(round(cb$meta$suggested_height, 2), 7.96)
  expect_output(print(cb), "Imputations : 5")
})

test_that("hv_balance averages a list of ps_match objects", {
  skip_if_not_installed("hvtiRpropensity")
  d <- hvtiRpropensity::sample_ps_data()
  imps <- lapply(1:3, function(i) {
    hvtiRpropensity::ps_match(d, covariates = c("age", "female", "ef"), caliper = 0.05, seed = i)
  })
  cb <- hv_balance(imps)
  hand <- rowMeans(sapply(imps, function(m) m$tables$smd_after$smd)) * 100
  expect_equal(cb$data[cb$data$group == "After", "std_diff"], unname(hand))
})

test_that("hv_balance rejects an imputation list mixing classes", {
  skip_if_not_installed("cobalt")
  skip_if_not_installed("hvtiRpropensity")
  bt <- balance_baltab(balance_cohort(n_terms = 4))
  w  <- hvtiRpropensity::ps_weight(hvtiRpropensity::sample_ps_data(), covariates = "age")
  expect_error(hv_balance(list(bt, w)), "same kind")
})

test_that("hv_balance rejects imputations with different covariates", {
  skip_if_not_installed("cobalt")
  a <- balance_baltab(balance_cohort(n_terms = 4))
  b <- balance_baltab(balance_cohort(n_terms = 6))
  expect_error(hv_balance(list(a, b)), "differ")
})

test_that("hv_balance rejects an empty list and a partly-adapter list", {
  skip_if_not_installed("cobalt")
  expect_error(hv_balance(list()), "empty")
  bt <- balance_baltab(balance_cohort(n_terms = 4))
  expect_error(hv_balance(list(bt, data.frame())), "every element")
})

# A copy of `bt` whose adjusted variance ratios are `vr` and SMDs are `smd`.
pooled_variant <- function(bt, vr, smd) {
  cont <- bt$Balance$Type != "Binary"
  bt$Balance$V.Ratio.Adj[cont] <- vr
  bt$Balance$Diff.Adj[cont]    <- smd
  bt
}

test_that("imputation pooling takes the geometric mean of variance ratios", {
  skip_if_not_installed("cobalt")
  bt <- balance_baltab(balance_cohort(n_terms = 4))
  n_cont <- sum(bt$Balance$Type != "Binary")
  a <- pooled_variant(bt, vr = rep(0.5, n_cont), smd = rep(0.1, n_cont))
  b <- pooled_variant(bt, vr = rep(2, n_cont), smd = rep(0.3, n_cont))
  cb <- hv_balance(list(a, b), stats = c("smd", "variance_ratio"))
  vr  <- cb$data[cb$data$stat == "variance_ratio" & cb$data$group == "After", "std_diff"]
  smd <- cb$data[cb$data$stat == "smd" & cb$data$group == "After" &
                   cb$data$variable %in% rownames(bt$Balance)[bt$Balance$Type != "Binary"], "std_diff"]
  expect_equal(vr, rep(1, n_cont))
  expect_equal(smd, rep(20, n_cont))
})

test_that("an NA in any imputation makes the pooled value NA and counts it", {
  skip_if_not_installed("cobalt")
  bt <- balance_baltab(balance_cohort(n_terms = 4))
  a <- bt
  b <- bt
  b$Balance$Diff.Adj[1] <- NA_real_
  expect_warning(cb <- hv_balance(list(a, b)), "missing values")
  expect_true(is.na(cb$data$std_diff[cb$data$group == "After"][1]))
  expect_equal(cb$meta$n_missing, 1L)
})
