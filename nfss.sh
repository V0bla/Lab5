#!/bin/bash
# настрока сервера nfs
sudo -i
# устанавливаем пакеты
yum install -y nfs-utils nano
# настраиваем fw
systemctl enable firewalld --now 
firewall-cmd --add-service="nfs3" \
--add-service="rpc-bind" \
--add-service="mountd" \
--permanent 
firewall-cmd --reload

systemctl enable nfs --now
# создаем и настраиваем директории
mkdir -p /srv/share/upload 
chown -R nfsnobody:nfsnobody /srv/share 
chmod 0777 /srv/share/upload
# создаем структуру для экспорта
cat << EOF > /etc/exports
/srv/share 192.168.50.11/32(rw,sync,root_squash)
EOF
# читаем структуру и проверяем, что применилась
exportfs -r
exportfs -s