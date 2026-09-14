test_that("ggsankey is a hard dependency with its GitHub remote", {
  path <- system.file("DESCRIPTION", package = "hvtiPlotR")
  description <- read.dcf(path)
  imports <- trimws(strsplit(description[1L, "Imports"], ",")[[1L]])

  expect_true(any(grepl("^ggsankey(?:\\s|$)", imports)))
  expect_match(
    description[1L, "Remotes"],
    "(?:^|,)\\s*davidsjoberg/ggsankey(?:\\s|,|$)"
  )
})
