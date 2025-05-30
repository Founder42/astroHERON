#!/bin/sh
#=================================================
# ChaHETG_ppl.sh
version=1.0.0
author="Fangzheng Shi"
copyrights="All rights reserved. (2019-2029)"
introduction="This is a pipeline script for reprocessing Chandra HETG observation data."
manual="Please execute the script and give the following 11 paramters in sequence: 1.working folder ADDRESS where your data reside, 2.RA and 3.DEC of your target, 4.'1/0':whether do you need to make 'product' and 'gspec' folder, 5.OBSIDs to be reproccessed as a string, 6.REFID with the longest exposure observation, 7.source name and 8.-11.:4 0/1-flags controling REDUCE/SWITCH/ASTROM/REPROC."
example=" "
echo "Chandra HETG reprocessing pipeline. version: " $version 
#===============================================
./mulred47_1.e $1 $2 $3 $4 $5 $6 $8 $9 $10 $11
./tg_spec_1-0-1.sh $1 $5
./spec_comb.sh $1/gspec $7
