# AutoManova.r v.02: AutoManova.r v.01 + select only the data range of pivottable

# Clipboard is assumed to contain a copy of an XL PivotTable
# with btw-sbj factor levels traversing rows and win-sbj factor levels traversing columns
# leading btw-sbj factor column must be iSbj (or equivalent)
# selection must include row, col, and data field areas, and exclude the page area
# If data is univariate (e.g. amplitude) the upper left cell of the selection (tDF[1,1], below)
# will contain the name of this data field.  If data is multivariate (e.g. real and imag),
# the data field must be nested below all other column fields; in this case the upper
# left cell of the selection will be empty, so we can use this information to determine
# data dimensionality.

rm(list=ls(all=TRUE))

tNDVFx <- 0 # optional number of trailing win-sbj factors, in addition to the last, to be expanded into DV
tNWFx <- 2 # the number of win-sbj factors, excluding those expanded into DV
tNBFx <- 0 # the number of btw-sbj factors

tDF <- read.table( if( .Platform$OS.type == "windows" ) "clipboard" else pipe("pbpaste"),F,"\t")

tNR <- dim(tDF)[1] # number of rows
tNC <- dim(tDF)[2] # number of columns
tNDimDV <- if (tDF[1,1] == "") 2 else 1 # number of dimensions of dependent variable (DV)
t1stDRow <- 1 + if ( tNWFx + tNDVFx == 0) 2 else ( tNWFx + tNDVFx + ( if (tNDimDV > 1) 2 else 1 ) ) # first data row
t1stDCol <- 2 + tNBFx # first data column

tY <- as.matrix( tDF[ t1stDRow:tNR, t1stDCol:tNC ] ) # the data
mode(tY)<-"numeric"

# BTW-SBJ FACTORS
if ( tNBFx == 0 ) {
	tBForm <- "tYC ~ 1"
} else {
	tBFxNmR <- t1stDRow - 1 # the btw-sbj factor name row
	# leading btw-sbj column is SbjID, so column range must be offset right by 1 to get btw-sbj factors
	tBFxNms <- as.character(t(tDF[ tBFxNmR, (1:tNBFx)+1 ])) # btw-sbj factor names
	tBFxDF <- vector("list",tNBFx) # create vector for btw-sbj factors
	for (i in 1:tNBFx ) {
		# We assume no special structure to btw-sbj factor levels so we must retrieve
		# exact contents of each btw-sbj factor level column
		tBFxDF [[i]] <- factor( as.character( tDF[ (tBFxNmR+1):tNR, i+1 ] ) ) # make each btw-sbj factor
	}
	names(tBFxDF)<-tBFxNms
	tBFxDF <- data.frame( tBFxDF ) # make it a data.frame for consistency with tWFxDF
	tBCList = rep( list("contr.helmert"), ncol(tBFxDF) ) # btw-sbj factor contrast list, to override default "contr.treatment"
	names( tBCList ) <- names(tBFxDF) # must have same names as btw-sbj factor data frame
	# here we can customize the btw-sbj contrasts; e.g., tBCList[["Dx"]] = "contr.poly"
	tBForm <- sprintf( "%s%s", "tYC ~ ", tBFxNms[1] ) # for at least 1 btw-sbj factor
	if( tNBFx > 1 )
		for (i in (2:tNBFx))
			tBForm <- sprintf( "%s * %s", tBForm , tBFxNms[i] ) # for additional btw-sbj factors
}
tBForm <- formula( tBForm )

# DEPENDENT VARIABLE CONTRAST MATRIX
tNDimDVC <- tNDimDV
if (tNDVFx > 0) {
	for ( i in (1:tNDVFx)+tNWFx+1) {
		tLevels = tDF[ i, t1stDCol:tNC ]
		tNDimDVC <- tNDimDVC * length( unique( t( tLevels [ 1, which( tLevels != "" ) ] ) ) )
	}
}
tDVC <- diag( tNDimDVC )

# WIN-SBJ INDEPENDENT VARIABLE FACTORS
if ( tNWFx == 0 ) {
	tWForm <- formula( "~ 1" ) # only the dependent variable, no win-sbj contrasts needed
} else {
	# WIN-SBJ FACTORS
	tiWFx <- (1:tNWFx)
	tWFx <- vector("list",tNWFx) # create vector for win-sbj factors
	# first row of tWHRs has the names of the win-sbj factors
	tWFxNms <- as.character( t( tDF[ 1, tiWFx + tNBFx + 1 ] ) ) # win-sbj factor names
	# actual range of win-sbj factor levels is offset one row below tWHRs
	for (i in tiWFx ) {
		# unique levels in each win-sbj factor level row may be sparse, repeated, or both,
		# so we get just the minimum list of levels, which we will expand below
		tLevels <- tDF[ i+1, t1stDCol:tNC ]
		tWFx[[i]] <- factor( unique( t( tLevels[ 1, which( tLevels != "" ) ] ) ) ) # make each win-sbj factor
	}
	tiWFx <- tiWFx[ tNWFx:1 ] # expand.grid nests columns from L-to-R, so we must reverse index order
	tWFxDF <- expand.grid( tWFx[tiWFx ])[tiWFx] # win-sbj factor data frame
	tiWFx <- tiWFx[ tNWFx:1 ] # back out expand.grid index reversal
	names(tWFxDF) <- tWFxNms
	tWCList = rep( list("contr.sum"), ncol(tWFxDF) ) # win-sbj factor contrast list, to override default "contr.treatment"
	# here we can customize the win-sbj contrasts; e.g., tWCList[["iBin"]] <- "contr.poly"
	# tWCList[2] <- "contr.poly" # needs debugging; seems to create appropriate contrast matrix, but it doesn't get applied to data
	names( tWCList ) <- tWFxNms # must have same names as btw-sbj factor data frame

	# WIN-SBJ FORMULA
	tWForm <-  sprintf( "~ %s", tWFxNms[ 1 ] ) # for at least 1 win-sbj factor
	if( tNWFx > 1 )
		for ( i in tiWFx[ -1 ] )
			tWForm <- sprintf( "%s * %s", tWForm, tWFxNms[ i ] ) # for additional win-sbj factors
	tWForm <- formula( tWForm )

	# WIN-SBJ MODEL MATRIX FOR CONTRASTS
	tWX <- model.matrix( tWForm, model.frame( tWForm, tWFxDF ), tWCList ) # tWCList overrides default contrasts
}

