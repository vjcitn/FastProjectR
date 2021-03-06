
#' Registers the projection methods to be used
#'
#' @param lean If FALSE, all projections applied; else a subset of essential ones are applied. Default is FALSE.
#' @return List of projection methods to be applied.
registerMethods <- function(lean=FALSE) {

    projMethods <- c()
    if (!lean) {
    projMethods <- c(projMethods, "ISOMap" = applyISOMap)
    projMethods <- c(projMethods, "ICA" = applyICA)
    #projMethods <- c(projMethods, "RBF Kernel PCA" = applyRBFPCA)
    }

    projMethods <- c(projMethods, "tSNE30" = applytSNE30)
    projMethods <- c(projMethods, "KNN" = applyKNN)
    projMethods <- c(projMethods, "tSNE10" = applytSNE10)

    return(projMethods)
}

#' Projects data into 2 dimensions using a variety of linear and non-linear methods.
#'
#' @importFrom stats quantile
#' @param expr ExpressionData object
#' @param weights weights estimated from FNR curve
#' @param filterName name of filter, to extract correct data for projections
#' @param inputProjections Precomputed projections
#' @param lean If TRUE, diminished number of algorithms applied,
#' if FALSE all algorithms applied. Default is FALSE
#' @param perm_wPCA If TRUE, apply permutation wPCA to determine significant
#' number of components. Default is FALSE.
#' @param BPPARAM the backend to use for parallelization
#' @return list:
#' \itemize{
#'     \item projections: a list of Projection objects
#'     \item geneNames: a character vector of the genes involved in the analsis
#'     \item fullPCA: the full PCA matrix of the data
#'     \item loadings: the loading vectors for the fullPCA matrix
#'     \item permMats: a list of permuted and projected data matrices, used for
#'     downstream permutation tests
#' }
generateProjections <- function(expr, weights, filterName="",
                                inputProjections=c(), lean=FALSE,
                                perm_wPCA=FALSE, BPPARAM = BiocParallel::bpparam()) {

    if (filterName == "novar") {
    exprData <- expr@noVarFilter
    } else if (filterName == "threshold") {
    exprData <- expr@thresholdFilter
    } else if (filterName == "fano") {
    exprData <- expr@fanoFilter
    } else if (filterName == "") {
    exprData <- expr@data
    } else {
    stop("FilterName not recognized: ", filterName)
    }

    methodList = registerMethods(lean)

    if (perm_wPCA) {
    res <- applyPermutationWPCA(exprData, weights, components=30)
    pca_res <- res[[1]]
    loadings <- res[[3]]
    permMats <- res$permuteMatrices
    } else {
    res <- applyWeightedPCA(exprData, weights, maxComponents = 30)
    pca_res <- res[[1]]
    loadings <- res[[3]]
    permMats <- NULL
    #m <- profmem(pca_res <- applyWeightedPCA(exprData, weights, maxComponents = 30)[[1]])
    }

    inputProjections <- c(inputProjections, Projection("PCA: 1,2", t(pca_res[c(1,2),])))
    inputProjections <- c(inputProjections, Projection("PCA: 1,3", t(pca_res[c(1,3),])))
    inputProjections <- c(inputProjections, Projection("PCA: 2,3", t(pca_res[c(2,3),])))

    fullPCA <- t(pca_res[1:min(15,nrow(pca_res)),])
    fullPCA <- as.matrix(apply(fullPCA, 2, function(x) return( x - mean(x) )))

    r <- apply(fullPCA, 1, function(x) sum(x^2))^(0.5)
    r90 <- quantile(r, c(.9))[[1]]

    if (r90 > 0) {
    fullPCA <- fullPCA / r90
    }
    fullPCA <- t(fullPCA)

    for (method in names(methodList)){
    gc()
    message(method)
    ## run on raw data
    if (method == "ICA" || method == "RBF Kernel PCA") {
        res <- methodList[[method]](exprData)
        proj <- Projection(method, res)
        inputProjections <- c(inputProjections, proj)
    } else if (method == "KNN") {
        res <- methodList[[method]](pca_res, BPPARAM)
        proj <- Projection(method, res, weights=res)
        inputProjections <- c(inputProjections, proj)
    } else { ## run on reduced data
        res <- methodList[[method]](pca_res, BPPARAM)
        proj <- Projection(method, res)
        inputProjections <- c(inputProjections, proj)
        }
    }

    output <- list()

    for (p in inputProjections) {
        coordinates <- p@pData

        coordinates <- as.matrix(apply(coordinates, 2, function(x) return( x - mean(x) )))

        r <- apply(coordinates, 1, function(x) sum(x^2))^(0.5)
        r90 <- quantile(r, c(.9))[[1]]

        if (r90 > 0) {
        coordinates <- coordinates / r90
        }

        coordinates <- t(coordinates)
        p <- updateProjection(p, data=coordinates)
        output[[p@name]] = p

        }

    output[["KNN"]]@pData <- output[["tSNE30"]]@pData

    return(list(projections = output, geneNames = rownames(exprData),
                fullPCA = fullPCA, loadings = loadings, permMats = permMats))
}

