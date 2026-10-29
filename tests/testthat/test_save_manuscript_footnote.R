# Tests for save_manuscript(footnote =): the provenance note in a strip below
# the plot, fitted with the output device's metrics, wrapped and never clipped.
library(testthat)
library(ggplot2)

mk_plot <- function() ggplot(mtcars, aes(.data$mpg, .data$wt)) + geom_point()

long_job <- "30_analyses/rfs.explain.long_term_survival.primary.qmd"
note <- function(job = long_job) {
  provenance_footnote("3f9c2a1", job,
                      versions = c(R = "4.5.1", hvtiPlotR = "2.8.19", hvtiRtemplates = "1.5.3"),
                      time = as.POSIXct("2026-10-29 14:40", tz = "UTC"))
}

# Pixel height from a PNG's IHDR or a TIFF's first IFD, so no image package.
png_height <- function(path) {
  b <- readBin(path, "raw", 32L)
  sum(as.integer(b[21:24]) * 256^(3:0))
}
tiff_height <- function(path) {
  b <- readBin(path, "raw", file.size(path))
  big <- identical(rawToChar(b[1:2]), "MM")
  num <- function(i, n) {
    v <- as.integer(b[i:(i + n - 1L)])
    sum((if (big) v else rev(v)) * 256^((n - 1L):0))
  }
  ifd <- num(5L, 4L) + 1L
  for (k in seq_len(num(ifd, 2L))) {
    e <- ifd + 2L + (k - 1L) * 12L
    if (num(e, 2L) == 257L)
      return(if (num(e + 2L, 2L) == 3L) num(e + 8L, 2L) else num(e + 8L, 4L))
  }
  NA
}

# Text runs of an uncompressed PDF (`compress = FALSE` to the pdf device):
# font size (the length of the text matrix's first column, so a rotated axis
# title reads true), baseline y in points from the bottom, and the text with
# the kerning of a TJ array removed. Reads the file as bytes, so no PDF package.
pdf_text_runs <- function(path) {
  x <- readLines(path, warn = FALSE, encoding = "bytes")
  x <- x[grepl(" Tm ", x, useBytes = TRUE) & grepl("T[jJ]$", x, useBytes = TRUE)]
  num <- regmatches(x, regexpr("Tf [-0-9. ]+ Tm", x, useBytes = TRUE))
  num <- lapply(strsplit(sub(" Tm$", "", sub("^Tf ", "", num)), " "), as.numeric)
  text <- vapply(x, function(s) {
    s <- sub("^.* Tm ", "", s, useBytes = TRUE)
    s <- gsub("\\\\[()]", "", s, useBytes = TRUE)
    strings <- regmatches(s, gregexpr("\\(([^)]*)\\)", s, useBytes = TRUE))[[1]]
    paste(gsub("^\\(|\\)$", "", strings, useBytes = TRUE), collapse = "")
  }, "", USE.NAMES = FALSE)
  data.frame(size = vapply(num, function(m) sqrt(m[1]^2 + m[2]^2), 0), y = vapply(num, `[`, 0, 6L), text = text)
}

test_that("provenance_footnote() puts the commit first, as given", {
  f <- note()
  expect_identical(f, c("3f9c2a1", long_job, "R 4.5.1", "hvtiPlotR 2.8.19",
                        "hvtiRtemplates 1.5.3", "2026-10-29 14:40"))
  expect_true(all(c("R", "hvtiPlotR") %in% sub(" .*", "", provenance_footnote("abc", "j.qmd")[3:4])))
  # Never shortened: a failure marker stays whole, and so does an ID the
  # caller lengthened past 7 because 7 was ambiguous in its repository.
  expect_identical(provenance_footnote("uncommitted", "j.qmd")[1], "uncommitted")
  expect_identical(provenance_footnote("297b4408627", "j.qmd")[1], "297b4408627")
  expect_error(provenance_footnote("", "j.qmd"), "commit")
  expect_error(provenance_footnote("abc", NA_character_), "job")
  expect_error(provenance_footnote("abc", "j.qmd", versions = "4.5.1"), "named")
  expect_error(provenance_footnote("abc", "j.qmd", time = "2026-10-29"), "POSIXct")
})

test_that("save_manuscript() validates `footnote`", {
  f <- tempfile(fileext = ".pdf")
  expect_error(save_manuscript(mk_plot(), f, footnote = 1), "character")
  expect_error(save_manuscript(mk_plot(), f, footnote = NA_character_), "character")
  expect_error(save_manuscript(mk_plot(), f, footnote = " "), "empty")
  expect_error(save_manuscript(mk_plot(), f, footnote = c("abc1234", "a\nb")), "line breaks")
})

