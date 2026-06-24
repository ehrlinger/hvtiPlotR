# tests/testthat/test_cluster_sankey.R
#
# Test suite for cluster-sankey-plot.R:
#   sample_cluster_sankey_data, cluster_sankey_plot
#
library(testthat)
library(ggplot2)

# ============================================================================
# sample_cluster_sankey_data
# ============================================================================

test_that("sample_cluster_sankey_data returns a data frame", {
  df <- sample_cluster_sankey_data(n = 100, seed = 1)
  expect_true(is.data.frame(df))
})

test_that("sample_cluster_sankey_data returns n rows", {
  df <- sample_cluster_sankey_data(n = 150, seed = 1)
  expect_equal(nrow(df), 150L)
})

test_that("sample_cluster_sankey_data has columns C2 through C9", {
  df <- sample_cluster_sankey_data(n = 100, seed = 1)
  expected_cols <- paste0("C", 2:9)
  expect_true(all(expected_cols %in% names(df)))
})

test_that("sample_cluster_sankey_data all columns are factors", {
  df <- sample_cluster_sankey_data(n = 100, seed = 1)
  are_factors <- sapply(df, is.factor)
  expect_true(all(are_factors))
})

test_that("sample_cluster_sankey_data C2 has exactly 2 levels", {
  df <- sample_cluster_sankey_data(n = 200, seed = 1)
  expect_equal(nlevels(df$C2), 2L)
})

test_that("sample_cluster_sankey_data C9 has exactly 9 levels", {
  df <- sample_cluster_sankey_data(n = 200, seed = 1)
  expect_equal(nlevels(df$C9), 9L)
})

test_that("sample_cluster_sankey_data each Ck has exactly k levels", {
  df <- sample_cluster_sankey_data(n = 300, seed = 42)
  for (k in 2:9) {
    col <- paste0("C", k)
    expect_equal(nlevels(df[[col]]), k,
                 label = sprintf("nlevels(C%d) == %d", k, k))
  }
})

test_that("sample_cluster_sankey_data C2 assignment is consistent with C9 merge tree", {
  df <- sample_cluster_sankey_data(n = 500, seed = 42)
  # All patients assigned C9 cluster A should have C2 = A
  a_rows <- df[df$C9 == "A", ]
  expect_true(all(as.character(a_rows$C2) == "A"))
  # All patients assigned C9 cluster B should have C2 = B
  b_rows <- df[df$C9 == "B", ]
  expect_true(all(as.character(b_rows$C2) == "B"))
})

test_that("sample_cluster_sankey_data no missing values", {
  df    <- sample_cluster_sankey_data(n = 200, seed = 1)
  has_na <- any(sapply(df, anyNA))
  expect_false(has_na)
})

test_that("sample_cluster_sankey_data is reproducible with same seed", {
  df1 <- sample_cluster_sankey_data(n = 100, seed = 7)
  df2 <- sample_cluster_sankey_data(n = 100, seed = 7)
  expect_identical(df1, df2)
})

test_that("sample_cluster_sankey_data differs across seeds", {
  df1 <- sample_cluster_sankey_data(n = 200, seed = 1)
  df2 <- sample_cluster_sankey_data(n = 200, seed = 2)
  expect_false(identical(df1, df2))
})

test_that("sample_cluster_sankey_data custom probs shifts cluster distribution", {
  # Give all weight to cluster A: expect almost all C2 rows to be "A"
  probs_a <- c(B = 0, F = 0, H = 0, D = 0, I = 0, C = 0, E = 0, G = 0, A = 1)
  df <- sample_cluster_sankey_data(n = 200, probs = probs_a, seed = 1)
  expect_true(all(as.character(df$C2) == "A"))
})

# ============================================================================
# hv_sankey + plot.hv_sankey
# ============================================================================

test_that("hv_sankey returns an hv_data object", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 100, seed = 1)
  expect_s3_class(hv_sankey(dta), "hv_data")
})

test_that("plot(hv_sankey) returns a ggplot (all K = 2:9)", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 100, seed = 1)
  expect_s3_class(plot(hv_sankey(dta)), "ggplot")
})

test_that("plot(hv_sankey) works with a subset of cluster columns", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 100, seed = 1)
  expect_s3_class(
    plot(hv_sankey(dta, cluster_cols = c("C2", "C3", "C4"))),
    "ggplot"
  )
})

test_that("plot(hv_sankey) is composable with + operator", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 100, seed = 1)
  p   <- plot(hv_sankey(dta)) + ggplot2::labs(x = "Number of clusters (K)")
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$x, "Number of clusters (K)")
})

test_that("plot(hv_sankey) is composable with theme_hv_manuscript()", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 100, seed = 1)
  p   <- plot(hv_sankey(dta)) + theme_hv_manuscript()
  expect_s3_class(p, "ggplot")
})

test_that("hv_sankey errors when data is not a data frame", {
  skip_if_not_installed("ggsankey")
  expect_error(
    hv_sankey(list(C2 = "A", C3 = "A")),
    "data.frame|data frame"
  )
})

test_that("hv_sankey errors when cluster_cols has fewer than 2 elements", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 50, seed = 1)
  expect_error(
    hv_sankey(dta, cluster_cols = "C2"),
    "at least 2|at least two|fewer than"
  )
})

