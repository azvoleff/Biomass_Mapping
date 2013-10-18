COMPILE_OPT idl2, hidden

TIC

input_folder = 'D:\Workspace\1_coregistered'
output_folder = 'D:\Workspace\2_radiance'

files = FILE_SEARCH(input_folder + PATH_SEP() + "*.dat")

; Cal coefs are for, in order, pan, blue, green, red, NIR
bgrn_cal_coefs = [728.0, 727.0, 949.0, 843.0]
bgrn_bandwidths = [71.3, 88.6, 65.8, 95.4]
; The below line will output the proper units for IDRISI AtmosC (mWcm-2sr-1µm-1)
;bgrn_gains = 10.0^3 / (bgrn_cal_coefs * bgrn_bandwidths)
; The below line will output radiance in (W/(m2 * µm * sr)). For ENVI FLAASH,
; set a scale factor of 10 within the FLAASH options.
bgrn_gains = 10.0^4 / (bgrn_cal_coefs * bgrn_bandwidths)
bgrn_offsets = [0, 0, 0, 0]

; Check that gain leaves image max value in the range of 20-30
; (for (mWcm-2sr-1µm-1). 2047 is the maximum value a 11 bit image can
; represent. See IDRISI AtmosC helpfile for details on why this check works.
; IDRISI AtmosC requires radiance images to be in mWcm-2sr-1µm-1.
;PRINT,2047 * bgrn_gains

pan_cal_coefs = [161.0]
pan_bandwidths = [403.0]
; Calibrate to radiance in units of mWcm-2sr-1µm-1
;pan_gains = 10.0^3 / (pan_cal_coefs * pan_bandwidths)
; The below line will output radiance in (W/(m2 * µm * sr)). For ENVI FLAASH,
; set a scale factor of 10 within the FLAASH options.
pan_gains = 10.0^4 / (pan_cal_coefs * pan_bandwidths)
pan_offsets = [0]

ENVI, /restore_base_save_files
ENVI_BATCH_INIT

FOR i=0L, (N_ELEMENTS(files)-1) DO BEGIN
  file = files[i]
  
  str_pos = STREGEX(file, "[0-9]{4}", length=len)
  year = STRMID(file, str_pos, len)
  
  str_pos = STREGEX(file, "_bgrn_", length=len)
  is_bgrn = STRMID(file, str_pos, len)
  IF is_bgrn EQ '_bgrn_' THEN BEGIN
    PRINT, "Processing bgrn file " + file
    gains = bgrn_gains
    offsets = bgrn_offsets
    radiance_out_name = output_folder + PATH_SEP() + year + "_bgrn_radiance.dat"
  ENDIF ELSE BEGIN
    PRINT, "Processing pan file " + file
    gains = pan_gains
    offsets = pan_offsets
    radiance_out_name = output_folder + PATH_SEP() + year + "_pan_radiance.dat"
  ENDELSE
  
  ENVI_OPEN_FILE, file, R_FID=fid
  ENVI_FILE_QUERY, fid, DIMS=dims, NB=nb
  pos = LINDGEN(nb)
  
  ENVI_DOIT, 'GAINOFF_DOIT', DIMS=dims, FID=fid, GAIN=gains, OFFSET=offsets, $
    OUT_DT=4, POS=pos, R_FID=temp_fid, /IN_MEMORY
  
  ; FLAASH requires BIL or BSP format
  ENVI_DOIT, 'CONVERT_DOIT', FID=temp_fid, DIMS=dims, POS=pos, R_FID=r_fid, $
    O_INTERLEAVE=1L, OUT_NAME=radiance_out_name
  
  ENVI_ASSIGN_HEADER_VALUE, FID=r_fid, KEYWORD='Sensor Type', VALUE='IKONOS'
  ENVI_ASSIGN_HEADER_VALUE, FID=r_fid, KEYWORD='Data Ignore Value', VALUE=0.0
  ENVI_ASSIGN_HEADER_VALUE, FID=r_fid, KEYWORD='wavelength units', $
    VALUE='Micrometers'
  IF is_bgrn EQ '_bgrn_' THEN BEGIN
    band_names = ['blue', 'green', 'red', 'nir']
    ENVI_ASSIGN_HEADER_VALUE, FID=r_fid, KEYWORD='band names', VALUE=band_names
    wavelengths = [0.480300, 0.550700, 0.664800, 0.805000]
    ENVI_ASSIGN_HEADER_VALUE, FID=r_fid, KEYWORD='wavelength', VALUE=wavelengths
    fwhm_values=[0.070000, 0.090000, 0.070000, 0.100000]
    ENVI_ASSIGN_HEADER_VALUE, FID=r_fid, KEYWORD='fwhm', VALUE=fwhm_values
  ENDIF ELSE BEGIN
    ENVI_ASSIGN_HEADER_VALUE, FID=r_fid, KEYWORD='band names', VALUE='pan'
    ENVI_ASSIGN_HEADER_VALUE, FID=r_fid, KEYWORD='wavelength', VALUE=.649
  ENDELSE
  ENVI_WRITE_FILE_HEADER, r_fid
  
ENDFOR

ENVI_BATCH_EXIT

TOC

END
