Average delay between master and slaves

Launch ping from master to all slave, save results to file and then run command below:
$ grep "time=" out.txt | cut -d'=' -f4 | cut -d' ' -f1 | awk '{s+=$1; i+=1} END {print s/i; }'

Dependencies
- kvm
    $ sudo apt-get install qemu-kvm libvirt-bin virtinst bridge-utils cpu-checker

- cloud-localds
    $ sudo apt-get install cloud-utils

- sshpass
    $ sudo apt instal sshpass

- problems with locale (https://askubuntu.com/questions/162391/how-do-i-fix-my-locale-issue)
    $ sudo locale-gen "en_US.UTF-8"
    $ sudo dpkg-reconfigure locales 
    

