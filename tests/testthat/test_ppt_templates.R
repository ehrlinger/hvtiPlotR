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

test_that("slate master titles are white, regular, centred Arial", {
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

test_that("slate theme carries the Slate colour scheme", {
  skip_if_not_installed("xml2")
  th <- slate_xml("ppt/theme/theme1.xml")
  cs <- xml2::xml_find_first(th, "//a:clrScheme", ns)
  expect_identical(xml2::xml_attr(cs, "name"), "Slate")
  val <- function(k) toupper(xml2::xml_attr(
    xml2::xml_find_first(cs, paste0("a:", k, "/a:srgbClr"), ns), "val"))
  expect_identical(val("accent1"), "0877BC")
  expect_identical(val("accent4"), "F8C946")
})
