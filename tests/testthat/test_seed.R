# Every exported generator with a `seed` argument: the default seed leaves the
# caller's random-number stream as it was, and seed = NULL opts out, drawing
# from that stream without setting a seed (CRAN Cookbook, "Setting a specific
# seed").

.seeded_generators <- function() {
  ns <- getNamespaceExports("hvtiPlotR")
  fns <- ns[vapply(ns, function(nm) {
    f <- get(nm, envir = asNamespace("hvtiPlotR"))
    is.function(f) && "seed" %in% names(formals(f))
  }, logical(1))]
  sort(fns)
}

test_that("the seeded generators are found", {
  expect_gt(length(.seeded_generators()), 15L)
})

test_that("the default seed restores the caller's stream", {
  for (nm in .seeded_generators()) {
    f <- getExportedValue("hvtiPlotR", nm)
    withr::local_seed(1)
    before <- .Random.seed
    suppressMessages(f())
    expect_identical(.Random.seed, before, info = nm)
  }
})

test_that("seed = NULL sets no seed and draws from the caller's stream", {
  for (nm in .seeded_generators()) {
    f <- getExportedValue("hvtiPlotR", nm)
    withr::local_seed(1)
    a <- expect_no_warning(suppressMessages(f(seed = NULL)))
    withr::local_seed(1)
    b <- suppressMessages(f(seed = NULL))
    expect_identical(a, b, info = nm)
  }
})
