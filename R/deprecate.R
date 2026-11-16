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
  .hv_deprecation_warning(msg)
}

.hv_deprecation_warning <- function(msg) {
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
# and `values` gives the default each still falls back to, as text. Each
# argument warns once per session: a later call that omits only arguments
# already warned about is silent.
.hv_deprecate_study_default <- function(fn, args, values) {
  if (!length(args)) return(invisible(FALSE))
  ids  <- paste0(fn, ":", args)
  new  <- !vapply(ids, function(id) isTRUE(.hv_deprecation_seen[[id]]), logical(1))
  args <- args[new]
  values <- values[new]
  if (!length(args)) return(invisible(FALSE))
  for (id in ids[new]) assign(id, TRUE, envir = .hv_deprecation_seen)
  .hv_deprecation_warning(
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

# A renamed argument. Returns the value to use: the old one when only the old
# name was passed (with a once-per-session warning), else the new one. Passing
# both is an error, since the two could disagree. `new_value` is a promise and
# is evaluated only when it is the one used, so a required new argument with
# no default is fine to pass along.
.hv_rename_arg <- function(fn, old, new, old_missing, new_missing, old_value, new_value) {
  if (old_missing) return(new_value)
  if (!new_missing)
    stop(sprintf("%s(): pass `%s` only. `%s` is its old name, and both were given.",
                 fn, new, old), call. = FALSE)
  .hv_deprecate(paste0(fn, ":", old), sprintf(
    "%s(): `%s` is renamed `%s`. The old name works until hvtiPlotR %s.",
    fn, old, new, .hv_removal_version))
  old_value
}
