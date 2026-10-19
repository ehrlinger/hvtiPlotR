# Layout contract and slate template (spec 2026-10-19).
library(testthat)

tpl <- function(name) system.file("extdata", name, package = "hvtiPlotR")

contract <- list(
  `Title Slide`       = c("ctrTitle", "subTitle"),
  `Section Header`    = "title",
  `Title and Content` = c("body", "title"),
  `Two Content`       = c("body", "title"),
  `Title Only`        = "title",
  Blank               = character()
)
templates <- c("hv_ppt_template.pptx", "hv_ppt_template_light.pptx",
               "hv_ppt_template_slate.pptx")

test_that("every bundled template carries the layout contract", {
  skip_if_not_installed("officer")
  for (f in templates) {
    doc <- officer::read_pptx(tpl(f))
    lays <- officer::layout_summary(doc)$layout
    props <- officer::layout_properties(doc)
    expect_false(anyDuplicated(lays) > 0, info = f)
    for (nm in names(contract)) {
      expect_true(nm %in% lays, info = paste(f, nm))
      expect_true(all(contract[[nm]] %in% props$type[props$name == nm]),
                  info = paste(f, nm))
    }
  }
})

test_that("old layout names are gone from the bundled templates", {
  skip_if_not_installed("officer")
  for (f in templates) {
    lays <- officer::layout_summary(officer::read_pptx(tpl(f)))$layout
    expect_false(any(c("Custom Layout", "1_Custom Layout", "1_Title Slide",
                       "1_Title Only") %in% lays), info = f)
  }
})

slate_xml <- function(part) {
  d <- tempfile("slate-")
  utils::unzip(tpl("hv_ppt_template_slate.pptx"), exdir = d)
  xml2::read_xml(file.path(d, part))
}
ns <- c(p = "http://schemas.openxmlformats.org/presentationml/2006/main",
        a = "http://schemas.openxmlformats.org/drawingml/2006/main")

test_that("slate master has a solid slate background", {
  skip_if_not_installed("xml2")
  m <- slate_xml("ppt/slideMasters/slideMaster1.xml")
  fill <- xml2::xml_find_first(m, "//p:cSld/p:bg/p:bgPr/a:solidFill/a:srgbClr", ns)
  expect_identical(toupper(xml2::xml_attr(fill, "val")), "384D60")
})

test_that("slate master titles are white, regular, centered Arial", {
  skip_if_not_installed("xml2")
  m <- slate_xml("ppt/slideMasters/slideMaster1.xml")
  lvl <- xml2::xml_find_first(m, "//p:txStyles/p:titleStyle/a:lvl1pPr", ns)
  rpr <- xml2::xml_find_first(lvl, "a:defRPr", ns)
  expect_identical(xml2::xml_attr(lvl, "algn"), "ctr")
  expect_identical(xml2::xml_attr(rpr, "b"), "0")
  expect_identical(toupper(xml2::xml_attr(
    xml2::xml_find_first(rpr, "a:solidFill/a:srgbClr", ns), "val")), "FFFFFF")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(rpr, "a:latin", ns),
                                  "typeface"), "Arial")
})

test_that("slate theme carries the Slate color scheme", {
  skip_if_not_installed("xml2")
  th <- slate_xml("ppt/theme/theme1.xml")
  cs <- xml2::xml_find_first(th, "//a:clrScheme", ns)
  expect_identical(xml2::xml_attr(cs, "name"), "Slate")
  val <- function(k) {
    node <- xml2::xml_find_first(cs, paste0("a:", k, "/a:srgbClr"), ns)
    toupper(xml2::xml_attr(node, "val"))
  }
  expect_identical(val("accent1"), "0877BC")
  expect_identical(val("accent4"), "F8C946")
})

