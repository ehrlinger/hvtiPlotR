utils::globalVariables(c("x", "y"))

library(testthat)
library(ggplot2)

# Helper: minimal test plot
create_test_plot <- function() {
  ggplot(data.frame(x = 1:10, y = 1:10), aes(.data$x, .data$y)) + geom_point()
}

# Helper: create a minimal in-memory pptx template and write to a temp file
make_temp_template <- function() {
  tmp <- tempfile(fileext = ".pptx")
  officer::read_pptx() |>
    officer::add_slide(layout = "Title and Content") |>
    print(target = tmp)
  tmp
}

# ============================================================================
# Success paths
# ============================================================================

test_that("save_ppt writes a file for a single ggplot", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  p            <- create_test_plot()
  temp_template <- make_temp_template()
  temp_ppt     <- tempfile(fileext = ".pptx")
  on.exit(unlink(c(temp_ppt, temp_template)))

  expect_no_error(
    save_ppt(p, template = temp_template, powerpoint = temp_ppt)
  )
  expect_true(file.exists(temp_ppt))
})

test_that("save_ppt writes a file for a list of ggplots", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  plots        <- list(create_test_plot(),
                       ggplot(data.frame(x = 1:5, y = 5:1), aes(x, y)) +
                         geom_line())
  temp_template <- make_temp_template()
  temp_ppt     <- tempfile(fileext = ".pptx")
  on.exit(unlink(c(temp_ppt, temp_template)))

  expect_no_error(
    save_ppt(plots, template = temp_template, powerpoint = temp_ppt,
             slide_titles = c("Plot A", "Plot B"))
  )
  expect_true(file.exists(temp_ppt))
})

test_that("save_ppt recycles a single slide_titles string across all plots", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  plots        <- list(create_test_plot(), create_test_plot())
  temp_template <- make_temp_template()
  temp_ppt     <- tempfile(fileext = ".pptx")
  on.exit(unlink(c(temp_ppt, temp_template)))

  expect_no_error(
    save_ppt(plots, template = temp_template, powerpoint = temp_ppt,
             slide_titles = "Same title")
  )
})

test_that("save_ppt works with custom width, height, left, top", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  p            <- create_test_plot()
  temp_template <- make_temp_template()
  temp_ppt     <- tempfile(fileext = ".pptx")
  on.exit(unlink(c(temp_ppt, temp_template)))

  expect_no_error(
    save_ppt(p, template = temp_template, powerpoint = temp_ppt,
             panel_box = NULL,
             width = 8, height = 5, left = 0.5, top = 1.5)
  )
})

test_that("save_ppt works with theme_hv_ppt_dark", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  p            <- create_test_plot() + theme_hv_ppt_dark()
  temp_template <- make_temp_template()
  temp_ppt     <- tempfile(fileext = ".pptx")
  on.exit(unlink(c(temp_ppt, temp_template)))

  expect_no_error(
    save_ppt(p, template = temp_template, powerpoint = temp_ppt)
  )
})

test_that("save_ppt runs without warnings (officer bg-namespace noise suppressed)", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  p            <- create_test_plot() + theme_hv_ppt_dark()
  temp_template <- make_temp_template()
  temp_ppt     <- tempfile(fileext = ".pptx")
  on.exit(unlink(c(temp_ppt, temp_template)))

  # The ph_location(bg = "transparent") fix for the white-box issue
  # emits three officer libxml2 warnings; suppress_officer_bg_warnings()
  # filters them. Lock that in so a regression (officer change, filter
  # typo) would fail this test.
  expect_no_warning(
    save_ppt(p, template = temp_template, powerpoint = temp_ppt,
             slide_titles = "warning-free")
  )
})

