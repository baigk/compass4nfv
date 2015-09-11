if [ -d "/var/local/osd" ]; then
rm -r /var/local/osd/*
umount /var/local/osd
rm -r /var/local/osd
fi

if [ ! -d "/ceph/images" ]; then
mkdir -p /ceph/images
fi

if [ ! -f "/ceph/images/ceph-volumes.img" ]; then 
dd if=/dev/zero of=/ceph/images/ceph-volumes.img bs=1M seek=10240 count=0 oflag=direct
sgdisk -g --clear /ceph/images/ceph-volumes.img
fi

if [ ! -L "/dev/ceph-volumes/ceph0" ]; then
vgcreate ceph-volumes $(sudo losetup --show -f /ceph/images/ceph-volumes.img)
sudo lvcreate -L9G -nceph0 ceph-volumes
mkfs.xfs -f /dev/ceph-volumes/ceph0
fi

if [ ! -d "/var/local/osd" ]; then
mkdir -p /var/local/osd
mount /dev/ceph-volumes/ceph0 /var/local/osd
fi

