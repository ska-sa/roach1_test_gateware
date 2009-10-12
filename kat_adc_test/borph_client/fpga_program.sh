#!/bin/bash
(echo -e -n "?progdev\n?progdev kat_adc_test.bof\n"; sleep 6) | socat STDIO TCP:$1:7147