test_that("save_ppt renders a transparent dml canvas (no white box)", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")
  skip_if_not_installed("xml2")

  p             <- create_test_plot() + theme_hv_ppt_dark()
  temp_template <- make_temp_template()
  temp_ppt      <- tempfile(fileext = ".pptx")
  ud            <- tempfile()
  on.exit(unlink(c(temp_ppt, temp_template, ud), recursive = TRUE))

  save_ppt(p, template = temp_template, powerpoint = temp_ppt)

  dir.create(ud)
  utils::unzip(temp_ppt, exdir = ud)
  slides <- list.files(file.path(ud, "ppt", "slides"), "^slide[0-9]+\\.xml$",
                       full.names = TRUE)

  # The editable plot lives in a <p:grpSp> whose child extent (chExt) spans
  # the full canvas. rvg::dml(bg = "white") -- the default -- adds a same-size
  # opaque white <p:sp> rect behind everything: the "white box" reported
  # against dark decks. bg = "transparent" drops it. Scan every slide and
  # assert no full-canvas opaque white rect survives in any plot group.
  white_canvas_in <- function(grp, ns) {
    chext <- xml2::xml_find_first(grp, "./p:grpSpPr/a:xfrm/a:chExt", ns)
    if (is.na(chext)) return(FALSE)
    cx <- xml2::xml_attr(chext, "cx")
    cy <- xml2::xml_attr(chext, "cy")
    sps <- xml2::xml_find_all(grp, "./p:sp", ns)
    any(vapply(sps, function(sp) {
      ext  <- xml2::xml_find_first(sp, "./p:spPr/a:xfrm/a:ext", ns)
      fill <- xml2::xml_find_first(sp, "./p:spPr/a:solidFill/a:srgbClr", ns)
      if (is.na(ext) || is.na(fill)) return(FALSE)
      alpha     <- xml2::xml_find_first(fill, "./a:alpha", ns)
      full_size <- identical(xml2::xml_attr(ext, "cx"), cx) &&
                   identical(xml2::xml_attr(ext, "cy"), cy)
      white     <- identical(toupper(xml2::xml_attr(fill, "val")), "FFFFFF")
      opaque    <- is.na(alpha) || xml2::xml_attr(alpha, "val") != "0"
      full_size && white && opaque
    }, logical(1)))
  }

  has_white_canvas <- any(vapply(slides, function(sl) {
    doc <- xml2::read_xml(sl)
    ns  <- xml2::xml_ns(doc)
    grps <- xml2::xml_find_all(doc, ".//p:grpSp", ns)
    any(vapply(grps, white_canvas_in, logical(1), ns = ns))
  }, logical(1)))

  expect_false(has_white_canvas)
})

test_that("save_ppt works with all hvtiPlotR themes", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  plots <- list(
    create_test_plot() + theme_hv_ppt_dark(),
    create_test_plot() + theme_hv_ppt_dark(),
    create_test_plot() + theme_hv_poster()
  )
  temp_template <- make_temp_template()
  temp_ppt     <- tempfile(fileext = ".pptx")
  on.exit(unlink(c(temp_ppt, temp_template)))

  expect_no_error(
    save_ppt(plots, template = temp_template, powerpoint = temp_ppt)
  )
})

test_that("save_ppt returns the output path invisibly", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  p            <- create_test_plot()
  temp_template <- make_temp_template()
  temp_ppt     <- tempfile(fileext = ".pptx")
  on.exit(unlink(c(temp_ppt, temp_template)))

  result <- save_ppt(p, template = temp_template, powerpoint = temp_ppt)
  expect_equal(result, temp_ppt)
})

# ============================================================================
# Validation failures
# ============================================================================

test_that("save_ppt errors on empty list", {
  skip_if_not_installed("officer")

  temp_template <- make_temp_template()
  on.exit(unlink(temp_template))

  expect_error(
    save_ppt(list(), template = temp_template,
             powerpoint = tempfile(fileext = ".pptx")),
    "list cannot be empty"
  )
})

test_that("save_ppt errors when list contains non-ggplot objects", {
  skip_if_not_installed("officer")

  temp_template <- make_temp_template()
  on.exit(unlink(temp_template))

  expect_error(
    save_ppt(list(create_test_plot(), "not a plot"),
             template  = temp_template,
             powerpoint = tempfile(fileext = ".pptx")),
    "must be ggplot objects"
  )
})

test_that("save_ppt errors when object is neither ggplot nor list", {
  skip_if_not_installed("officer")

  temp_template <- make_temp_template()
  on.exit(unlink(temp_template))

  expect_error(
    save_ppt("not a plot", template = temp_template,
             powerpoint = tempfile(fileext = ".pptx")),
    "ggplot"
  )
})

test_that("save_ppt errors when template path does not exist", {
  skip_if_not_installed("officer")

  expect_error(
    save_ppt(create_test_plot(),
             template   = tempfile(fileext = ".pptx"),
             powerpoint = tempfile(fileext = ".pptx")),
    "existing PowerPoint file"
  )
})

