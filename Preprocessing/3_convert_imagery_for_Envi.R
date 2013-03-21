library(raster)

input_path <- "D:/Workspace/Biomass_Mapping/3_IDRISI_AtmosC_COST_corrected_RSTs"
output_path <- "D:/Workspace/Biomass_Mapping/4_IDRISI_AtmosC_COST_corrected_Envi"

prefixes <- c("EAST_20011030_BGRN_RPCORTHO_WARP_ATMOSC",
              "EAST_20011030_PAN_RPCORTHO_WARP_ATMOSC",
              "EAST_20100304_BGRN_RPCORTHO_ATMOSC",
              "EAST_20100304_PAN_RPCORTHO_ATMOSC")

for (prefix in prefixes) {
    print("********************************")
    print(paste("Processing", prefix))
    files <- sort(list.files(input_path, pattern=paste("^", prefix, "_[1-4].rst$", sep="")))
    print(paste("Adding", files))
    output_name <- paste(output_path, "/", prefix, ".envi", sep="")
    rst_raster <- stack(paste(input_path, files, sep="/"))
    writeRaster(rst_raster, output_name, format="ENVI")
}
