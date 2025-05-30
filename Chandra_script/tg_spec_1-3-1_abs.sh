#!/bin/sh
#===================================================
#tg_spec_1-1-2.sh
version=1.4.3
author="Fangzheng Shi"
copyrights="All rights reserved. 2017-2027"
update="Add custom modification to source and background extraction region; Add a flag to choose the extracted instrument.(19.09) Add custom modification to detsubsys in mkrmf(191021). This version can extract ph2 file with 1/-1 order together.(210520)"
manual="Please execute the script and give following 8 parameters in sequence: 1. ADDRESS of your working directory, 2.OBSID,  3./4. bottom and top edge of up bkg region (deg), 5./6. bottom and top edge of down bkg region (reg), 7.INST(HEG=0/MEG=1), 8. detsubsys(ACIS-S3)"
#=========================================

#evtname="459 2463 3456 3457 4430 5169 7364 7365 8375 9703 14455 17393 18421 19867 20709 21815"
dir=$1
#evtname=$2

cd ${dir}

if [ $7 = 0 ] # HEG
then
    punlearn tgextract
    pset tgextract infile="${dir}/$2/cal/evt2file_new.fits"
    pset tgextract outfile="${dir}/gspec/$2_acis_ph2_heg.fits"
    pset tgextract tg_order_list = "-1,1"
    #pset tgextract min_tg_d=$3
    #pset tgextract max_tg_d=$4
    pset tgextract min_upbkg_tg_d=$3
    pset tgextract max_upbkg_tg_d=$4
    pset tgextract min_downbkg_tg_d=$5
    pset tgextract max_downbkg_tg_d=$6
    pset tgextract tg_part_list=HEG
    pset tgextract clobber=yes
    #pset tgextract backscale_method="region"
    #pset tgextract error = gehrels
    #pset tgextract bin_units=keV
    pset tgextract mode=h
    tgextract

    punlearn mkgrmf
    pset mkgrmf order=-1
    pset mkgrmf grating_arm=HEG
    pset mkgrmf outfile="${dir}/gspec/$2_heg_m1.rmf"
    pset mkgrmf obsfile="${dir}/$2/cal/evt2file_new.fits[EVENTS]"
    pset mkgrmf regionfile="${dir}/gspec/$2_acis_ph2_heg.fits"
    pset mkgrmf detsubsys=$8
    pset mkgrmf wvgrid_arf=compute
    pset mkgrmf wvgrid_chan=compute
    pset mkgrmf clobber=yes
    pset mkgrmf mode=h
    mkgrmf

    punlearn mkgrmf
    pset mkgrmf order=1
    pset mkgrmf grating_arm=HEG
    pset mkgrmf outfile="${dir}/gspec/$2_heg_p1.rmf"
    pset mkgrmf obsfile="${dir}/$2/cal/evt2file_new.fits[EVENTS]"
    pset mkgrmf regionfile="${dir}/gspec/$2_acis_ph2_heg.fits"
    pset mkgrmf detsubsys=$8
    pset mkgrmf wvgrid_arf=compute
    pset mkgrmf wvgrid_chan=compute
    pset mkgrmf clobber=yes
    pset mkgrmf mode=h
    mkgrmf

    cd ${dir}/gspec
    punlearn fullgarf
    pset fullgarf phafile="${dir}/gspec/$2_acis_ph2_heg.fits"
    pset fullgarf pharow=1
    pset fullgarf evtfile="${dir}/$2/cal/evt2file_new.fits"
    pset fullgarf asol="${dir}/$2/cal/aspect_1.fits"
    pset fullgarf engrid="grid(${dir}/gspec/$2_heg_m1.rmf[cols ENERG_LO,ENERG_HI])"
    pset fullgarf badpix="${dir}/$2/cal/bpixfile_new.fits"
    pset fullgarf maskfile="${dir}/$2/cal/maskfile.fits"
    pset fullgarf dafile=CALDB
    pset fullgarf rootname="$2"
    pset fullgarf clobber=yes
    pset fullgarf mode=h
    fullgarf
   
    punlearn fullgarf
    pset fullgarf phafile="${dir}/gspec/$2_acis_ph2_heg.fits"
    pset fullgarf pharow=2
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
fi

if [ $7 = 1 ] # MEG
then
    punlearn tgextract
    pset tgextract infile="${dir}/$2/cal/evt2file_new.fits"
    pset tgextract outfile="${dir}/gspec/$2_acis_ph2_meg.fits"
    pset tgextract tg_order_list = "-1,1"
    #pset tgextract min_tg_d=$3
    #pset tgextract max_tg_d=$4
    pset tgextract min_upbkg_tg_d=$3
    pset tgextract max_upbkg_tg_d=$4
    pset tgextract min_downbkg_tg_d=$5
    pset tgextract max_downbkg_tg_d=$6
    pset tgextract tg_part_list=MEG
    #pset tgextract backscale_method="region"
    #pset tgextract error = gehrels
    pset tgextract clobber=yes
    #pset tgextract bin_units=keV
    pset tgextract mode=h
    tgextract
    
    punlearn mkgrmf
    pset mkgrmf order=1
    pset mkgrmf grating_arm=MEG
    pset mkgrmf outfile="${dir}/gspec/$2_meg_p1.rmf"
    pset mkgrmf obsfile="${dir}/$2/cal/evt2file_new.fits[EVENTS]"
    pset mkgrmf regionfile="${dir}/gspec/$2_acis_ph2_meg.fits"
    pset mkgrmf detsubsys=$8
    pset mkgrmf wvgrid_arf=compute
    pset mkgrmf wvgrid_chan=compute
    pset mkgrmf clobber=yes
    pset mkgrmf mode=h
    mkgrmf

    punlearn mkgrmf
    pset mkgrmf order=-1
    pset mkgrmf grating_arm=MEG
    pset mkgrmf outfile="${dir}/gspec/$2_meg_m1.rmf"
    pset mkgrmf obsfile="${dir}/$2/cal/evt2file_new.fits[EVENTS]"
    pset mkgrmf regionfile="${dir}/gspec/$2_acis_ph2_meg.fits"
    pset mkgrmf detsubsys=$8
    pset mkgrmf wvgrid_arf=compute
    pset mkgrmf wvgrid_chan=compute
    pset mkgrmf clobber=yes
    pset mkgrmf mode=h
    mkgrmf

    cd ${dir}/gspec
    punlearn fullgarf
    pset fullgarf phafile="${dir}/gspec/$2_acis_ph2_meg.fits"
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

    punlearn fullgarf
    pset fullgarf phafile="${dir}/gspec/$2_acis_ph2_meg.fits"
    pset fullgarf pharow=2
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
fi
