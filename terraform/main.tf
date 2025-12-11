terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

########################################
# Crear VPC y Subnet
########################################

# VPC por defecto
data "aws_vpc" "default" {
  default = true
}

# Subnets de la VPC por defecto
data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

########################################
# Security Group VSFTPD
########################################

resource "aws_security_group" "sg_vsftpd" {
  name        = "sg_vsftpd"
  description = "Permite FTP y pasivo"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "FTP"
    from_port   = 21
    to_port     = 21
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "FTP pasivo 1024-1048"
    from_port   = 1024
    to_port     = 1048
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################################
# Security Group MySQL
########################################

resource "aws_security_group" "sg_mysql" {
  name        = "sg_mysql"
  description = "Permite MySQL"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


########################################
# Instancia VSFTPD
########################################

resource "aws_instance" "vsftpd" {
  ami           = "ami-0c02fb55956c7d316" # Ubuntu 22.04 us-east-1
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnets.default_subnets.ids[0]
  vpc_security_group_ids = [aws_security_group.sg_vsftpd.id]
  key_name = "FTP_ROLDAN"
  # Script externo sin incrustar
  user_data = templatefile("${path.module}/scripts/vsftpd.sh", {
  public_ip_ftp = aws_eip.elastic_ip.public_ip,
  mysql_private_ip = aws_instance.mysql.private_ip
  })


  tags = {
    Name = "Servidor-VSFTPD"
  }
}

########################################
# Elastic IP para el servidor FTP
########################################

# Crear interfaz de red secundaria
resource "aws_network_interface" "secondary" {
  subnet_id       = data.aws_subnets.default_subnets.ids[0]
  security_groups = [aws_security_group.sg_vsftpd.id]
}

# Asociar la interfaz a la instancia
resource "aws_network_interface_attachment" "attach_secondary" {
  instance_id          = aws_instance.vsftpd.id
  network_interface_id = aws_network_interface.secondary.id
  device_index         = 1
}

# Crear Elastic IP y asociarla a la interfaz secundaria
resource "aws_eip" "elastic_ip" {

}

resource "aws_eip_association" "eip_assoc" {
  network_interface_id = aws_network_interface.secondary.id
  allocation_id        = aws_eip.elastic_ip.id
}

########################################
# Instancia MySQL
########################################

resource "aws_instance" "mysql" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnets.default_subnets.ids[0]
  vpc_security_group_ids = [aws_security_group.sg_mysql.id]
  key_name = "FTP_ROLDAN"

  user_data = file("${path.module}/scripts/mysql.sh")

  tags = {
    Name = "Servidor-MySQL"
  }
}
