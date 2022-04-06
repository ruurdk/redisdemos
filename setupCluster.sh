#! /bin/bash

REDIS_URL=https://s3.amazonaws.com/redis-enterprise-software-downloads/6.2.10/redislabs-6.2.10-96-bionic-amd64.tar
REDIS_FILE=redislabs-6.2.10-96-bionic-amd64.tar

SERVER_IPS=$(terraform output -json cluster_ips | jq -r '.[]')
CLIENT_IP=$(terraform output -json client_ip | jq -r '.')
CLUSTER_NAME=$(terraform output -json clustername | jq -r '.')
MASTER_INTERNAL_IP=$(terraform output -json master_internal_ip | jq -r '.')

SSH_OPTIONS="-i ~/.ssh/gcp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

for serverip in $SERVER_IPS; do
    echo "Setting up node $serverip"

    ssh $SSH_OPTIONS ruurd.keizer@$serverip << EOF
        sudo -i
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
        'Download redis'
        wget $REDIS_URL
        tar xvf $REDIS_FILE
        'Install redis'
        ./install.sh -y
EOF
done

echo "Setting up cluster"
MASTER_IP=$(echo "$SERVER_IPS" | head -n 1)
NODE_IPS=$(echo "$SERVER_IPS" | tail -n 2)
echo "Making $MASTER_IP the master"
ssh $SSH_OPTIONS ruurd.keizer@$MASTER_IP << EOF
    sudo -i
    cd /opt/redislabs/bin/
    rladmin cluster create name $CLUSTER_NAME username ruurd.keizer@redis.com password Redis1 external_addr $MASTER_IP
EOF

for slave_ip in $NODE_IPS; do
    ssh $SSH_OPTIONS ruurd.keizer@$slave_ip << EOF
        sudo -i
        cd /opt/redislabs/bin/
        rladmin cluster join nodes $MASTER_INTERNAL_IP username ruurd.keizer@redis.com password Redis1 external_addr $slave_ip
EOF
done
