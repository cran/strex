#' Extract non-numerics assuming no number ambiguity.
#'
#' Sometimes the strings have ambiguous numbers in them e.g. 2.5.3. These have
#' to be dealt with by strex (which it does by returning `NA` in those cases).
#' This helper to `str_extract_non_numerics()` assumes that the input has
#' no such ambiguities.
#'
#' @param string A character vector.
#' @param num_pattern The regex defining a numer in the current context.
#'
#' @return A list of character vectors.
#'
#' @noRd
str_extract_non_nums_no_ambigs <- function(string, num_pattern) {
  stringi::stri_split_regex(string, num_pattern, omit_empty = TRUE)
}

#' Extract non-numbers from a string.
#'
#' Extract the non-numeric bits of a string where numbers are optionally defined
#' with decimals, scientific notation and thousand separators.
#'
#' \itemize{ \item `str_first_non_numeric(...)` is just
#' `str_nth_non_numeric(..., n = 1)`. \item `str_last_non_numeric(...)` is just
#' `str_nth_non_numeric(..., n = -1)`. }
#'
#' @inheritParams str_extract_numbers
#'
#' @examples
#' strings <- c(
#'   "abc123def456", "abc-0.12def.345", "abc.12e4def34.5e9",
#'   "abc1,100def1,230.5", "abc1,100e3,215def4e1,000"
#' )
#' str_extract_non_numerics(strings)
#' str_extract_non_numerics(strings, decimals = TRUE, leading_decimals = FALSE)
#' str_extract_non_numerics(strings, decimals = TRUE)
#' str_extract_non_numerics(strings, big_mark = ",")
#' str_extract_non_numerics(strings,
#'   decimals = TRUE, leading_decimals = TRUE,
#'   sci = TRUE
#' )
#' str_extract_non_numerics(strings,
#'   decimals = TRUE, leading_decimals = TRUE,
#'   sci = TRUE, big_mark = ",", negs = TRUE
#' )
#' str_extract_non_numerics(c("22", "1.2.3"), decimals = TRUE)
#' @family non-numeric extractors
#' @export
str_extract_non_numerics <- function(string, decimals = FALSE,
                                     leading_decimals = decimals, negs = FALSE,
                                     sci = FALSE, big_mark = "",
                                     commas = FALSE) {
  if (!isFALSE(commas)) {
    lifecycle::deprecate_stop(
      "2.0.0", "strex::str_extract_non_numerics(commas)",
      details = "Use the `big_mark` argument instead."
    )
  }
  checkmate::assert_character(string)
  checkmate::assert_flag(decimals)
  checkmate::assert_flag(leading_decimals)
  checkmate::assert_flag(negs)
  checkmate::assert_flag(sci)
  checkmate::assert_character(big_mark)
  if (is_l0_char(string)) {
    return(list())
  }
  num_pattern <- num_regex(
    decimals = decimals, leading_decimals = leading_decimals,
    negs = negs, sci = sci, big_mark = big_mark
  )
  ambig_pattern <- ambig_num_regex(
    decimals = decimals,
    leading_decimals = leading_decimals,
    sci = sci, big_mark = big_mark
  )
  ambigs <- num_ambigs(string,
    decimals = decimals,
    leading_decimals = leading_decimals, sci = sci,
    big_mark = big_mark
  )
  out <- vector(mode = "list", length = length(string))
  if (any(ambigs)) {
    ambig_warn(string, ambigs, ambig_regex = ambig_pattern)
    out[ambigs] <- NA_character_
    not_ambigs <- !ambigs
    out[not_ambigs] <- str_extract_non_nums_no_ambigs(
      string[not_ambigs],
      num_pattern
    )
  } else {
    out[] <- str_extract_non_nums_no_ambigs(string, num_pattern)
  }
  out
}

#' Extract the `n`th non-numeric substring from a string.
#'
#' This is a helper for `str_nth_non_numeric()` which assums non-ambiguous
#' input.
#'
#' For a detailed explanation of the number extraction, see
#' [str_extract_numbers()].
#'
#' @inheritParams str_extract_numbers
#' @inheritParams str_nth_number
#'
#' @return A character vector.
#'
#' @noRd
str_nth_non_numeric_no_ambigs <- function(string, num_pattern, n) {
  if (length(string) == 0) {
    return(character())
  }
  if (length(n) == 1 && n >= 0) {
    out <- stringi::stri_split_regex(string, num_pattern,
      n = n + 1,
      omit_empty = TRUE, simplify = TRUE
    )[, n]
    out[!str_length(out)] <- NA_character_
  } else {
    out <- stringi::stri_split_regex(string, num_pattern, omit_empty = TRUE) %>%
      chr_lst_nth_elems(n)
  }
  out
}

