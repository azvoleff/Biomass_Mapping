library(raster)

input_path <- "G:/Data/Nepal/Imagery/Biomass_Mapping/3_IDRISI_AtmosC_COST_corrected_RSTs"
output_path <- "G:/Data/Nepal/Imagery/Biomass_Mapping/4_IDRISI_AtmosC_COST_corrected_Envi"

prefixes <- c("east_2001_bgrn_warp2pan_atmosc",
              "east_2001_pan_warp2pan_atmosc",
              "east_2010_bgrn_warp2pan_atmosc",
              "east_2010_pan_nnortho_atmosc")

for (prefix in prefixes) {
    print("********************************")
    print(paste("Processing", prefix))
    files <- sort(list.files(input_path, pattern=paste("^", prefix, "_[1-4].rst$", sep="")))
    print(paste("Adding", files))
    output_name <- paste(output_path, "/", prefix, ".envi", sep="")
    rst_raster <- stack(paste(input_path, files, sep="/"))
    writeRaster(rst_raster, output_name, format="ENVI")
}
