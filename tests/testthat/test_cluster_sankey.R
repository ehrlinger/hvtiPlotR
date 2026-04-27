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
