#!/bin/bash

set -ufo pipefail

ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'


function _logger() {
    echo -e "$(date) ${YELLOW}[*] $@ ${NC}"
}

function install_c9_cli() {
    _logger "[+] Installing c9 CLI"
    npm install -g c9
}

function add_attendees_to_cloud9() {
    _logger "[*] Getting list of Cloud9 Environments"
    for env in $(aws cloud9 list-environments --query 'environmentIds' --output text)
        do
            for user in $(aws iam list-users --query 'Users[*].Arn' --output text)
                do
                    _logger "[+] Adding IAM User ${user} to Cloud9 Environment ${env}"
                    aws cloud9 create-environment-membership \
                        --environment-id ${env} \
                        --user-arn ${user} \
                        --permissions read-write
                done
        done
}


function upgrade_sam_cli() {
    _logger "[+] Upgrading system packages"
    sudo yum update -y
    _logger "[+] Upgrading Python pip and setuptools"
    sudo python3 -m pip install --upgrade pip
    sudo python3 -m pip install --upgrade setuptools
    _logger "[+] Upgrades AWS CLI version as Sept '18 version has dependency issues"
    pip install awscli --upgrade --user
    _logger "[+] Installing new SAM CLI"
    pip install aws-sam-cli --user
    _logger "[+] Backup up current SAM CLI"
    cp $(which sam) ~/.sam_old_backup
    _logger "[+] Backup up current SAM CLI replacing with the latest version"
    ln -sf ~/.local/bin/sam $(which sam)
}

function update_pip_alias() {
    _logger "[+] Updating pip command alias to Python 3 as default"
    sed -i "/alias python\=python27/a alias pip\=\'python3 -m pip'" ~/.bashrc
}

function install_utility_tools() {
    _logger "[+] Installing CFN Linting tool"
    pip install cfn-lint --upgrade --user
    _logger "[+] Installing JSON Parsing (JQ)"
    pip install jq --upgrade --user
    _logger "[+] Installing c9 (Cloud9 CLI)"
    npm install -g c9
}

function main() {
    add_attendees_to_cloud9
    update_pip_alias
    _logger "[+] Restarting Shell to reflect changes"
    upgrade_sam_cli
    install_c9_cli
    install_utility_tools
    echo -e "${RED} [!!!!!!!!!] Open up a new terminal to reflect changes ${NC}"
}

main
