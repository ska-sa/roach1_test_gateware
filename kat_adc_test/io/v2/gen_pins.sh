#!/bin/bash

IFS=$'\n'

for i in `cat adc_pinout0.txt`; do
  NET=`echo $i | cut -d ' ' -f 1`
  ADCPIN=`echo $i | cut -d ' ' -f 2`
  ROACH_NET=`grep "$ADCPIN " fpga_mapping0.txt | cut -d ' ' -f 2`
  ENTRY=`grep $ROACH_NET roachucf.txt | sed -e 's/^NET.*LOC/LOC/g'`
  echo "NET \"$NET\" $ENTRY"
done

for i in `cat adc_pinout1.txt`; do
  NET=`echo $i | cut -d ' ' -f 1`
  ADCPIN=`echo $i | cut -d ' ' -f 2`
  ROACH_NET=`grep "$ADCPIN " fpga_mapping1.txt | cut -d ' ' -f 2`
  ENTRY=`grep $ROACH_NET roachucf.txt | sed -e 's/^NET.*LOC/LOC/g'`
  echo "NET \"$NET\" $ENTRY"
done