test_that("footnote = NULL writes exactly what save_manuscript() wrote before", {
  f0 <- tempfile(fileext = ".png")
  f1 <- tempfile(fileext = ".png")
  on.exit(unlink(c(f0, f1)), add = TRUE)
  ggsave(f0, mk_plot(), width = 6, height = 4, units = "in", dpi = 300)
  out <- save_manuscript(mk_plot(), f1, footnote = NULL)
  expect_identical(out, f1)
  expect_null(attributes(out))
  expect_identical(readBin(f1, "raw", file.size(f1)), readBin(f0, "raw", file.size(f0)))
})

test_that("a long job path is printed whole below the figure in PDF, PNG and TIFF", {
  for (ext in c("pdf", "png", "tiff")) {
    f <- tempfile(fileext = paste0(".", ext))
    out <- save_manuscript(mk_plot(), f, footnote = note())
    dims <- attr(out, "dims")
    expect_identical(dims$width, 6)
    expect_identical(dims$units, "in")
    # The plot keeps its 4 in; the strip is added below it.
    expect_gt(dims$height, 4)
    expect_lt(dims$height, 4.5)
    # The reported height is the height written, to the pixel, whatever the
    # device's rounding.
    if (ext == "png") expect_equal(png_height(f), dims$height * 300)
    if (ext == "tiff") expect_equal(tiff_height(f), dims$height * 300)
    unlink(f)
  }
})

test_that("the note lies in the strip, below the plot panel and its axes", {
  f <- tempfile(fileext = ".pdf")
  on.exit(unlink(f), add = TRUE)
  out <- save_manuscript(mk_plot(), f, footnote = note(), compress = FALSE)
  runs <- pdf_text_runs(f)
  strip_top <- (attr(out, "dims")$height - 4) * 72
  foot <- runs[runs$size <= 8, ]
  plot_text <- runs[runs$size > 8, ]
  expect_gt(nrow(foot), 0L)
  expect_gt(nrow(plot_text), 0L)
  # Each note line, baseline plus its size, stays inside the strip ...
  expect_true(all(foot$y + foot$size <= strip_top))
  # ... and the lowest text of the plot, the x-axis title below the panel,
  # stands above it, so the panel does too.
  expect_true(all(plot_text$y >= strip_top))
  expect_true(any(grepl(long_job, foot$text, fixed = TRUE)))
})

test_that("a path too long for one line at 6 pt wraps and reads back whole", {
  job <- paste0("30_analyses/", strrep("long_directory_name/", 8),
                "rfs.explain.long_term_survival.primary.qmd")
  f <- tempfile(fileext = ".pdf")
  on.exit(unlink(f), add = TRUE)
  out <- save_manuscript(mk_plot(), f, footnote = note(job), compress = FALSE)
  foot <- pdf_text_runs(f)
  foot <- foot[foot$size <= 8, ]
  expect_true(all(foot$size == 6))
  expect_gt(nrow(foot), 1L)
  foot <- foot[order(-foot$y), ]
  expect_true(startsWith(foot$text[1], "3f9c2a1"))
  expect_true(grepl(job, paste(foot$text, collapse = ""), fixed = TRUE))
  expect_gt(attr(out, "dims")$height, 4 + 2 * 6 * 1.2 / 72)
})

test_that("wrapping breaks between fields, then at / and ., never in the first field", {
  w <- function(s) nchar(s)
  sep <- " \u00b7 "
  # Fields fit on lines of their own: break between them.
  expect_identical(hvtiPlotR:::.wrap_footnote(c("abc1234", "x.qmd"), 10, w),
                   c("abc1234", "x.qmd"))
  # A path too long for a line: break after / and ., read back whole.
  lines <- hvtiPlotR:::.wrap_footnote(c("abc1234", "dir/sub/name.part.qmd"), 10, w)
  expect_identical(lines[1], "abc1234")
  expect_identical(paste(lines[-1], collapse = ""), "dir/sub/name.part.qmd")
  expect_true(all(grepl("[/.]$", head(lines[-1], -1))))
  # A first field that fits a line is never broken ...
  expect_identical(hvtiPlotR:::.wrap_footnote(c("abcde", "x/y"), 5, w)[1], "abcde")
  # ... and one that does not, free text rather than a commit, wraps too,
  # at spaces, and reads back whole.
  lines <- hvtiPlotR:::.wrap_footnote("one two three", 5, w)
  expect_true(all(nchar(lines) <= 5))
  expect_identical(paste(lines, collapse = ""), "one two three")
  # A piece with no / or . still never overflows.
  lines <- hvtiPlotR:::.wrap_footnote(c("a", strrep("z", 12)), 5, w)
  expect_true(all(nchar(lines) <= 5))
  expect_identical(paste(lines[-1], collapse = ""), strrep("z", 12))
  # Short fields share a line, joined by the separator.
  expect_identical(hvtiPlotR:::.wrap_footnote(c("a", "b"), 10, w), paste0("a", sep, "b"))
})

