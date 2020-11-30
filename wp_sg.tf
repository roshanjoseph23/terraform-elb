resource "aws_security_group" "ha_wp_bastion" {
  name        = "allow Apache ports"
  description = "Allow Apache inbound traffic"
  vpc_id      = aws_vpc.hawp.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ha_wp_bastion"
  }
}

resource "aws_security_group" "ha_wp_site" {
  name        = "ha_wp_site"
  description = "Allow Apache inbound traffic"
  vpc_id      = aws_vpc.hawp.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ha_wp_bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ha_wp_site"
  }
}


resource "aws_security_group" "ha_wp_db" {
  name        = "ha_wp_db"
  description = "Allow DB inbound traffic"
  vpc_id      = aws_vpc.hawp.id

  ingress {
    description     = "DB from Website"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ha_wp_site.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ha_wp_db"
  }
}

resource "aws_security_group" "ha_wp_efs" {
  name        = "ha_wp_efs"
  description = "Allow EFS inbound traffic"
  vpc_id      = aws_vpc.hawp.id

  ingress {
    description     = "EFS from Website"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ha_wp_bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ha_wp_efs"
  }
}


