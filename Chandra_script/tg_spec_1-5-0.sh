#!/bin/sh
#===================================================
#tg_spec_1-1-2.sh
version=1.5.0
author="Fangzheng Shi"
copyrights="All rights reserved. 2017-2027"
update="Add custom modification to source and background extraction region; Add a flag to choose the extracted instrument.(19.09) 
Add custom modification to detsubsys in mkrmf(191021). 
Replace tgextract with tgextract2 and change the binning_units to angstronm. 
Fix the bug and set parameter 'region_file = none' to validate the bkg up and down position. Add 'tgsplit' to change PHA type from II to I. Make some modification for naming system(191230)"
manual="Please execute the script and give following 9 parameters in sequence: 
1. ADDRESS of your working directory, 
2.OBSID,  
3./4. bottom and top edge of up bkg region (deg), 
5./6. bottom and top edge of down bkg region (reg), 
7.INST(HEG=0/MEG=1), 
8.order of grating(-1/1) in str 
9. detsubsys(ACIS-S3)
10. src_name"
#=========================================

#evtname="459 2463 3456 3457 4430 5169 7364 7365 8375 9703 14455 17393 18421 19867 20709 21815"
dir=$1
srcid=$10

cd ${dir}

if [ $7 = 0 ] # HEG
then
  if [ $8 = -1 ] #HEG_-1
  then
    punlearn tgextract2
    pset tgextract2 infile="${dir}/$2/cal/evt2file_new.fits"
    pset tgextract2 outfile="${dir}/gspec/$2_acis_ph2_heg_m1.fits"
    pset tgextract2 tg_order_list = "-1"
    #pset tgextract2 min_tg_d=$3
    #pset tgextract2 max_tg_d=$4
    pset tgextract2 region_file=none
    pset tgextract2 min_upbkg_tg_d=$3
    pset tgextract2 max_upbkg_tg_d=$4
    pset tgextract2 min_downbkg_tg_d=$5
    pset tgextract2 max_downbkg_tg_d=$6
    pset tgextract2 tg_part_list=HEG
    pset tgextract2 clobber=yes
    #pset tgextract2 error = gehrels
    #pset tgextract2 bin_units=keV
    pset tgextract2 mode=h
    tgextract2

    punlearn mkgrmf
    pset mkgrmf order=-1
    pset mkgrmf grating_arm=HEG
    pset mkgrmf outfile="${dir}/gspec/$2_heg_m1.rmf"
    pset mkgrmf obsfile="${dir}/$2/cal/evt2file_new.fits[EVENTS]"
    pset mkgrmf regionfile="${dir}/gspec/$2_acis_ph2_heg_m1.fits"
    pset mkgrmf detsubsys=$9
    pset mkgrmf wvgrid_arf=compute
    pset mkgrmf wvgrid_chan=compute
    pset mkgrmf clobber=yes
    pset mkgrmf mode=h
    mkgrmf

    cd ${dir}/gspec
    punlearn fullgarf
    pset fullgarf phafile="${dir}/gspec/$2_acis_ph2_heg_m1.fits"
    pset fullgarf pharow=1
    pset fullgarf evtfile="${dir}/$2/cal/evt2file_new.fits"
    pset fullgarf asol="${dir}/$2/cal/aspect_1.fits"
    pset fullgarf engrid="grid(${dir}/gspec/$2_heg_m1.rmf[cols ENERG_LO,ENERG_HI])"
    pset fullgarf badpix="${dir}/$2/cal/bpixfile_new.fits"
    pset fullgarf maskfile="${dir}/$2/cal/maskfile.fits"
    pset fullgarf dafile=CALDB
    pset fullgarf rootname=$2
    pset fullgarf clobber=yes
    pset fullgarf mode=h
    fullgarf

    punlearn tgsplit
    pset tgsplit infile="${dir}/gspec/$2_acis_ph2_heg_m1.fits"
    pset tgsplit arffile="${dir}/gspec/$2HEG_-1_garf.fits"
    pset tgsplit rmffile="${dir}/gspec/$2_heg_m1.rmf"
    pset tgsplit outroot="$2_${srcid}"
    pset tgsplit clobber=yes
    pset tgsplit mode=h
    tgsplit
  fi
 
  if [ $8 = 1 ] # HEG_1
  then
    punlearn tgextract2
    pset tgextract2 infile="${dir}/$2/cal/evt2file_new.fits"
    pset tgextract2 outfile="${dir}/gspec/$2_acis_ph2_heg_p1.fits"
    pset tgextract2 tg_order_list = "1"
    pset tgextract2 region_file=none
    #pset tgextract2 min_tg_d=$3
    #pset tgextract2 max_tg_d=$4
    pset tgextract2 min_upbkg_tg_d=$3
    pset tgextract2 max_upbkg_tg_d=$4
    pset tgextract2 min_downbkg_tg_d=$5
    pset tgextract2 max_downbkg_tg_d=$6
    pset tgextract2 tg_part_list=HEG
    #pset tgextract2 error = gehrels
    pset tgextract2 clobber=yes
    #pset tgextract2 bin_units=keV
    pset tgextract2 mode=h
    tgextract2

    punlearn mkgrmf
    pset mkgrmf order=1
    pset mkgrmf grating_arm=HEG
    pset mkgrmf outfile="${dir}/gspec/$2_heg_p1.rmf"
    pset mkgrmf obsfile="${dir}/$2/cal/evt2file_new.fits[EVENTS]"
    pset mkgrmf regionfile="${dir}/gspec/$2_acis_ph2_heg_p1.fits"
    pset mkgrmf detsubsys=$9
    pset mkgrmf wvgrid_arf=compute
    pset mkgrmf wvgrid_chan=compute
    pset mkgrmf clobber=yes
    pset mkgrmf mode=h
    mkgrmf

    cd ${dir}/gspec   
    punlearn fullgarf
    pset fullgarf phafile="${dir}/gspec/$2_acis_ph2_heg_p1.fits"
    pset fullgarf pharow=1
    pset fullgarf evtfile="${dir}/$2/cal/evt2file_new.fits"
    pset fullgarf asol="${dir}/$2/cal/aspect_1.fits"
    pset fullgarf engrid="grid(${dir}/gspec/$2_heg_p1.rmf[cols ENERG_LO,ENERG_HI])"
    pset fullgarf badpix="${dir}/$2/cal/bpixfile_new.fits"
    pset fullgarf maskfile="${dir}/$2/cal/maskfile.fits"
    pset fullgarf dafile=CALDB
    pset fullgarf rootname=$2
    pset fullgarf clobber=yes
    pset fullgarf mode=h
    fullgarf

    punlearn tgsplit
    pset tgsplit infile="${dir}/gspec/$2_acis_ph2_heg_p1.fits"
    pset tgsplit arffile="${dir}/gspec/$2HEG_1_garf.fits"
    pset tgsplit rmffile="${dir}/gspec/$2_heg_p1.rmf"
    pset tgsplit outroot="$2_${srcid}"
    pset tgsplit clobber=yes
    pset tgsplit mode=h
    tgsplit
  fi
