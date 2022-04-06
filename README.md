# Bootstrap a Redis Enterprise demo environment on VMs on GCP

This is a very hacker-di-hack way of bootstrapping a Redis Enterprise cluster on GCP.
Disclaimer: Not production ready - especially the redis cluster creation - use at your own peril.

## Pre-reqs

- GCP:
    - service account with enough access to create all the required resources
    - a project 
    - a zone in Cloud DNS

## What it will do

- Create a VPS + firewall
- Create domain records
- Create 4 machines (3 for cluster + 1 for client)
- Set up a SSH config so you can log in
- Do some OS config
- Install Redis Enterprise on all 4 machines (client so we have tooling)
- Create a cluster

## How-to

- Customize the variables in the terraform.tfvars file
- 'terraform apply' => creates GCP resources and installs Redis Enterprise
- run the 'setupCluster.sh' script locally (parameters come from terraform output)=> create Redis Enterprise cluster. 
- fun & profit!