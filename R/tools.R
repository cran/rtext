order <- function(...){

  if ( "data.frame" %in% unlist(lapply(list(...), class)) ) {
    warning("order called");
    print(traceback())
  }


  base::order(...)
}


#' function to write csv files with UTF-8 characters (even under Windows)
#' @param df data frame to be written to file
#' @param file file name / path where to put the data
#' @keywords internal
write_utf8_csv <-
  function(df, file){
    if ( is.null(df) ) df <- data.frame()
    firstline <- paste(  '"', names(df), '"', sep = "", collapse = " , ")
    char_columns <- seq_along(df[1,])[sapply(df, class)=="character"]
    #for( i in  char_columns){
    #  df[,i] <- toUTF8(df[,i])
    #}
    data <- apply(df, 1, function(x){paste('"', x,'"', sep = "",collapse = " , ")})
    writeLines( text=c(firstline, data), con=file , useBytes = T)
  }


#' function to read csv file with UTF-8 characters (even under Windwos) that
#' were created by write_U
#' @param file file name / path where to get the data
#' @keywords internal
read_utf8_csv <- function(file){
  if ( !file.exists(file) ) return( data.frame() )
  # reading data from file
  content <- readLines(file, encoding = "UTF-8")
  if ( length(content) < 2 ) return( data.frame() )
  # extracting data
  content <- stringb::text_split(content, " , ")
  content <- lapply(content, stringb::text_replace_all, '"', "")
  content_names <- content[[1]][content[[1]]!=""]
  content <- content[seq_along(content)[-1]]
  # putting it into data.frame
  df <- data.frame(dummy=seq_along(content), stringsAsFactors = F)
  for(name in content_names){
    tmp <- sapply(content, `[[`, dim(df)[2])
    Encoding(tmp) <- "UTF-8"
    df[,name] <- tmp
  }
  df <- df[,-1]
  # return
  return(df)
}



#' function to get hash for R objects
#' @param x the thing to hash
#' @keywords internal
rtext_hash <- function(x){
  digest::digest(x, algo="xxhash64")
}

#' text function: wrapper for system.file() to access test files
#' @param x name of the file
#' @param pattern pattern of file name
#' @keywords internal
testfile <- function(x=NULL, pattern=NULL, full.names=FALSE){
  if(is.numeric(x)){
    return(testfile(testfile()[(x-1) %% length(testfile()) +1 ]))
  }
  if(is.null(x)){
    return(
      list.files(
        system.file(
          "testfiles",
          package = "rtext"
        ),
        pattern = pattern,
        full.names = full.names
      )
    )
  }else if(x==""){
    return(
      list.files(
        system.file(
          "testfiles",
          package = "rtext"
        ),
        pattern = pattern,
        full.names = full.names
      )
    )
  }else{
    return(
      system.file(
        paste("testfiles", x, sep="/"),
        package = "rtext")
    )
  }
}


#' function used to delete parts from a vector
#' @param x input vector
#' @param n number of items to be deleted
#' @param from from which position onwards elements should be deleted
#' @param to up to which positions elements should be deleted
#' @keywords internal

vector_delete <- function(x, n=NULL, from=NULL, to=NULL){
  # shortcuts
  if( is.null(n) ){
    if(is.null(from) & is.null(to)){
      return(x)
    }
  }else{
    if( n==0){
      return(x)
    }
  }
  # iffer
  iffer <- TRUE
  if( is.null(from) & is.null(to)  & !is.null(n) ){ # only n
    iffer <- seq_along(x) > length(x) | seq_along(x) <= length(x)-n
  }else if( !is.null(from) & is.null(to)  & is.null(n) ){ # only from
    iffer   <- seq_along(x) < from
  }else if( is.null(from) & !is.null(to) & is.null(n) ){ # only to
    iffer   <- seq_along(x) > to
  }else if( !is.null(from) & !is.null(to)  & is.null(n) ){ # from + to
    iffer   <- seq_along(x) > to | seq_along(x) < from
  }else if( !is.null(from) & is.null(to)  & !is.null(n) ){ # from + n
    if( n > 0 ){
      n     <- bind_between(n-1, 0, length(x))
      iffer <- seq_along(x) > from+n | seq_along(x) < from
    }
  }else if( is.null(from) & !is.null(to)  & !is.null(n) ){ # to + n
    iffer <- seq_along(x) > to | seq_along(x) <= to-n
  }
  # return
  return( x[iffer] )
}




