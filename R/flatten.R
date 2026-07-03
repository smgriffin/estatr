# Convert e-Stat's nested JSON records into flat tables.
#
# This is the first piece of the internal data.table engine described in the
# roadmap: records are flattened and assembled with data.table::rbindlist (a
# bulk operation, never a row-wise loop), and converted to a tibble only at the
# return boundary by the calling wrapper.

# e-Stat leaf objects frequently take the shape {"@code": "x", "$": "label"}.
# Flatten one record (a nested list) into a single named character vector,
# joining nested keys with "_" and taking the "$" text node as a leaf value.
flatten_record <- function(record, prefix = NULL) {
  if (!is.list(record)) {
    return(stats::setNames(list(record %||% NA), prefix %||% "value"))
  }

  out <- list()
  nms <- names(record)
  for (i in seq_along(record)) {
    key <- nms[[i]]
    value <- record[[i]]
    # The "$" text node is the human-readable value of its parent object; keep
    # it under the parent's own name rather than a "<parent>_$" column.
    child_name <- if (identical(key, "$")) {
      prefix %||% "value"
    } else {
      clean_key <- sub("^@", "", key)
      if (is.null(prefix)) clean_key else paste(prefix, clean_key, sep = "_")
    }

    if (is.list(value)) {
      out <- c(out, flatten_record(value, child_name))
    } else {
      out[[child_name]] <- if (length(value) == 0) NA else value[[1]]
    }
  }
  out
}

# Assemble a list of records into a data.table, filling missing columns with NA
# so heterogeneous records line up. Returns an empty data.table for no records.
records_to_dt <- function(records) {
  if (length(records) == 0) {
    return(data.table::data.table())
  }
  rows <- lapply(records, function(r) data.table::as.data.table(flatten_record(r)))
  data.table::rbindlist(rows, fill = TRUE, use.names = TRUE)
}

# Normalise an e-Stat "*_INF" node that may be either a single object (when the
# API returns exactly one row) or a list of objects (many rows) into a plain
# list of record objects.
as_record_list <- function(node) {
  if (is.null(node)) return(list())
  # A single record is a named list containing e.g. "@id"; a list of records is
  # an unnamed list of such objects.
  if (!is.null(names(node))) list(node) else node
}