test_that("a single footnote string is split into fields at the separator", {
  expect_identical(hvtiPlotR:::.footnote_fields(paste(note(), collapse = " \u00b7 ")), note())
})

test_that("draft_file gets its own strip, measured on its own device", {
  f <- tempfile(fileext = ".pdf")
  d <- tempfile(fileext = ".png")
  on.exit(unlink(c(f, d)), add = TRUE)
  out <- save_manuscript(mk_plot(), f, draft_file = d, draft_dpi = 100, footnote = note())
  dd <- attr(out, "draft_dims")
  expect_gt(dd$height, 4)
  expect_equal(png_height(d), dd$height * 100)
})

test_that("units other than inches are honored", {
  f <- tempfile(fileext = ".png")
  on.exit(unlink(f), add = TRUE)
  out <- save_manuscript(mk_plot(), f, width = 152.4, height = 101.6, units = "mm", footnote = note())
  dims <- attr(out, "dims")
  expect_identical(dims$units, "mm")
  expect_gt(dims$height, 101.6)
  expect_equal(png_height(f), dims$height / 25.4 * 300)
})

test_that("a long single-string note wraps instead of running off the page", {
  text <- paste(rep("free text with no commit at its head", 5), collapse = " ")
  for (footnote in list(text, c(text, "R 4.5.1"))) {
    f <- tempfile(fileext = ".pdf")
    out <- save_manuscript(mk_plot(), f, footnote = footnote, compress = FALSE)
    foot <- pdf_text_runs(f)
    foot <- foot[foot$size <= 8, ]
    foot <- foot[order(-foot$y), ]
    expect_gt(nrow(foot), 1L)
    expect_true(all(foot$y >= 0))
    expect_true(grepl(text, paste(foot$text, collapse = ""), fixed = TRUE))
    unlink(f)
  }
})

test_that("a patchwork keeps every panel when saved with a footnote", {
  pw <- patchwork::wrap_plots(mk_plot() + labs(x = "left_panel_x"),
                              mk_plot() + labs(x = "right_panel_x"))
  f <- tempfile(fileext = ".pdf")
  on.exit(unlink(f), add = TRUE)
  save_manuscript(pw, f, footnote = note(), compress = FALSE)
  text <- pdf_text_runs(f)$text
  expect_true(all(c("left_panel_x", "right_panel_x") %in% text))
})

test_that("`scale` sizes the note and the reported dims alike", {
  f <- tempfile(fileext = ".pdf")
  on.exit(unlink(f), add = TRUE)
  out <- save_manuscript(mk_plot(), f, footnote = note(), scale = 0.5, compress = FALSE)
  dims <- attr(out, "dims")
  expect_equal(dims$width, 3)
  box <- regmatches(readLines(f, warn = FALSE, encoding = "bytes"),
                    regexpr("/MediaBox \\[[0-9. ]+\\]", readLines(f, warn = FALSE, encoding = "bytes"),
                            useBytes = TRUE))
  box <- as.numeric(strsplit(gsub("[^0-9. ]", "", box[1]), " +")[[1]])
  box <- box[!is.na(box)]
  expect_equal(box[3:4] / 72, c(3, dims$height), tolerance = 1e-3)
  foot <- pdf_text_runs(f)
  foot <- foot[foot$size <= 8, ]
  expect_true(grepl(long_job, paste(foot$text, collapse = ""), fixed = TRUE))
})

test_that("saving with a footnote leaves no device open and no Rplots.pdf", {
  dir <- withr::local_tempdir()
  withr::local_dir(dir)
  before <- grDevices::dev.list()
  save_manuscript(mk_plot(), file.path(dir, "f.pdf"), footnote = note())
  expect_identical(grDevices::dev.list(), before)
  expect_false(file.exists(file.path(dir, "Rplots.pdf")))
})
