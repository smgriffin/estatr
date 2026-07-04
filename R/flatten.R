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

  # An unnamed list is a JSON array (e.g. a table's multiple RESOURCE files);
  # index its elements so they don't collapse into duplicate column names.
  if (is_json_array(record)) {
    out <- list()
    for (j in seq_along(record)) {
      child_name <- if (is.null(prefix)) as.character(j) else paste(prefix, j, sep = "_")
      out <- c(out, flatten_record(record[[j]], child_name))
    }
    return(out)
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

# A JSON array parses to a list with no names (or all-empty names); a JSON
# object parses to a named list.
is_json_array <- function(x) {
  is.list(x) && length(x) > 0 && (is.null(names(x)) || all(!nzchar(names(x))))
}

# Assemble a list of records into a data.table, filling missing columns with NA
# so heterogeneous records line up. Returns an empty data.table for no records.
#
# rbindlist consumes the list of flattened named lists directly; converting each
# record to a data.table first (as.data.table per row) is ~200x slower on large
# tables because it builds one data.table object per record.
records_to_dt <- function(records) {
  if (length(records) == 0) {
    return(data.table::data.table())
  }
  rows <- lapply(records, flatten_record)
  data.table::rbindlist(rows, fill = TRUE, use.names = TRUE)
}

# Fast column-wise assembly for *flat* records -- records whose values are all
# scalars (no nested objects), which is exactly the shape of getStatsData VALUE
# rows. Extracting each column with one vapply over the records is far cheaper
# than flattening every record individually, and this is the package's hottest
# path on large tables. Use records_to_dt() for records that may be nested.
flat_records_to_dt <- function(records) {
  if (length(records) == 0) {
    return(data.table::data.table())
  }
  keys <- unique(unlist(lapply(records, names), use.names = FALSE))
  cols <- lapply(keys, function(k) {
    vapply(records, function(r) {
      v <- r[[k]]
      if (is.null(v) || length(v) == 0) NA_character_ else as.character(v[[1]])
    }, character(1))
  })
  names(cols) <- vapply(keys, function(k) if (identical(k, "$")) "value" else sub("^@", "", k), character(1))
  data.table::setDT(cols)[]
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