test_that("save_ppt errors on non-positive width", {
  skip_if_not_installed("officer")

  temp_template <- make_temp_template()
  on.exit(unlink(temp_template))

  expect_error(
    save_ppt(create_test_plot(), template = temp_template,
             powerpoint = tempfile(fileext = ".pptx"), width = 0),
    "width"
  )
})

test_that("save_ppt errors on non-positive height", {
  skip_if_not_installed("officer")

  temp_template <- make_temp_template()
  on.exit(unlink(temp_template))

  expect_error(
    save_ppt(create_test_plot(), template = temp_template,
             powerpoint = tempfile(fileext = ".pptx"), height = -1),
    "height"
  )
})

test_that("save_ppt errors on negative left offset", {
  skip_if_not_installed("officer")

  temp_template <- make_temp_template()
  on.exit(unlink(temp_template))

  expect_error(
    save_ppt(create_test_plot(), template = temp_template,
             powerpoint = tempfile(fileext = ".pptx"), left = -0.5),
    "left"
  )
})

# ============================================================================
# Edge case: slide_titles length mismatch
# ============================================================================

test_that("save_ppt recycles a single slide_title across a multi-plot list", {
  # save_ppt uses rep_len() — a single title is recycled, not an error.
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  temp_template <- make_temp_template()
  on.exit(unlink(temp_template))

  pptx_out <- tempfile(fileext = ".pptx")
  on.exit(unlink(pptx_out), add = TRUE)

  plots <- list(create_test_plot(), create_test_plot())
  expect_no_error(
    save_ppt(
      object       = plots,
      template     = temp_template,
      powerpoint   = pptx_out,
      slide_titles = "Shared Title"   # single title recycled to both slides
    )
  )
  expect_true(file.exists(pptx_out))
})

# ============================================================================
# panel_box parameter (fixed-panel slide placement)
# ============================================================================

test_that("save_ppt writes a deck using panel_box layout", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  # Two plots with different y-axis label widths → different chrome per slide
  p1 <- ggplot(mtcars, aes(hp, mpg)) + geom_point() +
    scale_y_continuous(labels = function(x) sprintf("%3.1f", x))
  p2 <- ggplot(mtcars, aes(hp, mpg)) + geom_point() +
    scale_y_continuous(labels = function(x) sprintf("%8.1f", x * 10000))

  tmp_tpl <- make_temp_template()
  tmp_out <- tempfile(fileext = ".pptx")
  on.exit(unlink(c(tmp_tpl, tmp_out)))

  expect_no_error(
    save_ppt(
      list(p1, p2),
      template     = tmp_tpl,
      powerpoint   = tmp_out,
      slide_titles = c("Small", "Big"),
      panel_box    = list(width = 10, height = 5, left = 1.5, top = 1.5)
    )
  )
  expect_true(file.exists(tmp_out))
})

test_that("save_ppt works against the bundled CORR test template", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  tpl <- system.file("extdata", "hv_ppt_template.pptx", package = "hvtiPlotR")
  skip_if(!nzchar(tpl) || !file.exists(tpl), "bundled template not found")

  p   <- create_test_plot() + theme_hv_ppt_dark()
  out <- tempfile(fileext = ".pptx")
  on.exit(unlink(out))

  expect_no_error(
    save_ppt(p, template = tpl, powerpoint = out, slide_titles = "Test")
  )
  doc <- officer::read_pptx(out)
  expect_gte(length(doc), 1L)
  # the template ships the "Title and Content" layout save_ppt() defaults to
  expect_true("Title and Content" %in% officer::layout_summary(doc)$layout)
})

test_that("save_ppt defaults template to the bundled template", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  tpl <- system.file("extdata", "hv_ppt_template.pptx", package = "hvtiPlotR")
  skip_if(!nzchar(tpl) || !file.exists(tpl), "bundled template not found")
  old <- options(hvtiPlotR.ppt_template = NULL)
  on.exit(options(old), add = TRUE)
  expect_identical(eval(formals(save_ppt)$template), tpl)

  # no study-relative ../graphs/RD.pptx needed
  out <- tempfile(fileext = ".pptx")
  on.exit(unlink(out), add = TRUE)
  expect_no_error(save_ppt(create_test_plot(), powerpoint = out))
  expect_gte(length(officer::read_pptx(out)), 1L)
})

