# The one-release deprecations warn once per session. Their own tests
# (test_deprecate.R and beside each function) start from a clean slate with
# local_fresh_deprecations(). Every other test that relies on an old default
# does so on purpose, to test something else, so those warnings are marked as
# already shown here rather than repeated across the suite.
for (id in c(paste0("hv_followup:", c("origin_year", "study_start", "study_end", "close_date")),
             paste0("hv_mirror_hist:", c("group_col", "group_labels")),
             "make_footnote:text", "hv_panel_box:mode")) {
  assign(id, TRUE, envir = .hv_deprecation_seen)
}

# Forget which deprecations have warned for the rest of the calling test, and
# restore the previous state afterwards.
local_fresh_deprecations <- function(env = parent.frame()) {
  seen <- as.list(.hv_deprecation_seen, all.names = TRUE)
  .hv_deprecate_reset()
  withr::defer({
    .hv_deprecate_reset()
    list2env(seen, envir = .hv_deprecation_seen)
  }, envir = env)
}

# Evaluate `expr`, muffling and collecting every hvtiPlotR_deprecated warning.
# Any other warning passes through. Returns list(value, warnings).
collect_deprecations <- function(expr) {
  msgs <- character()
  value <- withCallingHandlers(expr, hvtiPlotR_deprecated = function(w) {
    msgs <<- c(msgs, conditionMessage(w))
    invokeRestart("muffleWarning")
  })
  list(value = value, warnings = msgs)
}
