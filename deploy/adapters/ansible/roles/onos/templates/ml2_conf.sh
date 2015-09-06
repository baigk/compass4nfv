cat <<EOT>> /etc/neutron/plugins/ml2/ml2_conf.ini
[ml2_onos]
password = admin
username = admin
url_path = http://{{ hostvars[groups['onos'][0]]['ansible_' + INTERNAL_INTERFACE].ipv4.address }}:8181/onos/vtn
EOT