#' Genrate projections based on a tree structure learned in high dimensonal space
#'
#' @importFrom stats quantile
#' @param expr the expressionSet object
#' @param filterName the filtered data to use
#' @param inputProjections a list of Projection objects. For each Projection, a
#' corresponding TreeProjection will be created in which the scores are based
#' on geodesic distances instead of euclidean one
#' @param permMats a list of matrices to use as a null distribution for
#' estimating the significance of the fitted tree. These are generated by the
#' permutation wPCA algorithm upstream
#' @param BPPARAM the backend to use for parallelization for this analysis
#' @return a list:
#' \itemize{
#'     \item projections a list of TreeProjection objects
#'     \item treeScore a score representing the singificance of the fitten tree
#'     return(list(projections = output, treeScore = hdTree$zscore))
#' }
generateTreeProjections <- function(expr, filterName="",
                                    inputProjections, permMats = NULL,
                                    BPPARAM = bpparam()) {


    if (filterName == "novar") {
    exprData <- expr@noVarFilter
    } else if (filterName == "threshold") {
    exprData <- expr@thresholdFilter
    } else if (filterName == "fano") {
    exprData <- expr@fanoFilter
    } else if (filterName == "") {
    exprData <- expr@data
    } else {
    stop("FilterName not recognized: ", filterName)
    }

    t <- Sys.time()
    timingList <- (t - t)
    timingNames <- c("Start")

    hdTree <- applySimplePPT(exprData, permExprData = permMats)
    hdProj <- TreeProjection(name = "PPT", pData = exprData,
                                vData = hdTree$princPnts, adjMat = hdTree$adjMat)

    ncls <- apply(hdTree$distMat, 1, which.min)
    pptNeighborhood <- findNeighbors(exprData, ##why was this fullPCA here?
                                    hdTree$princPnts,
                                    NCOL(exprData) / NCOL(hdTree$princPnts),
                                    BPPARAM)

    timingList <- rbind(timingList, c(difftime(Sys.time(), t, units="sec")))
    timingNames <- c(timingNames, "PPT")
    rownames(timingList) <- timingNames

    # Readjust coordinates of PPT
    c <- t(hdTree$princPnts[c(1,2),])
    coord <- as.matrix(apply(c, 2, function(x) return(x - mean(x))))
    r <- apply(coord, 1, function(x) sum(x^2))^(0.5)
    r90 <- quantile(r, c(0.9))[[1]]
    if (r90 > 0) {
    coord <- coord / r90
    }
    coord <- t(coord)
    hdTree$princPnts <- coord

    output <- list()
    output[[hdProj@name]] <- hdProj

    # Reposition tree node coordinates in nondimensional space
    for (proj in inputProjections) {
    new_coords <- vapply(pptNeighborhood, function(n)  {
        centroid <- proj@pData[,n$index] %*% t(n$dist / sum(n$dist))
        # n_vals <- proj@pData[,n$index] * rep(n$dist / sum(n$dist), rep(nrow(proj@pData), length(n$dist)))
        # centroid <- apply(n_vals, 1, mean)
        return(centroid)
    }, c(0.0,0.0))
    treeProj = TreeProjection(name = proj@name, pData = proj@pData,
                                vData = new_coords, adjMat = hdTree$adjMat)
    output[[treeProj@name]] = treeProj
    }

    return(list(projections = output, treeScore = hdTree$zscore))
}