test_that("hv_sankey errors when a cluster column is absent from data", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 50, seed = 1)
  expect_error(
    hv_sankey(dta, cluster_cols = c("C2", "nonexistent")),
    "not found|not a column|not in"
  )
})

# ============================================================================
# Lineage-preserving node order (.derive_node_order) and defaults
# ============================================================================

test_that("hv_sankey long data has no NA nodes and covers all 9 labels", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 300, seed = 42)
  sn  <- hv_sankey(dta)
  expect_false(anyNA(sn$data$node))
  # next_node is NA only on the final column (no successor); earlier cols clean
  non_terminal <- sn$data[!is.na(sn$data$next_x), ]
  expect_false(anyNA(non_terminal$next_node))
  expect_setequal(sn$meta$node_levels, LETTERS[1:9])
})

test_that(".derive_node_order reproduces the canonical AVSD lineage order", {
  dta <- sample_cluster_sankey_data(n = 2000, seed = 42)
  expect_identical(
    .derive_node_order(dta, paste0("C", 2:9)),
    c("B", "F", "H", "D", "I", "C", "E", "G", "A")
  )
})

test_that("explicit node_levels missing an observed label errors", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 200, seed = 1)
  expect_error(
    hv_sankey(dta, node_levels = LETTERS[1:8]),   # drops "I"
    "cover all observed|missing"
  )
})

test_that("complete explicit node_levels is used verbatim", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 200, seed = 1)
  lev <- c("A", "B", "C", "D", "E", "F", "G", "H", "I")
  sn  <- hv_sankey(dta, node_levels = lev)
  expect_identical(sn$meta$node_levels, lev)
})

test_that("default node_colours map Set1 in node_levels order", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 200, seed = 1)
  sn  <- hv_sankey(dta)
  expect_identical(names(sn$meta$node_colours), sn$meta$node_levels)
  expect_equal(unname(sn$meta$node_colours[1]), "#E41A1C")  # Set1[1]
})

# ============================================================================
# plot.hv_sankey styling arguments
# ============================================================================

test_that("flow_alpha and label_alpha reach the corresponding layers", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 100, seed = 1)
  p   <- plot(hv_sankey(dta), flow_alpha = 0.4, label_alpha = 0.2)
  alphas <- vapply(p$layers, function(l) {
    a <- l$aes_params$alpha
    if (is.null(a)) NA_real_ else a
  }, numeric(1L))
  expect_true(0.4 %in% alphas)   # geom_vline + geom_sankey
  expect_true(0.2 %in% alphas)   # geom_sankey_label
})

test_that("deprecated alpha sets both alphas and emits a message", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 100, seed = 1)
  expect_message(p <- plot(hv_sankey(dta), alpha = 0.7), "deprecated")
  alphas <- vapply(p$layers, function(l) {
    a <- l$aes_params$alpha
    if (is.null(a)) NA_real_ else a
  }, numeric(1L))
  expect_true(all(c(0.7) %in% alphas))
  expect_false(any(c(0.5, 0.3) %in% alphas))
})

test_that("group_labels produce milestone x-axis labels for listed columns", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 100, seed = 1)
  p   <- plot(
    hv_sankey(dta),
    group_labels = c(C2 = "2 groups", C7 = "5 groups")
  )
  x_scale <- p$scales$get_scales("x")
  expect_true("C2\n2 groups" %in% x_scale$labels)
  expect_true("C7\n5 groups" %in% x_scale$labels)
  expect_true("C3" %in% x_scale$labels)  # unlisted column stays bare
})

test_that(".derive_node_order drops NA and covers all observed labels", {
  dta <- data.frame(
    C2 = c("A", "B", "A", NA),
    C3 = c("A", "B", "C", "B"),
    stringsAsFactors = FALSE
  )
  ord <- .derive_node_order(dta, c("C2", "C3"))
  expect_false(anyNA(ord))
  expect_setequal(ord, c("A", "B", "C"))  # every non-NA label covered
})

test_that("plot.hv_sankey errors on unnamed group_labels", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 100, seed = 1)
  expect_error(
    plot(hv_sankey(dta), group_labels = c("2 groups", "5 groups")),
    "named"
  )
})

test_that("plot.hv_sankey warns on group_labels names matching no column", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 100, seed = 1)
  expect_warning(
    plot(hv_sankey(dta), group_labels = c(C2 = "2 groups", CX = "nope")),
    "match no cluster"
  )
})

# ---------------------------------------------------------------------------
# print.hv_sankey coverage
# ---------------------------------------------------------------------------

test_that("print.hv_sankey produces <hv_sankey> header", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 100, seed = 1)
  obj <- hv_sankey(dta)
  expect_output(print(obj), "<hv_sankey>")
})

test_that("print.hv_sankey returns x invisibly", {
  skip_if_not_installed("ggsankey")
  dta <- sample_cluster_sankey_data(n = 100, seed = 1)
  obj <- hv_sankey(dta)
  ret <- withVisible(print(obj))
  expect_false(ret$visible)
  expect_identical(ret$value, obj)
})
