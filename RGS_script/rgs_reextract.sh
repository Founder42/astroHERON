#!/bin/sh
#===================================================
version=1.0.0
author="Fangzheng Shi"
copyrights="All rights reserved. 2025-2035"
update=""
manual="RGS: Re-extract customized spectra and rmf files."
#=========================================
export SAS_CCFPATH=/Users/fangzheng42/Program/SAS/ccf

#obsid=("0110910201")
obsid=("0084030101" "0900170101")

for x in "${obsid[@]}"; do
    dir=/Volumes/Pegasus/LLAGN_archive/M104/XMM/$x
    cd ${dir}
    echo `pwd`
    export SAS_CCF=`pwd`/ccf.cif
    export SAS_ODF=`pwd`/`ls *SUM.SAS`

    # extract spectra
    rgsspectrum evlist=`ls *R1S*EVEN*` srclist=`ls *R1S*SRC*0000.FIT` order=1 source=3
    rgsspectrum evlist=`ls *R1S*EVEN*` srclist=`ls *R1S*SRC*0000.FIT` order=2 source=3
    rgsspectrum evlist=`ls *R2S*EVEN*` srclist=`ls *R2S*SRC*0000.FIT` order=1 source=3
    rgsspectrum evlist=`ls *R2S*EVEN*` srclist=`ls *R2S*SRC*0000.FIT` order=2 source=3

    # generate rmf files 
    rgsrmfgen evlist=`ls *R1S*EVEN*` srclist=`ls *R1S*SRC*0000.FIT` newrmf=yes spectrumset=`ls *R1S*SRSPEC1003.FIT`
    rgsrmfgen evlist=`ls *R1S*EVEN*` srclist=`ls *R1S*SRC*0000.FIT` newrmf=yes spectrumset=`ls *R1S*SRSPEC2003.FIT`
    rgsrmfgen evlist=`ls *R2S*EVEN*` srclist=`ls *R2S*SRC*0000.FIT` newrmf=yes spectrumset=`ls *R2S*SRSPEC1003.FIT`
    rgsrmfgen evlist=`ls *R2S*EVEN*` srclist=`ls *R2S*SRC*0000.FIT` newrmf=yes spectrumset=`ls *R2S*SRSPEC2003.FIT`

done