#' Performs weighted PCA on data
#'
#' @importFrom rsvd rsvd
#'
#' @param exprData Expression matrix
#' @param weights Weights to use for each coordinate in data
#' @param maxComponents Maximum number of components to calculate
#' @return Weighted PCA data
#' @return Variance of each component
#' @return Eigenvectors of weighted covariance matrix, aka the variable loadings
applyWeightedPCA <- function(exprData, weights, maxComponents=200) {

    projData <- exprData
    if (nrow(projData) != nrow(weights) || ncol(projData) != ncol(weights)) {
    weights <- weights[rownames(exprData), ]
    }

    # Center data
    wmean <- as.matrix(rowSums(multMat(projData, weights)) / rowSums(weights))
    dataCentered <- as.matrix(apply(projData, 2, function(x) x - wmean))

    # Compute weighted data
    #wDataCentered <- multMat(dataCentered, weights)
    wDataCentered <- dataCentered * weights

    # Weighted covariance / correlation matrices
    W <- tcrossprod(wDataCentered)
    Z <- tcrossprod(weights)

    wcov <- W / Z
    wcov[is.na(wcov)] <- 0.0
    var <- diag(wcov)

    # SVD of wieghted correlation matrix
    ncomp <- min(ncol(projData), nrow(projData), maxComponents)
    decomp <- rsvd::rsvd(wcov, k=ncomp)
    evec <- t(decomp$u)

    # Project down using computed eigenvectors
    dataCentered <- dataCentered / sqrt(var)
    wpcaData <- crossprod(t(evec), dataCentered)
    #wpcaData <- wpcaData * (decomp$d*decomp$d)
    eval <- as.matrix(apply(wpcaData, 1, var))
    totalVar <- sum(apply(projData, 1, var))
    eval <- eval / totalVar

    colnames(evec) <- rownames(exprData)


    return(list(wpcaData, eval, t(evec)))

}

#' Applies pemutation method to return the most significant components of weighted PCA data
#'
#' @details Based on the method proposed by Buja and Eyuboglu (1992), PCA is performed on the data
#' then a permutation procedure is used to assess the significance of components
#'
#' @importFrom stats pnorm
#' @param expr Expression data
#' @param weights Weights to apply to each coordinate in data
#' @param components Maximum components to calculate. Default is 50.
#' @param p_threshold P Value to cutoff components at. Default is .05.
#' @param verbose Logical value indicating whether or not a verbose session is being run.
#' @return (list):
#' \itemize{
#'     \item wPCA: weighted PCA data
#'     \item eval: the proortinal variance of each component
#'     \item evec: the eigenvectors of the weighted covariance matrix
#'     \item permuteMatrices: the permuted matrices generated as the null distrbution
#' }
applyPermutationWPCA <- function(expr, weights, components=50, p_threshold=.05, verbose=FALSE) {
    if(verbose) message("Permutation WPCA")
    comp <- min(components, nrow(expr), ncol(expr))

    NUM_REPEATS <- 20;

    w <- applyWeightedPCA(expr, weights, comp)
    wPCA <- w[[1]]
    eval <- w[[2]]
    evec <- w[[3]]

    # Instantiate matrices for background distribution
    bg_vals <- matrix(0L, nrow=NUM_REPEATS, ncol=components)
    bg_data <- matrix(0L, nrow=nrow(expr), ncol=ncol(expr))
    bg_weights <- matrix(0L, nrow=nrow(expr), ncol=ncol(expr))

    permMats <- list()

    # Compute background data and PCAs for comparing p values
    for (i in 1:NUM_REPEATS) {
    for (j in 1:nrow(expr)) {
        random_i <- sample(ncol(expr));
        bg_data[j,] <- expr[j,random_i]
        bg_weights[j,] <- weights[j,random_i]
    }

    bg = applyWeightedPCA(bg_data, bg_weights, comp)
    bg_vals[i,] = bg[[2]]
    permMats[[i]] <- bg[[1]]
    }

    mu <- as.matrix(apply(bg_vals, 2, mean))
    sigma <- as.matrix(apply(bg_vals, 2, biasedVectorSD))
    sigma[sigma==0] <- 1.0

    # Compute pvals from survival function & threshold components
    pvals <- 1 - pnorm((eval - mu) / sigma)
    thresholdComponent_i = which(pvals > p_threshold, arr.ind=TRUE)
    if (length(thresholdComponent_i) == 0) {
        thresholdComponent <- nrow(wPCA)
    } else {
        thresholdComponent <- thresholdComponent_i[[1]]
    }

    if (thresholdComponent < 5) {
    # Less than 5 components identified as significant.  Preserving top 5.
    thresholdComponent <- 5
    }

    wPCA <- wPCA[1:thresholdComponent, ]
    eval <- eval[1:thresholdComponent]
    evec = evec[1:thresholdComponent, ]

    permMats <- lapply(permMats, function(m) {m[1:thresholdComponent, ]})

    return(list(wPCA = wPCA, eval = eval, evec = evec, permuteMatrices = permMats))
}

