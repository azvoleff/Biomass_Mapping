library(raster)

input_path <- "G:/Data/Nepal/Imagery/Biomass_Mapping/1_coregistered"
output_path <- "G:/Data/Nepal/Imagery/Biomass_Mapping/2_IDRISI_AtmosC_input_RSTs"

dat_files <- list.files(input_path, pattern="*.envi$")

for (dat_file in dat_files) {
    dat_raster <- brick(paste(input_path, dat_file, sep="/"))
    writeRaster(dat_raster, paste(output_path, dat_file, sep="/"), 
                format="RST", bylayer=TRUE)
}
