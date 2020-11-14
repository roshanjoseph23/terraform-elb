resource "aws_route_table" "ha_rtb_pub" {
  vpc_id = aws_vpc.hawp.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }  
  tags = {
    Name = "ha_rtb_pub"
  }
}

resource "aws_route_table_association" "rtb_sub_pub" {
  subnet_id      = aws_subnet.ha_wp_pub1.id
  route_table_id = aws_route_table.ha_rtb_pub.id
}

resource "aws_route_table_association" "rtb_sub_pub2" {
  subnet_id      = aws_subnet.ha_wp_pub2.id
  route_table_id = aws_route_table.ha_rtb_pub.id
}

resource "aws_route_table_association" "rtb_sub_pub3" {
  subnet_id      = aws_subnet.ha_wp_pub3.id
  route_table_id = aws_route_table.ha_rtb_pub.id
}


resource "aws_route_table" "ha_rtb_priv" {
  vpc_id = aws_vpc.hawp.id
  tags = {
    Name = "ha_rtb_priv"
  }
}

resource "aws_route_table_association" "rtb_sub_priv" {
  subnet_id      = aws_subnet.ha_wp_priv1.id
  route_table_id = aws_route_table.ha_rtb_priv.id
}

resource "aws_route_table_association" "rtb_sub_priv2" {
  subnet_id      = aws_subnet.ha_wp_priv2.id
  route_table_id = aws_route_table.ha_rtb_priv.id
}

resource "aws_route_table_association" "rtb_sub_priv3" {
  subnet_id      = aws_subnet.ha_wp_priv3.id
  route_table_id = aws_route_table.ha_rtb_priv.id
}


