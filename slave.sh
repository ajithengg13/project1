#!/bin/sh
sudo apt-get update -y 
sudo apt-get install openjdk-8-jdk openjdk-8-jre -y
sudo chmod 777 /etc/environment
sudo echo 'JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> /etc/environment
sudo echo 'JRE_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre' >> /etc/environment
sudo apt-get install -y docker* 
sudo service docker start
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sudo apt-get install -y python-pip
sudo apt-get install software-properties-common
sudo apt-add-repository ppa:ansible/ansible -y
sudo apt-get install ansible -y
sudo apt-get install dos2unix	
sudo apt install maven -y 