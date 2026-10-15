#' hook-schema.json must describe what main.R actually reads and writes.
#' Run with:  Rscript tests/test_hook_schema.R
#'
#' The registry rejects a label with an unknown key, so this also keeps the file
#' to the declared fields. The publish workflow validates the rest (types, name
#' patterns) against the published JSON Schema.

library(jsonlite)
source("R/hook_schema.R")

declared <- function(kind) {
  specs <- HOOK_SCHEMA[[kind]]
  setNames(specs, vapply(specs, function(s) s$name, ""))
}

test_only_known_top_level_keys <- function() {
  stopifnot(all(names(HOOK_SCHEMA) %in% c("version", "inputs", "outputs")))
  stopifnot(HOOK_SCHEMA$version == 1)
  message("PASS: test_only_known_top_level_keys")
}

test_fixtures_send_required_inputs_in_declared_units <- function() {
  inputs <- declared("inputs")
  for (fixture in c("hook-input.json", "hook-input-wind.json", "hook-input-bad-rate.json")) {
    params <- fromJSON(file.path("fixtures", fixture), simplifyVector = FALSE)$parametersV1
    params <- setNames(params, vapply(params, function(p) p$name, ""))
    stopifnot(all(names(params) %in% names(inputs)))
    for (name in names(inputs)) {
      spec <- inputs[[name]]
      if (isTRUE(spec$required) && is.null(params[[name]])) {
        stop(sprintf("%s does not send required '%s'", fixture, name))
      }
      if (!is.null(spec$unit) && !is.null(params[[name]])) {
        stopifnot(identical(params[[name]]$number$unit, spec$unit))
      }
    }
  }
  message("PASS: test_fixtures_send_required_inputs_in_declared_units")
}

test_every_result_is_declared_with_its_unit <- function() {
  output_path <- tempfile(fileext = ".json")
  Sys.setenv(AIRELABS_HOOK_INPUT_PATH = "fixtures/hook-input.json")
  Sys.setenv(AIRELABS_HOOK_OUTPUT_PATH = output_path)
  source("main.R")
  results <- fromJSON(output_path, simplifyVector = FALSE)$results
  results <- setNames(results, vapply(results, function(r) r$name, ""))
  outputs <- declared("outputs")
  stopifnot(setequal(names(results), names(outputs)))
  for (name in names(outputs)) {
    if (!is.null(results[[name]]$number)) {
      stopifnot(identical(results[[name]]$number$unit, outputs[[name]]$unit))
    }
  }
  message("PASS: test_every_result_is_declared_with_its_unit")
}

test_only_known_top_level_keys()
test_fixtures_send_required_inputs_in_declared_units()
test_every_result_is_declared_with_its_unit()
message("\nAll hook schema tests passed.")
