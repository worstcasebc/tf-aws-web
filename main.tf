resource "aws_launch_configuration" "web" {
  name_prefix   = "web-"
  image_id      = "ami-0bd39c806c2335b95"
  instance_type = "t2.micro"
  key_name      = "mbp"

  security_groups             = [aws_security_group.webserver.id]
  associate_public_ip_address = false

  user_data = <<-USERDATA
    #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras install -y nginx1 
    sudo service nginx start
    USERDATA

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "web-elb" {
  name = "web-elb"
  security_groups = [
    aws_security_group.elb.id
  ]
  subnets = [
    aws_subnet.public-subnet[0].id,
    aws_subnet.public-subnet[1].id,
    aws_subnet.public-subnet[2].id,
  ]

  cross_zone_load_balancing = true

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:80/"
  }

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "80"
    instance_protocol = "http"
  }
}

resource "aws_autoscaling_group" "web" {
  name = "${aws_launch_configuration.web.name}-asg"

  min_size         = 1
  desired_capacity = 2
  max_size         = 4

  health_check_type = "ELB"
  load_balancers = [
    aws_elb.web-elb.id
  ]

  launch_configuration = aws_launch_configuration.web.name

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  vpc_zone_identifier = [
    aws_subnet.private-subnet[0].id,
    aws_subnet.private-subnet[1].id,
    aws_subnet.private-subnet[2].id,
  ]

  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }
}

resource "aws_instance" "bastionhost" {
  ami           = "ami-0bd39c806c2335b95"
  instance_type = "t2.micro"
  key_name      = "mbp"
  subnet_id     = aws_subnet.public-subnet[0].id

  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  tags = {
    "Name" = "bastionhost"
  }
}

resource "aws_security_group" "bastion" {
  vpc_id = aws_vpc.web.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [format("%s/32", chomp(data.http.icanhazip.body))]
  }
  tags = {
    "Name" = "bastionhost"
  }
}

resource "aws_security_group" "elb" {
  name        = "elb"
  description = "Allow HTTP through load balancer"
  vpc_id      = aws_vpc.web.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  //If you do not add this rule, you can not reach the NGIX  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "elb"
  }
}

resource "aws_security_group" "webserver" {
  vpc_id = aws_vpc.web.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    "Name" = "webserver"
  }
}

resource "aws_security_group_rule" "inbound-ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.webserver.id
}

resource "aws_security_group_rule" "inbound-http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.elb.id
  security_group_id        = aws_security_group.webserver.id
}