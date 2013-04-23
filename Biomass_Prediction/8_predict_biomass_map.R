#!/usr/bin/Rscript
# Used to run a multiple regression to predict biomass from IKONOS 
# multispectral data.

require(ggplot2)
require(nnet)
require(raster)
require(snow)
require(rgdal) # Required to read/write ENVI format

NODATA_VALUE <- -1
data_dir <- "G:/"

theme_set(theme_grey(base_size=12))
update_geom_defaults("line", aes(size=1))
DPI <- 300
WIDTH <- 6.5
HEIGHT <- 4

load("backups/biomass_nnet_76.Rdata")

#predictors <- brick(paste(data_dir, "Data/Imagery/IKONOS/Nepal_2010/Processed_Images/east_20100304_neuralnetpredictors_nnortho_warp2pan_specref_masked.bil", sep=""))
predictors <- brick(paste(data_dir, "Data/Imagery/IKONOS/Nepal_2010/Processed_Images/east_20100304_neuralnetpredictors_nnortho_warp2pan_specref_masked_rescaled.bil", sep=""))

out <- raster(predictors)
out <- writeStart(out, paste(data_dir, "Data/Imagery/IKONOS/Nepal_2010/Processed_Images/east_20100304_PREDICTED_BIOMASS_20110801.bil", sep=""))

# Process over blocks (rather than row by row) to save processing time.
pb <- txtProgressBar(style=3)
bs <- blockSize(predictors)
for (block_num in 1:bs$n) {
    setTxtProgressBar(pb, block_num/bs$n)
    this_block <- getValues(predictors, row=bs$row[block_num], nrows=bs$nrows[block_num])
    # The next line works because in this case if data is missing in one band, 
    # it is missing in ALL the bands (since I masked them this way).
    valid_pos <- this_block[,1] != NODATA_VALUE
    valid_block_vals <- data.frame(this_block[valid_pos,])
    names(valid_block_vals) <- attr(best_nnet_fit$terms, "term.labels")

    # First make a vector of nodata of the full row length.
    this_block_predictions <- rep(NODATA_VALUE, nrow(this_block))
    # Now fill in the valid data positions with the predictions, leaving 
    # nodata_value in the remaining positions.
    predictions <- predict(best_nnet_fit, valid_block_vals)
    # Force predictions less than zero to be zero - can't have negative 
    # biomass.
    predictions[predictions < 0] <- 0
    this_block_predictions[valid_pos] <- predictions
    writeValues(out, this_block_predictions, bs$row[block_num])
}
out <- writeStop(out)
close(pb)
