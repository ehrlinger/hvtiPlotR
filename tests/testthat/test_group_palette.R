# Tests for hv_group_palette(): colors for the groups compared in an outcome figure.
library(testthat)

vibrant <- c("#CC3311", "#0077BB", "#009988", "#EE3377", "#33BBEE")

# WCAG contrast of a color against white.
contrast_on_white <- function(hex) {
  rgb <- grDevices::col2rgb(hex)[, 1] / 255
  lin <- ifelse(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055)^2.4)
  1.05 / (sum(c(0.2126, 0.7152, 0.0722) * lin) + 0.05)
}

test_that("a single group is black", {
  expect_identical(hv_group_palette("All"), c(All = "#000000"))
})

test_that("two to five groups take Tol vibrant led by red and blue, named by group", {
  for (n in 2:5) {
    lv <- paste0("g", seq_len(n))
    expect_identical(hv_group_palette(lv), stats::setNames(vibrant[seq_len(n)], lv))
  }
  # Red and blue are the role colors: the same hexes, now free for groups.
  expect_identical(unname(hv_group_palette(c("a", "b"))),
                   unname(hv_role_palette(c("e", "c"), event = "e", censored = "c")))
})

test_that("a group's color follows its position in levels, not its name", {
  expect_identical(unname(hv_group_palette(c("Robotic", "Sternotomy"))),
                   unname(hv_group_palette(c("Sternotomy", "Robotic"))))
})

test_that("six and seven groups all switch to the muted overflow", {
  for (n in 6:7) {
    pal <- hv_group_palette(paste0("g", seq_len(n)))
    expect_length(unique(pal), n)
    expect_false(any(pal %in% vibrant))
  }
})

test_that("every group color clears 2:1 against white", {
  pal <- c(hv_group_palette(paste0("g", 1:5)), hv_group_palette(paste0("g", 1:7)))
  expect_true(all(vapply(pal, contrast_on_white, numeric(1)) >= 2))
})

test_that("more groups than the palettes hold is a classed error", {
  expect_error(hv_group_palette(paste0("g", 1:8)), class = "hv_group_palette_capacity")
})

test_that("levels must be distinct, non-missing text", {
  expect_error(hv_group_palette(character()), "non-empty")
  expect_error(hv_group_palette(c("a", "a")), "distinct")
  expect_error(hv_group_palette(c("a", NA)), "non-missing")
  expect_error(hv_group_palette(1:2), "character")
})
