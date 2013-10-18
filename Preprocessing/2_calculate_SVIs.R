library(teamr)

input_folder <- "D:/Workspace/5_FLAASH_Corrected"
output_path <- "D:/Workspace/6_SVIs"

input_files <- list.files(input_folder)
bgrn_files <- input_files[grepl('_bgrn_reflect.dat$', input_files)]

for (bgrn_file in bgrn_files) {

}
