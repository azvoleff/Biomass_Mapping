COMPILE_OPT idl2, hidden

tic

input_folders = ["D:\Workspace\Biomass_Mapping\5_stacked", $
                 "D:\Workspace\Biomass_Mapping\6_vegetation_indices"]
output_path = "D:\Workspace\Biomass_Mapping\7_2_textures"


FOR input_folder_num=0L, (N_ELEMENTS(input_folders)-1) DO BEGIN
  input_folder = input_folders[input_folder_num]
  PRINT, "***********************************************"
  PRINT, "Processing images from " + input_folder
  
  input_folder_clock = TIC(input_folder)
  
  all_images = FILE_SEARCH(input_folder + PATH_SEP() + "*.envi")
  
  ENVI, /restore_base_save_files
  ENVI_BATCH_INIT
  
  FOR image_num=0L, (N_ELEMENTS(all_images)-1) DO BEGIN
    file = all_images[image_num]
    all_images_clock = TIC(file)
    
    PRINT, "Processing " + file
    
    ENVI_OPEN_FILE, file, R_FID=fid
    ENVI_FILE_QUERY, fid, DIMS=dims, NB=nb
    
    ; extract basename without extension
    file_extension = STREGEX(file, "[.][a-zA-Z0-9]*$", /EXTRACT)
      file_no_ext = FILE_BASENAME(file, file_extension)
      
    ; Calculate texture measures - note that kernel size (KX and KY) must be odd.
    ; If they are not ENVI will not give an error, but will not run.
    out_name = output_path + PATH_SEP() + file_no_ext + "_occurrence_texture.envi"
    method = LONARR(5) + 1
    ENVI_DOIT, 'TEXTURE_STATS_DOIT', FID=fid, POS=LINDGEN(nb), DIMS=dims, $
      METHOD=method, KX=5, KY=5, OUT_NAME=out_name, R_FID=r_fid
      
    toc, all_images_clock
    
  ENDFOR
  
  toc, input_folder_clock
  
ENDFOR

ENVI_BATCH_EXIT

toc

END