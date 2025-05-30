#!/bin/sh
#===================================================
#spec_extract_0order.sh
version=1.1.0
author="Fangzheng Shi"
copyrights="All rights reserved. 2025-2035"
update=""
manual="Please execute the script and give following N parameters in sequence: 1. ADDRESS of your working directory, 2.OBSID,  3. outfile name 3./4. bottom and top edge of up bkg region (deg), 5./6. bottom and top edge of down bkg region (reg), 7.INST(HEG=0/MEG=1), 8. detsubsys(ACIS-S3)"
#=========================================
wkdir=/Volumes/Pegasus/LLAGN_archive/M104/ACIS-S
obsid=("1586")

for x in "${obsid[@]}"; do
    dir=${wkdir}/$x/repro
    cd ${dir}
    x_str=$(printf "%05d" "$x")
    echo `pwd`
    punlearn specextract
    pset specextract infile="acisf${x_str}_repro_evt2.fits[sky=region(src_2arcsec.reg)]"
    pset specextract bkgfile="acisf${x_str}_repro_evt2.fits[sky=region(bkg_ciao.reg)]"
    pset specextract outroot=$x"_2arcsec"
    pset specextract correctpsf=yes
    pset specextract weight=no
    pset specextract grouptype=NONE
    pset specextract binspec=NONE
    pset specextract clobber=yes
    pset specextract mode=h
    specextract
done