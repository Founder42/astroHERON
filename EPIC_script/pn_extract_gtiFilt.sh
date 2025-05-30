#!/bin/sh
#===================================================
version=1.0.0
author="Fangzheng Shi"
copyrights="All rights reserved. 2024-2034"
update=""
manual="PN generate good time interval and filter flaring particle background. Attention: You shall manually check file *ImagingEvts.ds* and determine which one to use.
By executing this script, You should manually assign the threshold. i.e. './PN_extract_gtiFilt.sh 0.4'"
#=========================================
export SAS_CCFPATH=/Users/fangzheng42/Program/SAS/ccf

obsid=("0084030101" "0900170101")
# Please check and edit this array
evtid=("0376_0084030101_EPN_U003_ImagingEvts.ds" "4128_0900170101_EPN_U002_ImagingEvts.ds")

# Loop through the arrays
for i in "${!obsid[@]}"; do
    echo "Processing iteration $((i+1)): obsid=${obsid[$i]}, evtid=${evtid[$i]}"
    
    dir=/Volumes/Pegasus/LLAGN_archive/M104/XMM/${obsid[$i]}
    cd ${dir}
    echo `pwd`
    export SAS_CCF=`pwd`/ccf.cif
    export SAS_ODF=`pwd`/`ls *SUM.SAS`

    tabgtigen table=pn_lc_${obsid[$i]}.fits expression='(RATE<='$1')' gtiset=pn_gti_${obsid[$i]}.fits
    # Please manually edit this to match your selected event list
    evselect table=${evtid[$i]} withfilteredset=Y filteredset=pn_${obsid[$i]}_clean.fits destruct=Y keepfilteroutput=T expression='#XMMEA_EP && gti(pn_gti_'${obsid[$i]}'.fits,TIME) && (PI>150)'
done