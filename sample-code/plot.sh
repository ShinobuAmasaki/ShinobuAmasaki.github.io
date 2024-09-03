#!/bin/bash
type gmt > /dev/null 2>&1
if [[ $? -eq 1 ]]; then
   type gmt6 > /dev/null 2>&1
   if [[ $? -eq 0 ]]; then 
      echo "command 'gmt6' found."
      shopt -s expand_aliases
      alias gmt='gmt6'
   else
      echo "gmt not found."
      exit 1
   fi
fi

NC='out.nc'
STEM='out'
range='0/1/0/1'

#dpi=100
GRAD_NC="$STEM.grd"
rm -rf ./GRAD_NC

gmt begin $STEM png
   echo "gmt: basemap"
   gmt basemap -JX8i -R$range -Bafg -BWeSn
   echo "gmt: makecpt"
   gmt makecpt -Cdrywet -T0/64/1
   echo "gmt: grdimage"

   gmt grdimage $NC -JX8i -R$range -C # -E$dpi -I$GRAD_NC
   gmt colorbar -Dg1.05/0+w4i/0.5 -Ba8f4
gmt end
