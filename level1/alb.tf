#Configure application load balancer
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  tags = {
    Name = "custom-alb"
  }
}

#create target groups
resource "aws_alb_target_group" "albtg" {
  name     = "albtg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.example.id

  health_check {
    port     = 80
    protocol = "HTTP"
    timeout  = 5
    interval = 10
  }

  tags = {
    Name = "target_group"
  }
}

#configure target group attachment
resource "aws_alb_target_group_attachment" "tg_attach" {
  count            = length(local.private_cidr)
  target_group_arn = aws_alb_target_group.albtg.arn
  target_id        = aws_instance.first-ec2[count.index].id
  port             = 80
}

#configure listener
resource "aws_alb_listener" "frontend" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.albtg.arn
  }

  tags = {
    Name = "listener-frontend"
  }
}

#configure security group
resource "aws_security_group" "alb_sg" {
  name   = "alb_sg"
  vpc_id = aws_vpc.example.id

  ingress {
    from_port   = 80
    to_port     = 80
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

  tags = {
    Name = "alb_sg"
  }
}
