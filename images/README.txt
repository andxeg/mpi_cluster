Папка с образами -> https://drive.google.com/open?id=1b4HjqNdH5K3QJ_OzFjaus8Mvfxgt0YXE

В данной папке хранятся два образа:

- xenial-server-cloudimg-amd64-disk1-master.qcow2 
- xenial-server-cloudimg-amd64-disk1-slave.qcow2   

Они оба базируются на xenial-server-cloudimg-amd64-disk1.img, который
взял отсюда -> https://cloud-images.ubuntu.com/xenial/current/

Эти образы подготовлены согласно ссылке -> http://mpitutorial.com/tutorials/running-an-mpi-cluster-within-a-lan/

В образе есть пользователь mpiuser, пароль mpiuser.

Master расшарил папку /home/mpiuser/cloud
Slave монтирует при каждом старте эту папку в свою -> /home/mpiuser/cloud  

Также в каждом образе есть папка /home/mpiuser/scripts/.
Из данной папки можно запускать скрипты с sudo и пароль не будет
запрашиваться, это сделано специально.
В ней хранятся скрпты для подготовки MPI кластера.
Подробнее про скрипты см. в /scripts/README.txt

Чтобы запустить виртуальную машину из этих образов, нужно
сделать snaptshot и конфигурационный файл для cloud-init.
Подробнее см. по ссылке -> https://youth2009.org/post/kvm-with-ubuntu-cloud-image/

 $ sudo qemu-img create -f qcow2 -b xenial-server-cloudimg-amd64-disk1-master.qcow2 master.img
 $ cat > config <<EOF
   #cloud-config
   password: THE_PASSWORD
   chpasswd: { expire: False }
   ssh_pwauth: True
   EOF

В конфигурационный файл можно добавлять публичный ssh ключ:
 $ cat > config.yaml << EOF
   #cloud-config
   package_upgrade: false
   users:
     - name: test_user
       groups: wheel
       lock_passwd: false
       passwd: test_user
       shell: /bin/bash
       sudo: ['ALL=(ALL) NOPASSWD:ALL']
       ssh-authorized-keys:
         - <ssh public key>

 $ cloud-localds config-master.img config
 $ sudo virt-install \
   --name master \
   --ram 1024 \
   --vcpus=1 \
   --os-type=linux \
   --os-variant=ubuntu16.04 \
   --virt-type=kvm \
   --hvm \
   --disk master.img,device=disk,bus=virtio \
   --disk config-master.img,device=cdrom \
   --network network=default \
   --graphics none \
   --import \
   --quiet \
   --noautoconsole

 Все тоже самое нужно повторить для slave узлов
 $ sudo qemu-img create -f qcow2 -b xenial-server-cloudimg-amd64-disk1-slave.qcow2 slave.img
   ...
 и т.д.