#' Performs PCA on data
#' @importFrom  utils tail
#' @importFrom stats prcomp
#' @param exprData Expression data
#' @param N Number of components to retain. Default is 0
#' @param variance_proportion Retain top X PC's such that this much variance is retained; if N=0, then apply this method
#' @return Matrix containing N components for each sample.
applyPCA <- function(exprData, N=0, variance_proportion=1.0) {
    res <- prcomp(x=t(exprData), retx=TRUE, center=TRUE)

    if(N == 0) {
    total_var <- as.matrix(cumsum(res$sdev^2 / sum(res$sdev^2)))
    last_i <- tail(which(total_var <= variance_proportion), n=1)
    N <- last_i
    }
    return(list(t(res$x[,1:N])*-1, t(res$rotation)))
}

#' Performs ICA on data
#'
#' @importFrom fastICA fastICA
#' @param exprData Expression data, NUM_GENES x NUM_SAMPLES
#' @param BPPARAM the parallelization backend to use
#' @return Reduced data NUM_SAMPLES x NUM_COMPONENTS
applyICA <- function(exprData, BPPARAM=bpparam()) {

    ndataT <- t(exprData)
    res <- fastICA(ndataT, n.comp=2, maxit=100, tol=.00001, alg.typ="parallel", fun="logcosh", alpha=1,
                    method = "C", row.norm=FALSE, verbose=TRUE)

    res <- res$S
    rownames(res) <- colnames(exprData)

    return(res)
}

#' Performs Spectral Embedding  on data
#'
#' @param exprData Expression data, NUM_GENES x NUM_SAMPLES
#' @param BPPARAM the parallelization backend to use
#' @importFrom wordspace dist.matrix
#' @importFrom igraph graph_from_adjacency_matrix
#' @importFrom igraph embed_adjacency_matrix
#' @return Reduced data NUM_SAMPLES x NUM_COMPONENTS
applySpectralEmbedding <- function(exprData, BPPARAM = bpparam()) {


    adj <- as.matrix(dist.matrix(t(exprData)))
    adm <- graph_from_adjacency_matrix(adj, weighted=TRUE)
    res <- embed_adjacency_matrix(adm, 2)$X

    rownames(res) <- colnames(exprData)

    return(res)

}

#' Performs tSNE with perplexity 10 on data
#'
#' @importFrom Rtsne Rtsne
#'
#' @param exprData Expression data, NUM_GENES x NUM_SAMPLES
#' @param BPPARAM the parallelization backend to use
#'
#' @return Reduced data NUM_SAMPLES x NUM_COMPONENTS
applytSNE10 <- function(exprData, BPPARAM=bpparam()) {

    ndataT <- t(exprData)
    #res <- Rtsne.multicore(ndataT, dims=2, max_iter=600, perplexity=10.0,
    #     check_duplicates=FALSE, pca=FALSE, num_threads=BPPARAM$workers)
    res <- Rtsne(ndataT, dims=2, max_iter=800, perplexity=10.0,
                check_duplicates=FALSE, pca=FALSE)
    res <- res$Y
    rownames(res) <- colnames(exprData)
    return(res)

}

