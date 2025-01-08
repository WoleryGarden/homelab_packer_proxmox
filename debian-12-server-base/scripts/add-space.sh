#!/bin/bash

cat > /root/add-space.sh  << EOF
#!/bin/bash

set -e

echo 1 | sudo tee /sys/class/block/sda/device/rescan
sudo growpart /dev/sda 2
sudo growpart /dev/sda 5

echo "Resizing lvm phisical volume.."
sudo pvresize /dev/sda5

echo "Resizing lvm logical volume and filesystem.."
sudo lvextend -r -l+100%FREE /dev/debian-vg/root
EOF

chmod +x /root/add-space.sh

cat > /etc/profile.d/add-space.sh  << EOF
screen -fa -dmS add-space sudo bash /root/add-space.sh
EOF

chmod +x /etc/profile.d/add-space.sh
