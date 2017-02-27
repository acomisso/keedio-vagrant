# keedio-vagrant



## Introduction
This is a Vagrant based test environment, designed to test the integration of the different packages of the Keedio software stack, which can be used to deploy virtual clusters using either Ambari or by manually configuring the services.
A hiera based configuration file can be used to adapt Keedio-vagrant to different environments and requirements. 
By default it uses the Keedio public repository to install the packages. To limit the external bandwidth requirement, a local mirror of the main keedio repository repo.keedio.org can be created in a VM called buildoop. The same VM contains the buildoop packaging system and can be used to build new versions of the software components. These new versions can then be deployed to the test VMs using the local repo.
The vagrant plugin "vagrant-vbox-snapshot" can be used to snapshot the state of the cluster, and move easily back and forward in time by selecting the right snapshot.


## Obtaining access to Keedio stack
Keedio uses Red Hat satellite to manage the distribution of its Keedio stack, in order to install it stack you need to request an activation code.   You can request it here  https://www.keedio.org/demo/

You have to use it in the setup process. 

As an alternative you can package your own repository using buildoop and you can tell keedio-vagrant to use default yum repositories by setting the variable satellite: false in ./hiera/configuration.yaml.


#Preliminary steps

Install Vagrant and Virtualbox before starting.  
Make sure you install the vagrant snapshotting plugin for virtualbox 
```
vagrant plugin install vagrant-vbox-snapshot
```
Install hiera-eyaml ruby gem
```
gem install hiera-eyaml
```
Download the keedio-vagrant stack

```
git clone --recursive https://github.com/keedio/keedio-vagrant.git
cd  keedio-vagrant
```

#Setup the cluster
The following procedure is required and independent from hypervisor or cloud provider.
```
./setup.sh
####################################################
Setting up environment for Keedio Stack deployment
This will use default encryption keys and passwords
Please use setup_secure.sh if you want to change them
#####################################################
[hiera-eyaml-core] hiera-eyaml (core): 2.0.8
Please provide the activation key:
####################################################
The hiera/secure.eyaml file has been created
You can check the values and modify it with the command

eyaml edit hiera/secure.eyaml
#####################################################
```
## Optional: setup the cluster in secure mode

To generate new encryption keys, and set non default password you can issue the foillowing command:
```
./setup_secure.sh

####################################################
Setting up environment for Keedio Stack deployment
This will use default encryption keys and passwords
Please use setup_secure.sh if you want to change them
#####################################################
[hiera-eyaml-core] hiera-eyaml (core): 2.0.8
Creating Hiera encryption keys
Are you sure you want to overwrite "./keys/private_key.pkcs7.pem"? (y/N): y
Are you sure you want to overwrite "./keys/public_key.pkcs7.pem"? (y/N): y
[hiera-eyaml-core] Keys created OK
Please provide the activation key:
Please provide the admin password for the backend database:[adminadmin]
Please provide the hue user password for the backend database:[hue]
Please provide the hive user password for the backend database:[hive]
Please provide the oozie user password for the backend database:[oozie]
Please provide the ambari user password for the backend database:[bigdata]
Please provide the Free IPA admin password:[adminadmin]
Please provide the Ambari admin password:[admin]
####################################################
The hiera/secure.eyaml file has been created
You can check the values and modify it with the command

eyaml edit hiera/secure.eyaml
#####################################################
Making a backup-copy of the existing ssh keys in ./files/ssh-backup
Generating new ssh keys in ./files/.ssh/
Generating public/private rsa key pair.
./files/.ssh/id_rsa already exists.
Overwrite (y/n)? y
Your identification has been saved in ./files/.ssh/id_rsa.
Your public key has been saved in ./files/.ssh/id_rsa.pub.
The key fingerprint is...
```

# Keedio-vagrant with Virtualbox

##Preliminary steps


Populate the /etc/hosts of your machine with the provided information
```
sudo cat  append-to-etc-hosts.txt  >> /etc/hosts
```
Prepare Vagrantfile and configuration.yaml
```
cd  ambari1
cp vagrantfiles/Vagrantfile.virtualbox Vagrantfile
cp configurations/standard-user.yaml hiera/configuration.yaml
```




##Start the cluster
You can now start your ambari cluster, you should always start the master machine, and a number of slaves (ambari1, ambari2, ambari3...)

```
vagrant up master ambari1 ambari2
```

this can take several minutes, when it is complete you should be able to access the Ambari web page: master.ambari.keedio.org:8080. The default credentials are both "admin".

 
You can suspend the execution of all the VMs with

```
vagrant suspend
```

And restart with 

```
vagrant resume
``` 
# keedio-vagrant on the Produban openstack cloud

The machine controller1.keedio.prbes.lab  must be reachable from your workstation. So make sure that you are connected to the Produban VPN and that you have the following line in your /etc/hosts file. 
```
180.133.240.102     controller1.keedio.prbes.lab controller1
```

It's possible to start keedio-vagrant on the Produban cloud using the openstack-provider plugin. You have to install the plugin first.
```
vagrant plugin install vagrant-openstack-provider
```
You also have to install GNU parallel to run parallel scripts, on the Mac
```
brew install parallel
```
In order to access the cloud you have to download the "Openstack RC file" in the "Access and Security" section of Horizon interface. The filename is $USER_openrc.sh.
Before starting any vagrant-openstack session you have to source it
```
source $USER_openrc.sh
```
You will be prompted for you openstack password. Input it. 

