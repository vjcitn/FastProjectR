# Can use res$text(body) to set body of response
# Can use res$json(obj) to convert object to json
#  and return

# Options for 'serve_it'
# serve_it<-function(jug,
#    host="127.0.0.1",
#    port=8080,
#    daemonized=FALSE,
#    verbose=FALSE)

# ---------------
# Sample API BELOW
# ----------------

library(jug)
library(jsonlite)


if (class(arg1) == "FastProject") {
  fpout <- arg1
} else {
  fpout <- readRDS(arg1)
}

path <- find.package("FastProjectR")

setwd(path)

if (is.null(port)) {
    port <- sample(8000:9999, 1)
}
if (is.null(host)) {
    host <- "127.0.0.1"
}

url <- paste0("http://", host, ":", port, "/html_output/Results.html")
message(paste("Navigate to", url, "in a browser to interact with the app."))
browseURL(url)

# Launch the server
jug() %>%
  get("/Signature/Scores/(?<sig_name1>.*)", function(req, res, err) {
    sigMatrix <- fpout@sigMatrix
    name <- URLdecode(req$params$sig_name1)
    out <- "Signature does not exist!"
    if (name %in% colnames(sigMatrix)) {
      out <- FastProjectR:::sigScoresToJSON(sigMatrix[name])
    }
    return(out)
  }) %>%
  get("/Signature/ListPrecomputed", function(req, res, err){
    signatures <- fpout@sigData
    keys <- lapply(signatures, function(x) x@name)
    vals <- lapply(signatures, function(x) x@isPrecomputed)
    names(vals) <- keys
    out <- toJSON(vals, auto_unbox=TRUE)
    return(out)
  }) %>%
  get("/Signature/Info/(?<sig_name2>.*)", function(req, res, err){
    signatures <- fpout@sigData
    name <- URLdecode(req$params$sig_name2)
    out <- "Signature does not exist!"
    if (name %in% names(signatures)) {
      sig <- signatures[[name]]
      out <- FastProjectR:::signatureToJSON(sig)
    }
    return(out)
  }) %>%
  get("/Signature/Ranks/(?<sig_name3>.*)", function(req, res, err) {
    sigMatrix <- fpout@sigMatrix
    name <- URLdecode(req$params$sig_name3)
    out <- "Signature does not exist!"
    if (name %in% colnames(sigMatrix)) {
      out <- FastProjectR:::sigRanksToJSON(sigMatrix[name])
    }
    return(out)
  }) %>%
  get("/Signature/Expression/(?<sig_name4>.*)", function(req, res, err) {
    all_names = vapply(fpout@sigData, function(x){ return(x@name) }, "")
    name <- URLdecode(req$params$sig_name4)
    index = match(name, all_names)
    if(is.na(index)){
        out <- "Signature does not exist!"
    }
    else{
        sig = fpout@sigData[[index]]
        genes = names(sig@sigDict)
        expMat = fpout@exprData@data
        return(FastProjectR:::expressionToJSON(expMat, genes))
    }
    return(out)
  }) %>%
  get("/FilterGroup/(?<filter_group1>.*)/SigClusters/Normal", function(req, res, err) {
  	filter <- URLdecode(req$params$filter_group1)
  	if (filter == "1") {
  	  filter = 1
  	}
    cls <- fpout@filterModuleList[[filter]]@ProjectionData@sigClusters
    # cls <- fpout@sigClusters[[filter]]
    cls <- cls$Computed

    out <- toJSON(cls, auto_unbox=TRUE)
    return(out)
  }) %>%
  get("/FilterGroup/(?<filter_group2>.*)/SigClusters/Precomputed", function(req, res, err) {
    filter <- URLdecode(req$params$filter_group2)
    if (filter == "1") {
      filter = 1
    }
    cls <- fpout@filterModuleList[[filter]]@ProjectionData@sigClusters
    # cls <- fpout@sigClusters[[filter]]
    cls <- cls$Precomputed

    out <- toJSON(cls, auto_unbox=TRUE)
    return(out)
  }) %>%
  get("/FilterGroup/(?<filter_name1>.*)/(?<proj_name1>.*)/coordinates", function(req, res, err) {
    filter <- URLdecode(req$params$filter_name1)
    proj <- URLdecode(req$params$proj_name1)
    out <- FastProjectR:::coordinatesToJSON(fpout@filterModuleList[[filter]]@ProjectionData@projections[[proj]]@pData)
    return(out)
  }) %>%
  get("/FilterGroup/(?<filter_name2>.*)/SigProjMatrix/Normal", function(req, res, err) {
    filter <- URLdecode(req$params$filter_name2)

    signatures <- fpout@sigData
    keys <- vapply(signatures, function(x) x@name, "")
    vals <- vapply(signatures, function(x) x@isPrecomputed, TRUE)
	  sigs <- keys[!vals]
    out <- FastProjectR:::sigProjMatrixToJSON(fpout@filterModuleList[[filter]]@ProjectionData@sigProjMatrix, sigs)
    return(out)
  }) %>%
  get("/FilterGroup/(?<filter_name3>.*)/SigProjMatrix/Precomputed", function(req, res, err) {
    filter <- URLdecode(req$params$filter_name3)

    signatures <- fpout@sigData
    keys <- vapply(signatures, function(x) x@name, "")
    vals <- vapply(signatures, function(x) x@isPrecomputed, TRUE)
    sigs <- keys[!vals]
	  out <- FastProjectR:::sigProjMatrixToJSON(fpout@filterModuleList[[filter]]@ProjectionData@sigProjMatrix, sigs)
    return(out)
  }) %>%
  get("/FilterGroup/(?<filter_name4>.*)/SigProjMatrix_P/Normal", function(req, res, err) {
    filter <- URLdecode(req$params$filter_name4)

    signatures <- fpout@sigData
    keys <- vapply(signatures, function(x) x@name, "")
    vals <- vapply(signatures, function(x) x@isPrecomputed, TRUE)
    sigs <- keys[!vals]
	  out <- FastProjectR:::sigProjMatrixToJSON(fpout@filterModuleList[[filter]]@ProjectionData@pMatrix, sigs)
    return(out)
  }) %>%
  get("/FilterGroup/(?<filter_name5>.*)/SigProjMatrix_P/Precomputed", function(req, res, err) {
    filter <- URLdecode(req$params$filter_name5)

    signatures <- fpout@sigData
    keys <- vapply(signatures, function(x) x@name, "")
    vals <- vapply(signatures, function(x) x@isPrecomputed, TRUE)
    sigs <- keys[vals]
    
	  out <- FastProjectR:::sigProjMatrixToJSON(fpout@filterModuleList[[filter]]@ProjectionData@pMatrix, sigs)
    return(out)
  }) %>%
  get("/FilterGroup/(?<filter_name20>.*)/Tree/SigProjMatrix_P/Normal", function(req, res, err) {
    # projData <- fpout@projData
    filter <- URLdecode(req$params$filter_name20)

    signatures <- fpout@sigData
    keys <- vapply(signatures, function(x) x@name, "")
    vals <- vapply(signatures, function(x) x@isPrecomputed, TRUE)
    sigs <- keys[!vals]
	  out <- FastProjectR:::sigProjMatrixToJSON(fpout@filterModuleList[[filter]]@TreeProjectionData@pMatrix, sigs)
    return(out)
  }) %>%
  get("/FilterGroup/(?<filter_name21>.*)/Tree/SigProjMatrix_P/Precomputed", function(req, res, err) {
    # projData <- fpout@projData
    filter <- URLdecode(req$params$filter_name21)

    signatures <- fpout@sigData
    keys <- vapply(signatures, function(x) x@name, "")
    vals <- vapply(signatures, function(x) x@isPrecomputed, TRUE)
    sigs <- keys[vals]
	  out <- FastProjectR:::sigProjMatrixToJSON(fpout@filterModuleList[[filter]]@TreeProjectionData@pMatrix, sigs)
    # out <- sigProjMatrixPToJSON(projData[[filter]]@pMatrix, sigs)
    return(out)
  }) %>%
  get("/FilterGroup/(?<filter_name6>.*)/(?<proj_name2>.*)/clusters/(?<cluster_procedure>.*)/(?<param>.*)", function(req, res, err) {
    # projData <- fpout@projData

    filter <- URLdecode(req$params$filter_name6)
    proj <- URLdecode(req$params$proj_name2)
    method <- URLdecode(req$params$cluster_procedure)
    param <- as.numeric(URLdecode(req$params$param))

    clust <- FastProjectR:::cluster(fpout@filterModuleList[[filter]]@ProjectionData@projections[[proj]], method, param)
	  # clust = cluster(projData[[filter]]@projections[[proj]], method, param)
    out <- FastProjectR:::clusterToJSON(clust)
    return(out)
  }) %>%
  get("/FilterGroup/(?<filter_name7>.*)/genes", function(req, res, err) {
    # projData <- fpout@projData
    filter <- URLdecode(req$params$filter_name7)

    out <- toJSON(fpout@filterModuleList[[filter]]@genes)
    # out <- toJSON(projData[[filter]]@genes)

    return(out)
  }) %>%
  get("/FilterGroup/(?<filter_name8>.*)/Tree/List", function(req, res, err) {
    filter <- URLdecode(req$params$filter_name8)

    ## all Trees have the same adjacency matrix, so we can use the first one
    W <- fpout@filterModuleList[[filter]]@TreeProjectionData@projections[[1]]@adjMat

    return(toJSON(W))
  }) %>%
  get("/FilterGroup/(?<filter_name18>.*)/(?<proj_name3>.*)/Tree/Points", function(req, res, err) {
    proj <- URLdecode(req$params$proj_name3)
    filter <- URLdecode(req$params$filter_name18)

    C <- fpout@filterModuleList[[filter]]@TreeProjectionData@projections[[proj]]@vData

    return(toJSON(C))
  }) %>%
  get("/FilterGroup/(?<filter_name19>.*)/(?<proj_name4>.*)/Tree/Projection", function(req, res, err) {
    proj <- URLdecode(req$params$proj_name4)
    filter <- URLdecode(req$params$filter_name19)

    out <- FastProjectR:::coordinatesToJSON(fpout@filterModuleList[[filter]]@TreeProjectionData@projections[[proj]]@pData)

    return(out)
  }) %>%
  get("/FilterGroup/list", function(req, res, err) {
    filters <- vapply(fpout@filterModuleList, function(x) {
      return(x@filter)
    }, "")
    return(toJSON(filters))
  }) %>%
  get("/FilterGroup/(?<filter_name10>.*)/(?<pc_num1>.*)/Loadings/Positive", function(req, res, err) {
    filter <- URLdecode(req$params$filter_name10)
    pcnum <- as.numeric(URLdecode(req$params$pc_num1))

    l <- fpout@filterModuleList[[filter]]@PCAnnotatorData@loadings[,pcnum]

    posl <- l[l >= 0]
    sumposl <- sum(posl)
    nposl <- vapply(posl, function(x) x / sumposl, 1.0)

    nposl <- sort(nposl, decreasing=T)

    js1 <- toJSON(with(stack(nposl), tapply(values, ind, c, simplify=F)))

	  return(js1)

  }) %>%
  get("/FilterGroup/(?<filter_name16>.*)/(?<pc_num6>.*)/Loadings/Negative", function(req, res, err) {
  	filter <- URLdecode(req$params$filter_name16)
  	pcnum <- as.numeric(URLdecode(req$params$pc_num6))

  	l <- fpout@filterModuleList[[filter]]@PCAnnotatorData@loadings[,pcnum]

  	negl <- l[l < 0]
    sumneg1 <- sum(negl)
  	nnegl <- vapply(negl, function(x) x / sumneg1, 1.0)

  	nnegl <- sort(nnegl, decreasing=T)

  	js2 <- toJSON(with(stack(nnegl), tapply(values, ind, c, simplify=F)))

  	return(js2)

  }) %>%
  get("/FilterGroup/(?<filter_name12>.*)/(?<sig_name5>.*)/(?<pc_num2>.*)/Coordinates", function(req, res, err) {
    # projData <- fpout@projData
    filter <- URLdecode(req$params$filter_name12)
  	pcnum <- as.numeric(URLdecode(req$params$pc_num2))
  	signame <- URLdecode(req$params$sig_name5)

  	pc <- fpout@filterModuleList[[filter]]@PCAnnotatorData@fullPCA[pcnum,]
  	# pc <- projData[[filter]]@fullPCA[pcnum,]
  	ss <- fpout@sigMatrix[,signame]

  	ret <- cbind(pc, ss)
  	coord <- apply(unname(ret), 1, as.list)
  	names(coord) <- rownames(ret)

    return(toJSON(coord, force=T, auto_unbox=T))
  }) %>%
  get("/FilterGroup/(?<filter_name13>.*)/PCVersus/(?<pc_num3>.*)/(?<pc_num4>.*)", function(req, res, err) {
    # projData <- fpout@projData
    filter <- URLdecode(req$params$filter_name13)
  	pc1 <- as.numeric(URLdecode(req$params$pc_num3))
  	pc2 <- as.numeric(URLdecode(req$params$pc_num4))

  	pcdata1 <- fpout@filterModuleList[[filter]]@PCAnnotatorData@fullPCA[pc1,]
  	# pcdata1 <- projData[[filter]]@fullPCA[pc1,]
  	pcdata2 <- fpout@filterModuleList[[filter]]@PCAnnotatorData@fullPCA[pc2,]
  	# pcdata2 <- projData[[filter]]@fullPCA[pc2,]


  	ret <- cbind(pcdata1, pcdata2)
  	coord <- apply(unname(ret), 1, as.list)
  	names(coord) <- rownames(ret)

    return(toJSON(coord, force=T, auto_unbox=T))
  }) %>%
  get("/FilterGroup/(?<filter_name14>.*)/PearsonCorr/Normal", function(req, res, err) {
    # projData <- fpout@projData
	  filter <- URLdecode(req$params$filter_name14)

    signatures <- fpout@sigData
    keys <- vapply(signatures, function(x) x@name, "")
    vals <- vapply(signatures, function(x) x@isPrecomputed, TRUE)
    sigs <- keys[!vals]
	  pc <- fpout@filterModuleList[[filter]]@PCAnnotatorData@pearsonCorr
	  # pc <- projData[[filter]]@pearsonCorr

    return(FastProjectR:::pearsonCorrToJSON(pc, sigs))
  }) %>%
  get("/FilterGroup/(?<filter_name15>.*)/PearsonCorr/Precomputed", function(req, res, err) {
    # projData <- fpout@projData
	  filter <- URLdecode(req$params$filter_name15)

    signatures <- fpout@sigData
    keys <- vapply(signatures, function(x) x@name, "")
    vals <- vapply(signatures, function(x) x@isPrecomputed, TRUE)
    sigs <- keys[vals]
  	pc <- fpout@filterModuleList[[filter]]@PCAnnotatorData@pearsonCorr
  	# pc <- projData[[filter]]@pearsonCorr

  	return(FastProjectR:::pearsonCorrToJSON(pc, sigs))
  }) %>%
  get("/Expression", function(req, res, err) {
    return(FastProjectR:::expressionToJSON(fpout@exprData@data, matrix(NA)))
  }) %>%
  get("/FilterGroup/(?<filter_name17>.*)/Expression", function(req, res, err) {
    filter <- URLdecode(req$params$filter_name17)
    if (filter == "fano") {
      data <- fpout@exprData@fanoFilter
	  } else if (filter == "threshold") {
  	  data <- fpout@exprData@thresholdFilter
	  } else if (filter == "novar") {
  	  data <- fpout@exprData@noVar
	  } else {
			data <- fpout@exprData@data
	  }

	  genes <- rownames(data)

	  return(FastProjectR:::expressionToJSON(data, genes))

  }) %>%
  post("/Analysis/Run/", function(req, res, err) {
	subset <- fromJSON(req$body)
	subset <- subset[!is.na(subset)]
	allData <- fpout@allData

	if (length(fpout@pools) > 0) {
		clust <- fpout@pools[subset]
		subset <- unlist(clust)
	}

	nfp <- FastProjectR:::createNewFP(fpout, subset)
	FastProjectR:::newAnalysis(nfp)
	return()
  }) %>%
  get("/path2", function(req, res, err){
    return("Hello Mars!")
  }) %>%
  get("/person/(?<your_name1>.*)/eats/(?<your_food>.*)",
      function(req, res, err){
        name = URLdecode(req$params$your_name1)
        food = URLdecode(req$params$your_food)
        if ('howmany' %in% names(req$params)) {
          howmany = URLdecode(req$params$howmany)
          out = paste0(name, ' would like to eat ',
                       howmany, " ", food, "s!")
        }
        else{
          out = paste(name, 'likes to eat', food)
        }
        return(out)
      }) %>%
  get("/person/(?<your_name2>.*)", function(req, res, err){
    out = paste0("Hello ",
                 URLdecode(req$params$your_name2),
                 "!")
    return(out)
  }) %>%
  get("/genes", function(req, res, err){
    if ('number' %in% names(req$params)) {
      number = URLdecode(req$params$number)
      number = as.integer(number) # All params are string by default

      gene_list = c( "PPP2R1A", "CDK7", "SEM1",
                     "PSMF1", "PSMB10", "DNM2", "CEP63", "CDC25B",
                     "CDC25B", "CEP57", "RAB11A", "KHDRBS1", "RCC2",
                     "ARPP19", "MUS81", "BACH1", "PSMA7", "CDC25C",
                     "CDC25C", "PSMC5", "PLCB1", "PSMC1", "APP",
                     "WEE1", "PPP1CB", "CCNB2", "DYNC1H1", "DCTN1",
                     "PSMA6", "PBX1", "NAE1", "UBC", "UBC",
                     "UBC", "FOXN3", "CEP41", "TUBG1", "CDK4",
                     "HAUS6", "CDK6", "PSMA8", "CDK3", "WNT10B",
                     "WNT10B", "PSMC4", "CLASP1", "PSMD4", "PSMB11",
                     "KDM8", "ABCB1", "TICRR", "CENPJ", "SFI1",
                     "DYNLL1", "PPP2R2A", "CHEK2", "YWHAG", "PKIA",
                     "PSMD1", "PSMD7", "CDKN1A", "PHOX2B", "PSMB7",
                     "NEK2", "MNAT1", "CCNH", "PHLDA1", "ORAOV1",
                     "ATM", "SKP2", "CEP72")

      res$json(gene_list[1:number])

    }
    else{
      out = "ERROR!"
    }
    return(out)
  }) %>%
  serve_static_files("../html_output", root_path=setwd(path)) %>%
  simple_error_handler_json() %>%
  serve_it(host=host, port=port)
