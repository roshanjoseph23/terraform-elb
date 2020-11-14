resource "aws_instance" "bastionserver" {


  ami                         = var.ami
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ha_wp_bastion.id]
  key_name                    = "project"
  subnet_id                   = random_shuffle.ha_sub_pub.result[0]
  root_block_device {
    volume_size = "8"
  }
  tags = {
    Name = "Bastion"
  }
}
