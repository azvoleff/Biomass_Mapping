#!/usr/bin/Rscript
# Used to run a multiple regression to predict biomass from IKONOS 
# multispectral data.

require(tools) # for file_path_sans_ext
require(ggplot2)
require(raster)
require(rgdal) # Required to read/write ENVI format

NODATA_VALUE <- -9999

PLOT_WIDTH <- 8.33
PLOT_HEIGHT <- 5.53
DPI <- 300

#input_path <- "D:/Workspace/Biomass_Mapping/7_textures"
#output_path <- "D:/Workspace/Biomass_Mapping/8_corrected_layers_for_biomass_prediction"
#input_path <- "D:/Workspace/Biomass_Mapping/NDVI_Differencing"
#output_path <- "D:/Workspace/Biomass_Mapping/NDVI_Differencing"
input_path <- "D:/Workspace/Biomass_Mapping/6_vegetation_indices"
output_path <- "D:/Workspace/Biomass_Mapping/6_vegetation_indices_corrected"

invariant_regions_folder <- "D:/Workspace/Biomass_Mapping/Invariant_regions"
invariant_regions_name <- "invariant_regions"
invariant_regions <- readOGR(invariant_regions_folder, invariant_regions_name)

indep_prefixes <- file_path_sans_ext(list.files(input_path, pattern=".*2001.*[.]envi$"))
dep_prefixes <- file_path_sans_ext(list.files(input_path, pattern=".*2010.*[.]envi$"))
if (length(indep_prefixes) != length(dep_prefixes)) {
    stop("length of indep_prefixes does not match length of dep_prefixes")
}
for (n in 1:length(indep_prefixes)) {
    if (gsub("2001", "", indep_prefixes[n]) != gsub("2010", "", dep_prefixes[n])) {
        stop("error - indep_prefixes and dep_prefixes are not aligned")
    }
}

for (image_num in 1:length(indep_prefixes)) {
    indep_prefix <- indep_prefixes[image_num]
    dep_prefix <- dep_prefixes[image_num]
    print("************************************************")
    print(paste("*****Building prediction models", dep_prefix, "from", indep_prefix))

    indep_image <- brick(paste(input_path, "/", indep_prefix, '.envi', sep=""))
    dep_image <- brick(paste(input_path, "/", dep_prefix, '.envi', sep=""))

    load(paste("Data/", indep_prefix, "_invariant_pts.Rdata", sep=""))
    indep_pts <- invariant_pts
    load(paste("Data/", dep_prefix, "_invariant_pts.Rdata", sep=""))
    dep_pts <- invariant_pts

    lm_models <- list()
    for (band_num in 1:nlayers(indep_image)) {
        print(paste("Predicting layer", band_num, "of", dep_prefix, "from", indep_prefix))
        df <- cbind(indep_pts[band_num], dep_pts[band_num])
        names(df) <- c("indep_reflectance", "dep_reflectance")
        lm_model <- lm(dep_reflectance ~ indep_reflectance, data=df)
        lm_models <- c(lm_models, list(lm_model))
        print(summary(lm_model))
        qplot(indep_reflectance, dep_reflectance, data=df, xlab="2001 value", 
              ylab="2010 value")
        ggsave(paste("Data/", dep_prefix, "_VS_", indep_prefix, "_", band_num, ".png", 
                     sep=""), width=PLOT_WIDTH, height=PLOT_HEIGHT, 
               dpi=DPI)
        qplot(dep_reflectance, predict(lm_model), data=df, xlab="2010 observed", 
              ylab="2010 predicted")
        ggsave(paste("Data/", dep_prefix, "_VS_", indep_prefix, "_", band_num, "_PREDICTED.png", 
                     sep=""), width=PLOT_WIDTH, height=PLOT_HEIGHT, 
               dpi=DPI)
    }

    out_filenames <- c()
    print(paste("*****Correcting", dep_prefix, "from", indep_prefix))
    for (layer_num in 1:nlayers(dep_image)) {
        out <- raster(dep_image, layer=layer_num)
        out_filename <- paste(output_path, "/", dep_prefix, 
                              '_corr_to_2001_band', layer_num, '_TEMP.envi', sep="")
        out_filenames <- c(out_filenames, out_filename)
        out <- writeStart(out, out_filename)
        this_lm_model <- lm_models[[layer_num]]
        this_dep_layer <- raster(dep_image, layer=layer_num)
        pb <- txtProgressBar(style=3)
        bs <- blockSize(this_dep_layer)

        for (block_num in 1:bs$n) {
            setTxtProgressBar(pb, block_num/bs$n)
            this_block <- getValues(this_dep_layer, row=bs$row[block_num], 
                                    nrows=bs$nrows[block_num])
            valid_pos <- (this_block != NODATA_VALUE) & (!is.na(this_block))
            indep_df <- data.frame(indep_reflectance=this_block[valid_pos])
            # Make a vector of nodata of the full row length.
            this_block_predictions <- rep(NODATA_VALUE, length(this_block))
            # Now fill in the valid data positions with the predictions, leaving 
            # nodata_value in the remaining positions.
            # To make correction, first subtract the intercept
            predictions <- indep_df$indep_reflectance - this_lm_model$coefficients[1]
            # Now divide by the slope
            predictions <- predictions/this_lm_model$coefficients[2]
            this_block_predictions[valid_pos] <- predictions
            writeValues(out, this_block_predictions, bs$row[block_num])
        }
        close(pb)
        out <- writeStop(out)
    }
    out_stack <- stack(out_filenames)
    writeRaster(out_stack, paste(output_path, "/", dep_prefix, 
                                 '_corr_to_2001.envi', sep=""), format="ENVI")
    # Now delete the temporary individual band output files
    unlink(paste(file_path_sans_ext(out_filenames), ".*", sep=""))
}
