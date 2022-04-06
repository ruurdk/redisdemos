boot_disk_size = "40"
boot_disk_image = "ubuntu-os-cloud/ubuntu-1804-lts"
machine_type = "e2-standard-2"
machine_base_name = "ruurd-te"
network_base_name = "ruurd-te"

gcp_project_id = "central-beach-194106"
gcp_region = "europe-west4"
gcp_zone = "europe-west4-a"

dns_base = "demo.redislabs.com"
managed_zone = "demo-clusters"

gce_ssh_user = "ruurd.keizer"
gce_ssh_private_key_file = "/Users/ruurd/.ssh/gcp"
gce_ssh_pub_key_file = "/Users/ruurd/.ssh/gcp.pub"

redis_enterprise_download_url = "https://s3.amazonaws.com/redis-enterprise-software-downloads/6.2.10/redislabs-6.2.10-96-bionic-amd64.tar"

cluster_name = "ruurd-te"
cluster_account = "ruurd.keizer@redis.com"
cluster_password = "Redis1"
