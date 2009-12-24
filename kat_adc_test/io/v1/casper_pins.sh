#!/bin/bash

for i in `cat casper_zdok_map`; do
  NUM=`echo $i | cut -d ',' -f 1`
  ADCPIN=`echo $i | cut -d ',' -f 2`
  ROACH_NET=`grep "$ADCPIN " katadc.ucf | cut -d ' ' -f 2`
  echo "\"$NUM\" $ADCPIN $ROACH_NET"
done
