
resource "aws_vpc" "hawp" {
  cidr_block = "172.16.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "ha_wp"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.hawp.id
  tags = {
    Name = "ha_wp_igw"
  }
}

resource "aws_subnet" "ha_wp_pub1" {
  vpc_id = aws_vpc.hawp.id
  cidr_block = "172.16.32.0/19"
  availability_zone = var.pub_az1
  map_public_ip_on_launch = true
  tags = {
    Name = "ha_wp_pub1"
  }
}

resource "aws_subnet" "ha_wp_pub2" {
  vpc_id = aws_vpc.hawp.id
  cidr_block = "172.16.64.0/19"
  availability_zone = var.pub_az2
  map_public_ip_on_launch = true
  tags = {
    Name = "ha_wp_pub2"
  }
}

resource "aws_subnet" "ha_wp_pub3" {
  vpc_id = aws_vpc.hawp.id
  cidr_block = "172.16.96.0/19"
  availability_zone = var.pub_az3
  map_public_ip_on_launch = true
  tags = {
    Name = "ha_wp_pub3"
  }
}

resource "aws_subnet" "ha_wp_priv1" {
  vpc_id = aws_vpc.hawp.id
  cidr_block = "172.16.128.0/19"
  availability_zone = var.priv_az1
  tags = {
    Name = "ha_wp_priv1"
  }
}


resource "aws_subnet" "ha_wp_priv2" {
  vpc_id = aws_vpc.hawp.id
  cidr_block = "172.16.160.0/19"
  availability_zone = var.priv_az2
  tags = {
    Name = "ha_wp_priv2"
  }
}

resource "aws_subnet" "ha_wp_priv3" {
  vpc_id = aws_vpc.hawp.id
  cidr_block = "172.16.192.0/19"
  availability_zone = var.priv_az3
  tags = {
    Name = "ha_wp_priv3"
  }
}


resource "aws_lb_target_group" "hawpmaster" {
  name        = "hawpmaster"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.hawp.id
  target_type = "instance"
  health_check {
    protocol            = "HTTP"
    port                = 80
    path                = "/wp-admin/healthcheck.html"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200"
    interval            = 30
  }
}

resource "aws_lb_target_group" "hawpslave" {
  name        = "hawpslave"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.hawp.id
  target_type = "instance"
  health_check {
    protocol            = "HTTP"
    port                = 80
    path                = "/healthcheck.html"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200"
    interval            = 30
  }
}

resource "aws_lb" "hawordpress" {
  name               = "hawordpress"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ha_wp_site.id] 
  subnets            = [aws_subnet.ha_wp_pub1.id, aws_subnet.ha_wp_pub2.id, aws_subnet.ha_wp_pub3.id]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "hawpslave01" {
  load_balancer_arn = aws_lb.hawordpress.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hawpslave.arn
  }
}

resource "aws_lb_listener" "hawpslave02" {
  load_balancer_arn = aws_lb.hawordpress.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:060377381042:certificate/fa825fa1-88d7-452c-9d06-24a85d64ee92"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hawpslave.arn
  }
}

resource "aws_lb_listener_rule" "master" {
  listener_arn = aws_lb_listener.hawpslave01.arn
  priority     = 2
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hawpmaster.arn
  }
  condition {
    path_pattern {
      values = ["/wp-admin/*", "/wp-login.php"]
    }
  }
}

resource "aws_lb_listener_rule" "master02" {
  listener_arn = aws_lb_listener.hawpslave02.arn
  priority     = 2
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hawpmaster.arn
  }
  condition {
    path_pattern {
      values = ["/wp-admin/*", "/wp-login.php"]
    }
  }
}

resource "aws_launch_configuration" "hamaster" {
  name                 = "ha_wp_master"
  image_id             = var.ami
  instance_type        = "t2.micro"
  key_name             = "project"
  security_groups      = [aws_security_group.ha_wp_site.id]
  iam_instance_profile = aws_iam_instance_profile.s3_role.name
  user_data            = templatefile("s3sfs.sh",{ efspoint = aws_efs_mount_target.wp_efs.dns_name })
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "hamasterasg" {
  name                 = "ha_wp_master_asg"
  launch_configuration = aws_launch_configuration.hamaster.name
  min_size             = 1
  max_size             = 1
  desired_capacity     = 1
  vpc_zone_identifier  = [aws_subnet.ha_wp_pub1.id, aws_subnet.ha_wp_pub1.id, aws_subnet.ha_wp_pub1.id]
  target_group_arns    = [aws_lb_target_group.hawpmaster.arn]
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "WordpressMaster"
    propagate_at_launch = true
  }
}


resource "aws_launch_configuration" "haslave" {
  name            = "ha_wp_slave"
  image_id        = var.ami
  instance_type   = "t2.micro"
  key_name        = "project"
  security_groups = [aws_security_group.ha_wp_site.id]
  user_data       = file("efs.sh")
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "haslaveasg" {
  name                 = "ha_wp_slave_asg"
  launch_configuration = aws_launch_configuration.haslave.name
  min_size             = var.min
  max_size             = var.max
  desired_capacity     = var.des
  vpc_zone_identifier  = [aws_subnet.ha_wp_pub1.id, aws_subnet.ha_wp_pub1.id, aws_subnet.ha_wp_pub1.id]
  target_group_arns    = [aws_lb_target_group.hawpslave.arn]
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "WordpressSlave"
    propagate_at_launch = true
  }
}

resource "aws_db_subnet_group" "private" {
  name       = "main"
  subnet_ids = [aws_subnet.ha_wp_priv1.id, aws_subnet.ha_wp_priv2.id, aws_subnet.ha_wp_priv3.id]

  tags = {
    Name = "My DB subnet group"
  }
}
resource "aws_db_instance" "ha_wordpress_db" {
  identifier              = "hawordpressdb"
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "mysql"
  engine_version          = "8.0.21"
  instance_class          = "db.t2.micro"
  name                    = "wordpress"
  username                = "root"
  password                = "admin123"
  parameter_group_name    = "default.mysql8.0"
  port                    = 3306
  vpc_security_group_ids  = [aws_security_group.ha_wp_db.id]
  backup_retention_period = 1
  availability_zone       = random_shuffle.ha_az.result[0]
  db_subnet_group_name    = aws_db_subnet_group.private.name
  skip_final_snapshot     = true
}


resource "aws_efs_file_system" "ha_wp_efs" {
  creation_token = "fs-hawpefs"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  tags = {
    Name = "ha_wp_efs"
  }
}

resource "aws_efs_mount_target" "wp_efs" {
  file_system_id = aws_efs_file_system.ha_wp_efs.id
  subnet_id      = random_shuffle.ha_sub_pub.result[0]
  security_groups = [aws_security_group.ha_wp_efs.id]
}

output "RDS_Endpoint" {
  value = aws_db_instance.ha_wordpress_db.address
}

output "Application_LB_DNS" {
  value = aws_lb.hawordpress.dns_name 
}

output "EFS_Mount_target" {
  value = aws_efs_mount_target.wp_efs.dns_name 
}

output "CDN_Name" {
  value = aws_cloudfront_distribution.s3cdn.domain_name
}
