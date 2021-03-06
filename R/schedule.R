assertthat::assert_that(require(R6))

#' @title Class providing an object to manipulate a schedule in a FR Y-9c
#' @name schedule
#'
#' @docType class
#' @importFrom R6 R6Class
#' @return Object of \code{\link{R6Class}}
#' @format \code{\link{R6Class}} object.
#' @field desig the designator of the schedule, e.g. "HI"
#' @field title the title of the schedule
#' @field dat A dataset from the Fed with all FR Y-9c data for a quarter.  The dataset contains columns with names that correspond to \code{key}s
#' @field comp a \code{component}
#' @field num The line item number of a component of a schedule
#' @field key The lookup key associated with the line item number
#' @field index the index of the desired \code{component} in the \code{schedule}
#' @field bank_names a vector of bank names to be stored in the \code{schedule}
#' @field pos_num_list a vector of \code{component} \code{num}s to be added
#' @field neg_num_list a vector of \code{component} \code{num}s to be subtracted
#' @section Methods:
#' \describe{
#'   \item{Documentation}{}
#'   \item{\code{new(desig, title)}}{generate a new \code{schedule}}
#'   \item{\code{initializeData(dat)}}{initialize the values in each \code{schedule}}
#'   \item{\code{add(comp)}}{add a \code{component} to this \code{schedule}}
#'   \item{\code{export_csv()}}{export this \code{schedule} in CSV format}
#'   \item{\code{print()}}{print the \code{schedule} as a string}
#'   \item{\code{getValueFromKey(key)}}{get a \code{component} value from this object or a sub-\code{component} that matches the \code{key}}
#'   \item{\code{getValueFromNum(num)}}{get a \code{component} value from the \code{component} number in this object or a sub-\code{component}}
#'   \item{\code{getCommonSizeValueFromNum(num)}}{get a \code{component} common-sized value from the \code{component} number in this object or a sub-\code{component}}
#'   \item{\code{getCommonSizeValueFromKey(key)}}{get a \code{component} common-sized value from the \code{component} \code{key} in this object or a sub-\code{component}}
#'   \item{\code{sumLevels(pos_num_list, neg_num_list)}}{add or subtract the \code{component}s in this schedule}
#'   \item{\code{getDesig()}}{get the \code{desig} for this object}
#'   \item{\code{getTitle()}}{get the \code{title} for this object}
#'   \item{\code{getBankNames()}}{get the \code{bank_names} assigned to this object}
#'   \item{\code{addBankNames(bank_names)}}{add \code{bank_names} to this object}
#'   \item{\code{createDataFrame()}}{create a \code{data.frame} from the \code{component}s in this object}
#'   \item{\code{getComponent(index)}}{get a \code{component} by its index in the \code{schedule}}
#'   \item{\code{commonSize(divisor)}}{common-size the \code{component}s in this \code{schedule} using the \code{divisor}}
#' }

