# Remote debugging with VirtualBox

1) Install VirtualBox and create your target environment
2) Select *Bridged Adapter* for network card (name: default or wlp4s0)
3) Establish trust from VirtualBox machine to your development environment
   1) First generate ssh key ssh-keygen -t rsa -b 2048 
      1) Select all defaults.
   2) Then copy it to your development machine
      1) ssh-copy-id id@server
         1) Where id is your login and server is your machine i.e. tomaz@hansolo Choose all defaults.
   3) Now you can run remote commands from Virtual Box to your 
      dev environemnt
   4) Update /etc/hosts, add your host for quicker 
