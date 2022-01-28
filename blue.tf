data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

#------------------------- State terraform backend location---------------------
data "terraform_remote_state" "vpc" {
  backend = "s3" 
  config = {
    bucket = "surfingjoes-terraform-states"
    key    = "deployment_test-terraform.tfstate"
    region = "us-west-1"
  }
}

data "aws_region" "current" { }

# --------------------- Determine region from backend data -------------------
provider "aws" {
  region = data.terraform_remote_state.vpc.outputs.aws_region
}

resource "aws_instance" "blue" {
  count = var.enable_blue_env ? var.blue_instance_count : 0

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.aws_key_name
  subnet_id              = data.terraform_remote_state.vpc.outputs.public_subnet_ids[count.index % length(data.terraform_remote_state.vpc.outputs.public_subnet_ids)]
  vpc_security_group_ids = data.terraform_remote_state.vpc.outputs.app-sg_id
  #user_data              = file("bootstrap_blue.sh")
  user_data              = file("bootstrap_blue_nginx.sh")

  tags = {
    Name = "blue-version-1.0-${count.index}"
  }
}

resource "aws_lb_target_group" "blue" {
  name     = "blue-tg-${random_pet.app.id}-lb"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.vpc.outputs.vpc_id

  health_check {
    port     = 80
    protocol = "HTTP"
    timeout  = 5
    interval = 10
  }
}

resource "aws_lb_target_group_attachment" "blue" {
  count            = length(aws_instance.blue)
  target_group_arn = aws_lb_target_group.blue.arn
  target_id        = aws_instance.blue[count.index].id
  port             = 80
}
