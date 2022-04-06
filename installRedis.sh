#! /bin/bash
TEST_FILE=/opt/redislabs/bin/rladmin

sudo -i
if [ ! -f "$TEST_FILE"]; then
    echo 'Updating packages'
    apt update
    apt upgrade -y
    echo 'Switching swap off'
    swapoff -a
    sed -i.bak '/ swap / s/^(.*)$/#1/g' /etc/fstab
    echo 'Disabling DNSMasq'
    echo "DNSStubListener=no" >> /etc/systemd/resolved.conf
    mv /etc/resolv.conf /etc/resolv.conf.orig
    ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
    service systemd-resolved restart
    echo 'Download redis'
    wget $REDIS_URL -O redisenterprise.tar
    tar xvf redisenterprise.tar
    echo 'Install redis'
    ./install.sh -y
else
    echo 'Redis Enterprise already installed'
fi