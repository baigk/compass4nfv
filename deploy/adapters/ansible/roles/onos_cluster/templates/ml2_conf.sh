cat <<EOT>> /etc/neutron/plugins/ml2/ml2_conf.ini
[ml2_onos]
password = admin
username = admin
url = http://{{ hostvars[inventory_hostname]['ansible_' + INTERNAL_INTERFACE].ipv4.address }}:8181/onos/vtn
EOT

