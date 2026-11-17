* The `sample_*()` generators take `seed = NULL` to draw from the session's random-number stream without setting a seed. The default, `42`, still gives the same data on every call and leaves the caller's stream as it was. Before, `seed = NULL` warned and could not opt out.

* Examples that run in a few seconds are no longer wrapped in `\donttest{}`, so `R CMD check` runs them every time.

* The maintainer is declared as copyright holder (`cph`) in `Authors@R`.
