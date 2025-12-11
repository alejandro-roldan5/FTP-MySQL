#!/bin/bash
set -euxo pipefail

# Instalar vsftpd y pam_mysql
apt-get update -y
apt-get install -y vsftpd libpam-mysql
systemctl enable vsftpd
systemctl start vsftpd

# Crear usuario del sistema para mapear usuarios virtuales
adduser --system --home /home/vsftpd --group --shell /bin/false vsftpd || true

# Crear carpeta para el usuario virtual 'roldan'
mkdir -p /home/vsftpd/roldan
chown -R vsftpd:nogroup /home/vsftpd/roldan
chmod 755 /home/vsftpd/roldan

# Configuración PAM para vsftpd
cat >/etc/pam.d/vsftpd <<EOF
auth    required pam_listfile.so item=user sense=deny file=/etc/ftpusers onerr=succeed
auth    required pam_mysql.so user=ftpuser passwd=ftp  host=${mysql_private_ip} db=vsftpd table=usuarios usercolumn=nombre passwdcolumn=passwd crypt=2
account required pam_mysql.so user=ftpuser passwd=ftp  host=${mysql_private_ip} db=vsftpd table=usuarios usercolumn=nombre passwdcolumn=passwd crypt=2
EOF

# Configuración vsftpd
cat >/etc/vsftpd.conf <<EOF
listen=YES
listen_ipv6=NO

anonymous_enable=NO
local_enable=YES
write_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES

guest_enable=YES
guest_username=vsftpd
user_sub_token=\$USER
local_root=/home/vsftpd/\$USER
pam_service_name=vsftpd

virtual_use_local_privs=YES

pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100
pasv_address=${public_ip_ftp}

xferlog_enable=YES
log_ftp_protocol=YES
vsftpd_log_file=/var/log/vsftpd.log

utf8_filesystem=YES
EOF

systemctl restart vsftpd