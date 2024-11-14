#!/usr/bin/env bash

set -xeo pipefail

# install extra dependencies.
# TODO: Do we need to move them into the image build process?
dnf install -y osbuild osbuild-tools osbuild-ostree jq xfsprogs e2fsprogs podman podman-machine podman-remote gvisor-tap-vsock

# Build process must run with selinux disabled?!
setenforce 0

# create a rootless user, needed to run the verification tests rootless
ROOTLESS_USER="${ROOTLESS_USER:-some${RANDOM}dude}"
rootless_uid=$((1500 + RANDOM % 5000))
ROOTLESS_UID=$rootless_uid
rootless_gid=$((1500 + RANDOM % 5000))
echo "creating $rootless_uid:$rootless_gid $ROOTLESS_USER user"
groupadd -g $rootless_gid $ROOTLESS_USER
useradd -g $rootless_gid -u $rootless_uid --no-user-group --create-home $ROOTLESS_USER


# setup ssh access to the user
mkdir -p "$HOME/.ssh" "/home/$ROOTLESS_USER/.ssh"
echo "Creating ssh key pairs"
[[ -r "$HOME/.ssh/id_rsa" ]] || \
    ssh-keygen -t rsa -P "" -f "$HOME/.ssh/id_rsa"
ssh-keygen -t ed25519 -P "" -f "/home/$ROOTLESS_USER/.ssh/id_ed25519"
ssh-keygen -t rsa -P "" -f "/home/$ROOTLESS_USER/.ssh/id_rsa"

echo "Set up authorized_keys"
cat $HOME/.ssh/*.pub /home/$ROOTLESS_USER/.ssh/*.pub >> $HOME/.ssh/authorized_keys
cat $HOME/.ssh/*.pub /home/$ROOTLESS_USER/.ssh/*.pub >> /home/$ROOTLESS_USER/.ssh/authorized_keys

echo "Configure ssh file permissions"
chmod -R 700 "$HOME/.ssh"
chmod -R 700 "/home/$ROOTLESS_USER/.ssh"
chown -R $ROOTLESS_USER:$ROOTLESS_USER "/home/$ROOTLESS_USER/.ssh"

# chown current working dir to rootless user
chown -R $ROOTLESS_USER:$ROOTLESS_USER .

ssh-keyscan localhost > /root/.ssh/known_hosts
# Maintain access-permission consistency with all other .ssh files.
install -Z -m 700 -o $ROOTLESS_USER -g $ROOTLESS_USER \
    /root/.ssh/known_hosts /home/$ROOTLESS_USER/.ssh/known_hosts

# Make all future CI scripts aware of these values
echo "ROOTLESS_USER=$ROOTLESS_USER" >> /etc/ci_environment
echo "ROOTLESS_UID=$ROOTLESS_UID" >> /etc/ci_environment