test_that("bundled dark and light templates carry layouts but no slides", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  for (name in c("hv_ppt_template.pptx", "hv_ppt_template_light.pptx")) {
    tpl <- system.file("extdata", name, package = "hvtiPlotR")
    expect_true(nzchar(tpl) && file.exists(tpl), info = name)
    doc <- officer::read_pptx(tpl)
    # example slides in a template would lead every deck save_ppt() writes
    expect_identical(length(doc), 0L, info = name)
    expect_true("Title and Content" %in% officer::layout_summary(doc)$layout,
                info = name)
    # nor the notes pages of removed slides, which every deck would copy (#173)
    parts <- utils::unzip(tpl, list = TRUE)$Name
    expect_false(any(startsWith(parts, "ppt/notesSlides/")), info = name)
    types <- readLines(unz(tpl, "[Content_Types].xml"), warn = FALSE)
    expect_false(any(grepl("notesSlide[0-9]", types)), info = name)
    app <- paste(readLines(unz(tpl, "docProps/app.xml"), warn = FALSE), collapse = "")
    expect_match(app, "<Slides>0</Slides>", fixed = TRUE, info = name)
    expect_match(app, "<Notes>0</Notes>", fixed = TRUE, info = name)
    # nor the removed slides' titles: no "Slide Titles" heading, and the
    # remaining headings count exactly the titles listed
    props <- xml2::read_xml(app)
    ns    <- xml2::xml_ns(props)
    heads <- xml2::xml_text(xml2::xml_find_all(props, ".//d1:HeadingPairs//vt:lpstr", ns))
    count <- as.integer(xml2::xml_text(xml2::xml_find_all(props, ".//d1:HeadingPairs//vt:i4", ns)))
    parts <- xml2::xml_find_all(props, ".//d1:TitlesOfParts//vt:lpstr", ns)
    expect_false("Slide Titles" %in% heads, info = name)
    expect_identical(sum(count), length(parts), info = name)
    # every part is reachable from the package root and has a content type, or
    # save_ppt() copies dead weight, or an invalid package, into every deck (#188)
    audit <- pptx_audit(tpl)
    for (check in names(audit))
      expect_identical(audit[[check]], character(0), info = paste(name, check))
  }

  out <- tempfile(fileext = ".pptx")
  on.exit(unlink(out))
  light <- system.file("extdata", "hv_ppt_template_light.pptx",
                       package = "hvtiPlotR")
  save_ppt(create_test_plot() + theme_hv_ppt_light(),
           template = light, powerpoint = out)
  expect_identical(length(officer::read_pptx(out)), 1L)
  # and the deck save_ppt() writes from it is as sound as the template
  audit <- pptx_audit(out)
  for (check in names(audit))
    expect_identical(audit[[check]], character(0), info = paste("saved deck", check))
})

