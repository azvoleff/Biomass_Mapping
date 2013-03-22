#!/usr/bin/Rscript

require(tools) # for file_path_sans_ext
require(raster)
require(rgdal) # Required to read/write ENVI format

input_dir <- "D:/Biomass_Mapping/9_stacked_biomass_predictors/"
input_dir <- "D:/Biomass_Mapping/7_textures"
input_files <- list.files(input_dir, pattern=".*2010.*[.]envi$")

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
biomass_data <- data.frame(biomass=plots$biomass, PLOT_ID=plots$ID.Plot)


for (file in input_files) {
    predictors <- brick(paste(input_dir, file, sep="/"))

    image_data <- data.frame(extract(predictors, plots))

    # Setup names
    name_root <- file_path_sans_ext(file)
    if (grepl('texture_stats', name_root)) {
        name_root <- gsub('texture_stats', '', name_root)
        name_root <- paste("y", name_root, sep="")
        names(image_data) <- paste(name_root, c("range", "mean", "variance", "entropy", "skewness"), sep="")
    } else if (grepl('glcm', name_root)) {
        name_root <- gsub('glcm', '', name_root)
        name_root <- paste("y", name_root, "glcm_", sep="")
        names(image_data) <- paste(name_root, c("homogeneity", "contrast", "dissimilarity", "entropy", "secondmoment", "correlation"), sep="")
    }
    biomass_data <- cbind(biomass_data, image_data)
}
save(biomass_data, file="Data/biomass_and_predictors.Rdata")

# Make a table of correlations
# Note that the -2 below is to skip the plot ID column
cor_results <- round(cor(biomass_data[-2]), 4)
write.csv(cor_results, file="Data/biomass_and_predictors_cross_corr.csv")

cor_results <- cor_results[, 1]
cor_tests <- c(1) # biomass is perfectly correlated with itself.
# Start from 3 in below loop to skip the Plot ID and biomass columns
for (variable in biomass_data[3:length(biomass_data)]) {
    cor.signif <- cor.test(biomass_data$biomass, variable)$p.value
    cor_tests <- c(cor_tests, round(cor.signif,4))
}

corr <- data.frame(cbind(cor_results, cor_tests))
names(corr) <- c("r", "p")
corr <- corr[order(abs(corr$r), decreasing=TRUE), ]
write.csv(corr, file="Data/biomass_and_predictors_corr.csv")
