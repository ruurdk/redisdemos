#! /bin/bash
echo "Querying terraform for parameters..."

REDIS_URL=$(terraform output -json redis_enterprise_download_url | jq -r '.')

SERVER_IPS=$(terraform output -json cluster_ips | jq -r '.[]')
CLIENT_IP=$(terraform output -json client_ip | jq -r '.')
CLUSTER_NAME=$(terraform output -json clustername | jq -r '.')
MASTER_INTERNAL_IP=$(terraform output -json master_internal_ip | jq -r '.')

CLUSTER_ACCOUNT=$(terraform output -json cluster_account | jq -r '.')
CLUSTER_PASSWORD=$(terraform output -json cluster_password | jq -r '.')

GCE_SSH_USER=$(terraform output -json gce_ssh_user | jq -r '.')
GCE_SSH_PRIVATE_KEY_FILE=$(terraform output -json gce_ssh_private_key_file | jq -r '.')

SSH_OPTIONS="-i $GCE_SSH_PRIVATE_KEY_FILE -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

for serverip in $SERVER_IPS; do
    echo "Setting up node $serverip"

    ssh $SSH_OPTIONS $GCE_SSH_USER@$serverip 'bash -s' < installRedis.sh
done

echo "Installing Redis on client machine (for tooling - memtier etc.)"
ssh $SSH_OPTIONS $GCE_SSH_USER@$CLIENT_IP 'bash -s' < installRedis.sh

echo "Setting up cluster"
MASTER_IP=$(echo "$SERVER_IPS" | head -n 1)
NODE_IPS=$(echo "$SERVER_IPS" | tail -n 2)
echo "Making $MASTER_IP the master"
ssh $SSH_OPTIONS $GCE_SSH_USER@$MASTER_IP << EOF
    sudo -i
    cd /opt/redislabs/bin/
    rladmin cluster create name $CLUSTER_NAME username $CLUSTER_ACCOUNT password $CLUSTER_PASSWORD external_addr $MASTER_IP
EOF

for slave_ip in $NODE_IPS; do
    echo "Joining $slave_ip to cluster as a slave"
    ssh $SSH_OPTIONS $GCE_SSH_USER@$slave_ip << EOF
        sudo -i
        cd /opt/redislabs/bin/
        rladmin cluster join nodes $MASTER_INTERNAL_IP username $CLUSTER_ACCOUNT password $CLUSTER_PASSWORD external_addr $slave_ip
EOF
done

echo "Our glorious cluster:"
ssh $SSH_OPTIONS $GCE_SSH_USER@$MASTER_IP << EOF
    sudo -i
    cd /opt/redislabs/bin/
    rladmin status
EOF

echo "Master login: ssh -i $GCE_SSH_PRIVATE_KEY_FILE $GCE_SSH_USER@$MASTER_IP"
echo "Client login: ssh -i $GCE_SSH_PRIVATE_KEY_FILE $GCE_SSH_USER@$CLIENT_IP"
