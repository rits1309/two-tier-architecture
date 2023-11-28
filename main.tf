#VPC 
resource "aws_vpc" "myvpc" {
    cidr_block = var.myvpc
tags = {
  Name ="Ritushree-vpc"
}
}
#Internet Gateway to facilate network connection to the Infrastructure.
resource "aws_internet_gateway" "int-gateway" {
    vpc_id = aws_vpc.myvpc.id

    tags = {
      Name="Int-gateway"
    } 
}
##Web Tier
#Public subnet1
resource "aws_subnet" "pub-sub1" {
    vpc_id = aws_vpc.myvpc.id
    availability_zone = "us-east-1a"
    cidr_block = var.pub-sub1

    tags = {
      Name ="pub-sub1"
    }
}
#Public route  table1
resource "aws_route_table" "pub-routeTB" {
    vpc_id = aws_vpc.myvpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.int-gateway.id
    }
    tags = {
      Name="pub-routeTB"
    }
}
#Association of public subnet1 and routetable1
resource "aws_route_table_association" "rtb-association" {
  subnet_id = aws_subnet.pub-sub1.id
  route_table_id = aws_route_table.pub-routeTB.id
}

#Public subnet2
resource "aws_subnet" "pub-sub2" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = var.pub-sub2

    tags = {
      Name ="pub-sub2"
    }
}
#Association of public subnet2 and routetable1
resource "aws_route_table_association" "rtb-association1" {
  subnet_id= aws_subnet.pub-sub2.id
  route_table_id = aws_route_table.pub-routeTB.id
}
#DB Tier
resource "aws_subnet" "pr-sub1" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = var.pr-sub1
    availability_zone = "us-east-1a"
    tags = {
      Name="private-sub1"
    }
}
#Elastic IP
resource "aws_eip" "eip" {
  //instance = aws_instance.web.id
  domain   = "vpc"
  tags = {
    name="Elastic_ip"
  }
}
#Nat Gateway 
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.pub-sub1.id

  tags = {
    Name = "gw NAT"
  }
 // depends_on = [aws_internet_gateway.int-gateway]
}
#Private route table
resource "aws_route_table" "prb-routeTB1" {
    vpc_id = aws_vpc.myvpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.nat.id
    }
    tags = {
      Name="prb-routeTB1"
    }
}

resource "aws_route_table_association" "rtb-association-prb" {
  subnet_id =aws_subnet.pr-sub1.id
  route_table_id = aws_route_table.prb-routeTB1.id
}
resource "aws_subnet" "pr-sub2" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = var.pr-sub2
    availability_zone = "us-east-1d"
    tags = {
      Name="private-sub2"
    }
}
resource "aws_route_table_association" "rtb-association-prb1" {
  subnet_id =aws_subnet.pr-sub2.id
  route_table_id = aws_route_table.prb-routeTB1.id
}
#EC2 
resource "tls_private_key" "terrafrom_generated_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
 
resource "aws_key_pair" "generated_key" {
 
  # Name of key : Write the custom name of your key
  key_name   = "${var.ssh_key}"
 
  # Public Key: The public will be generated using the reference of tls_private_key.terrafrom_generated_private_key
  public_key = tls_private_key.terrafrom_generated_private_key.public_key_openssh
}
resource "aws_instance" "website" {
    ami = var.ami
    subnet_id = aws_subnet.pub-sub1.id
    key_name = var.ssh_key
    instance_type = "t2.micro"
    tags = {
      Name="Ritushree-ec2"
    }
}
#DB Subnet group
resource "aws_db_subnet_group" "dbsubnet" {
    name = "rds-subnet-grp"
    subnet_ids =[aws_subnet.pr-sub1.id,aws_subnet.pr-sub2.id]
  
}
#DB instance
resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  username             = "admin"
  password             = "ritu1234"
  parameter_group_name = "default.mysql5.7"
  db_subnet_group_name = aws_db_subnet_group.dbsubnet.id
  skip_final_snapshot  = true

  tags = {
    Name="Rits-DB"
  }
}
#ALB
resource "aws_security_group" "alb_sec_grp" {
  name        = "alb_sec_grp"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    //ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "alb_sec_grp"
  }
}
resource "aws_lb" "app-lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sec_grp.id]
  subnets            = [aws_subnet.pr-sub1.id,aws_subnet.pr-sub2.id]

  tags = {
    Name="rits-alb"
  }
}
resource "aws_lb_target_group" "target_group" {
  name     = "alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path    = "/"
    matcher = 200
  }
}
resource "aws_lb_target_group_attachment" "target_group_attachment" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.website.id
  port             = 80
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.app-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  tags = {
    Name        = "Rits-alb"
  }
}