.schedule <- R6::R6Class("schedule",
  public = list(
    initialize = function(desig, title)
    {
      assertthat::assert_that(length(desig) == 1 & length(title) == 1)
      private$desig <- desig
      private$title <- title
      private$len <- 0
    },
    initializeData = function(dat)
    {
      assertthat::assert_that(is.data.frame(dat), msg = "Can only initialize data with a data.frame")
      assertthat::assert_that(private$len > 0, msg = "Must add components to a schedule to initialize the data")
      private$value_len <- nrow(dat)
      dummy <- lapply(private$components, function(x) x$initializeData(dat))
    },
    add = function(comp)
    {
      assertthat::assert_that("component" %in% class(comp), msg = "Can only add components")
      private$components[[private$len + 1]] <- comp
      private$len <- private$len + 1
    },
    export_csv = function()
    {
      temp <- paste0("Schedule ", private$desig, ", ", private$title, ", ")
      if (private$len > 0)
      {
        temp <- c(temp, unlist(lapply(private$components, function(z) z$export_csv())))
      }
      return(temp)
    },
    print = function()
    {
      cat(paste0("Schedule ", private$desig, " ", private$title), "\n")
      if (private$len > 0)
      {
        lapply(private$components, print)
      }
    },
    getMetricFrom = function(key, num=NA, metric=.metric$value)
    {
      if (!missing(key))
      {
        cmp <- self$getComponentFrom(key)
        if (!is.null(cmp))
        {
          if (metric == .metric$value) return(cmp$getValue())
          else if (metric == .metric$common_size_value) return(cmp$getCommonSizeValue())
          else if (metric == .metric$num) return(cmp$getNum())
          else if (metric == .metric$name) return(cmp$getName())
          else if (metric == .metric$key) return(cmp$getKey())
          else stop("metric not found")
        } else
        {
          stop(paste("Key:", key, "not found"))
        }
      } else if (missing(key) && !is.na(num))
      {
        cmp <- self$getComponentFrom(num = num)
        if (!is.null(cmp))
        {
          if (metric == .metric$value) return(cmp$getValue())
          else if (metric == .metric$common_size_value) return(cmp$getCommonSizeValue())
          else if (metric == .metric$num) return(cmp$getNum())
          else if (metric == .metric$name) return(cmp$getName())
          else if (metric == .metric$key) return(cmp$getKey())
          else stop("metric not found")
        } else
        {
          stop(paste("Num:", num, "not found"))
        }
      } else
      {
        stop("Must supply key or num")
      }
    },
    getComponentFrom = function(key, num=NA)
    {
      if (!missing(key))
      {
        if (private$len == 0)
        {
          return(NULL)
        } else
        {
          for (i in 1:private$len)
          {
            if (!is.na(private$components[[i]]$getKey()) &&
                private$components[[i]]$getKey() == key)
            {
              return(private$components[[i]])
            } else
            {
              tmp <- private$components[[i]]$getComponentFrom(key)
              if (!is.null(tmp)) return(tmp)
            }
          }
        }
      } else if (missing(key) && !is.na(num))
      {
        if (private$len == 0)
        {
          return(NULL)
        } else
        {
          for (i in 1:private$len)
          {
            if (!is.na(private$components[[i]]$getNum()) &&
                private$components[[i]]$getNum() == num)
            {
              return(private$components[[i]])
            } else
            {
              tmp <- private$components[[i]]$getComponentFrom(num = num)
              if (!is.null(tmp)) return(tmp)
            }
          }
        }
      } else
      {
        stop("Must supply key or num")
      }
    },
    getValueFromKey = function(key)
    {
      self$getMetricFrom(key, metric = .metric$value)
    },
    getNumFromKey = function(key)
    {
      self$getMetricFrom(key, metric = .metric$num)
    },
    getKeyFromNum = function(num)
    {
      self$getMetricFrom(num = num, metric = .metric$key)
    },
    getValueFromNum = function(num)
    {
      self$getMetricFrom(num = num, metric = .metric$value)
    },
    getCommonSizeValueFromNum = function(num)
    {
      self$getMetricFrom(num = num, metric = .metric$common_size_value)
    },
    getCommonSizeValueFromKey = function(key)
    {
      self$getMetricFrom(key, metric = .metric$common_size_value)
    },
    getComponentFromKey = function(key)
    {
      self$getComponentFrom(key)
    },
    sumLevels = function(pos_num_list, neg_num_list)
    {
      temp <- matrix(0, ncol = length(pos_num_list), nrow = private$value_len)
      if (all(!is.na(pos_num_list)))
      {
        temp <- sapply(pos_num_list, function(x) self$getValueFromNum(x))
      }
      tempneg <- matrix(0, ncol = length(neg_num_list), nrow = private$value_len)
      if (all(!is.na(neg_num_list)))
      {
        tempneg <- sapply(neg_num_list, function(x) self$getValueFromNum(x))
      }
      if (length(dim(temp)) != 2)
      {
        cat("an item was likely not found\n")
        for (i in seq_along(pos_num_list))
        {
          cat(paste("\t", pos_num_list[i], paste(self$getValueFromNum(pos_num_list[i]), collapse = ", "), "\n"))
        }
        stop("")
      }
      if (length(dim(tempneg)) != 2)
      {
        cat("an item was likely not found\n")
        for (i in seq_along(neg_num_list))
        {
          cat(paste("\t", neg_num_list[i], paste(self$getValueFromNum(neg_num_list[i]), collapse = ", "), "\n"))
        }
        stop("")
      }
      return(apply(temp, 1, sum, na.rm = TRUE) - apply(tempneg, 1, sum, na.rm = TRUE))
    },
    getDesig = function()
    {
      return(private$desig)
    },
    getTitle = function()
    {
      return(private$title)
    },
    getBankNames = function()
    {
      return(private$bank_names)
    },
    addBankNames = function(bank_names)
    {
      assertthat::assert_that(length(bank_names) == private$value_len,
                              msg = paste0("bank_names are wrong length: ", length(bank_names),
                                           " vs ", private$value_len))
      private$bank_names <- bank_names
    },
    createDataFrame = function()
    {
      assertthat::assert_that(private$len > 0, msg = "Cannot create a data.frame from a schedule with no components")
      assertthat::assert_that(length(private$bank_names) > 0, msg = "Cannot create a data.frame until bank names have been added")
      dat_names <- c("Num", "Description", private$bank_names)
      allNums <- lapply(private$components, function(z) z$getAllNums())
      allNames <- lapply(private$components, function(z) z$getAllNames())
      allValues <- lapply(private$components, function(z) z$getAllValues())
      valueMat <- matrix(unlist(allValues), ncol = private$value_len, byrow = TRUE)
      temp <- data.frame(num = unlist(allNums),
                         name = unlist(allNames))
      temp <- cbind(temp, valueMat)
      names(temp) <- dat_names
      return(temp)
    },
    getComponent = function(index)
    {
      return(private$components[[index]])
    },
    commonSize = function(divisor)
    {
      if (private$len > 0)
      {
        dummy <- lapply(private$components, function(z) z$commonSize(divisor))
      } else
      {
        warning("There are no added Components to common size")
      }
    }
  ),
  private = list(
    desig = character(),
    title = character(),
    components = list(),
    len = integer(),
    value_len = integer(),
    bank_names = character()
  )
)

