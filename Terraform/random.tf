resource "random_shuffle" "ha_sub_pub" {
  input        = [aws_subnet.ha_wp_pub1.id, aws_subnet.ha_wp_pub1.id, aws_subnet.ha_wp_pub1.id]
  result_count = 1
}

resource "random_shuffle" "ha_az" {
  input        = [var.priv_az1, var.priv_az2, var.priv_az3]
  result_count = 1
}