tWTerms <- terms.formula( formula( tWForm ) ) # object containing win-sbj terms from formula
tWTermLabels <- attr( tWTerms, "term.labels" )
tNWTerms <- length( tWTermLabels )
tIsWIntercept <- attr( tWTerms, "intercept" ) == 1 # intercept term is included in formula
tWTermStart <- if (tIsWIntercept) 0 else 1 # start index for the analysis loop depends on inclusion of intercept term
tIsFirstTerm <- TRUE # term loop flag to create (on first pass) or append to (on subsequent passes) tResultsTable
for ( iT in tWTermStart:tNWTerms  ) { # for each win-sbj IV term
	# if needed, create the win-sbj contrast matrix, attr(tWX,"assign") maps term indices to the columns of tWX
	tWC <- if ( tNWFx == 0 ) 1 else tWX[, attr(tWX,"assign") == iT ] # win-sbj IV contrast, 1 if only DV
	tWC <- tWC %x% tDVC # kronecker product of this term's contrast matrix with the DV contrast matrix
	tYC <- tY %*% tWC # apply win-sbj contrast to data
	if ( ncol( tYC ) > 1 ) { # Mulitvariate DV needs manova
		tManova <- if ( tNBFx == 0 ) manova( tBForm ) else manova( tBForm, tBFxDF, contrasts=tBCList ) # tBCList overrides default contrasts
		tResults <- data.frame(summary( tManova, "Wilks", T )$stats) # a matrix
		tResults <- tResults[ -nrow(tResults), -(1:2) ] # skip last row ("Residuals") and first column ("Df")
		rownames( tResults ) <- paste( if (iT==0) "(Intercept)" else tWTermLabels[ iT ], ":", rownames( tResults ), sep="" )
		tFirstRow <- TRUE
		for (iR in 1:nrow(tResults)) {
			tFV <- round( tResults[iR,1], 2 )
			tRP <- round( tResults[iR,4], 3 )
			tPStr <- if (tRP>0) sprintf( ", p=%.3f", tRP ) else ", p<0.001"
			tSummStr <- sprintf( "F(%d,%d)=%.2f%s", tResults[iR,2], tResults[iR,3], tFV, tPStr )
			tSummCol <- if (tFirstRow ) tSummStr else rbind( tSummCol, tSummStr )
			tFirstRow <- FALSE
		}
	} else { # univariate DV needs anova (aov)
		tAnova <- if ( tNBFx == 0 ) aov( tBForm ) else aov( tBForm, tBFxDF, contrasts=tBCList ) # tBCList overrides default contrasts
		tResults <- data.frame( summary( tAnova, intercept=T )[[1]] ) # a data frame
		tNResultRows = nrow( tResults )
		tDOF = tResults[ tNResultRows, 1 ]
		tResults <- tResults[ -tNResultRows, ] # skip last row ("Residuals")
		tResults[,2] <- tDOF
		tResults <- tResults[,c(4,1,2,5)]
		rownames( tResults ) <- paste( if (iT==0) "(Intercept)" else tWTermLabels[ iT ], ":", rownames( tResults ), sep="" )
		tFirstRow <- TRUE
		for (iR in 1:nrow(tResults)) {
			tFV = round( tResults[iR,1], 2 )
			tRP = round( tResults[iR,4], 3 )
			tPStr = if (tRP>0) sprintf( ", p=%.3f", tRP ) else ", p<0.001"
			tSummStr = sprintf( "F(%d,%d)=%.2f%s", tResults[iR,2], tResults[iR,3], tFV, tPStr )
			tSummCol = if (tFirstRow ) tSummStr else rbind( tSummCol, tSummStr )
			tFirstRow = FALSE
		}
	}
	tResultsAndSummary <- cbind( tResults, Summary=tSummCol )
	colnames( tResultsAndSummary ) <- c( "F Val", "NDoF", "DDoF", "P(>F)", "Summary" )
	tResultsTable <- if (tIsFirstTerm) tResultsAndSummary else rbind( tResultsTable, tResultsAndSummary  ) # create/append to results table
	tIsFirstTerm <- FALSE

}
tRTNC = ncol(tResultsTable) # Results Table number of columns
tResultsTable = tResultsTable[,c(tRTNC, 1:(tRTNC-1))]
print( tResultsTable )
write.table( tResultsTable, if( .Platform$OS.type == "windows" ) "clipboard" else pipe("pbcopy"), sep="\t" )