#' @rdname schedule
#'
#' @param desig the designator of the schedule, e.g. "HI"
#' @param title the title of the schedule
#'
#' @return an object of class \code{schedule}
#' @export
#'
#' @examples
#' x <- Schedule("HI", "Income Statement")
#' y <- Component("1.a.", "Income", "ZZZZ1234")
#' y$add(Component("1.a.(1)", "Sub-Income", "ABCD5555"))
#' x$add(y)
#' x$initializeData(data.frame(ZZZZ1234 = 1:4,
#'                             ABCD5555 = 5:8))
#' x$addBankNames(paste("bank", LETTERS[1:4], sep=""))
#' all(x$export_csv() == c("Schedule HI, Income Statement, ",
#'                         "1.a., Income, 1,2,3,4",
#'                         "1.a.(1), Sub-Income, 5,6,7,8"))
#' print(x)
#' all(x$getValueFromKey("ABCD5555") == 5:8)
#' all(x$getValueFromNum("1.a.") == 1:4)
#' x$getDesig() == "HI"
#' x$getTitle() == "Income Statement"
#' all(x$getBankNames() == paste("bank", LETTERS[1:4], sep=""))
#' x$getComponent(1)$getKey() == "ZZZZ1234"
#' all(x$sumLevels(c("1.a.", "1.a.(1)"), NA) == 1:4 + 5:8)
#' all(x$sumLevels("1.a.", "1.a.(1)") == 1:4 - 5:8)
#' all(x$createDataFrame()$bankA == c(1,5))
#' x$commonSize(100)
#' all.equal(x$getCommonSizeValueFromNum("1.a."), (1:4)/100)
#' all.equal(x$getCommonSizeValueFromKey("ZZZZ1234"), (1:4)/100)

Schedule <- function(desig, title)
{
  return(.schedule$new(desig, title))
}
