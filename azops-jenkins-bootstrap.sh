#create Azure resource group & linux vm w/public IP & DNS
az group create -l westus2 -n ops
az vm create -n pipeline -g ops --public-ip-address-dns-name kbpipe --image ubuntults --vnet-name kbopsvnet --data-disk-sizes-gb 20 40 --size Standard_DS2_v2 --ssh-key-value ~/.ssh/id_rsa.pub


#update & install toools
sudo apt-get update
sudo apt-get install unzip
sudo apt-get install jq

#!/usr/bin/env bash
# Get URLs for most recent versions of Terraform & Packer

terraform_url=$(curl --silent https://releases.hashicorp.com/index.json | jq '{terraform}' | egrep "linux.*64" | sort -rh | head -1 | awk -F[\"] '{print $4}')

packer_url=$(curl --silent https://releases.hashicorp.com/index.json | jq '{packer}' | egrep "linux.*64" | sort -rh | head -1 | awk -F[\"] '{print $4}')


# Create a move into directory.

cd

mkdir packer

mkdir terraform && cd $_



# Download Terraform. URI: https://www.terraform.io/downloads.html

curl -o terraform.zip $terraform_url

# Unzip and install

unzip terraform.zip



# Change directory to Packer

cd ~/packer



# Download Packer. URI: https://www.packer.io/downloads.html

curl -o packer.zip $packer_url

# Unzip and install

unzip packer.zip


#add to path
echo '

# Terraform & Packer Paths.

export PATH=~/terraform/:~/packer/:$PATH

' >>~/.bash_profile



source ~/.bash_profile



#install Jenkins
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get install jenkins
sudo apt-get install aptitude

#install Azure CLI

echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | \
     sudo tee /etc/apt/sources.list.d/azure-cli.list

	
sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
sudo apt-get install apt-transport-https
sudo apt-get update && sudo apt-get install azure-cli	
sudo apt-get update && sudo apt-get install -y libssl-dev libffi-dev python-dev build-essential 

#install nginx
sudo aptitude -y install nginx

#configure nginx proxy for Jenkins dashboard
cd /etc/nginx/sites-available

sudo rm default ../sites-enabled/default

sudo vim jenkins

upstream app_server {

    server 127.0.0.1:8080 fail_timeout=0;

}



server {

    listen 80;

    listen [::]:80 default ipv6only=on;

    server_name kbops01.westus2.cloudapp.azure.com;



    location / {

        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        proxy_set_header Host $http_host;

        proxy_redirect off;



        if (!-f $request_filename) {

            proxy_pass http://app_server;

            break;

        }

    }

}

sudo ln -s /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/

sudo service nginx restart

