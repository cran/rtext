// Generated by using Rcpp::compileAttributes() -> do not edit by hand
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include <Rcpp.h>

using namespace Rcpp;

// which_token_worker
IntegerVector which_token_worker(NumericVector x, NumericVector y1, NumericVector y2);
RcppExport SEXP rtext_which_token_worker(SEXP xSEXP, SEXP y1SEXP, SEXP y2SEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< NumericVector >::type x(xSEXP);
    Rcpp::traits::input_parameter< NumericVector >::type y1(y1SEXP);
    Rcpp::traits::input_parameter< NumericVector >::type y2(y2SEXP);
    rcpp_result_gen = Rcpp::wrap(which_token_worker(x, y1, y2));
    return rcpp_result_gen;
END_RCPP
}
