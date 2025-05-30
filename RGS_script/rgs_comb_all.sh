#!/bin/sh
#===================================================
#spec_extract_0order.sh
version=1.0.0
author="Fangzheng Shi"
copyrights="All rights reserved. 2024-2034"
update=""
manual="RGS combine all: move spec cross epochs together, then combine all. When use please follow by src name: like './rgs_comb_all.sh M83'"
#=========================================
#obsid=("0110910201")
obsid=("0084030101" "0900170101")

for x in "${obsid[@]}"; do
    dir=/Volumes/Pegasus/LLAGN_archive/M104/XMM/$x
    cd ${dir}
    echo `pwd`
    #export SAS_CCF=`pwd`/ccf.cif
    #export SAS_ODF=`pwd`/`ls *SUM.SAS`
    
    #src spec rgs1+rgs2 #bkg spec rgs1+rgs2
    cp `ls *R*S*SPEC1003*` /Volumes/Pegasus/LLAGN_archive/M104/XMM/comb_spec_try2
    #rsp mat rgs1+rgs2
    cp `ls *R*S*RSPMAT1003*` /Volumes/Pegasus/LLAGN_archive/M104/XMM/comb_spec_try2

done

cd /Volumes/Pegasus/LLAGN_archive/M104/XMM/comb_spec_try2
echo `pwd`

fsrc=$(ls *R*S*SRSPEC1003* | tr '\n' ' ')
fbkg=$(ls *R*S*BGSPEC1003* | tr '\n' ' ')
fmat=$(ls *R*S*RSPMAT1003* | tr '\n' ' ')

rgscombine pha="${fsrc% }" rmf="${fmat% }" bkg="${fbkg% }" filepha=$1"_o1_src.fits" filermf=$1"_o1.rmf" filebkg=$1"_o1_bkg.fits"
ftgrouppha infile=$1"_o1_src.fits" backfile=$1"_o1_bkg.fits" outfile=$1"_o1_opt.grp" grouptype=opt respfile=$1"_o1.rmf" clobber=yes