#' Performs tSNE with perplexity 30 on data
#'
#' @importFrom Rtsne Rtsne
#'
#' @param exprData Expression data, NUM_GENES x NUM_SAMPLES
#' @param BPPARAM the parallelization backend to use
#' @return Reduced data NUM_SAMPLES x NUM_COMPONENTS
applytSNE30 <- function(exprData, BPPARAM=bpparam()) {

    ndataT <- t(exprData)
    #res <- Rtsne.multicore(ndataT, dims=2, max_iter=600,
    # perplexity=30.0, check_duplicates=FALSE, pca=FALSE,
    #num_threads=BPPARAM$workers)
    res <- Rtsne(ndataT, dims=2, max_iter=800, perplexity=30.0,
                check_duplicates=FALSE, pca=FALSE)
    res <- res$Y

    rownames(res) <- colnames(exprData)

    return(res)
}

#' create a Knearest neighbor graph from the data
#'
#' @importFrom Matrix rowSums
#' @param exprData the data to base the KNN graph on
#' @param BPPARAM the parallelization backend to use for the computation
#'
#' @return the weghted adjacency matrix of the KNN graph
applyKNN <- function(exprData, BPPARAM=bpparam()) {

    k <- ball_tree_knn(t(exprData), round(sqrt(ncol(exprData))), BPPARAM$workers)
    nn <- k[[1]]
    d <- k[[2]]

    sigma <- apply(d, 1, max)

    sparse_weights <- exp(-1 * (d * d) / sigma^2)
    weights <- load_in_knn(nn, sparse_weights)

    weightsNormFactor <- rowSums(weights)
    weightsNormFactor[weightsNormFactor == 0] <- 1.0
    weightsNormFactor[is.na(weightsNormFactor)] <- 1.0
    weights <- weights / weightsNormFactor

    return(weights)
}

#' Performs ISOMap on data
#'
#' @importFrom RDRToolbox Isomap
#'
#' @param exprData Expression data, NUM_GENES x NUM_SAMPLES
#' @param BPPARAM the parallelization backend to use
#' @return Reduced data NUM_SAMPLES x NUM_COMPONENTS
applyISOMap <- function(exprData, BPPARAM=bpparam()) {

    res <- Isomap(t(exprData), dims=2)
    res <- res$dim2

    rownames(res) <- colnames(exprData)

    return(res)

}

#' Performs PCA on data that has been transformed with the Radial Basis Function.
#'
#' @importFrom stats sd
#' @param exprData Expression data, NUM_GENES x NUM_SAMPLES
#' @param BPPARAM the parallelization backend to use
#' @return Reduced data NUM_SAMPLES x NUM_COMPONENTS
applyRBFPCA <- function(exprData, BPPARAM=bpparam()) {

    distanceMatrix <- as.matrix(dist.matrix(t(exprData)))
    distanceMatrix <- log(distanceMatrix)
    point_mult(distanceMatrix, distanceMatrix)
    kMat <- as.matrix(exp(-1 * (distanceMatrix) / .33^2))
    diag(kMat) <- 0
    kMatNormFactor <- rowSums(kMat)
    kMatNormFactor[kMatNormFactor == 0] <- 1.0
    kMatNormFactor[is.na(kMatNormFactor)] <- 1.0
    kMat <- kMat / kMatNormFactor

    # Compute normalized matrix & covariance matrix
    kMat <- as.matrix(kMat, 1, function(x) (x - mean(x)) / sd(x))
    W <- tcrossprod(kMat)

    decomp <- rsvd::rsvd(W, k=2)
    evec <- decomp$u

    # project down using evec
    rbfpca <- crossprod(t(kMat), evec)
    rownames(rbfpca) <- colnames(exprData)

    return(rbfpca)

}


#' Alternative computation of distance matrix, based on matrix multiplication.
#'
#' @param X n x d matrix
#' @param Y m x d matrix
#' @return n x m distance matrix
sqdist <- function(X, Y) {

    aa = rowSums(X**2)
    bb = rowSums(Y**2)
    x = -2 * tcrossprod(X, Y)
    x = x + aa
    x = t(t(x) + bb)
    x[x<0] <- 0
    return(x)

}

#' Sets all values below a certain level in the data equal to 0
#'
#' @param x Data matrix
#' @param mi Minimum value
#' @return Data matrix with all values less than MI set to 0
clipBottom <- function(x, mi) {
    x[x < mi] <- mi
    return(x)
}