#' Extract the `n`th non-numeric substring from a string.
#'
#' Extract the `n`th non-numeric bit of a string where numbers are optionally
#' defined with decimals, scientific notation and thousand separators.
#' \itemize{ \item `str_first_non_numeric(...)` is just
#' `str_nth_non_numeric(..., n = 1)`. \item `str_last_non_numeric(...)` is
#' just `str_nth_non_numeric(..., n = -1)`. }
#'
#' @inheritParams str_extract_non_numerics
#' @inheritParams str_after_nth
#'
#'
#'
#' @examples
#' strings <- c(
#'   "abc123def456", "abc-0.12def.345", "abc.12e4def34.5e9",
#'   "abc1,100def1,230.5", "abc1,100e3,215def4e1,000"
#' )
#' str_nth_non_numeric(strings, n = 2)
#' str_nth_non_numeric(strings, n = -2, decimals = TRUE)
#' str_first_non_numeric(strings, decimals = TRUE, leading_decimals = FALSE)
#' str_last_non_numeric(strings, big_mark = ",")
#' str_nth_non_numeric(strings,
#'   n = 1, decimals = TRUE, leading_decimals = TRUE,
#'   sci = TRUE
#' )
#' str_first_non_numeric(strings,
#'   decimals = TRUE, leading_decimals = TRUE,
#'   sci = TRUE, big_mark = ",", negs = TRUE
#' )
#' str_first_non_numeric(c("22", "1.2.3"), decimals = TRUE)
#' @family non-numeric extractors
#' @export
str_nth_non_numeric <- function(string, n, decimals = FALSE,
                                leading_decimals = decimals, negs = FALSE,
                                sci = FALSE, big_mark = "", commas = FALSE) {
  if (!isFALSE(commas)) {
    lifecycle::deprecate_stop("2.0.0", "strex::str_nth_non_numeric(commas)",
                              details = "Use the `big_mark` argument instead.")
  }
  if (is_l0_char(string)) {
    return(character())
  }
  verify_string_n(string, n)
  checkmate::assert_flag(decimals)
  checkmate::assert_flag(leading_decimals)
  checkmate::assert_flag(negs)
  checkmate::assert_flag(sci)
  checkmate::assert_character(big_mark)
  num_pattern <- num_regex(
    decimals = decimals, leading_decimals = leading_decimals,
    negs = negs, sci = sci, big_mark = big_mark
  )
  ambig_pattern <- ambig_num_regex(
    decimals = decimals,
    leading_decimals = leading_decimals,
    sci = sci, big_mark = big_mark
  )
  ambigs <- num_ambigs(string,
    decimals = decimals,
    leading_decimals = leading_decimals, sci = sci,
    big_mark = big_mark
  )
  out <- character(length(string))
  if (any(ambigs)) {
    ambig_warn(string, ambigs, ambig_pattern)
    out[ambigs] <- NA_character_
    not_ambigs <- !ambigs
    out[not_ambigs] <- str_nth_non_numeric_no_ambigs(
      string[not_ambigs],
      num_pattern, n
    )
  } else {
    out[] <- str_nth_non_numeric_no_ambigs(string, num_pattern, n)
  }
  out
}

#' @rdname str_nth_non_numeric
#' @export
str_first_non_numeric <- function(string, decimals = FALSE,
                                  leading_decimals = decimals, negs = FALSE,
                                  sci = FALSE, big_mark = "", commas = FALSE) {
  str_nth_non_numeric(string,
    n = 1,
    decimals = decimals, leading_decimals = leading_decimals,
    negs = negs, sci = sci, big_mark = big_mark, commas = commas
  )
}

#' @rdname str_nth_non_numeric
#' @export
str_last_non_numeric <- function(string, decimals = FALSE,
                                 leading_decimals = decimals, negs = FALSE,
                                 sci = FALSE, big_mark = "") {
  str_nth_non_numeric(string,
    n = -1,
    decimals = decimals, leading_decimals = leading_decimals,
    negs = negs, sci = sci, big_mark = big_mark
  )
}
