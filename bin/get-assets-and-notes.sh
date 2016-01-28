#!/bin/bash

HOST=${HOST:-tessa1.hjm.im}

get_notes=0
for i in $(seq 1 10000)
do
    asset_name="user_${i}"
    asset_uri="myorg:///users/user_${i}"
    curl http://$HOST/assets 2&>1 >/dev/null
  
   # every other asset created, create a note
   if [ $get_notes -eq 1 ]; then 
  	curl http://$HOST/$i/notes 2&>1 >/dev/null
	get_notes=0
   else 
	get_notes=1
   fi
done
