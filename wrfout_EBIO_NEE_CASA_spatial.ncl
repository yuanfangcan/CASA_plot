load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

begin
   month_abbr = (/"","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep", \
                    "Oct","Nov","Dec"/)
year = 2016
   months_si = (/   1,    32,   61,     92,    122,   153,   183,   214,   245,    275,   306,  336/)

 GEE = True 
 if (GEE) then 
  UTC_time =18
 else 
  UTC_time =6
;  UTC_time =18
 end if 
do idomain = 1,1  
;  files = systemfunc ("ls sib4_1x1_*.pft.nc ")
  files = systemfunc ("ls *GPP*"+year+"*nc4 ")
  filesR = systemfunc ("ls *RECO*"+year+"*nc4 ")
;layer = 7 ; around 250m 
layer = 0 
 do ifile =  0,  dimsizes(files)-1
  file_target = files(ifile) 
  f     = addfile(file_target+".nc","r")
  f2     = addfile(filesR(ifile)+".nc","r")
  fmap  = addfile("/oasis/scratch/comet/xhu2/temp_project/Run/CO2_and_otherGHG/WRFV3.9.1.1/wrfchem3.9.1.1_R2_CONUS_trac16_10mb_Hil3ReShrubRES_addOce_restoreDF_ODIAC_CT2017.2016010100/wrfinput_d01.nc","r") 
  time = f->time
  dims_eachMon = dimsizes(time)
 do itime = 0, dims_eachMon/8-1 
 if(GEE) then 
   data_to_plot =    f->Biogenic_GPP_Para01_3hr(itime*8+5,:,:) 
   data_to_plot2 =   f2->Biogenic_RECO_Para01_3hr(itime*8+5,:,:) 
   do imem = 2, 27
     if (imem.lt.10) then 
      varmember = "Biogenic_GPP_Para0"+imem+"_3hr"
      varmember2 = "Biogenic_RECO_Para0"+imem+"_3hr"
     else 
      varmember = "Biogenic_GPP_Para"+imem+"_3hr"
      varmember2 = "Biogenic_RECO_Para"+imem+"_3hr"
     end if 
      temp = f->$varmember$
     data_to_plot = (/data_to_plot + temp(itime*8+5,:,:)/)
     delete(temp)
      temp = f2->$varmember2$
     data_to_plot2 = (/data_to_plot2 + temp(itime*8+5,:,:)/)
     delete(temp)
   end do 
   data_to_plot =    (/(data_to_plot2-data_to_plot)/27/3.600/3./12*1e3/) ; convert from g C m-2 3hr-1 to micromoles C/m2/s 
;   printVarSummary(data_to_plot)
;  else
;   data_to_plot =    dim_sum_n_Wrap(f->resp_tot(UTC_time,:,:,:),0) 
  end if 
;   printVarSummary(data_to_plot)
  ifile_infigurename = months_si(ifile)-1+itime 
 if (GEE) then 
  figurename = "wrfout_d0"+idomain+"_CASA_NEE_"+ifile_infigurename
 else 
  figurename = "wrfout_d0"+idomain+"_CASA_RES"+UTC_time+"Z_"+ifile_infigurename
 end if 
   wks_type = "png"
   wks_type@wkWidth = 998
   wks_type@wkHeight = 998 
  wks = gsn_open_wks(wks_type ,figurename)           ; ps,pdf,x11,ncgm,eps
  gsn_define_colormap(wks,"BlAqGrYeOrReVi200") ; select color map
 cmap = gsn_retrieve_colormap(wks)
do icorlor = 2,4
 cmap(icorlor,:) = cmap(0,:)
end do
  gsn_define_colormap(wks,cmap) ; select color map
 if(GEE) then 
   gsn_reverse_colormap(wks)  
 end if 
      gsres               = True
      gsres@gsMarkerIndex = 16          ; circle at first
      gsres@gsMarkerThicknessF = 1
      gsres@gsMarkerSizeF = 0.005
      gsres@gsMarkerColor      = "black"
  tres       =  True
  tres@txFontHeightF = 0.025


  res                       = True             ; plot mods desired
  res@lbLabelFontHeightF = 0.018
  res@tmXBLabelFontHeightF = 0.018
  res@tmYLLabelFontHeightF = 0.018

  res@gsnFrame  = False
  res@gsnMaximize = True
  res@gsnPaperOrientation   = "portrait"
  res@gsnSpreadColors       = True             ; use full range of colormap
  res@cnFillOn              = True             ; color plot desired
  res@cnLinesOn             = False            ; turn off contour lines
  res@cnLineLabelsOn        = False            ; turn off contour labels
  res@cnLevelSelectionMode  = "ManualLevels"
  res@cnMaxLevelValF        = -2; + 380
  res@cnMinLevelValF       = -40 ; 2  +380
  res@cnLevelSpacingF   =   2.
 if(GEE) then 
 if (ifile_infigurename.gt.258.or.ifile_infigurename.lt.113) then
  res@cnMaxLevelValF        = -2; + 380
  res@cnMinLevelValF       = -24 ; 2  +380
  res@cnLevelSpacingF   =   2.
 else
  res@cnMaxLevelValF        = -2; + 380
  res@cnMinLevelValF       = -30 ; 2  +380
  res@cnLevelSpacingF   =   2.
 end if 
 else 
  res@cnMaxLevelValF        = 24; + 380
  res@cnMinLevelValF       = 2 ; 2  +380
  res@cnLevelSpacingF   =   2.
 end if 
