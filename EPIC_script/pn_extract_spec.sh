#!/bin/sh
#===================================================
version=1.0.0
author="Fangzheng Shi"
copyrights="All rights reserved. 2025-2035"
update=""
manual="extract PN src/bkg spec and arf rmf files. You shall modify the src and bkg region array."
#=========================================
export SAS_CCFPATH=/Users/fangzheng42/Program/SAS/ccf

obsid=("0084030101" "0900170101")
# Please check and edit this array
srcreg=("circle(25524.328,23916.964,800)" "circle(24216.703,29320.896,800)")
bkgreg=("circle(23518.155,23029.618,628)" "circle(26516.336,30213.958,800)")

# Loop through the arrays
for i in "${!obsid[@]}"; do
    echo "Processing iteration $((i+1)): obsid=${obsid[$i]}"
    
    dir=/Volumes/Pegasus/LLAGN_archive/M104/XMM/${obsid[$i]}
    cd ${dir}
    echo `pwd`
    export SAS_CCF=`pwd`/ccf.cif
    export SAS_ODF=`pwd`/`ls *SUM.SAS`

    # extract source spectrum
    evselect table=pn_${obsid[$i]}_clean.fits withspectrumset=yes spectrumset=pn_${obsid[$i]}_src_spec.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=20479 expression='(FLAG==0) && (PATTERN<=4) && ((X,Y) IN '${srcreg[$i]}')'
    # extract background spectrum
    evselect table=pn_${obsid[$i]}_clean.fits withspectrumset=yes spectrumset=pn_${obsid[$i]}_bkg_spec.fits energycolumn=PI spectralbinsize=5 withspecranges=yes specchannelmin=0 specchannelmax=20479 expression='(FLAG==0) && (PATTERN<=4) && ((X,Y) IN '${bkgreg[$i]}')'
    # calculate backscal
    backscale spectrumset=pn_${obsid[$i]}_src_spec.fits badpixlocation=pn_${obsid[$i]}_clean.fits
    backscale spectrumset=pn_${obsid[$i]}_bkg_spec.fits badpixlocation=pn_${obsid[$i]}_clean.fits
    # generate rmf
    rmfgen spectrumset=pn_${obsid[$i]}_src_spec.fits rmfset=pn_${obsid[$i]}.rmf
    # generate arf
    arfgen spectrumset=pn_${obsid[$i]}_src_spec.fits arfset=pn_${obsid[$i]}.arf withrmfset=yes rmfset=pn_${obsid[$i]}.rmf badpixlocation=pn_${obsid[$i]}_clean.fits detmaptype=psf
done