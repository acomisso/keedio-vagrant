# keedio-vagrant

## Introduction
This is a Vagrant based test environment, designed to test the integration of the different packages of the Keedio software stack, 
 which can be used to deploy virtual clusters using either Ambari or by manually configuring the services. To limit the external bandwidth requirement, a local mirror of the main keedio repository repo.keedio.org is hosted in a VM called buildoop. The same VM contains the buildoop packaging system and can be used to build new versions of the software components. This new version can then be deployed to the test VMs using the local repo.   



##Preliminary steps

Install Vagrant and Virtualbox before starting. 
Make sure you install the vagrant snapshotting plugin for virtualbox 
```
vagrant plugin install vagrant-vbox-snapshot
```


Download the keedio-vagrant stack

```
git clone --recursive https://github.com/keedio/keedio-vagrant.git

cd  keedio-vagrant
```

Populate the /etc/hosts of your machine with the provided information
```
cat  append-to-etc-hosts.txt  >> /etc/hosts
```
Start the local repositories 
```
cd  ambari1
vagrant up buildoop
```
Enter in the VM and become root 
```
vagrant ssh buildoop
sudo su
python /vagrant/sync-localrepo.py
```

Answer "Yes" to all the repositories that you want to replicate. At the moment keedio-1.2 and keedio-1.2-updates. 
This will take several minutes. 
When the process is complete you can check the status of your repo by pointing your browser to http://buildoop/openbus/

Installing third party proprietary libraries

```
/vagrant/opsec-setup.sh
```
 
Exit from the buildoop VM
```
exit
```

You can now start your ambari cluster, you should always start the master machine, and a number of slaves (ambari1, ambari2, ambari3...)

```
vagrant up master ambari1 ambari2
```

this can take several minutes, when it is complete you should be able to access the Ambari web page: master.ambari.keedio.org:8080

 
You can suspend the execution of all the VMs with

```
vagrant suspend
```

And restart with 

```
vagrant resume
``` 