;  res@cnLevelSelectionMode  = "AutomaticLevels"
;  res@lbLabelStride         =2 
  res@cnFillMode = "RasterFill"
  res@lbLabelAutoStride = True ; 

  res@tmYLLabelStride = 2
  res@tmXBLabelStride = 2

  WRF_map_c(fmap, res, 0)                   ; reads info from file
;  res@mpOutlineBoundarySets = "AllBoundaries"
  res@tfDoNDCOverlay       = False ; True     

  res@pmTickMarkDisplayMode = "Always"         ; turn on tickmarks
 res@tmXTOn = False            ; turn off top   labels 
 res@tmYROn = False            ; turn off right labels
 res@gsnLeftString     = "3-Hourly NEE 27member mean";data_to_plot@long_name 
 simname = "CASA"
 res@gsnRightString    = simname

  res@cnInfoLabelOn       = True

  res@lbTitleOn        =  True                ; turn on title
  res@lbTitleString    = "   ~C~  ~C~~V10~micromoles C/m2/s" ; +data_to_plot@units   ; "O~B~3, ~N~ppbv"             ; title string
  res@lbTitlePosition  = "Right"              ; title position
  res@lbTitleFontHeightF= .018                ; make title smaller
  res@lbTitleDirection = "Across"             ; title direction
;  res@lbTopMarginF = -0.3
  res@lbRightMarginF = 0.4
  res@lbTitleOffsetF = -0.004
  res@lbTitleJust = "CenterCenter"


  res@cnInfoLabelOrthogonalPosF = -0.00064
  res@cnInfoLabelString   = "Min= $ZMN$ Max= $ZMX$"
  res@lbLabelFontHeightF = 0.018
;  res@mpDataBaseVersion  = "Ncarg4_1"
;  res@mpDataSetName      = "Earth..4"
res@tmYRMajorOutwardLengthF = 0
res@tmYLMajorOutwardLengthF = 0
res@tmYLMinorOutwardLengthF = 0
res@tmXBMajorOutwardLengthF = 0
res@tmXBMinorOutwardLengthF = 0
res@tmYRLabelsOn = False
res@tmXTLabelsOn = False
res@tmXTOn = True
res@tmYROn = True
; CST_hr = mod(stringtoint(chartostring(Times_char(0,11:12)))-6+24, 24)
  utc_date = cd_calendar(f->time(itime*8+5),0);chartostring(fmap->Times) + " UTC "+ CST_hr+" CST"
   year   = tointeger(utc_date(:,0))    ; Convert to integer for
   month  = tointeger(utc_date(:,1))    ; use sprinti 
   day    = tointeger(utc_date(:,2))
   hour   = tointeger(utc_date(:,3))
   minutes= tointeger(utc_date(:,4))
 res@tiMainString =  sprinti("%0.2i", hour)+":"+sprinti("%0.2iZ ", minutes) + sprinti("%0.2i ", day) + \
              month_abbr(month) + " "  + sprinti("%0.4i", year) 
  print("working on " + res@tiMainString)
 res@mpGeophysicalLineThicknessF = 8.0
 res@mpGeophysicalLineColor = "Black"; (/22/)
 res@mpNationalLineThicknessF = 4.0
 res@mpNationalLineColor = res@mpGeophysicalLineColor
 res@mpUSStateLineThicknessF = 4.0
 res@mpUSStateLineColor = res@mpGeophysicalLineColor

;  plot                 = gsn_csm_vector_scalar_map(wks,u,v,x,res)
   data_to_plot_reorder = data_to_plot(lat|:,lon|: )
  plot                 = gsn_csm_contour_map(wks,data_to_plot_reorder ,res)
;  gsn_polymarker(wks,plot,-96.8,32.7833333,gsres)
;  gsn_text(wks,plot,"Dallas",-96.8,32.7833333+0.1,tres)
;  gsn_polymarker(wks,plot,-95.560913,30.722949,gsres)
;  gsn_text(wks,plot,"Huntsville",-95.560913,30.722949+0.1,tres)
;  gsn_polymarker(wks,plot,-97.6,35.40,gsres)
;  gsn_text(wks,plot,"OKC",-97.6,35.40-0.1,tres)
; 35.468762,-97.516304   location of PWIDS used in Ju2003, intersection of Park Ave and N Robinson Ave
;  gsn_polymarker(wks,plot,longitude_OKC,latitude,gsres)

;  gsn_polymarker(wks,plot,-95.90,36.20,gsres)
;  gsn_text(wks,plot,"Tulsa",-95.90,36.20-0.15,tres)
    gsres = True
     gsres@gsMarkerIndex = 12          ; circle at first
      gsres@gsMarkerThicknessF = 3
      gsres@gsMarkerSizeF = 0.015
      gsres@gsMarkerColor      = "red"
;             Lamont ,   dryden,  caltech,   park_falls,wBI
     latm = (/36.604  , 34.958  ,34.136   , 45.945,    41.7248/)
     lonm = (/-97.486 , -117.882,-118.127 ,-90.273,    -91.3529/)
  gsn_polymarker(wks,plot,lonm,latm,gsres)



  frame(wks)
;  system("mkdir -p /nsftor/xhu/public_html/WRF-UCM/FocusON_OKC/WRFV3.4.1/YSU/wrf"+simname+".2017012000/")
;  system("convert -density 300 -resize 1000x1000 -trim "+figurename+".eps /nsftor/xhu/public_html/WRF-UCM/FocusON_OKC/WRFV3.4.1/YSU/wrf"+simname+".2017012000/"+figurename+".png")
; system("rm "+figurename+".eps")
 print("finish plotting "+figurename+".eps")
  end do ; itime
  delete(time) ;  = f->time
 end do ; ifile
end do ; idomain 
end
