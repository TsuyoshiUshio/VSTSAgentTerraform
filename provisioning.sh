#!/bin/bash

# Install Docker
sudo sh -c 'curl -sSL https://get.docker.com/ | sh'
sudo service docker start
sudo gpasswd -a azureuser docker
sudo service docker restart

# Pre-requisites
# https://github.com/Microsoft/vsts-agent/blob/master/docs/start/envubuntu.md
sudo apt-get install -y libunwind8 libcurl3
sudo apt-add-repository ppa:git-core/ppa -y
sudo apt-get update 
sudo apt-get install git -y 

# Get parameter

vsts_account_name=$1
vsts_personal_access_token=$2
vsts_agent_name=$3
vsts_agent_pool_name=$4
user_account=$5

vsts_url=https://$vsts_account_name.visualstudio.com

# Install dotnet core

sudo sh -c 'echo "deb [arch=amd64] https://apt-mo.trafficmanager.net/repos/dotnet-release/ xenial main" > /etc/apt/sources.list.d/dotnetdev.list'
sudo apt-key adv --keyserver apt-mo.trafficmanager.net --recv-keys 417A0893
sudo apt-get update -y

sudo apt-get install dotnet-dev-1.0.0-preview2-003121 -y

# Install the VSTS agent
agent_folder=/home/azureuser/myagent
mkdir ${agent_folder}
cd ${agent_folder}
tar zxvf /home/azureuser/vsts-agent-ubuntu.16.04-x64-2.110.0.tar.gz

sudo -u ${user_account} bash ${agent_folder}/config.sh --url $vsts_url --agent $vsts_agent_name --pool $vsts_agent_pool_name --acceptteeeula --auth PAT --token $vsts_personal_access_token --unattended

# Configure agent to run as a service
sudo bash ${agent_folder}/svc.sh install
sudo bash ${agent_folder}/svc.sh start &

# Install Azure CLI 2.0
sudo apt-get update
sudo apt-get install wget -y
sudo apt-get update && sudo apt-get install -y libssl-dev libffi-dev python-dev build-essential

echo "deb [arch=amd64] https://apt-mo.trafficmanager.net/repos/azure-cli/ wheezy main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-key adv --keyserver apt-mo.trafficmanager.net --recv-keys 417A0893
sudo apt-get install -y apt-transport-https
sudo apt-get update && sudo apt-get install -y azure-cli

# Install Kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl



