#!/usr/bin/Rscript
# Used to extract predictors for a linear regression to adjust 2001 imagery 
# biomass predictors to 2010 imagery, to account for phenological change.

require(tools) # for file_path_sans_ext
require(ggplot2)
require(raster)
require(rgdal) # Required to read/write ENVI format

#input_path <- "D:/Biomass_Mapping/7_2_textures"
input_path <- "D:/Workspace/Biomass_Mapping/NDVI_Differencing"

invariant_regions_folder <- "D:/Workspace/Biomass_Mapping/Invariant_regions"
invariant_regions_name <- "invariant_regions"
invariant_regions <- readOGR(invariant_regions_folder, invariant_regions_name)

prefixes <- file_path_sans_ext(list.files(input_path, pattern=".*(2001|2010).*[.]envi$"))

for (prefix in prefixes) {
    print("********************************")
    print(paste("Processing", prefix))
    invariant_pts <- list()
    pb <- txtProgressBar(style=3)
    layer_stack <- brick(paste(input_path, "/", prefix, '.envi', sep=""))
    for (layer_num in 1:nlayers(layer_stack)) {
        setTxtProgressBar(pb, layer_num/nlayers(layer_stack))
        this_raster <- raster(paste(input_path, "/", prefix, '.envi', sep=""), band=layer_num)
        invariant_pts <- c(invariant_pts, list(extract(this_raster, invariant_regions)))
    }
    invariant_pts <- data.frame(matrix(unlist(invariant_pts), ncol=nlayers(layer_stack), byrow=T))
    names(invariant_pts) <- names(layer_stack)
    save(invariant_pts, file=paste("Data/", prefix, "_invariant_pts.Rdata", sep=""))
}
close(pb)
