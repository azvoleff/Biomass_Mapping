#!/usr/bin/Rscript

require(tools) # for file_path_sans_ext
require(raster)
require(rgdal) # Required to read/write ENVI format

input_dir <- "D:/Biomass_Mapping/9_stacked_biomass_predictors/"
input_files <- list.files(input_dir, pattern=".*[.]envi")

plots <- read.csv(file="Data/processed_plot_results.csv")
# Throw out plots 1203 and 1203 as they fall almost in the Rapti (1202), 
# and in the CNP (1203), so they get zeros assigned for their texture 
# measures as they are outside the Barandabar Forest mask.
plots <- plots[!plots$ID.Plot==1201,]
plots <- plots[!plots$ID.Plot==1202,]
plots <- plots[!plots$ID.Plot==1203,]
# Now convert plots to a SpatialPointsDataFrame
coords <- SpatialPoints(plots[,c("X", "Y")])
plots <- SpatialPointsDataFrame(coords, plots)
proj4string(plots) <- "+proj=utm +zone=45 +ellps=WGS84 +units=m +no_defs"

for (file in input_files) {
    predictors <- brick(paste(input_dir, file, sep="/"))

    biomass_data <- data.frame(biomass=plots$biomass, PLOT_ID=plots$ID.Plot)

    image_data <- data.frame(extract(predictors, plots))

    # Setup names
    name_root <- file_path_sans_ext(file)
    if (grepl('texture_stats', name_root)) {
        name_root <- gsub('texture_stats', '', name_root)
        names(image_data) <- paste(name_root, c("range", "mean", "variance", "entropy", "skewness"), sep="")
    }
    biomass_data <- cbind(biomass_data, image_data)

    save(biomass_data, file=paste("Data/", file_path_sans_ext(file), "_predictors.Rdata", sep=""))
}
