COMPILE_OPT idl2, hidden

TIC

input_folder = "D:\Biomass_Mapping\6_vegetation_indices"
output_path = "D:\Biomass_Mapping\7_textures"

all_images = FILE_SEARCH(input_folder + PATH_SEP() + "*.envi")
  
ENVI, /restore_base_save_files
ENVI_BATCH_INIT

FOR i=0L, (N_ELEMENTS(all_images)-1) DO BEGIN
  file = all_images[i]
  all_images_clock = TIC(file)
  
  PRINT, "Processing " + file
  
  ENVI_OPEN_FILE, file, R_FID=fid
  ENVI_FILE_QUERY, fid, DIMS=dims, NB=nb
  
  ; extract basename without extension
  file_extension = STREGEX(file, "[.][a-zA-Z0-9]*$", /EXTRACT)
  file_no_ext = FILE_BASENAME(file, file_extension)
  
  ; Calculate GLCM measures - note that kernel size (KX and KY) must be odd.
  ; If they are not ENVI will not give an error, but will not run.
  glcm_out_name = output_path + PATH_SEP() + file_no_ext + "_glcm.envi"
  method = LONARR(8) + 1
  direction = [1,1]
  g_levels = 64
  ENVI_DOIT, 'TEXTURE_COOCCUR_DOIT', FID=fid, POS=LINDGEN(nb), DIMS=dims, $
    METHOD=method, DIRECTION=direction, G_LEVELS=g_levels, KX=5, KY=5, $
    OUT_NAME=glcm_out_name, R_FID=glcm_fid
    
  TOC, all_images_clock
ENDFOR

ENVI_BATCH_EXIT

TOC

END