test_that("pptx_audit() reports the broken packages the template test exists to catch", {
  # Every check above is seen only in its empty state, so a detector that
  # always returned nothing would pass there. Break a copy of the template in
  # the two ways the old any-.rels check missed, and one it must not flag (#191).
  skip_if(!nzchar(Sys.getenv("R_ZIPCMD", Sys.which("zip"))), "no zip program to build test packages")
  tpl <- system.file("extdata", "hv_ppt_template.pptx", package = "hvtiPlotR")
  skip_if(!nzchar(tpl) || !file.exists(tpl), "bundled template not found")

  rels <- function(...) {
    paste0(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">',
      paste0('<Relationship Id="rId', seq_along(c(...)), '" Type="http://example.org/x" Target="', c(...), '"/>',
             collapse = ""),
      "</Relationships>")
  }
  # a copy of the template with extra parts, zipped from inside its own folder
  broken <- function(extra) {
    dir <- tempfile("pptx")
    utils::unzip(tpl, exdir = dir)
    for (part in names(extra)) {
      dir.create(file.path(dir, dirname(part)), recursive = TRUE, showWarnings = FALSE)
      writeLines(extra[[part]], file.path(dir, part))
    }
    out <- tempfile(fileext = ".pptx")
    old <- setwd(dir)
    on.exit(setwd(old))
    utils::zip(out, list.files(".", recursive = TRUE, all.files = TRUE), flags = "-q")
    out
  }
  layout <- basename(grep("^ppt/slideLayouts/slideLayout[0-9]+[.]xml$",
                          utils::unzip(tpl, list = TRUE)$Name, value = TRUE)[1L])

  # a .rels left by a removed slide: its target exists, its source does not
  leftover <- pptx_audit(broken(list(
    "ppt/slides/_rels/slide9.xml.rels" = rels(paste0("../slideLayouts/", layout)))))
  expect_identical(leftover$orphan_rels, "ppt/slides/_rels/slide9.xml.rels")
  expect_identical(leftover$unreached, character(0))

  # two parts that point only at each other
  pair <- pptx_audit(broken(list(
    "ppt/extra/a.xml"            = "<a/>",
    "ppt/extra/b.xml"            = "<b/>",
    "ppt/extra/_rels/a.xml.rels" = rels("b.xml"),
    "ppt/extra/_rels/b.xml.rels" = rels("a.xml"))))
  expect_setequal(pair$unreached, c("ppt/extra/a.xml", "ppt/extra/b.xml"))
  expect_identical(pair$orphan_rels, character(0))

  # an absolute target with a ".." in it resolves, rather than reading as
  # dangling; it has to hang off a reached part, here the package root
  root <- paste(readLines(unz(tpl, "_rels/.rels"), warn = FALSE), collapse = "")
  root <- sub("</Relationships>", paste0('<Relationship Id="rIdAbs" Type="http://example.org/x" ',
                                         'Target="/ppt/../docProps/app.xml"/></Relationships>'), root)
  absolute <- pptx_audit(broken(list("_rels/.rels" = root)))
  expect_identical(absolute$dangling, character(0))
})

test_that("save_ppt takes its default template from hvtiPlotR.ppt_template", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  tpl <- system.file("extdata", "hv_ppt_template.pptx", package = "hvtiPlotR")
  skip_if(!nzchar(tpl) || !file.exists(tpl), "bundled template not found")
  master <- tempfile(fileext = ".pptx")
  file.copy(tpl, master)
  old <- options(hvtiPlotR.ppt_template = master)
  on.exit(options(old), add = TRUE)
  on.exit(unlink(master), add = TRUE)

  expect_identical(eval(formals(save_ppt)$template), master)

  # the option is read at call time; a missing master fails loudly, naming the
  # option, since a path set in .Rprofile is nowhere in the call (#174)
  options(hvtiPlotR.ppt_template = tempfile(fileext = ".pptx"))
  expect_error(
    save_ppt(create_test_plot(), powerpoint = tempfile(fileext = ".pptx")),
    "`options(hvtiPlotR.ppt_template)`", fixed = TRUE
  )
  # an explicit template argument is blamed, not the option
  expect_error(
    save_ppt(create_test_plot(), template = tempfile(fileext = ".pptx"),
             powerpoint = tempfile(fileext = ".pptx")),
    "`template` must be the path to an existing PowerPoint file"
  )
})

test_that("save_ppt requires an explicit powerpoint output path", {
  expect_error(save_ppt(create_test_plot()), "`powerpoint` is required")
})

test_that("save_ppt defaults panel_box to the standard fixed-panel rectangle", {
  default_box <- eval(formals(save_ppt)$panel_box)
  expect_equal(
    default_box,
    list(width = 8.79, height = 4.422, left = 2.67, top = 1.29)
  )
})

test_that("save_ppt uses the panel_box path by default (no explicit panel_box)", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  p       <- create_test_plot() + theme_hv_ppt_dark()
  tmp_tpl <- make_temp_template()
  tmp_out <- tempfile(fileext = ".pptx")
  on.exit(unlink(c(tmp_tpl, tmp_out)))

  # A default call must succeed and write a file even though it now routes
  # through hv_ph_location() (panel_box default is non-NULL).
  expect_no_error(
    save_ppt(p, template = tmp_tpl, powerpoint = tmp_out)
  )
  expect_true(file.exists(tmp_out))
})

test_that("save_ppt rejects panel_box missing required fields", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")

  p      <- create_test_plot()
  tmp_tpl <- make_temp_template()
  tmp_out <- tempfile(fileext = ".pptx")
  on.exit(unlink(c(tmp_tpl, tmp_out)))

  expect_error(
    save_ppt(p, template = tmp_tpl, powerpoint = tmp_out,
             panel_box = list(width = 10, height = 5)),
    "panel_box"
  )
})
