## Builds the bundled slide templates in inst/extdata/ from the pristine
## sources in data-raw/templates/ (spec 2026-10-19). Run from the package
## root:  Rscript data-raw/build_ppt_templates.R
##
## When the CORR dark master is refreshed, replace
## data-raw/templates/hv_ppt_template_src.pptx with the new master (example
## slides removed) and rerun. Output depends only on the sources, so the
## script is idempotent.

library(xml2)

src <- "data-raw/templates"
ext <- "inst/extdata"
ns  <- c(p = "http://schemas.openxmlformats.org/presentationml/2006/main",
         a = "http://schemas.openxmlformats.org/drawingml/2006/main")

unpack <- function(pptx) {
  d <- tempfile("pptx-")
  dir.create(d)
  utils::unzip(pptx, exdir = d)
  d
}

repack <- function(dir, pptx) {
  files <- list.files(dir, recursive = TRUE, all.files = TRUE, no.. = TRUE)
  ct <- "[Content_Types].xml"
  files <- c(ct, setdiff(files, ct))   # content types first, as PowerPoint writes it
  out <- file.path(normalizePath(dirname(pptx)), basename(pptx))
  unlink(out)
  ## Fixed timestamps, read in UTC, so a rebuild of unchanged content is
  ## byte-identical (ZIP stores each entry's local modification time).
  old_tz <- Sys.getenv("TZ", unset = NA)
  Sys.setenv(TZ = "UTC")
  on.exit(if (is.na(old_tz)) Sys.unsetenv("TZ") else Sys.setenv(TZ = old_tz),
          add = TRUE)
  Sys.setFileTime(file.path(dir, files), as.POSIXct("2026-01-01", tz = "UTC"))
  zip::zip(out, files = files, root = dir, mode = "mirror")
  invisible(out)
}

## Renames layouts by their name in the source file (one pass, so a chain
## such as "Title Slide" -> "Title Slide Background" and "1_Title Slide" ->
## "Title Slide" cannot collide).
rename_layouts <- function(dir, map) {
  files <- list.files(file.path(dir, "ppt", "slideLayouts"), "\\.xml$",
                      full.names = TRUE)
  for (f in files) {
    x <- read_xml(f)
    csld <- xml_find_first(x, "//p:cSld", ns)
    nm <- xml_attr(csld, "name")
    if (!is.na(nm) && nm %in% names(map)) {
      xml_set_attr(csld, "name", map[[nm]])
      write_xml(x, f)
    }
  }
}

dark_map  <- c(`1_Title Only` = "Section Header")
light_map <- c(`Title Slide`     = "Title Slide Background",
               `1_Title Slide`   = "Title Slide",
               `1_Custom Layout` = "Section Header",
               `Custom Layout`   = "Title Only")

dark_dir <- unpack(file.path(src, "hv_ppt_template_src.pptx"))
rename_layouts(dark_dir, dark_map)
repack(dark_dir, file.path(ext, "hv_ppt_template.pptx"))

light_dir <- unpack(file.path(src, "hv_ppt_template_light_src.pptx"))
rename_layouts(light_dir, light_map)
repack(light_dir, file.path(ext, "hv_ppt_template_light.pptx"))

## --- Slate: the renamed dark template with the CHSS look -----------------
slate_scheme <- c(dk1 = "000000", lt1 = "FFFFFF", dk2 = "44546A",
                  lt2 = "E7E6E6", accent1 = "0877BC", accent2 = "7AD0E7",
                  accent3 = "F79647", accent4 = "F8C946", accent5 = "DBDBDB",
                  accent6 = "1EC85A", hlink = "0563C1", folHlink = "954F72")

