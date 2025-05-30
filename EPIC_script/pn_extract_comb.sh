#!/bin/sh
#===================================================
#spec_extract_0order.sh
version=1.0.0
author="Fangzheng Shi"
copyrights="All rights reserved. 2024-2034"
update=""
manual="PN combine all: combine all. When use please follow by src name: like './rgs_comb_all.sh M83'"
#=========================================
cd /Users/fangzheng42/Documents/HUBS/M104/combine_spec/PN_spec
echo `pwd`

fsrc=$(ls *src*spec* | tr '\n' ' ')
fbkg=$(ls *bkg*spec* | tr '\n' ' ')
frmf=$(ls *.rmf | tr '\n' ' ')
farf=$(ls *.arf | tr '\n' ' ')

epicspeccombine pha="${fsrc% }" bkg="${fbkg% }" rmf="${frmf% }" arf="${farf% }" filepha=$1"_pn_src.pha" filebkg=$1"_pn_bkg.pha" filersp=$1"_pn.rmf"
ftgrouppha infile=$1"_pn_src.pha" backfile=$1"_pn_bkg.pha" outfile=$1"_pn_opt.grp" grouptype=opt respfile=$1"_pn.rmf" clobber=yes