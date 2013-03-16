; Layer stack the bgrn and pan files in memory (as two separate stacks) using
; the exclusive keyword to cut out areas from the images that overlap, and to
; ensure that image coordinates match between the two images. Then output them
; again as separate envi binary files.
COMPILE_OPT idl2, hidden

input_path = "M:\Data\Nepal\Imagery\Biomass_Mapping\4_IDRISI_AtmosC_COST_corrected_Envi"
output_path = "M:\Data\Nepal\Imagery\Biomass_Mapping\5_stacked"

ENVI, /restore_base_save_files
ENVI_BATCH_INIT

;envi_files = FILE_SEARCH(input_path + PATH_SEP() + "*_bgrn_*.envi")
envi_files = FILE_SEARCH(input_path + PATH_SEP() + "*_pan_*.envi")

fid = []
pos = []
dims = []
FOR file_num=0L,(N_ELEMENTS(envi_files)-1) DO BEGIN
  file = envi_files[file_num]
  ENVI_OPEN_FILE, file, R_FID=this_fid
  ENVI_FILE_QUERY, this_fid, DIMS=this_dims, NB=this_nb
  
  pos = [pos, LINDGEN(this_nb)]
  FOR i=0L,(this_nb-1) DO BEGIN
    fid = [fid, this_fid]
    dims = [[dims], [this_dims]]
  ENDFOR
ENDFOR

projection = ENVI_GET_PROJECTION(FID=this_fid, PIXEL_SIZE=out_ps)
out_dt=4
ENVI_DOIT, 'ENVI_LAYER_STACKING_DOIT', FID=fid, DIMS=dims, OUT_DT=out_dt, $
  INTERP=0, OUT_PS=out_ps, /IN_MEMORY, /EXCLUSIVE, OUT_PROJ=projection, $
  POS=pos, R_FID=layers_fid
ENVI_FILE_QUERY, layers_fid, DIMS=layers_dims, NB=layers_nb
print, layers_fid
print, layers_dims
print, layers_nb
  
; Now write the layer stack into two pieces - one for 2001, one for 2010
FOR file_num=0L,(N_ELEMENTS(envi_files)-1) DO BEGIN
  out_name = output_path + PATH_SEP() + FILE_BASENAME(envi_files[file_num])
  print,out_name
  ENVI_OPEN_FILE, file, R_FID=this_fid
  ENVI_FILE_QUERY, this_fid, DIMS=this_dims, NB=this_nb
  pos = LINDGEN(this_nb) + (this_nb) * file_num
  fid = MAKE_ARRAY(this_nb, 1, VALUE=layers_fid)
  ENVI_DOIT, 'CF_DOIT', FID=fid, DIMS=layers_dims, POS=pos, $
    OUT_NAME=out_name
ENDFOR

ENVI_BATCH_EXIT

END