provider "aws" {
  region                  = var.region
}


# 1. create vpc
resource "aws_vpc" "terraform-vpc" {
  cidr_block       = var.cidr
  #cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "terraform-vpc1"
  }
}

# 2. create igw

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.terraform-vpc.id

  tags = {
    Name = "internet-gw"
  }
}

# 3. create custom public RT

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.terraform-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Public-RT"
  }
}

# 4. create 2 subnet

resource "aws_subnet" "terraform-subnet1" {
  vpc_id            = aws_vpc.terraform-vpc.id
  cidr_block        = var.cidr_subnet1
  availability_zone = var.zone1
  #cidr_block        = "10.0.1.0/24"
  #availability_zone = "ap-southeast-1a"

  tags = {
    Name = "terraform-subnet1"
  }
}

resource "aws_subnet" "terraform-subnet2" {
  vpc_id            = aws_vpc.terraform-vpc.id
  cidr_block = var.cidr_subnet2
  availability_zone = var.zone2
  #cidr_block        = "10.0.2.0/24"
  #availability_zone = "ap-southeast-1b"

  tags = {
    Name = "terraform-subnet2"
  }
}
# 5. associate subnet to public RT

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.terraform-subnet1.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.terraform-subnet2.id
  route_table_id = aws_route_table.public-rt.id
}



# 6. Create SG for instance and allow 22,80,443

resource "aws_security_group" "webserver-sg" {
  name        = "web-terraform-allow"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.terraform-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "terraform1-sg"
  }
}

# 7. create n/w interface for the instance
resource "aws_network_interface" "terraform-web-nic" {
  subnet_id       = aws_subnet.terraform-subnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.webserver-sg.id]

}

 resource "aws_network_interface" "terraform-web-nic1" {
   subnet_id       = aws_subnet.terraform-subnet2.id
   private_ips     = ["10.0.2.50"]
   security_groups = [aws_security_group.webserver-sg.id]

 }

# 8. assign an EIP to n/w interface

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.terraform-web-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [
    aws_internet_gateway.gw
  ]

}

# 9. create amazon ec2 server and install httpd
resource "aws_instance" "terraform-web-server" {
  ami = var.ami_id
  instance_type = var.instance_type
  availability_zone = var.zone1
  key_name = var.keyname
  #ami               = "ami-082105f875acab993" # ap-southeast-1
  #instance_type     = "t2.nano"
  #availability_zone = "ap-southeast-1a"
  #key_name          = "ansible-master"

  network_interface {
    network_interface_id = aws_network_interface.terraform-web-nic.id
    device_index         = 0
  }

  user_data = <<-EOF
            #!/bin/bash
            sudo yum update -y
            sudo yum install httpd -y
            sudo systemctl start httpd.service
            sudo bash -c 'echo this is my terraform module >/var/www/html/index.html'
            EOF
  tags = {
    Name = "terraform-webserver1"
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
}

# 10 Create security group for load balancer and allow 80,443 port
resource "aws_security_group" "alb" {
  name        = "terraform_alb_security_group"
  description = "Terraform load balancer security group"
  vpc_id      = "${aws_vpc.terraform-vpc.id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-alb-sg"
  }
}

#11 Create application loadbalancer

resource "aws_alb" "alb" {
  name            = "terraform-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups = ["${aws_security_group.alb.id}"]
  subnets = [aws_subnet.terraform-subnet2.id, aws_subnet.terraform-subnet1.id]
  #subnets = ["subnet-0fdff53f552a25e39", "subnet-0c1f5722acfbb2dfd"]

  # access_logs {
  #   bucket  = "aws_s3_bucket.lb_logs.bucket"
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  
  tags = {
    Name = "terraform1-alb-sg"
  }
}

# 12 Create target group
resource "aws_alb_target_group" "group" {
  name     = "terraform-alb-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.terraform-vpc.id}"

  # Alter the destination of the health check to be the login page.
  health_check {
    path = "/"
    port = 80
  }
}

# 13 Create listner for 80 port and attached to TG

resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.group.arn}"
    type             = "forward"
  }
}

# 13 Create listner for 443 port and attached to TG

# -- resource "aws_alb_listener" "listener_https" {
# --     load_balancer_arn = "${aws_alb.alb.arn}"
# --     port              = "443"
# --     protocol          = "HTTPS"
# --     ssl_policy        = "ELBSecurityPolicy-2016-08"
# --     certificate_arn   = "${var.certificate_arn}"
# --     default_action {
# --       target_group_arn = "${aws_alb_target_group.group.arn}"
# --       type             = "forward"
# --     }
# --   }


# 14 attach instance to the alb target group

resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_alb_target_group.group.arn
  target_id        = aws_instance.terraform-web-server.id
  port             = 80
}




