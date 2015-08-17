#!/bin/bash
function mac_address_part() {
    hex_number=$(printf '%02x' $RANDOM)
    number_length=${#hex_number}
    number_start=$(expr $number_length - 2)
    echo ${hex_number:$number_start:2}
}

function mac_address() {
    echo "'00:00:$(mac_address_part):$(mac_address_part):$(mac_address_part):$(mac_address_part)'"
}

machines=''
for i in `seq $1`; do
  mac=$(mac_address)

  if [[ -z $machines ]]; then
    machines="${mac}"
  else
    machines="${machines} ${mac}"
  fi 
done
#echo ${machines}
echo "'00:00:2e:2f:22:3d' '00:00:75:57:dd:68' '00:00:20:d7:c3:2a' '00:00:9a:ba:40:62' '00:00:76:35:00:3a'"