## White Arial on a run-properties node; bold = "0" for titles.
set_run_props <- function(rpr, bold = NULL) {
  xml_remove(xml_find_all(rpr, "a:solidFill|a:gradFill|a:noFill|a:latin", ns))
  ## Schema order of a:defRPr children: a:ln, fill, effects, highlight,
  ## underline, a:latin, a:ea, a:cs, a:sym, hyperlinks, a:rtl, a:extLst.
  ln <- xml_find_first(rpr, "a:ln", ns)
  fill <- if (inherits(ln, "xml_missing")) {
    xml_add_child(rpr, "a:solidFill", .where = 0)
  } else {
    xml_add_sibling(ln, "a:solidFill", .where = "after")
  }
  xml_add_child(fill, "a:srgbClr", val = "FFFFFF")
  after_latin <- xml_find_first(
    rpr, paste0("a:ea|a:cs|a:sym|a:hlinkClick|a:hlinkMouseOver|a:rtl|",
                "a:extLst"), ns)
  if (inherits(after_latin, "xml_missing")) {
    xml_add_child(rpr, "a:latin", typeface = "Arial")
  } else {
    xml_add_sibling(after_latin, "a:latin", typeface = "Arial",
                    .where = "before")
  }
  if (!is.null(bold)) xml_set_attr(rpr, "b", bold)
  invisible(rpr)
}

## Every a:defRPr under a level node, created if missing.
level_rpr <- function(lvl) {
  rpr <- xml_find_first(lvl, "a:defRPr", ns)
  if (inherits(rpr, "xml_missing")) rpr <- xml_add_child(lvl, "a:defRPr")
  rpr
}

slate_dir <- unpack(file.path(src, "hv_ppt_template_src.pptx"))
rename_layouts(slate_dir, dark_map)

master_f <- file.path(slate_dir, "ppt", "slideMasters", "slideMaster1.xml")
m <- read_xml(master_f)
csld <- xml_find_first(m, "//p:cSld", ns)
xml_remove(xml_find_all(csld, "p:bg", ns))
bg <- xml_add_child(csld, "p:bg", .where = 0)
bgpr <- xml_add_child(bg, "p:bgPr")
xml_add_child(xml_add_child(bgpr, "a:solidFill"), "a:srgbClr", val = "384D60")
xml_add_child(bgpr, "a:effectLst")

title_lvl <- xml_find_first(m, "//p:txStyles/p:titleStyle/a:lvl1pPr", ns)
xml_set_attr(title_lvl, "algn", "ctr")
set_run_props(level_rpr(title_lvl), bold = "0")
for (lvl in xml_find_all(m, "//p:txStyles/p:bodyStyle/*", ns)) {
  if (grepl("^lvl[1-9]pPr$", xml_name(lvl))) set_run_props(level_rpr(lvl))
}
write_xml(m, master_f)

## Layouts: drop any background of their own (the master's applies) and any
## title color, weight or font override, so the master title style shows.
for (f in list.files(file.path(slate_dir, "ppt", "slideLayouts"), "\\.xml$",
                     full.names = TRUE)) {
  l <- read_xml(f)
  xml_remove(xml_find_all(l, "//p:cSld/p:bg", ns))
  title_sp <- xml_find_all(
    l, "//p:sp[.//p:ph[@type='title' or @type='ctrTitle']]", ns)
  for (sp in title_sp) {
    for (rpr in xml_find_all(sp, ".//a:lstStyle/a:lvl1pPr/a:defRPr", ns)) {
      set_run_props(rpr, bold = "0")
    }
  }
  write_xml(l, f)
}

## Theme: the master's theme part, found through the master's relationships.
rels <- read_xml(file.path(slate_dir, "ppt", "slideMasters", "_rels",
                           "slideMaster1.xml.rels"))
theme_target <- xml_attr(xml_find_first(
  rels, "//*[local-name()='Relationship'][contains(@Type, '/theme')]"), "Target")
theme_f <- normalizePath(file.path(slate_dir, "ppt", "slideMasters", theme_target))
th <- read_xml(theme_f)
cs <- xml_find_first(th, "//a:clrScheme", ns)
xml_set_attr(cs, "name", "Slate")
for (k in names(slate_scheme)) {
  node <- xml_find_first(cs, paste0("a:", k), ns)
  xml_remove(xml_children(node))
  xml_add_child(node, "a:srgbClr", val = slate_scheme[[k]])
}
write_xml(th, theme_f)

repack(slate_dir, file.path(ext, "hv_ppt_template_slate.pptx"))

message("Built dark, light and slate templates in ", ext)