#' function that loads saved rtext
#' @param save_file a saved rtext object in Rdata format
#' @keywords internal

load_into <- function(save_file){
  tmp_env <- new.env(parent = emptyenv())
  load(save_file, envir = tmp_env)
  tmp <- lapply(tmp_env, I)
  class(tmp) <- NULL
  return(tmp)
}


#' function that shifts vector values to right or left
#'
#' @param x Vector for which to shift values
#' @param n Number of places to be shifted.
#'    Positive numbers will shift to the right by default.
#'    Negative numbers will shift to the left by default.
#'    The direction can be inverted by the invert parameter.
#' @param default The value that should be inserted by default.
#' @param invert Whether or not the default shift directions
#'    should be inverted.
#' @keywords internal

shift <- function(x, n=0, default=NA, invert=FALSE){
  n <-
    switch (
      as.character(n),
      right    =  1,
      left     = -1,
      forward  =  1,
      backward = -1,
      lag      =  1,
      lead     = -1,
      as.numeric(n)
    )
  if( length(x) <= abs(n) ){
    if(n < 0){
      n <- -1 * length(x)
    }else{
      n <- length(x)
    }
  }
  if(n==0){
    return(x)
  }
  n <- ifelse(invert, n*(-1), n)
  if(n<0){
    n <- abs(n)
    forward=FALSE
  }else{
    forward=TRUE
  }
  if(forward){
    return(c(rep(default, n), x[seq_len(length(x)-n)]))
  }
  if(!forward){
    return(c(x[seq_len(length(x)-n)+n], rep(default, n)))
  }
}

#' function forcing value to fall between min and max
#' @param x the values to be bound
#' @param max upper boundary
#' @param min lower boundary
#' @keywords internal
bind_between <- function(x, min, max){
  x[x<min] <- min
  x[x>max] <- max
  return(x)
}


#' function for binding data.frames even if names do not match
#' @param df1 first data.frame to rbind
#' @param df2 second data.frame to rbind
#' @keywords internal

rbind_fill <- function(df1=data.frame(), df2=data.frame()){
  names_df <- c(names(df1), names(df2))
  if( dim1(df1) > 0 ){
    df1[, names_df[!(names_df %in% names(df1))]] <- rep(NA, dim1(df1))
  }else{
    df1 <- data.frame()
  }
  if( dim1(df2) > 0 ){
    df2[, names_df[!(names_df %in% names(df2))]] <- rep(NA, dim1(df2))
  }else{
    df2 <- data.frame()
  }
  rbind(df1, df2)
}




#' function that checks is values are in between values
#' @param x input vector
#' @param y lower bound
#' @param z upper bound
#' @keywords internal
is_between <- function(x,y,z){
  return(x>=y & x<=z)
}


