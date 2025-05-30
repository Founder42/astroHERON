#!/bin/sh
#===================================================
#tg_spec_ada_1-2-0.sh
version=1.2.0
author="Fangzheng Shi"
copyrights="All rights reserved. 2017-2027"
update="Specify source and background extraction region by customed files(191024); Add a flag to choose the extracted instrument.(19.09) Add custom modification to detsubsys in mkrmf(191021). Use tgextract2 to replace tgextract2 2 and use angstrom as the bin unit.(191027). Use tgsplit to change Type II file into Type I file. Delete the input region parameter.(200107)"
manual="Please execute the script and give following 9 parameters in sequence: 1. ADDRESS of your working directory, 2.OBSID, 3.INST(HEG=0/MEG=1), 4.order of grating(-1/1) in str 5. detsubsys(ACIS-S3) 6.src_id"
#=========================================
#evtname="459 2463 3456 3457 4430 5169 7364 7365 8375 9703 14455 17393 18421 19867 20709 21815"
dir=$1
srcid=$6
#evtname=$2

cd ${dir}

if [ $3 = 0 ] # HEG
then
  if [ $4 = -1 ] #HEG_-1
  then
    punlearn tgextract2
    pset tgextract2 infile="${dir}/$2/cal/evt2file_new.fits"
    pset tgextract2 outfile="${dir}/gspec/$2_acis_ph2_heg_m1.fits"
    pset tgextract2 tg_order_list="-1"
    pset tgextract2 region_file="${dir}/$2/cal/$2_adareg.fits"
    #pset tgextract2 region_file=$3
    #pset tgextract2 min_tg_d=$3
    #pset tgextract2 max_tg_d=$4
    #pset tgextract2 min_upbkg_tg_d=$3
    #pset tgextract2 max_upbkg_tg_d=$4
    #pset tgextract2 min_downbkg_tg_d=$5
    #pset tgextract2 max_downbkg_tg_d=$6
    pset tgextract2 tg_part_list=HEG
    pset tgextract2 clobber=yes
    #pset tgextract2 bin_units=keV
    pset tgextract2 mode=h
    tgextract2

    punlearn mkgrmf
    pset mkgrmf order=-1
    pset mkgrmf grating_arm=HEG
    pset mkgrmf outfile="${dir}/gspec/$2_heg_m1.rmf"
    pset mkgrmf obsfile="${dir}/$2/cal/evt2file_new.fits[EVENTS]"
    pset mkgrmf regionfile="${dir}/gspec/$2_acis_ph2_heg_m1.fits"
    pset mkgrmf detsubsys=$5
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
 
  if [ $4 = 1 ] # HEG_1
  then
    punlearn tgextract2
    pset tgextract2 infile="${dir}/$2/cal/evt2file_new.fits"
    pset tgextract2 outfile="${dir}/gspec/$2_acis_ph2_heg_p1.fits"
    pset tgextract2 tg_order_list="1"
    #pset tgextract2 min_tg_d=$3
    #pset tgextract2 max_tg_d=$4
    pset tgextract2 region_file="${dir}/$2/cal/$2_adareg.fits"
    #pset tgextract2 min_upbkg_tg_d=$3
    #pset tgextract2 max_upbkg_tg_d=$4
    #pset tgextract2 min_downbkg_tg_d=$5
    #pset tgextract2 max_downbkg_tg_d=$6
    pset tgextract2 tg_part_list=HEG
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
    pset mkgrmf detsubsys=$5
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

if [ $3 = 1 ] # MEG
then
  if [ $4 = 1 ] # MEG_1
  then
    punlearn tgextract2
    pset tgextract2 infile="${dir}/$2/cal/evt2file_new.fits"
    pset tgextract2 outfile="${dir}/gspec/$2_acis_ph2_meg_p1.fits"
    pset tgextract2 tg_order_list = "1"
    #pset tgextract2 min_tg_d=$3
    #pset tgextract2 max_tg_d=$4
    pset tgextract2 region_file = "${dir}/$2/cal/$2_adareg.fits"
    #pset tgextract2 min_upbkg_tg_d=$3
    #pset tgextract2 max_upbkg_tg_d=$4
    #pset tgextract2 min_downbkg_tg_d=$5
    #pset tgextract2 max_downbkg_tg_d=$6
    pset tgextract2 tg_part_list=MEG
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
    pset mkgrmf detsubsys=$5
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

  if [ $4 = -1 ] # MEG_-1
  then
    punlearn tgextract2
    pset tgextract2 infile="${dir}/$2/cal/evt2file_new.fits"
    pset tgextract2 outfile="${dir}/gspec/$2_acis_ph2_meg_m1.fits"
    pset tgextract2 tg_order_list = "-1"
    #pset tgextract2 min_tg_d=$3
    #pset tgextract2 max_tg_d=$4
    pset tgextract2 region_file = "${dir}/$2/cal/$2_adareg.fits"
    #pset tgextract2 min_upbkg_tg_d=$3
    #pset tgextract2 max_upbkg_tg_d=$4
    #pset tgextract2 min_downbkg_tg_d=$5
    #pset tgextract2 max_downbkg_tg_d=$6
    pset tgextract2 tg_part_list=MEG
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
    pset mkgrmf detsubsys=$5
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
