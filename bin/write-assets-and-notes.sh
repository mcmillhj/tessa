#!/bin/bash

HOST=${HOST:-tessa1.hjm.im}
write_note=0

for i in $(seq 1 10000)
do
    asset_name="user_${i}"
    asset_uri="myorg:///users/user_${i}"
    curl -X POST http://$HOST/assets \
         -H 'Content-Type: application/json' \
         -d "{\"name\":\"$asset_name\",\"uri\":\"$asset_uri\"}" 2&>1 >/dev/null
  
   # every other asset created, create a note
   if [ $write_note -eq 1 ]; then 
  	curl -X POST http://$HOST/assets/$i/notes \
             -H 'Content-Type: application/json' \
	     -d "{\"note\":\"This is a NOTE for $asset_name\"}" 2&>1 >/dev/null
	write_note=0
   else 
	write_note=1
   fi
done
