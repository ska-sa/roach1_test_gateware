#!/bin/bash

BMM_PROTOTYPE=$1

BMM_OUT=$2

BRAM_TAG=$3

NCD_FILE=$4

MLOW=$5

MHIGH=$6


if [ $# -ne 6 ] ; then
  echo usage gen_bmm.sh BMM_PROTOTYPE BMM_OUT BRAM_TAG NCD_FILE MLOW MHIGH
  exit -1
fi

XDL_CMD=xdl-9.2
XDL_TMP=foo.xdl
$XDL_CMD -ncd2xdl $NCD_FILE $XDL_TMP

#get the LOC of the tagged BRAM
LOC=`grep -m 1 $BRAM_TAG $XDL_TMP | cut -d ' ' -f 5|sed -e 's/RAMB36_//'`
rm $XDL_TMP

cat $BMM_PROTOTYPE | sed -e "s/MLOW/$MLOW/" -e "s/MHIGH/$MHIGH/" -e "s/BRAMLOC/PLACED = $LOC/g" -e "s/TAG/$BRAM_TAG/" > $BMM_OUT
