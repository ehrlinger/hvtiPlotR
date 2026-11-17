# seed.R
# The sample_*() generators default to seed = 42 so examples and vignettes
# draw the same data every time, and restore the caller's RNG state on exit.
# seed = NULL opts out (CRAN Cookbook, "Setting a specific seed"): the draw
# then uses the session's current random-number stream and no seed is set.
.hv_local_seed <- function(seed, envir = parent.frame()) {
  if (!is.null(seed)) withr::local_seed(seed, .local_envir = envir)
  invisible()
}

# The per-group seed some generators derive from `seed`; NULL stays NULL.
.hv_offset_seed <- function(seed, offset) {
  if (is.null(seed)) NULL else seed + offset
}
