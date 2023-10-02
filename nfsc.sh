#!/bin/bash
# настрока клиента nfs
sudo -i
# устанавливаем пакеты
yum install -y nfs-utils nano
# задаем конфигурацию монтируемой шары в fstab
echo "192.168.50.10:/srv/share/ /mnt/ nfs defaults,vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab
# перечитываем конфигурацию
systemctl daemon-reload 
systemctl restart remote-fs.target 
#проверяем успешность монтирования каталога mnt
cd /mnt
mount | grep mnt 