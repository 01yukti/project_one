#configure security group
resource "aws_security_group" "alb_sg" {
  name   = "alb_sg"
  #vpc_id = aws_vpc.example.id
  vpc_id = var.vpc_id

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

#Configure application load balancer
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  #subnets            = [for subnet in var.aws_subnet_public : subnet.id]
  subnets = [var.aws_subnet_public[0],var.aws_subnet_public[1]]
  tags = {
    Name = "custom-alb"
  }
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

#create target groups
resource "aws_alb_target_group" "albtg" {
  name     = "albtg"
  port     = 80
  protocol = "HTTP"
  #vpc_id   = aws_vpc.example.id
  vpc_id = var.vpc_id

  health_check {
    port     = 80
    protocol = "HTTP"
    timeout  = 6
    interval = 10
  }

  tags = {
    Name = "target_group"
  }
}

output "target_group_arn" {
    value = aws_alb_target_group.albtg.arn
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "asg_tg_attach" {
  autoscaling_group_name = var.autoscaling_grp_name
  alb_target_group_arn   = var.target_group_arn
}
