# tests/testthat/test_venn.R
library(testthat)
library(ggplot2)

test_that(".venn_regions counts the 3 regions of a 2-set frame", {
  df <- data.frame(
    A = c(TRUE,  TRUE,  FALSE, TRUE,  FALSE),
    B = c(FALSE, TRUE,  TRUE,  FALSE, FALSE)
  )
  reg <- .venn_regions(df, c("A", "B"))
  expect_equal(nrow(reg), 3L)                       # A only, B only, A & B
  expect_setequal(reg$region, c("A only", "B only", "A & B"))
  expect_equal(reg$n[reg$region == "A only"], 2L)   # rows 1,4
  expect_equal(reg$n[reg$region == "B only"], 1L)   # row 3
  expect_equal(reg$n[reg$region == "A & B"], 1L)    # row 2
})

test_that(".venn_regions has 7 regions for 3 sets and treats NA as absent", {
  df <- data.frame(
    A = c(TRUE,  TRUE,  NA),
    B = c(TRUE,  FALSE, FALSE),
    C = c(TRUE,  FALSE, FALSE)
  )
  reg <- .venn_regions(df, c("A", "B", "C"))
  expect_equal(nrow(reg), 7L)
  expect_equal(reg$n[reg$region == "A & B & C"], 1L)  # row 1
  expect_equal(reg$n[reg$region == "A only"], 1L)     # row 2 (row 3 NA->absent)
  expect_equal(sum(reg$n), 2L)                        # row 3 is all-absent, uncounted
})

test_that("hv_venn returns an hv_venn / hv_data object with region table", {
  dta <- sample_upset_data(n = 200, seed = 1)
  v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement", "CABG"))
  expect_s3_class(v, "hv_venn")
  expect_s3_class(v, "hv_data")
  expect_equal(v$meta$sets, c("AV_Replacement", "MV_Replacement", "CABG"))
  expect_equal(v$meta$n_sets, 3L)
  expect_equal(nrow(v$tables$regions), 7L)
})

test_that("hv_venn errors on fewer than 2 sets", {
  dta <- sample_upset_data(n = 50, seed = 1)
  expect_error(hv_venn(dta, sets = "CABG"), "at least 2")
})

test_that("hv_venn errors on more than 3 sets and names hv_upset", {
  dta <- sample_upset_data(n = 50, seed = 1)
  expect_error(
    hv_venn(dta, sets = c("AV_Replacement", "AV_Repair",
                          "MV_Replacement", "CABG")),
    "hv_upset"
  )
})

test_that("hv_venn errors on a non-binary column", {
  dta <- sample_upset_data(n = 50, seed = 1)
  dta$age <- rnorm(nrow(dta), 65, 10)
  expect_error(hv_venn(dta, sets = c("CABG", "age")), "binary")
})

test_that("hv_venn errors on a missing column", {
  dta <- sample_upset_data(n = 50, seed = 1)
  expect_error(hv_venn(dta, sets = c("CABG", "nonexistent")),
               "not found|not a column|not in|Missing")
})

test_that("plot(hv_venn) returns a ggplot", {
  dta <- sample_upset_data(n = 200, seed = 1)
  v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement"))
  expect_s3_class(plot(v), "ggplot")
})

test_that("plot(hv_venn) is composable with theme_hv_manuscript()", {
  dta <- sample_upset_data(n = 200, seed = 1)
  v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement", "CABG"))
  p   <- plot(v) + theme_hv_manuscript()
  expect_s3_class(p, "ggplot")
})

test_that("plot(hv_venn) accepts show_percentage and a fill override", {
  dta <- sample_upset_data(n = 200, seed = 1)
  v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement"))
  p   <- plot(v, show_percentage = FALSE,
              fill = c("steelblue", "firebrick"))
  expect_s3_class(p, "ggplot")
})

test_that("plot(hv_venn) errors on a wrong-length fill", {
  dta <- sample_upset_data(n = 100, seed = 1)
  v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement", "CABG"))
  expect_error(plot(v, fill = c("red", "blue")), "one colour per set")
})

test_that("plot(hv_venn) errors when fill and fill_color are both given", {
  dta <- sample_upset_data(n = 100, seed = 1)
  v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement"))
  expect_error(
    plot(v, fill = c("red", "blue"), fill_color = c("green", "yellow")),
    "not `fill_color`"
  )
})

test_that("print.hv_venn produces a <hv_venn> header", {
  dta <- sample_upset_data(n = 100, seed = 1)
  v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement"))
  expect_output(print(v), "<hv_venn>")
  expect_output(print(v), "N patients")
  expect_output(print(v), "Sets")
  expect_output(print(v), "Regions\\s*:\\s*3")  # 2 sets => 3 regions
})

test_that("print.hv_venn returns x invisibly", {
  dta <- sample_upset_data(n = 100, seed = 1)
  v   <- hv_venn(dta, sets = c("AV_Replacement", "MV_Replacement"))
  ret <- withVisible(print(v))
  expect_false(ret$visible)
  expect_identical(ret$value, v)
})
