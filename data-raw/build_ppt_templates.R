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

message("Built dark and light templates in ", ext)
