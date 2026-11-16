# Conformance with the hvtiR API rubric's shared specs. Each hvtiR package
# carries its own copy of these tests.

test_that(".hvti_inform() is silenced by options(hvti.quiet = TRUE), and only it", {
  expect_message(.hvti_inform("hello"), "hello")
  withr::local_options(hvti.quiet = TRUE)
  expect_silent(.hvti_inform("hello"))
})

test_that("informational messages respect hvti.quiet", {
  df <- sample_mirror_histogram_data(60)
  df$prob_t[1:3] <- NA
  expect_message(hv_mirror_hist(df, group_col = "tavr", group_labels = c("A", "B")),
                 "hv_mirror_hist\\(\\): dropped")
  withr::local_options(hvti.quiet = TRUE)
  expect_silent(hv_mirror_hist(df, group_col = "tavr", group_labels = c("A", "B")))
})

rec <- function(...) {
  r <- list(package = "hvtiRbootstrap", version = "1.0.4", sha = "3f9c2a1",
            method = "stepwise", seed = 42L, rng_kind = RNGkind(),
            time = as.POSIXct("2026-10-29 14:40", tz = "UTC"))
  utils::modifyList(r, list(...))
}

test_that("provenance_footnote() reads the seven-field provenance record", {
  out <- provenance_footnote(job = "30_analyses/boot.qmd", versions = c(R = "4.5.1"),
                             record = rec())
  expect_identical(out, c("3f9c2a1", "30_analyses/boot.qmd", "R 4.5.1",
                          "hvtiRbootstrap 1.0.4", "2026-10-29 14:40", "seed 42"))
})

test_that("an NA field in the record prints a gap, not a plausible value", {
  out <- provenance_footnote(job = "j.qmd", versions = c(R = "4.5.1"),
                             record = rec(sha = NA_character_, seed = NA_integer_))
  expect_identical(out[1], "commit unknown")
  expect_false(any(grepl("^seed", out)))
})

test_that("explicit commit and time win over the record", {
  out <- provenance_footnote("abc1234", "j.qmd", versions = c(R = "4.5.1"),
                             time = as.POSIXct("2026-01-01 09:00", tz = "UTC"),
                             record = rec())
  expect_identical(out[1], "abc1234")
  expect_true("2026-01-01 09:00" %in% out)
})

test_that("a record missing a field or of the wrong type is refused", {
  bad <- rec()
  bad$rng_kind <- NULL
  expect_error(provenance_footnote(job = "j", record = bad), "lacks field\\(s\\) `rng_kind`")
  expect_error(provenance_footnote(job = "j", record = rec(seed = 42)), "record\\$seed")
  expect_error(provenance_footnote(job = "j", record = rec(rng_kind = "Mersenne-Twister")),
               "record\\$rng_kind")
})

test_that("catchable errors carry hvtiPlotR_<condition> classes", {
  expect_error(hv_survival(data.frame(a = 1), time_col = "t", event_col = "e"),
               class = "hvtiPlotR_missing_column")
  expect_error(hv_role_palette(letters[1:8]), class = "hvtiPlotR_role_palette_capacity")
  expect_error(hv_role_palette(letters[1:8]), class = "hv_role_palette_capacity")
  expect_error(hv_group_palette(paste0("g", 1:8)), class = "hvtiPlotR_group_palette_capacity")
})

test_that("an NA time in the record prints a gap too", {
  out <- provenance_footnote(job = "j.qmd", versions = c(R = "4.5.1"),
                             record = rec(time = as.POSIXct(NA)))
  expect_identical(out, c("3f9c2a1", "j.qmd", "R 4.5.1", "hvtiRbootstrap 1.0.4",
                          "time unknown", "seed 42"))
})

test_that("provenance_footnote() errors name the function and carry a class", {
  expect_error(provenance_footnote(commit = 1, job = "j"),
               "^provenance_footnote\\(\\): `commit`", class = "hvtiPlotR_invalid_provenance")
  expect_error(provenance_footnote(commit = "c", job = "j", versions = "4.5.1"),
               "^provenance_footnote\\(\\): `versions`", class = "hvtiPlotR_invalid_provenance")
  expect_error(provenance_footnote(commit = "c", job = "j", time = "today"),
               "^provenance_footnote\\(\\): `time`", class = "hvtiPlotR_invalid_provenance")
  expect_error(provenance_footnote(job = "j", record = list(package = "x")),
               "^provenance_footnote\\(\\): `record`", class = "hvtiPlotR_invalid_provenance")
})

test_that("the slides use save_ppt()'s current argument name", {
  qmd <- system.file("slides", "hvtiPlotR-whats-new.qmd", package = "hvtiPlotR")
  skip_if(!nzchar(qmd), "slides not installed")
  expect_false(any(grepl("powerpoint", readLines(qmd, warn = FALSE))))
})