fi

if [ $7 = 1 ] # MEG
then
  if [ $8 = 1 ] # MEG_1
  then
    punlearn tgextract2
    pset tgextract2 infile="${dir}/$2/cal/evt2file_new.fits"
    pset tgextract2 outfile="${dir}/gspec/$2_acis_ph2_meg_p1.fits"
    pset tgextract2 tg_order_list = "1"
    #pset tgextract2 min_tg_d=$3
    #pset tgextract2 max_tg_d=$4
    pset tgextract2 region_file=none
    pset tgextract2 min_upbkg_tg_d=$3
    pset tgextract2 max_upbkg_tg_d=$4
    pset tgextract2 min_downbkg_tg_d=$5
    pset tgextract2 max_downbkg_tg_d=$6
    pset tgextract2 tg_part_list=MEG
    #pset tgextract2 error = gehrels
    pset tgextract2 clobber=yes
    #pset tgextract2 bin_units=keV
    pset tgextract2 mode=h
    tgextract2
    
    punlearn mkgrmf
    pset mkgrmf order=1
    pset mkgrmf grating_arm=MEG
    pset mkgrmf outfile="${dir}/gspec/$2_meg_p1.rmf"
    pset mkgrmf obsfile="${dir}/$2/cal/evt2file_new.fits[EVENTS]"
    pset mkgrmf regionfile="${dir}/gspec/$2_acis_ph2_meg_p1.fits"
    pset mkgrmf detsubsys=$9
    pset mkgrmf wvgrid_arf=compute
    pset mkgrmf wvgrid_chan=compute
    pset mkgrmf clobber=yes
    pset mkgrmf mode=h
    mkgrmf

    cd ${dir}/gspec
    punlearn fullgarf
    pset fullgarf phafile="${dir}/gspec/$2_acis_ph2_meg_p1.fits"
    pset fullgarf pharow=1
    pset fullgarf evtfile="${dir}/$2/cal/evt2file_new.fits"
    pset fullgarf asol="${dir}/$2/cal/aspect_1.fits"
    pset fullgarf engrid="grid(${dir}/gspec/$2_meg_p1.rmf[cols ENERG_LO,ENERG_HI])"
    pset fullgarf badpix="${dir}/$2/cal/bpixfile_new.fits"
    pset fullgarf maskfile="${dir}/$2/cal/maskfile.fits"
    pset fullgarf dafile=CALDB
    pset fullgarf rootname=$2
    pset fullgarf clobber=yes
    pset fullgarf mode=h
    fullgarf

    punlearn tgsplit
    pset tgsplit infile="${dir}/gspec/$2_acis_ph2_meg_p1.fits"
    pset tgsplit arffile="${dir}/gspec/$2MEG_1_garf.fits"
    pset tgsplit rmffile="${dir}/gspec/$2_meg_p1.rmf"
    pset tgsplit outroot="$2_${srcid}"
    pset tgsplit clobber=yes
    pset tgsplit mode=h
    tgsplit
  fi

  if [ $8 = -1 ] # MEG_-1
  then
    punlearn tgextract2
    pset tgextract2 infile="${dir}/$2/cal/evt2file_new.fits"
    pset tgextract2 outfile="${dir}/gspec/$2_acis_ph2_meg_m1.fits"
    pset tgextract2 tg_order_list = "-1"
    pset tgextract2 region_file=none
    #pset tgextract2 min_tg_d=$3
    #pset tgextract2 max_tg_d=$4
    pset tgextract2 min_upbkg_tg_d=$3
    pset tgextract2 max_upbkg_tg_d=$4
    pset tgextract2 min_downbkg_tg_d=$5
    pset tgextract2 max_downbkg_tg_d=$6
    pset tgextract2 tg_part_list=MEG
    #pset tgextract2 error = gehrels
    pset tgextract2 clobber=yes
    #pset tgextract2 bin_units=keV
    pset tgextract2 mode=h
    tgextract2    

    punlearn mkgrmf
    pset mkgrmf order=-1
    pset mkgrmf grating_arm=MEG
    pset mkgrmf outfile="${dir}/gspec/$2_meg_m1.rmf"
    pset mkgrmf obsfile="${dir}/$2/cal/evt2file_new.fits[EVENTS]"
    pset mkgrmf regionfile="${dir}/gspec/$2_acis_ph2_meg_m1.fits"
    pset mkgrmf detsubsys=$9
    pset mkgrmf wvgrid_arf=compute
    pset mkgrmf wvgrid_chan=compute
    pset mkgrmf clobber=yes
    pset mkgrmf mode=h
    mkgrmf

    cd ${dir}/gspec
    punlearn fullgarf
    pset fullgarf phafile="${dir}/gspec/$2_acis_ph2_meg_m1.fits"
    pset fullgarf pharow=1
    pset fullgarf evtfile="${dir}/$2/cal/evt2file_new.fits"
    pset fullgarf asol="${dir}/$2/cal/aspect_1.fits"
    pset fullgarf engrid="grid(${dir}/gspec/$2_meg_m1.rmf[cols ENERG_LO,ENERG_HI])"
    pset fullgarf badpix="${dir}/$2/cal/bpixfile_new.fits"
    pset fullgarf maskfile="${dir}/$2/cal/maskfile.fits"
    pset fullgarf dafile=CALDB
    pset fullgarf rootname=$2
    pset fullgarf clobber=yes
    pset fullgarf mode=h
    fullgarf

    punlearn tgsplit
    pset tgsplit infile="${dir}/gspec/$2_acis_ph2_meg_m1.fits"
    pset tgsplit arffile="${dir}/gspec/$2MEG_-1_garf.fits"
    pset tgsplit rmffile="${dir}/gspec/$2_meg_m1.rmf"
    pset tgsplit outroot="$2_${srcid}"
    pset tgsplit clobber=yes
    pset tgsplit mode=h
    tgsplit
  fi
fi


