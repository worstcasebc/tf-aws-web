resource "aws_instance" "web" {
  ami           = "ami-0bd39c806c2335b95"
  instance_type = "t2.micro"
  key_name      = "mbp"

  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id              = aws_subnet.public-subnet[0].id

  # nginx installation
  # provisioner "remote-exec" {
  #   connection {
  #     type        = "ssh"
  #     user        = "ec2-user"
  #     host        = self.public_ip
  #     private_key = file("/infra/.ssh/id_rsa")
  #     agent       = false
  #     timeout     = "2m"
  #   }
  #   inline = [
  #     "sudo amazon-linux-extras install -y nginx1",
  #     "sudo service nginx start",
  #   ]
  # }

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras install -y nginx1 
    sudo service nginx start
    EOF

  tags = {
    "Name" = "WebserverByTerraform"
  }
}
