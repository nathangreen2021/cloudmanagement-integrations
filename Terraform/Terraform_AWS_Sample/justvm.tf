# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = "test"
      Service     = "webserver"
    }
  }
}

output "public_ip" {
  value       = aws_instance.instance.public_ip
  description = "The public IP of the web server"
}
output "Webserver_Port" {
  value       = var.server_port
  description = "The public IP of the web server"
}
output "Address" {
  value       = format("http://%s:%s", aws_instance.instance.public_ip, var.server_port )
  description = "Web Server Address"
}

#-------------------------------------------------------------------------------------------------------------------

resource "aws_instance" "instance" {
  # Ubuntu Server 18.04 LTS (HVM), SSD Volume Type in us-east-2
  ami                    = "ami-0c27a26eca5dc74fc"
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.security_group.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, I was deployed with Terraform!" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  tags = {
    Name = var.sgname
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE SECURITY GROUP THAT'S APPLIED TO THE EC2 INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "security_group" {

  # Inbound HTTP from anywhere
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
