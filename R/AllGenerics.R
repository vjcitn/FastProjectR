#' @rdname FastProject-class
#' @export
setGeneric("FastProject", function(data, ...) {
    standardGeneric("FastProject")
})

setGeneric("addSigData", function(object, data) {
    standardGeneric("addSigData")
})

setGeneric("analyze", function(object, ...) {
    standardGeneric("analyze")
})

setGeneric("cluster", function(object, method, param) {
    standardGeneric("cluster")
})

setGeneric("createOutputDirectory", function(object) {
    standardGeneric("createOutputDirectory")
})

setGeneric("getExprData", function(object) {
    standardGeneric("getExprData")
})

setGeneric("getNormalizedCopy", function(object, func) {
    standardGeneric("getNormalizedCopy")
})

setGeneric("saveAndViewResults", function(fpout, ...) {
    standardGeneric("saveAndViewResults")
})

setGeneric("sigEqual", function(object, compareSig) {
    standardGeneric("sigEqual")
})

setGeneric("readExprData", function(object) {
    standardGeneric("readExprData")
})

setGeneric("updateExprData", function(object, newData) {
    standardGeneric("updateExprData")
})

setGeneric("updateProjection", function(object, name, data) {
    standardGeneric("updateProjection")
})

setGeneric("viewResults", function(object, ...) {
    standardGeneric("viewResults")
})

setGeneric("computeKNNWeights", function(object, K, BPPARAM) {
    standardGeneric("computeKNNWeights")
})
