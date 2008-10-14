#!/bin/bash

cat $1 | sed -n -e '/Utilization by Hierarchy/,$ s/.*/&/p' | sed -e '1 d'| sed -n -e '/Utilization by Hierarchy/,$ s/.*/&/p' | sed -e '/^[^|]/ d' -e '/++/ d' -e 's/  *//g' -e 's/|/,/g' -e 's/^,//g' -e 's/+//' -e 's_[^,]*/__g'
