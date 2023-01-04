#!/usr/bin/env bash

terraform init
terraform apply -auto-approve 
mv hosts.yaml ansible/inventory/
cd ../ansible/
sleep 60
ansible-playbook -i inventory/hosts.yaml start_role.yml