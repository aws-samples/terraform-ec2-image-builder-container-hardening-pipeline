resource "aws_security_group" "image_builder_sg" {
  depends_on = [
    aws_vpc.hardening_pipeline
  ]
  name        = "${var.image_name}-sg"
  description = "Security group for EC2 Image Builder"
  vpc_id      = aws_vpc.hardening_pipeline.id

  ingress {
    description = "TLS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Ephemeral"
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description      = "Allow all eggress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = local.core_tags
}