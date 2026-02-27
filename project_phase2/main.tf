resource "aws_ecr_repository" "foo" {
  name                 = "site-prod"
  image_tag_mutability = "MUTABLE" // optional, defaults to MUTABLE
}

resource "aws_key_pair" "tf_key" {
  key_name   = "tf-aws-key"
  public_key = file("C:/Users/migue/.ssh/tf_aws_key.pub") // caminho para a chave pública, que deve ser gerada previamente usando ssh-keygen ou similar
}

resource "aws_iam_role" "iam_role" {
  name = "ECR-EC2-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "test_profile" {
  name = "ECR-EC2-Profile"
  role = aws_iam_role.iam_role.name
}


resource "aws_instance" "website-server" {
  ami                    = "ami-0c5c1b3399d21cdc6" // Amazon Linux 2 AMI (HVM), SSD Volume Type - ami-0c5c1b3399d21cdc6
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.tf_key.key_name // associando a chave de acesso à instância, para permitir acesso via SSH
  vpc_security_group_ids = [aws_security_group.website_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.test_profile.name

  tags = {
    Name        = "website-server" // o nome da instancia é passado como tag, para facilitar a identificação.
    Provisioned = "Terraform"      // tag para identificar que a instancia foi provisionada por terraform
    Client      = "Tiago Miguel"   // tag para identificar o cliente
  }
}

resource "aws_security_group" "website_sg" {
  name        = "website-sg"
  description = "Security group for website server"
  vpc_id      = "vpc-0c747c52a1492d6d2"

  tags = {
    Name        = "website-sg"
    Provisioned = "Terraform"
    Client      = "Tiago Miguel"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.website_sg.id
  cidr_ipv4         = "ip/32" // substitua pelo seu endereço IP público, para permitir acesso SSH apenas a partir do seu IP
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.website_sg.id
  cidr_ipv4         = "0.0.0.0/0" // qualquer endereço IP pode acessar a porta 80, para permitir acesso HTTP público
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.website_sg.id
  cidr_ipv4         = "0.0.0.0/0" // qualquer endereço IP pode acessar a porta 443, para permitir acesso HTTPS público
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.website_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1

}



