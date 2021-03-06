% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/methods-FastProject.R
\docType{methods}
\name{viewResults,FastProject-method}
\alias{viewResults,FastProject-method}
\alias{viewResults}
\alias{viewResults,character-method}
\title{View results of analysis without saving output object}
\usage{
\S4method{viewResults}{FastProject}(object, port = NULL, host = NULL)

\S4method{viewResults}{character}(object, port = NULL, host = NULL)
}
\arguments{
\item{object}{FastProject object or path to a file containing such an
object (saved using saveAndViewResults, or directly using saveRDS)}

\item{port}{The port on which to serve the output viewer.  If omitted, a
random port between 8000 and 9999 is chosen.}

\item{host}{The host used to serve the output viewer. If omitted, "127.0.0.1"
is used.}
}
\value{
None
}
\description{
launch a local server to explore the results with a browser.
}
\examples{
expMat <- matrix(rnorm(200000), nrow=500)
rownames(expMat) <- paste0("gene",1:500)

# choose housekeeping genes
hkg <- housekeeping$default

#create 20 signatures of 25 genes each
sigs <- lapply(1:20, function(i) {
sigData <- sign(rnorm(25))
names(sigData) <- paste0("gene",sample(1:100,25))
return(createGeneSignature(name = paste0("sig",i),
                                 sigData = sigData))
})

fp <- FastProject(data = expMat,
                     housekeeping = hkg,
                     signatures = sigs)

## analyze requires actual non-random data to run properly
\dontrun{
fp.out <- analyze(fp)
viewResults(fp.out)
}
}
