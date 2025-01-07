#!/bin/bash -eux

echo "==> Creating awx management user"
USR=andrewsav
NAME=Andrew
GITHUB_USERNAME=AndrewSav
KEYS=$(curl -s "https://github.com/$GITHUB_USERNAME.keys")

if [[ $KEYS != ssh-rsa* ]]; then
  echo "Keys for github user $GITHUB_USERNAME are not found"
  exit -1
fi

useradd -m -c "$NAME" -s /bin/bash "$USR"
HOM=$(eval echo "~$USR")
mkdir -p "$HOM/.ssh"
chmod 700 "$HOM/.ssh"

tee "$HOM/.ssh/authorized_keys" >/dev/null <<.
$KEYS
.

chmod 600 "$HOM/.ssh/authorized_keys"
chown -R "$USR:$USR" "$HOM"
usermod -a -G adm,cdrom,sudo,dip,plugdev,docker "$USR"
echo "==> Created user $NAME"

cat > "/etc/sudoers.d/$USR" << EOF
$USR ALL=(ALL) NOPASSWD:ALL
EOF
