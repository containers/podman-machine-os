#!/usr/bin/env bash

set -xeo pipefail

# create a rootless user, needed to run the verification tests rootless
ROOTLESS_USER="${ROOTLESS_USER:-some${RANDOM}dude}"
rootless_uid=$((1500 + RANDOM % 5000))
ROOTLESS_UID=$rootless_uid
rootless_gid=$((1500 + RANDOM % 5000))
echo "creating $rootless_uid:$rootless_gid $ROOTLESS_USER user"
groupadd -g $rootless_gid $ROOTLESS_USER

# Adjust SUB_UID and SUB_GID ranges to support running rootless Podman inside a rootless run Podman container.
#
# By default, a new user is assigned the following sub-ID ranges:
#   SUB_UID_MIN=100000, SUB_GID_MIN=100000, SUB_UID_COUNT=65536, SUB_GID_COUNT=65536
# This means the user’s sub-UID and sub-GID ranges are 100000–165535.
#
# When the container is run rootless with the user defined below, ID mappings occur as follows:
# - Container ID 0 (root) maps to user ID 1000 on the host (which is the user created below).
# - Container IDs 1–65536 map to IDs 100000–165535 on host (the subid range previously mentioned).
#
# If a new user is created inside this container (to build containers for example), it will
# attempt to use the default sub-ID range (100000–165535). However, this exceeds the container’s
# available ID mapping, since only IDs up to 65536 are mapped. This causes nested rootless Podman
# to fail.
#
# To enable container-in-container builds, the sub-ID ranges for the user must be large enough
# to provide at least 65536 usable IDs. A minimum SUB_UID_COUNT and SUB_GID_COUNT of 165536 is
# required, but 200000 is used here to provide additional margin.
useradd -g $rootless_gid -u $rootless_uid --no-user-group --create-home $ROOTLESS_USER \
    --key SUB_GID_COUNT=200000 --key SUB_UID_COUNT=200000

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
