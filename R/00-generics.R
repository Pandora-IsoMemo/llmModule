#' Generic update function
#'
#' Dispatches update methods for different object classes.
#'
#' @param x Object to update
#' @param ... Further arguments
#' @export
update <- function(x, ...) {
  UseMethod("update")
}
