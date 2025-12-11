#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

# Actualizamos paquetes
apt-get update -y

# Instalamos dependencias para MySQL APT repo
apt-get install -y wget lsb-release gnupg

# Añadimos el repositorio oficial de MySQL 8
wget https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb
dpkg -i mysql-apt-config_0.8.29-1_all.deb <<< "mysql-8.0"
apt-get update -y

# Instalamos MySQL Server
apt-get install -y mysql-server

systemctl enable mysql
systemctl start mysql

# Esperar un poco para que MySQL termine de inicializar
sleep 5

# Permitir conexiones remotas
sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf || true
systemctl restart mysql
sleep 3

# Configuración SQL
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS vsftpd CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE vsftpd;

CREATE TABLE IF NOT EXISTS usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(64) NOT NULL UNIQUE,
  passwd VARCHAR(255) NOT NULL
);

INSERT IGNORE INTO usuarios (nombre, passwd)
VALUES ('roldan', SHA2('roldan', 256));

CREATE USER IF NOT EXISTS 'ftpuser'@'%' IDENTIFIED BY 'ftp';
GRANT SELECT (nombre, passwd) ON vsftpd.usuarios TO 'ftpuser'@'%';
FLUSH PRIVILEGES;
EOF
