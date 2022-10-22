#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'


function _logger() {
    echo "$(date) ${YELLOW}[*] $@ ${NC}"
}


function brew_install_or_upgrade {
    if brew ls --versions "$1" >/dev/null; then
        _logger "upgrade"
        HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade "$1"
    else
        _logger "install"
        HOMEBREW_NO_AUTO_UPDATE=1 brew install "$1"
    fi
}

function brew_install_or_upgrade_cask {
    if brew ls --versions "$1" >/dev/null; then
        _logger "upgrade"
        HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade --cask "$1"
    else
        _logger "install"
        HOMEBREW_NO_AUTO_UPDATE=1 brew install -- cask "$1"
    fi
}

_logger "[+] Update brew"
brew update
brew upgrade
brew cleanup -s

#now diagnotic
brew doctor
brew missing
true > ~/.bash_profile
true > ~/.zshrc

echo 'export PATH="/usr/local/sbin:$PATH"' >> ~/.zshrc
echo 'export PATH="/usr/local/sbin:$PATH"' >> ~/.bash_profile
source ~/.zshrc
source ~/.bash_profile


_logger "[+] Installing tools"
brew_install_or_upgrade git
git --version
brew_install_or_upgrade httpie
http --version
brew_install_or_upgrade gnu-sed
brew_install_or_upgrade go-task/tap/go-task
brew brew_install_or_upgrade gitlab-runner
brew_install_or_upgrade ffmpeg
brew_install_or_upgrade plantuml
brew_install_or_upgrade youtube-dl
brew_install_or_upgrade ocrmypdf
brew_install_or_upgrade tesseract-lang
brew_install_or_upgrade_cask sourcetree
brew_install_or_upgrade_cask rectangle
brew_install_or_upgrade_cask drawio
brew_install_or_upgrade_cask alfred
brew_install_or_upgrade_cask transmit
brew_install_or_upgrade_cask vlc
brew_install_or_upgrade_cask microsoft-teams
brew_install_or_upgrade_cask deezer
brew_install_or_upgrade_cask visual-studio-code
brew_install_or_upgrade_cask duet


_logger "[+] Installing code tools : nodejs"
#brew uninstall --ignore-dependencies node 
#brew uninstall --force node
brew_install_or_upgrade nvm
mkdir ~/.nvm
echo 'export NVM_DIR=~/.nvm' >> ~/.bash_profile  
echo 'source $(brew --prefix nvm)/nvm.sh' >> ~/.bash_profile 
source ~/.bash_profile 
echo 'export NVM_DIR=~/.nvm' >> ~/.zprofile 
echo 'source $(brew --prefix nvm)/nvm.sh' >> ~/.zprofile 
source ~/.zprofile
nvm install 16.3.0
nvm use 16.3.0
node -v
npm -v

_logger "[+] Installing code tools : Python"
brew_install_or_upgrade python
brew unlink python && brew link python
brew_install_or_upgrade pyenv
brew_install_or_upgrade pipenv

echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.profile
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.profile
echo 'eval "$(pyenv init --path)"' >> ~/.profile
echo 'if [ -n "$PS1" -a -n "$BASH_VERSION" ]; then source ~/.bashrc; fi' >> ~/.profile
echo 'eval "$(pyenv init -)"' >> ~/.bashrc

echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init --path)"' >> ~/.zprofile
echo 'eval "$(pyenv init -)"' >> ~/.zshrc

source ~/.bash_profile
source ~/.profile
source ~/.zshrc
source ~/.zprofile

pyenv install --skip-existing 3.10.0
pyenv global 3.10.0
pyenv versions
python --version

_logger "[+] Installing aws tools"
brew tap aws/tap
brew_install_or_upgrade awscli
aws --version
brew_install_or_upgrade aws-cdk
cdk --version
brew_install_or_upgrade aws-sam-cli
sam --version
#brew_install_or_upgrade aws-cfn-tools

_logger "[+] Installing k8s tools"
brew_install_or_upgrade kubernetes-cli
kubectl version
brew_install_or_upgrade aws-iam-authenticator
brew tap weaveworks/tap
brew_install_or_upgrade weaveworks/tap/eksctl
eksctl version

_logger "[+] cleanup"
brew cleanup