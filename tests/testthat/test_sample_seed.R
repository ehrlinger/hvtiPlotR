library(testthat)

# Every sample_*() generator that takes `seed` must leave the caller's random
# number stream as it found it. A generator that called set.seed() and left it
# there silently reset the stream of any script that seeded once at the top, so
# everything drawn after the first sample_*() call stopped depending on the
# script's own seed.
seeded_generators <- function() {
  exports <- getNamespaceExports("hvtiPlotR")
  gens <- sort(grep("^sample_", exports, value = TRUE))
  gens[vapply(gens, function(g) {
    "seed" %in% names(formals(getExportedValue("hvtiPlotR", g)))
  }, logical(1))]
}

test_that("seeded sample_*() generators exist to check", {
  expect_gt(length(seeded_generators()), 20L)
})

test_that("sample_*() generators restore the caller's RNG stream", {
  for (g in seeded_generators()) {
    fn <- getExportedValue("hvtiPlotR", g)

    set.seed(1)
    expected <- stats::runif(3)

    set.seed(1)
    fn()
    expect_identical(stats::runif(3), expected, label = g)
  }
})

test_that("sample_*() generators leave an unseeded session unseeded", {
  withr::local_preserve_seed()
  for (g in seeded_generators()) {
    fn <- getExportedValue("hvtiPlotR", g)

    suppressWarnings(rm(".Random.seed", envir = globalenv()))
    fn()
    expect_false(
      exists(".Random.seed", envir = globalenv(), inherits = FALSE),
      label = g
    )
  }
})

test_that("sample_*() generators stay reproducible for a given seed", {
  for (g in seeded_generators()) {
    fn <- getExportedValue("hvtiPlotR", g)
    expect_identical(fn(seed = 7L), fn(seed = 7L), label = g)
  }
})
