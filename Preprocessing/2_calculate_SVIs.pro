COMPILE_OPT idl2, hidden

TIC

input_folder = "D:\Workspace\Biomass_Mapping\5_stacked"
output_path = "D:\Workspace\Biomass_Mapping\6_vegetation_indices"

bgrn_images = FILE_SEARCH(input_folder + PATH_SEP() + $
  "EAST_*_BGRN_RPCORTHO*_ATMOSC.ENVI")
pan_images = FILE_SEARCH(input_folder + PATH_SEP() + $
  "EAST_*_PAN_RPCORTHO*_ATMOSC.ENVI")

ENVI, /restore_base_save_files
ENVI_BATCH_INIT

FOR i=0L, (N_ELEMENTS(bgrn_images)-1) DO BEGIN
  file = bgrn_images[i]
  bgrn_images_clock = TIC(file)
  print, "Processing " + file
  
  str_pos = STREGEX(file, "[0-9]{4}", length=len)
  year = STRMID(file, str_pos, len)
  
  ENVI_OPEN_FILE, file, R_FID=fid
  ENVI_FILE_QUERY, fid, DIMS=dims, NB=nb
  
  ; Calculate NDVI
  ndvi_out_name = output_path + PATH_SEP() + year + "_NDVI.envi"
  ndvi_exp = '(float(b4) - float(b3)) / (float(b4) + float(b3))'
  ENVI_DOIT, 'MATH_DOIT', FID=[fid, fid], POS=[2L, 3L], DIMS=dims, $
    EXP=ndvi_exp, OUT_NAME=ndvi_out_name, OUT_BNAME="NDVI", R_FID=ndvi_fid
  
;  ; Calculate EVI
;  evi_out_name = output_path + PATH_SEP() + year + "_EVI.envi"
;  evi_exp = '2.5*((float(b4) - float(b3)) / (float(b4) + 6.*float(b3) - 7.5*float(b1) + 1.))'
;  ENVI_DOIT,'MATH_DOIT', FID=[fid, fid, fid], POS=[0L, 2L, 3L], DIMS=dims, $
;    EXP=evi_exp, OUT_NAME=evi_out_name, OUT_BNAME="EVI", R_FID=evi_fid
  
  ; Calculate MSAVI2 - from Qi, Kerr, and Chehbouni (1994), "External factor
  ; consideration in vegetation index development"  
  msavi_out_name = output_path + PATH_SEP() + year + "_MSAVI.envi"
  msavi_exp = '(2.*float(B4) + 1 - sqrt((2.*float(B4) + 1.)^2. - 8.*(float(B4) - float(B3))))/2.'
  ENVI_DOIT,'MATH_DOIT', FID=[fid, fid], POS=[2L, 3L], DIMS=dims, $
    EXP=msavi_exp, OUT_NAME=msavi_out_name, OUT_BNAME="MSAVI", R_FID=msavi_fid
   
;   ; Calculate ARVI
;   arvi_out_name = output_path + PATH_SEP() + year + "_ARVI.envi"
;   arvi_exp = '(float(b4) - 2.*float(b3) - float(b1)) / (float(b4) + 2.*float(b3) - float(b1))'
;   ENVI_DOIT,'MATH_DOIT', FID=[fid, fid, fid], POS=[0L, 2L, 3L], DIMS=dims, $
;     EXP=arvi_exp, OUT_NAME=arvi_out_name, OUT_BNAME="ARVI", R_FID=arvi_fid
;   toc, bgrn_images_clock
   
ENDFOR

ENVI_BATCH_EXIT

TOC

END