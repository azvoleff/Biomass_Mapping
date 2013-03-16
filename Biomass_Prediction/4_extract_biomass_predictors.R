#!/usr/bin/Rscript
# Used to run a multiple regression to predict biomass from IKONOS 
# multispectral data.

require(raster)
require(rgdal) # Required to read/write ENVI format

data_dir <- "G:/"
#data_dir <- "/media/Orange_Data/"

#theme_update(theme_grey(base_size=18))
theme_update(theme_grey(base_size=12))
update_geom_defaults("line", aes(size=1))

DPI <- 300
#WIDTH <- 8.33
#HEIGHT <- 5.53
WIDTH <- 6.5
HEIGHT <- 4

predictors <- brick(paste(data_dir, "Data/Imagery/IKONOS/Nepal_2010/Processed_Images/east_20100304_neuralnetpredictors_nnortho_warp2pan_specref_masked.bil", sep=""))

plots <- read.csv(file="processed_plot_results.csv")
# Throw out plots 1203 and 1203 as they fall almost in the Rapti (1202), and in 
# the CNP (1203), so they get zeros assigned for their texture measures as they 
# are outside the Barandabar Forest mask.
plots <- plots[!plots$ID.Plot==1202,]
plots <- plots[!plots$ID.Plot==1203,]

# Now convert plots to a SpatialPointsDataFrame
coords <- SpatialPoints(plots[,c("X", "Y")])
plots <- SpatialPointsDataFrame(coords, plots)
proj4string(plots) <- projection(predictors)


biomass_data <- data.frame(biomass=plots$biomass, extract(predictors, plots), row.names=plots$ID.Plot)
names(biomass_data) <- c("biomass", "mean_B1", "mean_B2", "mean_B3", "mean_B4", "mean_MSAVI", "std_MSAVI")

save(biomass_data, file="neural_net_predictors_5x5_textures.Rdata")
write.csv(biomass_data, file="neural_net_predictors_5x5_textures.csv")
