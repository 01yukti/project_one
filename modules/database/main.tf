#create mysql database
resource "aws_db_instance" "project_db" {
  count = var.autocreate_db ? 1 : 0
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "8.0.27"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "admin"
  multi_az               = true
  password = data.aws_secretsmanager_secret.by-name.name
  vpc_security_group_ids = [aws_security_group.rdssg.id]
  maintenance_window      = "Mon:06:00-Mon:09:00"
  backup_window           = "09:01-11:00"
  backup_retention_period = 0
  port = 3306
  skip_final_snapshot = true
  apply_immediately = true
  db_subnet_group_name = "${aws_db_subnet_group.db-subnet.name}"

   tags = {
    Environment = "test"
  }
}

#db_subnet_group
resource "aws_db_subnet_group" "db-subnet" {
name = "db subnet group"
subnet_ids = [var.aws_subnet_private[0],var.aws_subnet_private[1]]
}

#secret
 data "aws_secretsmanager_secret" "by-name" {
  name = "rds_yukti"
}

#db security group
resource "aws_security_group" "rdssg" {
    name = "rdssg"
    vpc_id =  var.vpc_id

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [var.security_groups]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
