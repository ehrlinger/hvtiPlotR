# Acceptance test for the Installation vignette.
#
# Covers presence, registration, and content completeness so that future
# edits to vignettes/installation.qmd can't silently drop a required
# section or the canonical install command. Does not execute any
# installs — content-only checks, runs in <1s.

test_that("installation vignette exists and is registered", {
  path <- test_path("..", "..", "vignettes", "installation.qmd")
  expect_true(file.exists(path), info = "vignettes/installation.qmd is missing")

  txt <- readLines(path, warn = FALSE)
  # VignetteIndexEntry is how R CMD build discovers the vignette
  expect_match(
    paste(txt, collapse = "\n"),
    "%\\\\VignetteIndexEntry\\{Installing hvtiPlotR\\}",
    info = "VignetteIndexEntry missing or misspelled"
  )
  expect_match(
    paste(txt, collapse = "\n"),
    "%\\\\VignetteEngine\\{quarto::html\\}",
    info = "VignetteEngine must be quarto::html to match other hvtiPlotR vignettes"
  )
})

test_that("installation vignette contains all required sections", {
  path    <- test_path("..", "..", "vignettes", "installation.qmd")
  content <- paste(readLines(path, warn = FALSE), collapse = "\n")

  required_sections <- c(
    "## Requirements",
    "## Standard install",
    "## Install with suggested packages",
    "## Developer install",
    "## Verifying the install",
    "## Updating",
    "## Troubleshooting"
  )
  for (section in required_sections) {
    expect_true(
      grepl(section, content, fixed = TRUE),
      info = sprintf("missing required section header: %s", section)
    )
  }
})

test_that("installation vignette documents the canonical install commands", {
  path    <- test_path("..", "..", "vignettes", "installation.qmd")
  content <- paste(readLines(path, warn = FALSE), collapse = "\n")

  # Canonical GitHub install
  expect_match(
    content,
    'remotes::install_github\\("ehrlinger/hvtiPlotR"\\)',
    info = "canonical remotes::install_github() call must appear verbatim"
  )
  # Full-Suggests install (dependencies = TRUE)
  expect_match(
    content,
    "dependencies = TRUE",
    info = "Suggests-install path (dependencies = TRUE) must be shown"
  )
  # GitHub-only dep
  expect_match(
    content,
    'install_github\\("davidsjoberg/ggsankey"\\)',
    info = "ggsankey GitHub-only install must be documented"
  )
  # Developer workflow
  expect_match(
    content,
    "devtools::install_deps",
    info = "developer install path (devtools::install_deps) must be documented"
  )
  # Version-pinned install example
  expect_match(
    content,
    "ehrlinger/hvtiPlotR@",
    info = "at least one pinned-ref install example (@tag/branch/sha) must appear"
  )
  # Verification smoke test
  expect_match(
    content,
    'hv_theme\\("manuscript"\\)',
    info = "post-install verification must demonstrate hv_theme()"
  )
  expect_match(
    content,
    "save_ppt\\(",
    info = "post-install verification must demonstrate save_ppt()"
  )
  # Uninstall
  expect_match(
    content,
    'remove\\.packages\\("hvtiPlotR"\\)',
    info = "uninstall command must be documented in the Updating section"
  )
})

test_that("installation vignette states the minimum R version consistent with DESCRIPTION", {
  desc <- read.dcf(test_path("..", "..", "DESCRIPTION"))
  depends <- desc[1, "Depends"]
  # Pull "4.1.0" (or similar) out of "R (>= 4.1.0)"
  r_ver <- sub(".*R \\(>= ([0-9.]+)\\).*", "\\1", depends)
  expect_match(r_ver, "^[0-9]+\\.[0-9]+", info = "Could not parse R version floor from DESCRIPTION")

  path    <- test_path("..", "..", "vignettes", "installation.qmd")
  content <- paste(readLines(path, warn = FALSE), collapse = "\n")
  expect_true(
    grepl(r_ver, content, fixed = TRUE),
    info = sprintf(
      "vignette does not state R >= %s; keep it in sync with DESCRIPTION Depends",
      r_ver
    )
  )
})