test_that("slate master run properties keep DrawingML schema child order", {
  skip_if_not_installed("xml2")
  order <- c("ln", "noFill", "solidFill", "gradFill", "blipFill", "pattFill",
             "grpFill", "effectLst", "effectDag", "highlight", "uLnTx", "uLn",
             "uFillTx", "uFill", "latin", "ea", "cs", "sym", "hlinkClick",
             "hlinkMouseOver", "rtl", "extLst")
  rank <- c(ln = 1, noFill = 2, solidFill = 2, gradFill = 2, blipFill = 2,
            pattFill = 2, grpFill = 2, effectLst = 3, effectDag = 3,
            highlight = 4, uLnTx = 5, uLn = 5, uFillTx = 6, uFill = 6,
            latin = 7, ea = 8, cs = 9, sym = 10, hlinkClick = 11,
            hlinkMouseOver = 12, rtl = 13, extLst = 14)
  expect_setequal(names(rank), order)
  m <- slate_xml("ppt/slideMasters/slideMaster1.xml")
  lvls <- xml2::xml_find_all(
    m, paste0("//p:txStyles/p:titleStyle/a:lvl1pPr|",
              "//p:txStyles/p:bodyStyle/*[starts-with(local-name(), 'lvl')]"), ns)
  expect_gt(length(lvls), 1L)
  for (lvl in lvls) {
    rpr <- xml2::xml_find_first(lvl, "a:defRPr", ns)
    kids <- xml2::xml_name(xml2::xml_children(rpr))
    expect_true(all(kids %in% names(rank)), info = xml2::xml_name(lvl))
    expect_false(is.unsorted(unname(rank[kids])),
                 info = paste(xml2::xml_name(lvl), paste(kids, collapse = ",")))
  }
})

test_that(".hv_available_layouts restricts to the requested master", {
  ls <- data.frame(layout = c("Title Only", "Blank", "Title Only"),
                   master = c("A", "A", "B"), stringsAsFactors = FALSE)
  expect_identical(.hv_available_layouts(ls, NULL), ls$layout)
  expect_identical(.hv_available_layouts(ls, "A"), c("Title Only", "Blank"))
  expect_identical(.hv_available_layouts(ls, "B"), "Title Only")
  expect_identical(.hv_available_layouts(ls, "C"), character())
})

test_that("hv_ppt_layout returns the contract name for each role", {
  expect_identical(hv_ppt_layout(), "Title Only")
  expect_identical(hv_ppt_layout("figure"), "Title Only")
  expect_identical(hv_ppt_layout("section"), "Section Header")
  expect_identical(hv_ppt_layout("title"), "Title Slide")
  expect_identical(hv_ppt_layout("content"), "Title and Content")
  expect_identical(hv_ppt_layout("two"), "Two Content")
  expect_identical(hv_ppt_layout("blank"), "Blank")
  expect_error(hv_ppt_layout("chart"))
})

test_that(".hv_resolve_layout maps old names to new and back", {
  new_set <- c("Title Slide", "Section Header", "Title Only", "Blank")
  old_set <- c("1_Title Slide", "1_Custom Layout", "Custom Layout", "Blank")
  rm(list = ls(.hv_layout_alias_env), envir = .hv_layout_alias_env)
  expect_message(r <- .hv_resolve_layout("Custom Layout", new_set),
                 "'Custom Layout' is now 'Title Only'")
  expect_identical(r, "Title Only")
  expect_silent(.hv_resolve_layout("Custom Layout", new_set))  # once per session
  expect_identical(.hv_resolve_layout("Title Only", old_set), "Custom Layout")
  expect_identical(.hv_resolve_layout("Section Header", old_set), "1_Custom Layout")
  expect_identical(.hv_resolve_layout("Blank", new_set), "Blank")
  expect_identical(.hv_resolve_layout("Nope", new_set), "Nope")
})

test_that("save_ppt accepts an old layout name on the renamed light template", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")
  skip_if_not_installed("xml2")
  rm(list = ls(.hv_layout_alias_env), envir = .hv_layout_alias_env)
  out <- tempfile(fileext = ".pptx")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  expect_message(
    save_ppt(p, template = tpl("hv_ppt_template_light.pptx"),
             powerpoint = out, layout = "Custom Layout"),
    "is now 'Title Only'")
  d <- tempfile("chk-")
  utils::unzip(out, exdir = d)
  rel <- xml2::read_xml(file.path(d, "ppt/slides/_rels/slide1.xml.rels"))
  lay <- xml2::xml_attr(xml2::xml_find_first(
    rel, "//*[local-name()='Relationship'][contains(@Type,'slideLayout')]"), "Target")
  lx <- xml2::read_xml(file.path(d, "ppt/slides", lay))
  expect_identical(xml2::xml_attr(xml2::xml_find_first(lx, "//*[local-name()='cSld']"),
                                  "name"), "Title Only")
})

test_that("save_ppt writes a figure slide on every bundled template", {
  skip_if_not_installed("officer")
  skip_if_not_installed("rvg")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  for (f in templates) {
    out <- tempfile(fileext = ".pptx")
    save_ppt(p, template = tpl(f), powerpoint = out,
             layout = hv_ppt_layout("figure"))
    expect_identical(length(officer::read_pptx(out)), 1L, info = f)
  }
})
