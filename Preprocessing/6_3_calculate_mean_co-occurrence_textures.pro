COMPILE_OPT idl2, hidden

tic

input_folder = "D:\Workspace\Biomass_Mapping\7_1_raw_co-occurrence_textures"
output_path = "D:\Workspace\Biomass_Mapping\7_2_textures"

ENVI, /restore_base_save_files
ENVI_BATCH_INIT

all_images = FILE_SEARCH(input_folder + PATH_SEP() + "*co-occurrence_texture.envi")

FOR image_num=0L, (N_ELEMENTS(all_images)-1) DO BEGIN
  file = all_images[image_num]
  all_images_clock = TIC(file)
  
  PRINT, "Processing " + file
  
  ENVI_OPEN_FILE, file, R_FID=fid
  ENVI_FILE_QUERY, fid, DIMS=dims, NB=nb
  
  ; extract basename without extension
  file_extension = STREGEX(file, "[.][a-zA-Z0-9]*$", /EXTRACT)
    file_no_ext = FILE_BASENAME(file, file_extension)
    
  ; Calculate mean GLCM texture over a 5x5 (20x20m) window. Note that kernel
  ; size (KX and KY) must be odd. If they are not ENVI will not give an error,
  ; but will not run.
  out_name = output_path + PATH_SEP() + file_no_ext + "_mean.envi"
  method = LONARR(5)
  ; Only use method 0 (the mean) because all we want here is the mean GLCM
  ; texture in a 5x5 window.
  method[0] = 1
  ENVI_DOIT, 'TEXTURE_STATS_DOIT', FID=fid, POS=LINDGEN(nb), DIMS=dims, $
    METHOD=method, KX=5, KY=5, OUT_NAME=out_name, R_FID=r_fid
    
  toc, all_images_clock
  
ENDFOR

ENVI_BATCH_EXIT

toc

END