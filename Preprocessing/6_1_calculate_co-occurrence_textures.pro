COMPILE_OPT idl2, hidden

tic

input_folders = ["D:\Workspace\Biomass_Mapping\5_stacked", $
                 "D:\Workspace\Biomass_Mapping\6_vegetation_indices"]
output_path = "D:\Workspace\Biomass_Mapping\7_1_raw_co-occurrence_textures"

ENVI, /restore_base_save_files
ENVI_BATCH_INIT

FOR input_folder_num=0L, (N_ELEMENTS(input_folders)-1) DO BEGIN
  input_folder = input_folders[input_folder_num]
  PRINT, "***********************************************"
  PRINT, "Processing images from " + input_folder
  
  input_folder_clock = TIC(input_folder)
  
  all_images = FILE_SEARCH(input_folder + PATH_SEP() + "*.envi")
  
  FOR image_num=0L, (N_ELEMENTS(all_images)-1) DO BEGIN
    file = all_images[image_num]
    all_images_clock = TIC(file)
    
    PRINT, "Processing " + file
    
    ENVI_OPEN_FILE, file, R_FID=fid
    ENVI_FILE_QUERY, fid, DIMS=dims, NB=nb
    
    ; extract basename without extension
    file_extension = STREGEX(file, "[.][a-zA-Z0-9]*$", /EXTRACT)
      file_no_ext = FILE_BASENAME(file, file_extension)
      
    ; Calculate GLCM measures - note that kernel size (KX and KY) must be odd.
    ; If they are not ENVI will not give an error, but will not run.
    glcm_out_name = output_path + PATH_SEP() + file_no_ext + "_co-occurrence_texture.envi"
    method = LONARR(8)
    ; Skip calculating the mean and variance (methods 0 and 1) as they are
    ; identical to the mean and variance calculated by ENVIs
    ; "TEXTURE_STATS_DOIT"
    method[2:7] = 1
    direction = [1, 1]
    g_levels = 64
    ENVI_DOIT, 'TEXTURE_COOCCUR_DOIT', FID=fid, POS=LINDGEN(nb), DIMS=dims, $
      METHOD=method, DIRECTION=direction, G_LEVELS=g_levels, KX=5, KY=5, $
      OUT_NAME=glcm_out_name, R_FID=glcm_fid
      
    toc, all_images_clock
  ENDFOR
  
  toc, input_folder_clock
  
ENDFOR

ENVI_BATCH_EXIT

toc

END