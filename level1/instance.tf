#configure aws_ami
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["aws-marketplace"]
}

#configure instances
resource "aws_instance" "first-ec2" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.secgroup.id]
  key_name        = "project1"
  count           = length(local.private_cidr)
  subnet_id       = aws_subnet.private[count.index].id

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt -y install apache2
              sudo service apache2 start
              echo "<h1>hello world</h1>" | sudo tee /var/www/html/index.html
              EOF

  tags = {
    Name = "instances"
  }
}

#configure security group
resource "aws_security_group" "secgroup" {
  name   = "secgroup"
  vpc_id = aws_vpc.example.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
