# The seed contract of every exported generator with a `seed` argument
# (CRAN Cookbook, "Setting a specific seed").
#
# Random generators: the default seed leaves the caller's random-number
# stream as it was, different seeds give different data, and seed = NULL
# sets no seed but draws from (and so advances) the caller's stream.
#
# Deterministic generators compute their curve analytically. `seed` is kept
# for a uniform signature and has no effect; their docs say so. Naming them
# here means a generator that starts or stops drawing fails a test.

.deterministic_generators <- c(
  "sample_hazard_data",
  "sample_nnt_data",
  "sample_nonparametric_curve_data",
  "sample_nonparametric_ordinal_data",
  "sample_survival_difference_data"
)

.seeded_generators <- function() {
  ns <- getNamespaceExports("hvtiPlotR")
  sort(ns[vapply(ns, function(nm) {
    f <- get(nm, envir = asNamespace("hvtiPlotR"))
    is.function(f) && "seed" %in% names(formals(f))
  }, logical(1))])
}

.call <- function(nm, ...) suppressMessages(getExportedValue("hvtiPlotR", nm)(...))

test_that("the seeded generators are found, and every deterministic one exists", {
  gens <- .seeded_generators()
  expect_gt(length(gens), 20L)
  expect_true(all(.deterministic_generators %in% gens))
})

test_that("no generator disturbs the caller's stream with its default seed", {
  for (nm in .seeded_generators()) {
    withr::local_seed(1)
    before <- .Random.seed
    .call(nm)
    expect_identical(.Random.seed, before, info = nm)
  }
})

test_that("random generators: different seeds differ, and seed = NULL draws from the stream", {
  for (nm in setdiff(.seeded_generators(), .deterministic_generators)) {
    expect_false(identical(.call(nm, seed = 1), .call(nm, seed = 2)), info = nm)

    withr::local_seed(17)
    before <- .Random.seed
    a <- expect_no_warning(.call(nm, seed = NULL))
    expect_false(identical(.Random.seed, before), info = nm)

    withr::local_seed(17)
    expect_identical(.call(nm, seed = NULL), a, info = nm)
  }
})

test_that("deterministic generators ignore seed and leave the stream alone", {
  for (nm in .deterministic_generators) {
    expect_identical(.call(nm, seed = 1), .call(nm, seed = 2), info = nm)

    withr::local_seed(17)
    before <- .Random.seed
    expect_no_warning(.call(nm, seed = NULL))
    expect_identical(.Random.seed, before, info = nm)
  }
})