Go in the ambari1 directory and prepare the Vagrantfile and the configuration.yaml
```
cd keedio-vagrant/ambari1 
cp vagrantfiles/Vagrantfile.workshop Vagrantfile
cp configurations/workshop.yaml hiera/configuration.yaml
```

Edit the Vagrantfile to select the flavour and the floating IP of each machine. Remove or add  the machines as you wish.

Check that you are properly connected with 
```
vagrant status
```

If you get an error, repeate the procedure. If you get the status of the machines  you can proceed.

To startup the system in parallel 
```
./para-startup.sh
```
To set proper name resolution
```
python set-hosts-openstack.py
```
At the end you will get a summary table that should be pasted into the /etc/hosts file of your workstation.
Then you can run the parallel puppet provisioner
```
./para-provision.sh
```
# keedio-vagrant on the Cediant openstack cloud 

It's possible to start keedio-vagrant on the Cediant cloud using the openstack-provider plugin. You have to install the plugin first.
```
vagrant plugin install vagrant-openstack-provider
```

In order to access the cloud you have to download the "Openstack RC file" in the "Access and Security" section of Horizon interface. The filename is $USER_openrc.sh.
Before starting any vagrant-openstack session you have to source it
```
source $USER_openrc.sh
```
You will be prompted for you openstack password. Input it. 

Go in the ambari1 directory and prepare the Vagrantfile and the configuration.yaml
```
cd keedio-vagrant/ambari1 
cp vagrantfiles/Vagrantfile.openstack Vagrantfile
cp configurations/openstack-cediant.yaml hiera/configuration.yaml
```

After that you can start you VMs with vagrant up adding a flag to specify the openstack provider. Buildoop is not required, as the Cediant cloud local repo will be used.

```
vagrant up master ambari1 ambari2
```

This version of openstack doesn't export "metadata" to the guests, so the hostsnames and name resolution is not set. We need to to execute a script to fix it. In the directory ambari1 issue 
```
#python set-hosts-openstack.py

########################################################
KEEDIO-VAGRANT
Automatic population of /etc/hosts for cloud environment
########################################################

Collecting information about available nodes

master                    active (openstack)
ambari1                   active (openstack)
ambari2                   active (openstack)
Available nodes:
['master', 'ambari1', 'ambari2']

setting hostnames on the VMs

...

master
Private IP: 192.168.0.6
Floating IP: 10.129.135.119

ambari1
Private IP: 192.168.0.2
Floating IP: 10.129.135.118

ambari2
Private IP: 192.168.0.3
Floating IP: 10.129.135.167

Add the following lines to your local /etc/hosts

#Cluster ambari /etc/hosts section starts here###
10.129.135.119  master.ambari.keedio.org  master
10.129.135.118  ambari1.ambari.keedio.org  ambari1
10.129.135.167  ambari2.ambari.keedio.org  ambari2
#Cluster ambari /etc/hosts section end here######


!!!Remember to run the following command!!!
 vagrant provision
 ```
It is useful to copy and paste the section 
```
#Cluster ambari /etc/hosts section starts here###
10.129.135.119  master.ambari.keedio.org  master
10.129.135.118  ambari1.ambari.keedio.org  ambari1
10.129.135.167  ambari2.ambari.keedio.org  ambari2
#Cluster ambari /etc/hosts section end here######
```
in the /etc/hosts file of your workstation. Rememebr to remove ti when you destroy the cluster.

This script has now populated a puppet module, so you can now propagate the configuration changes with 
```
vagrant provision
```
You should be able to point your browser to master.ambari.keedio.org:8080 and install your cluster.

Notice: everytime you install a new host in the cluster, you have to repeat the execution of the  script and the vagrant provision steps. The script is cusomizable, and you can select different cluster and domain names for your cluster.  

## Know problems

If you delete VMs in horizon, vagrant will enter an invalid state and you will be forced to start from scratch. 

# Optional:  Enabling Free IPA

Free IPA is a RedHat service that provides LDAP and Kerberos authentication, you need to enable it only if you want to test the securization of your cluster. We reccomend enabling it after the VMs have been started. In order to do that you have to change the hiera/configuration.yaml file.
```
ipa: true
```
Then you have to reprovision all the VMs
```
vagrant provision
```

# Managing passwords 

We use hiera-eyaml to encrypt passwords in the file /keedio-vagrant/ambari1/hiera/secure.eyaml. Full descrition of hiera-email can be found here https://github.com/TomPoulton/hiera-eyaml. Here we give a quick introduction. 
To install hiera-eyaml 
```
gem install hiera-eyaml
```
You need to move to ambari1 folder. 

You can view and edit existing passwords with 
```
eyaml edit hiera/secure.eyaml
```
You can create new encryption  keys with 
```
eyaml createkeys
```
You can encrypt passwords with 
```
eyaml encrypt -s 'password'
```
You can take the output and paste it manually into hiera/secure.eyaml using any editor.  