#' function that extracts elements from vector
#'
#' @param vec the chars field
#' @param length number of elements to be returned
#' @param from first element to be returned
#' @param to last element to be returned
#' @keywords internal
get_vector_element <-
  function(vec, length=NULL , from=NULL, to=NULL){
    # helper functions
    bind_to_vecrange <- function(x){bind_between(x, 1, length(vec))}
    bind_length       <- function(x){bind_between(x, 0, length(vec))}
    return_from_to    <- function(from, to, split){
      res  <- vec[seq(from=from, to=to)]
      return(res)
    }
    # only length
    if( !is.null(length) & ( is.null(from) & is.null(to) ) ){
      length <- max(0, min(length, length(vec)))
      length <- bind_length(length)
      if(length==0){
        return("")
      }
      from   <- 1
      to     <- length
      return(return_from_to(from, to, split))
    }
    # from and to (--> ignores length argument)
    if( !is.null(from) & !is.null(to) ){
      from <- bind_to_vecrange(from)
      to   <- bind_to_vecrange(to)
      return(return_from_to(from, to, split))
    }
    # length + from
    if( !is.null(length) & !is.null(from) ){
      if( length<=0 | from + length <=0 ){
        return("")
      }
      to   <- from + length-1
      if((to < 1 & from < 1) | (to > length(vec) & from > length(vec) )){
        return("")
      }
      to   <- bind_to_vecrange(to)
      from <- bind_to_vecrange(from)
      return(return_from_to(from, to, split))
    }
    # length + to
    if( !is.null(length) & !is.null(to) ){
      if( length<=0 | to - (length-1) > length(vec) ){
        return("")
      }
      from <- to - length + 1
      if((to < 1 & from < 1) | (to > length(vec) & from > length(vec) )){
        return("")
      }
      from <- bind_to_vecrange(from)
      to   <- bind_to_vecrange(to)
      return(return_from_to(from, to, split))
    }
    stop("get_vector_element() : I do not know how to make sense of given length, from, to argument values passed")
  }



#' get first dimension or length of object
#' @param x object, matrix, vector, data.frame, ...

#' @keywords internal
dim1 <- function(x){
  ifelse(is.null(dim(x)[1]), length(x), dim(x)[1])
}


#' get first dimension or length of object
#' @param x object, matrix, vector, data.frame, ...
#' @keywords internal

dim2 <- function(x){
  dim(x)[2]
}


#' seq along first dimension / length
#' @param x x
#' @keywords internal

seq_dim1 <- function(x){
  seq_len(dim1(x))
}


#' function returning index of spans that entail x
#' @param x position of the character
#' @param y1 start position of the token
#' @param y2 end position of the token
#' @keywords internal

which_token <- function(x, y1, y2){
  # how to order x and y?
  order_x <- order(x)
  order_y <- order(y1)
  # order x and y! - which_token_worker expects inputs to be ordered
  ordered_x  <- x[order_x]
  ordered_y1 <- y1[order_y]
  ordered_y2 <- y2[order_y]
  # doing-duty-to-do
  index <- which_token_worker(ordered_x, ordered_y1, ordered_y2)
  # ordering back to input ordering
  index <- order_y[index[order(order_x)]]
  # return
  index
}




#' function giving back the mode

#' @param x vector to get mode for
#' @param multimodal wether or not all modes should be returned in case of more than one
#' @param warn should the function warn about multimodal outcomes?
#' @export
modus <- function(x, multimodal=FALSE, warn=TRUE) {
  x_unique <- unique(x)
  tab_x    <- tabulate(match(x, x_unique))
  res      <- x_unique[which(tab_x==max(tab_x))]
  if( identical(multimodal, TRUE) ){
    return(res)
  }else{
    if( warn & length(res) > 1 ){
      warning("modus : multimodal but only one value returned (use warn=FALSE to turn this off)")
    }
    if( !identical(multimodal, FALSE) & length(res) > 1 ){
      return(multimodal)
    }else{
      return(res[1])
    }
  }
}





#' function to get classes from e.g. lists
#' @param x list to get classes for
#' @keywords internal
classes <- function(x){
  tmp <- lapply(x, class)
  data.frame(name=names(tmp), class=unlist(tmp) , row.names = NULL)
}






#' function to sort df by variables
#' @param df data.frame to be sorted
#' @param ... column names to use for sorting
#' @keywords internal
dp_arrange <- function(df, ...){
  sorters    <- as.character(as.list(match.call()))
  if( length(sorters)>2 ){
    sorters     <- sorters[-c(1:2)]
    sort_list   <- unname(as.list(df[, sorters, drop=FALSE]))
    order_index <- do.call(order, sort_list)
    return(df[order_index, , drop=FALSE])
  }else{
    return(df)
  }
}






















