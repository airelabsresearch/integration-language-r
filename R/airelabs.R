#' Aire Labs Hook I/O helpers for R.
#'
#' Thin wrapper around jsonlite that reads HookInput parameters and writes
#' HookOutput results.  Copy this file into any R container function project
#' as a starting point.

library(jsonlite)

# ── Reading input ────────────────────────────────────────────────────────────

#' Read and parse the HookInput JSON file.
#' Returns the parametersV1 data frame.
read_hook_input <- function() {
  path <- Sys.getenv("AIRELABS_HOOK_INPUT_PATH")
  if (path == "") stop("AIRELABS_HOOK_INPUT_PATH is not set")
  hook_input <- fromJSON(path)
  hook_input$parametersV1
}

#' Look up a single parameter row by name.  Stops if missing.
require_param <- function(params, name) {
  row <- params[params$name == name, ]
  if (nrow(row) == 0) {
    stop(sprintf("missing required parameter: '%s'", name))
  }
  row
}

#' Extract a numeric parameter as a double.
#' Optionally checks that the unit matches expected_unit.
require_number <- function(params, name, expected_unit = NULL) {
  row <- require_param(params, name)
  num <- row$number
  if (is.null(num)) {
    stop(sprintf("parameter '%s': expected 'number' field", name))
  }
  if (!is.null(expected_unit) && !is.null(num$unit) && num$unit != expected_unit) {
    stop(sprintf(
      "parameter '%s': expected unit '%s', got '%s'",
      name, expected_unit, num$unit
    ))
  }
  as.numeric(num$value)
}

#' Extract a string parameter.
require_string <- function(params, name) {
  row <- require_param(params, name)
  if (is.null(row$string)) {
    stop(sprintf("parameter '%s': expected 'string' field", name))
  }
  row$string
}

#' Extract a boolean parameter (returns logical TRUE/FALSE).
require_boolean <- function(params, name) {
  row <- require_param(params, name)
  if (is.null(row$boolean)) {
    stop(sprintf("parameter '%s': expected 'boolean' field", name))
  }
  row$boolean == "true"
}

#' Extract a date parameter (returns Date object).
require_date <- function(params, name) {
  row <- require_param(params, name)
  if (is.null(row$date)) {
    stop(sprintf("parameter '%s': expected 'date' field", name))
  }
  as.Date(row$date)
}

# ── Building results ─────────────────────────────────────────────────────────

#' Build a number result entry.
number_result <- function(name, value, unit = NULL) {
  num <- list(value = trimws(format(round(value, 2), nsmall = 2, scientific = FALSE)))
  if (!is.null(unit)) num$unit <- unit
  list(name = name, number = num)
}

#' Build a numberArray result entry.
number_array_result <- function(name, values, unit = NULL) {
  arr <- list(values = trimws(format(round(values, 2), nsmall = 2, scientific = FALSE)))
  if (!is.null(unit)) arr$unit <- unit
  list(name = name, numberArray = arr)
}

#' Build a string result entry.
string_result <- function(name, value) {
  list(name = name, string = value)
}

#' Build a boolean result entry.
boolean_result <- function(name, value) {
  list(name = name, boolean = if (value) "true" else "false")
}

#' Build a date result entry.
date_result <- function(name, value) {
  list(name = name, date = format(value, "%Y-%m-%d"))
}

#' Build an error result entry.
#' Use this when a specific output could not be computed. The platform
#' displays the error string in the model cell and marks downstream cells
#' as dependent errors.
error_result <- function(name, error_code) {
  list(name = name, error = error_code)
}

# ── Writing output ───────────────────────────────────────────────────────────

#' Write a list of results to the HookOutput JSON file.
write_hook_output <- function(results) {
  path <- Sys.getenv("AIRELABS_HOOK_OUTPUT_PATH")
  if (path == "") stop("AIRELABS_HOOK_OUTPUT_PATH is not set")
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  write_json(list(results = results), path, auto_unbox = TRUE)
}
