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
