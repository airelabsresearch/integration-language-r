#' This container's declared inputs and outputs, read from `hook-schema.json`.
#'
#' `hook-schema.json` is the only place they are written down. The publish
#' workflow copies it into the image label `com.airelabs.schema.v1.hook`, and
#' main.R reads its units from here, so the label and the code cannot disagree.

library(jsonlite)

HOOK_SCHEMA <- fromJSON("hook-schema.json", simplifyVector = FALSE)

.hook_spec <- function(kind, name) {
  for (spec in HOOK_SCHEMA[[kind]]) {
    if (identical(spec$name, name)) return(spec)
  }
  stop(sprintf("'%s' is not declared in hook-schema.json %s", name, kind))
}

#' The unit an input is declared in, or NULL. Stops on an undeclared name.
input_unit <- function(name) .hook_spec("inputs", name)$unit

#' The unit an output is declared in, or NULL. Stops on an undeclared name.
output_unit <- function(name) .hook_spec("outputs", name)$unit
