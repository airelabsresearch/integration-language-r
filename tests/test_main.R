#' Integration tests — full HookInput -> R computation -> HookOutput flow.
#' Run with:  Rscript tests/test_main.R

library(jsonlite)

# ── Helpers ──────────────────────────────────────────────────────────────────

assert_equal <- function(actual, expected, tol = 0.01, label = "") {
  if (abs(actual - expected) > tol) {
    stop(sprintf("FAIL %s: expected %.4f, got %.4f", label, expected, actual))
  }
}

run_with_fixture <- function(fixture_path) {
  output_path <- tempfile(fileext = ".json")
  Sys.setenv(AIRELABS_HOOK_INPUT_PATH = fixture_path)
  Sys.setenv(AIRELABS_HOOK_OUTPUT_PATH = output_path)
  source("main.R")
  stopifnot(file.exists(output_path))
  fromJSON(output_path)
}

get_result_value <- function(output, name, field = "number") {
  r <- output$results
  if (is.data.frame(r)) {
    row <- r[r$name == name, ]
    if (field == "number") return(as.numeric(row$number$value))
    if (field == "string") return(row$string)
    if (field == "error") return(row$error)
  } else {
    entry <- Filter(function(x) x$name == name, r)[[1]]
    if (field == "number") return(as.numeric(entry$number$value))
    if (field == "string") return(entry$string)
    if (field == "error") return(entry$error)
  }
}

# ── Tests ────────────────────────────────────────────────────────────────────

test_solar <- function() {
  output <- run_with_fixture("fixtures/hook-input.json")
  lcoe <- get_result_value(output, "lcoe")
  stopifnot(lcoe > 30 && lcoe < 80)
  assert_equal(get_result_value(output, "capex"), 960, label = "capex")
  stopifnot(get_result_value(output, "dataset", "string") == "solar")
  message(sprintf("PASS: test_solar (lcoe=%.2f USD/MWh)", lcoe))
}

test_wind <- function() {
  output <- run_with_fixture("fixtures/hook-input-wind.json")
  lcoe <- get_result_value(output, "lcoe")
  stopifnot(lcoe > 30 && lcoe < 100)
  stopifnot(get_result_value(output, "dataset", "string") == "wind")
  message(sprintf("PASS: test_wind (lcoe=%.2f USD/MWh)", lcoe))
}

test_error_result <- function() {
  output <- run_with_fixture("fixtures/hook-input-bad-rate.json")
  err <- get_result_value(output, "lcoe", "error")
  stopifnot(!is.null(err))
  stopifnot(err == "INVALID_DISCOUNT_RATE")
  # Other outputs should still have values
  assert_equal(get_result_value(output, "capex"), 960, label = "capex despite error")
  message("PASS: test_error_result")
}

# ── Run all ──────────────────────────────────────────────────────────────────

test_solar()
test_wind()
test_error_result()
message("\nAll integration tests passed.")
