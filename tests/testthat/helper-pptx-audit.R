# tests/testthat/helper-pptx-audit.R
#
# Audits a .pptx as an Open Packaging Conventions package. The walk starts at
# the package root, `_rels/.rels`, and follows each reached part's own `.rels`,
# so parts that only point at each other, or a `.rels` left behind by a
# removed part, are caught. Counting every target named by any `.rels` in the
# zip would pass both (#191).
#
# Returns a list of character vectors, each empty when the package is sound:
#   unreached     parts no relationship chain from the root reaches
#   dangling      relationship targets that are not in the package
#   orphan_rels   `.rels` files whose source part is not in the package
#   untyped       parts with neither a Default nor an Override content type

pptx_audit <- function(path) {
  files <- utils::unzip(path, list = TRUE)$Name
  files <- files[!endsWith(files, "/")]
  read  <- function(part) xml2::read_xml(unz(path, part))

  types <- read("[Content_Types].xml")
  ext   <- tolower(xml2::xml_attr(xml2::xml_find_all(types, "//*[local-name()='Default']"), "Extension"))
  over  <- sub("^/", "", xml2::xml_attr(xml2::xml_find_all(types, "//*[local-name()='Override']"), "PartName"))

  # "" is the package root; a part's relationships sit in <dir>/_rels/<name>.rels
  rels_of <- function(part) {
    if (part == "") return("_rels/.rels")
    dir <- dirname(part)
    paste0(if (dir == ".") "" else paste0(dir, "/"), "_rels/", basename(part), ".rels")
  }
  source_of <- function(rels) {
    dir  <- dirname(dirname(rels))
    name <- sub("[.]rels$", "", basename(rels))
    if (name == "") "" else if (dir == ".") name else paste0(dir, "/", name)
  }
  # Targets resolve against the source part's folder; "." and ".." segments
  # are collapsed and percent-escapes decoded.
  resolve <- function(source, target) {
    target <- utils::URLdecode(target)
    # an absolute target starts from the package root, and still collapses
    base <- if (startsWith(target, "/") || source == "" || dirname(source) == ".") "" else dirname(source)
    out  <- if (base == "") character() else strsplit(base, "/")[[1]]
    for (seg in strsplit(target, "/")[[1]]) {
      if (seg == "..") out <- utils::head(out, -1L)
      else if (seg != "." && seg != "") out <- c(out, seg)
    }
    paste(out, collapse = "/")
  }

  reached  <- character()
  dangling <- character()
  queue    <- ""
  while (length(queue)) {
    part  <- queue[1L]
    queue <- queue[-1L]
    rels  <- rels_of(part)
    if (!rels %in% files) next
    rel <- xml2::xml_find_all(read(rels), "//*[local-name()='Relationship']")
    rel <- rel[!(xml2::xml_attr(rel, "TargetMode") %in% "External")]
    for (target in vapply(xml2::xml_attr(rel, "Target"), resolve, character(1L), source = part)) {
      if (!target %in% files) {
        dangling <- union(dangling, target)
      } else if (!target %in% reached) {
        reached <- c(reached, target)
        queue   <- c(queue, target)
      }
    }
  }

  all_rels <- files[endsWith(files, ".rels")]
  content  <- setdiff(files[!endsWith(files, ".rels")], "[Content_Types].xml")
  # tools::file_ext() gives "" for "_rels/.rels", so take the text after the last dot
  suffix   <- tolower(sub("^.*[.]", "", basename(files)))
  list(
    unreached   = setdiff(content, reached),
    dangling    = dangling,
    orphan_rels = all_rels[vapply(all_rels, function(r) {
      src <- source_of(r)
      src != "" && !src %in% files
    }, logical(1L))],
    untyped     = files[!(files %in% over) & !(suffix %in% ext)]
  )
}
