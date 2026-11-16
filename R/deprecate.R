# deprecate.R
# One-release deprecations, warned once per session.
#
# The family rubric ships every rename and every removed study-specific
# default as a deprecation, never as a break: the old form keeps working for
# one release with a warning, then goes. The warning carries the class
# `hvtiPlotR_deprecated` so a caller can catch or muffle it precisely.

# The release in which the deprecated forms are removed. The minor digit is
# the maintainer's call; this names the next minor so the messages can say
# when, and moves with that decision.
.hv_removal_version <- "2.9.0"

.hv_deprecation_seen <- new.env(parent = emptyenv())

# Warn once per session for `id`. `msg` is the full text.
.hv_deprecate <- function(id, msg) {
  if (isTRUE(.hv_deprecation_seen[[id]])) return(invisible(FALSE))
  assign(id, TRUE, envir = .hv_deprecation_seen)
  warning(warningCondition(
    paste0(msg, " This warning is shown once per session."),
    class = c("hvtiPlotR_deprecated", "deprecatedWarning")
  ))
  invisible(TRUE)
}

# Forget which deprecations have warned. For tests.
.hv_deprecate_reset <- function() {
  rm(list = ls(.hv_deprecation_seen, all.names = TRUE), envir = .hv_deprecation_seen)
  invisible()
}

# A study-specific default was relied on. `args` names the omitted arguments
# and `values` gives the default each still falls back to, as text.
.hv_deprecate_study_default <- function(fn, args, values) {
  if (!length(args)) return(invisible(FALSE))
  .hv_deprecate(
    paste0(fn, ":", paste(args, collapse = ",")),
    sprintf(paste0(
      "%s(): %s %s study-specific and will have no default from hvtiPlotR %s. ",
      "Pass %s explicitly. Using the old default%s for now: %s."),
      fn,
      paste0("`", args, "`", collapse = ", "),
      if (length(args) == 1L) "is" else "are",
      .hv_removal_version,
      if (length(args) == 1L) "it" else "them",
      if (length(args) == 1L) "" else "s",
      paste(args, "=", values, collapse = ", "))
  )
}
