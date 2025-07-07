#!/usr/bin/env bash
set -e

PLAYBOOK=windows_cert_crawler_install.yml
INVENTORY=hosts.ini

EXTRA_VARS="fid='HEMANTH/testuser2' installation_path='C:/Temp/CertCrawler/' operation_mode='opmode1' cert1_dir_path='C:/Temp/CertCrawler/test-certs/' cert1_types='p12,cer' extract_root_certs='Y'"

echo "Running ansible-playbook with variables:"
echo $EXTRA_VARS

ansible-playbook -i $INVENTORY $PLAYBOOK -e "$EXTRA_VARS"

echo "Playbook completed successfully."
