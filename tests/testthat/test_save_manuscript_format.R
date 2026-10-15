# Tests for save_manuscript()'s raster `format`: TIFF by default, PNG on
# request, and an extension the caller wrote always wins.
library(testthat)
library(ggplot2)

mk_plot <- function() ggplot(mtcars, aes(.data$mpg, .data$wt)) + geom_point()

# Pixel size, resolution (dpi) and, for TIFF, the compression tag, read from
# the file header so the tests need no image package.
read_png_header <- function(path) {
  b <- readBin(path, "raw", 4096L)
  u32 <- function(i) sum(as.integer(b[i:(i + 3L)]) * 256^(3:0))
  phys <- grepRaw("pHYs", b)
  list(width = u32(17L), height = u32(21L),
       dpi = round(u32(phys + 4L) * 0.0254))
}

read_tiff_header <- function(path) {
  b <- readBin(path, "raw", file.size(path))
  big <- identical(rawToChar(b[1:2]), "MM")
  num <- function(i, n) {
    v <- as.integer(b[i:(i + n - 1L)])
    sum((if (big) v else rev(v)) * 256^((n - 1L):0))
  }
  ifd <- num(5L, 4L) + 1L
  tags <- list()
  for (k in seq_len(num(ifd, 2L))) {
    e <- ifd + 2L + (k - 1L) * 12L
    type <- num(e + 2L, 2L)
    tags[[as.character(num(e, 2L))]] <- switch(
      as.character(type),
      "3" = num(e + 8L, 2L),
      "4" = num(e + 8L, 4L),
      "5" = {
        o <- num(e + 8L, 4L) + 1L
        num(o, 4L) / num(o + 4L, 4L)
      },
      NA
    )
  }
  list(width = tags[["256"]], height = tags[["257"]],
       compression = tags[["259"]], dpi = round(tags[["282"]]))
}

test_that("a path without an extension is written as a TIFF by default", {
  f <- file.path(withr::local_tempdir(), "fig")
  out <- save_manuscript(mk_plot(), f)
  expect_identical(out, paste0(f, ".tiff"))
  expect_true(file.exists(out))
  h <- read_tiff_header(out)
  expect_identical(c(h$width, h$height), c(1800, 1200))
  expect_identical(h$dpi, 300)
  expect_identical(h$compression, 5) # LZW
})

test_that("format = \"png\" writes a PNG with the same geometry", {
  f <- file.path(withr::local_tempdir(), "fig")
  out <- save_manuscript(mk_plot(), f, format = "png")
  expect_identical(out, paste0(f, ".png"))
  h <- read_png_header(out)
  expect_identical(c(h$width, h$height), c(1800, 1200))
  expect_identical(h$dpi, 300)
})

test_that("an explicit .tif or .tiff extension writes a compressed TIFF", {
  d <- withr::local_tempdir()
  for (ext in c(".tif", ".tiff")) {
    f <- file.path(d, paste0("fig", ext))
    expect_identical(save_manuscript(mk_plot(), f, width = 3, height = 2,
                                     dpi = 600), f)
    h <- read_tiff_header(f)
    expect_identical(c(h$width, h$height), c(1800, 1200))
    expect_identical(h$dpi, 600)
    expect_identical(h$compression, 5)
  }
})

test_that("an explicit .png extension stays PNG under the TIFF default", {
  f <- file.path(withr::local_tempdir(), "fig.png")
  expect_identical(save_manuscript(mk_plot(), f), f)
  expect_identical(readBin(f, "raw", 4L)[2:4], charToRaw("PNG"))
})

test_that("draft_file without an extension follows format", {
  d <- withr::local_tempdir()
  save_manuscript(mk_plot(), file.path(d, "fig.pdf"),
                  draft_file = file.path(d, "draft"), draft_dpi = 150)
  h <- read_tiff_header(file.path(d, "draft.tiff"))
  expect_identical(c(h$width, h$height, h$dpi), c(900, 600, 150))
  save_manuscript(mk_plot(), file.path(d, "fig.pdf"),
                  draft_file = file.path(d, "draft"), format = "png")
  expect_true(file.exists(file.path(d, "draft.png")))
})

test_that("a format that contradicts the extension is an error", {
  d <- withr::local_tempdir()
  expect_error(save_manuscript(mk_plot(), file.path(d, "f.tiff"),
                               format = "png"), "contradicts")
  expect_error(save_manuscript(mk_plot(), file.path(d, "f.png"),
                               format = "tiff"), "contradicts")
  expect_error(save_manuscript(mk_plot(), file.path(d, "f"), format = "gif"))
  expect_error(save_manuscript(mk_plot(), file.path(d, "f"),
                               draft_file = file.path(d, "f")),
               "must not be the same path")
})

test_that("a .pdf file ignores format", {
  f <- file.path(withr::local_tempdir(), "fig.pdf")
  expect_identical(save_manuscript(mk_plot(), f, format = "png"), f)
  expect_true(file.exists(f))
})

test_that("an explicit device leaves an extension-less path alone", {
  d <- withr::local_tempdir()
  f <- file.path(d, "figure")
  expect_identical(save_manuscript(mk_plot(), f, device = "pdf"), f)
  expect_true(file.exists(f))
  expect_false(file.exists(paste0(f, ".tiff")))
  expect_identical(rawToChar(readBin(f, "raw", 4L)), "%PDF")

  g <- file.path(d, "figure_png")
  expect_identical(save_manuscript(mk_plot(), g, device = "png"), g)
  expect_identical(readBin(g, "raw", 4L)[2:4], charToRaw("PNG"))
  expect_false(file.exists(paste0(g, ".tiff")))
})

test_that("grDevices TIFF options still render, with ggplot2's warning", {
  f <- file.path(withr::local_tempdir(), "figure.tiff")
  expect_warning(save_manuscript(mk_plot(), f, type = "cairo"),
                 "Ignoring")
  expect_identical(read_tiff_header(f)$compression, 5)
  expect_warning(save_manuscript(mk_plot(), f, antialias = "none"),
                 "Ignoring")
  expect_identical(read_tiff_header(f)$compression, 5)
})

test_that("a caller's compression and device = \"tiff\" are honored", {
  d <- withr::local_tempdir()
  f <- file.path(d, "plain.tiff")
  save_manuscript(mk_plot(), f, compression = "none")
  expect_identical(read_tiff_header(f)$compression, 1)
  g <- file.path(d, "figure")
  expect_identical(save_manuscript(mk_plot(), g, device = "tiff"), g)
  expect_identical(read_tiff_header(g)$compression, 5)
})
