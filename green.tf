resource "aws_instance" "green" {
  count = var.enable_green_env ? var.green_instance_count : 0

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.aws_key_name
  subnet_id              = data.terraform_remote_state.vpc.outputs.public_subnet_ids[count.index % length(data.terraform_remote_state.vpc.outputs.public_subnet_ids)]
  vpc_security_group_ids = data.terraform_remote_state.vpc.outputs.app-sg_id
  #user_data              = file("bootstrap_green.sh")
  user_data              = file("bootstrap_green_nginx.sh")

  tags = {
    Name = "green-version-1.1-${count.index}"
  }
}

resource "aws_lb_target_group" "green" {
  name     = "green-tg-${random_pet.app.id}-lb"
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

resource "aws_lb_target_group_attachment" "green" {
  count            = length(aws_instance.green)
  target_group_arn = aws_lb_target_group.green.arn
  target_id        = aws_instance.green[count.index].id
  port             = 80
}
