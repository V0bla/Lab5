## Домашнее задание №5
### Задание
- Развернуть сервис NFS и подключить к нему клиента.
- Решение предоставить в виде автоматизированного Vagrantfile.
- Конфигурирование сервера и клиента произвести через 2 bash-скрипта nfss.sh и nfsс.sh соответственно.
- Описать особенности реализации, каталоги и файлы
### Решение
- #### Сконфигурирован [vagrantfile](./Vagrantfile) для запуска скриптов
```
  config.vm.define "nfss" do |nfss| 
    nfss.vm.network "private_network", ip: "192.168.50.10",  virtualbox__intnet: "net1" 
    nfss.vm.hostname = "nfss"
    nfss.vm.provision "shell", path: "nfss.sh"
  end 
  config.vm.define "nfsc" do |nfsc| 
    nfsc.vm.network "private_network", ip: "192.168.50.11",  virtualbox__intnet: "net1" 
    nfsc.vm.hostname = "nfsc"
    nfsc.vm.provision "shell", path: "nfsc.sh"
  end
```
- #### Созданы скрипты для конфигурирования nfs сервера [nfss.sh](./nfss.sh) и клиента [nfsс.sh](./nfsc.sh)
    - ##### настройки сервера NFS: 
        - устанавливается пакет nfs-utils
        ```
        yum install -y nfs-utils nano
        ```
        - настраивается firewalld и запускается nfs
        ```
        systemctl enable firewalld --now 
        firewall-cmd --add-service="nfs3" \
        --add-service="rpc-bind" \
        --add-service="mountd" \
        --permanent 
        firewall-cmd --reload
        systemctl enable nfs --now
        ```
        - создается каталог для шары и настраиваются права на него
        ```
        mkdir -p /srv/share/upload 
        chown -R nfsnobody:nfsnobody /srv/share 
        chmod 0777 /srv/share/upload
        ```
        - публикуется каталог в /etc/exports
        ```
        cat << EOF > /etc/exports
        /srv/share 192.168.50.11/32(rw,sync,root_squash)
        EOF
        ```
        - перечитывается конфигурация и проверяется
        ```
        exportfs -r
        exportfs -s
        ```
    - ##### настройки клиента:
        - устанавливается пакет nfs-utils
        ```
        yum install -y nfs-utils nano
        ```
        - задается конфигурация монтируемой шары в fstab
        ```
        echo "192.168.50.10:/srv/share/ /mnt/ nfs defaults,vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab
        ```
        - перечитывается конфигурация
        ```
        systemctl daemon-reload 
        systemctl restart remote-fs.target 
        #проверяем успешность монтирования каталога mnt
        cd /mnt
        mount | grep mnt 
        
        ```
### Результат проверки
- #### Стенд развертывается автоматически при выполнении `vagrant up`.
- #### Проверка:
    - На сервере создаем файл file_srv в каталоге /srv/share/upload
    ```
    [vagrant@nfss ~]$ touch /srv/share/upload/file_srv
    [vagrant@nfss ~]$ dir /srv/share/upload/file_srv
    file_srv
    ```
    - На клиенте создаем файл file_client в каталоге /mnt/upload
    ```
    [vagrant@nfsc ~]$ touch /mnt/upload/file_client
    [vagrant@nfsc ~]$ dir /mnt/upload/
    file_client  file_srv
    ```
    - После перезагрузки сервера и клиента убедились в доступности файлов
    ```
    [vagrant@nfss ~]$ dir /srv/share/upload/
    file_client  file_srv
    [vagrant@nfsc ~]$ dir /mnt/upload/
    file_client  file_srv
    ```
    - Статус сервера nfs, fw и rpc
    ```
    [vagrant@nfss ~]$ systemctl status nfs
      ● nfs-server.service - NFS server and services
    Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; vendor preset: disabled)
    Drop-In: /run/systemd/generator/nfs-server.service.d
            └─order-with-mounts.conf
    Active: active (exited) since Mon 2023-10-02 06:10:37 UTC; 13min ago
    Process: 831 ExecStartPost=/bin/sh -c if systemctl -q is-active gssproxy; then systemctl reload gssproxy ; fi (code=exited, status=0/SUCCESS)
    Process: 805 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
    Process: 801 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
    Main PID: 805 (code=exited, status=0/SUCCESS)
    CGroup: /system.slice/nfs-server.service

    ```
    ```
    [vagrant@nfss ~]$ systemctl status firewalld
  ● firewalld.service - firewalld - dynamic firewall daemon
    Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
    Active: active (running) since Mon 2023-10-02 06:10:33 UTC; 15min ago
      Docs: man:firewalld(1)
  Main PID: 407 (firewalld)
    CGroup: /system.slice/firewalld.service
            └─407 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid
    ```
    ```
    [vagrant@nfss ~]$ showmount -a 192.168.50.10
    All mount points on 192.168.50.10:
    192.168.50.11:/srv/share
    ```
    - На клиенте проверяем статус rpc, монтирования
    ```
    [vagrant@nfsc ~]$ showmount -a 192.168.50.10
    All mount points on 192.168.50.10:
    192.168.50.11:/srv/share
    ```
    ```
    [vagrant@nfsc ~]$ mount | grep mnt
    systemd-1 on /mnt type autofs (rw,relatime,fd=27,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=10975)
    192.168.50.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10)
    ```
- #### Итог
В соответствии с заданием монтирование и работа NFS на клиенте организована с использованием NFSv3 по протоколу UDP; 
```
192.168.50.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10)
```


