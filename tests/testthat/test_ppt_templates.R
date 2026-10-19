# Layout contract and slate template (spec 2026-10-19).
library(testthat)

tpl <- function(name) system.file("extdata", name, package = "hvtiPlotR")

contract <- list(
  `Title Slide`       = c("ctrTitle", "subTitle"),
  `Section Header`    = "title",
  `Title and Content` = c("body", "title"),
  `Two Content`       = c("body", "title"),
  `Title Only`        = "title",
  Blank               = character()
)
templates <- c("hv_ppt_template.pptx", "hv_ppt_template_light.pptx")

test_that("every bundled template carries the layout contract", {
  skip_if_not_installed("officer")
  for (f in templates) {
    doc <- officer::read_pptx(tpl(f))
    lays <- officer::layout_summary(doc)$layout
    props <- officer::layout_properties(doc)
    expect_false(anyDuplicated(lays) > 0, info = f)
    for (nm in names(contract)) {
      expect_true(nm %in% lays, info = paste(f, nm))
      expect_true(all(contract[[nm]] %in% props$type[props$name == nm]),
                  info = paste(f, nm))
    }
  }
})

test_that("old layout names are gone from the bundled templates", {
  skip_if_not_installed("officer")
  for (f in templates) {
    lays <- officer::layout_summary(officer::read_pptx(tpl(f)))$layout
    expect_false(any(c("Custom Layout", "1_Custom Layout", "1_Title Slide",
                       "1_Title Only") %in% lays), info = f)
  }
})
