#!/bin/bash

set -euxo pipefail

ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
CURRENT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

export INFOPATH="/home/linuxbrew/.linuxbrew/share/info"

function _logger() {
    echo -e "$(date) ${YELLOW}[*] $@ ${NC}"
}



function install_linuxbrew() {
    _logger "[+] Creating touch symlink"
    sudo ln -sf /bin/touch /usr/bin/touch
    _logger "[+] Installing homebrew..."
    echo | sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
    _logger "[+] Adding homebrew in PATH"
    test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv)
    test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
    test -r ~/.bash_profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.bash_profile
    echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.profile
}

function brew_install_or_upgrade {
    if brew ls --versions "$1" >/dev/null; then
        HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade "$1"
    else
        HOMEBREW_NO_AUTO_UPDATE=1 brew install "$1"
    fi
}

function add_attendees_to_cloud9() {
    # Cloud9 Environment has a limit of 20 IAM users you can share with
    # Therefore, we only add service and presenter users
    C9_IDS=($(aws cloud9 list-environments --query 'environmentIds' --output text))
    for env in ${C9_IDS[@]}; do
        _logger "[*] Getting list of Cloud9 Environments"
        C9_ENV=($(aws cloud9 describe-environments --environment-ids ${env} --query 'environments[*].name' --output text))
        for workspace in ${C9_ENV[@]}; do
            for user_no in $(seq 1 5); do
                _logger "[+] Adding IAM User ${user_no} to Cloud9 ${workspace} Environment"
                aws cloud9 create-environment-membership \
                    --environment-id ${env} \
                    --user-arn arn:aws:iam::${ACCOUNT_ID}:user/${workspace}ServiceUser${user_no} \
                    --permissions read-write
            done
        done
    done

    for presenter_no in $(seq 1 4); do
        _logger "[+] Adding Presenter ${presenter_no} to Cloud9 ${workspace} Environment"
        aws cloud9 create-environment-membership \
            --environment-id ${env} \
            --user-arn arn:aws:iam::${ACCOUNT_ID}:user/Presenter${presenter_no} \
            --permissions read-write
    done
}

function upgrade_sam_cli() {
    _logger "[+] Backing up current SAM CLI"
    cp $(which sam) ~/.sam_old_backup

    _logger "[+] Installing latest SAM CLI"
    # pipx install aws-sam-cli
    # cfn-lint currently clashing with SAM CLI deps
    ## installing SAM CLI via brew instead
    brew tap aws/tap
    brew_install_or_upgrade aws-sam-cli

    _logger "[+] Updating Cloud9 SAM binary"
    # Allows for local invoke within IDE (except debug run)
    ln -sf $(which sam) ~/.c9/bin/sam
}

function upgrade_existing_packages() {
    _logger "[+] Upgrading system packages"
    sudo yum update -y

    _logger "[+] Upgrading Python pip and setuptools"
    python3 -m pip install --upgrade pip setuptools --user

}

function install_utility_tools() {
    _logger "[+] Installing CFN Linting"
    python3 -m pip install --upgrade --user cfn-lint

    _logger "[+] Installing c9 (Cloud9 CLI)"
    npm install -g c9
    
    _logger "[+] Installing httpie"
    brew_install_or_upgrade httpie
    
    _logger "[+] Installing terraform"
    brew_install_or_upgrade terraform
    
    _logger "[+] Installing Task runner tool"
    brew_install_or_upgrade go-task/tap/go-task
    
    _logger "[+] Installing linux tools"
    brew_install_or_upgrade jq
    brew_install_or_upgrade gettext
    brew_install_or_upgrade yq
    
    _logger "[+] Installing developer tools"
    brew_install_or_upgrade pyenv
    npm install speccy -g
}

function configure_aws_cli() {
    _logger "[!] Overriding AWS CLI configuration... don't forget to attach IAM Role to EC2"
    rm -f ~/.aws/credentials
    cat <<-EOF >~/.aws/config
[default]
output = json
region = ${CURRENT_REGION}

EOF
}


function install_aws_tools() {
    
    _logger "[+] Installing latest AWS CLI"
    python3 -m pip install --upgrade --user boto3
    python3 -m pip install --upgrade --user awscli
    python3 -m pip install --upgrade --user git-remote-codecommit
    
    _logger "[+] Installing Amplify CLI"
    npm install -g @aws-amplify/cli
    npm install -g amplify-category-video
    
    _logger "[+] Installing CDK"
    npm install -g aws-cdk
    npm install -g typescript@latest
}

function install_containers_tools() {
    _logger "[+] Installing kubernetes cli(s)"
    brew tap weaveworks/tap
    brew_install_or_upgrade kubernetes-cli   
    #brew_install_or_upgrade fluxctl
    brew_install_or_upgrade kustomize
    brew_install_or_upgrade helm
    brew install aws-iam-authenticator
    brew_install_or_upgrade weaveworks/tap/eksctl
    
}

function main() {
    #add_attendees_to_cloud9
    install_linuxbrew
    upgrade_existing_packages
    install_utility_tools
    configure_aws_cli
    upgrade_sam_cli
    install_aws_tools
    install_containers_tools
    echo -e "${RED} [!!!!!!!!!] Open up a new terminal to reflect changes ${NC}"
    _logger "[+] Restarting Shell to reflect changes"
    exec ${SHELL}
}

main
