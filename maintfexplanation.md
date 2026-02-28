# main.tf explanation


Primeiramente, foi criado um repositório no ECR (Elastic Container Registry) para armazenar as imagens Docker. 

``` hcl
resource "aws_ecr_repository" "foo" {
  name                 = "site-prod"
  image_tag_mutability = "MUTABLE" 
}
```

---

Foi criado um par de chaves SSH para acesso às instâncias EC2, e a chave pública foi adicionada ao Terraform para ser provisionada junto com as instâncias.

``` hcl
resource "aws_key_pair" "tf_key" {
  key_name   = "tf-aws-key"
  public_key = file("C:/Users/migue/.ssh/tf_aws_key.pub") 
}
```

---

Foi criado uma IAM Role para as instâncias EC2, permitindo que elas acessem o ECR para puxar as imagens Docker. Foi anexado uma managed policy da AWS (ECR ReadOnly). Foi também criado um instance profile para associar o IAM Role às instâncias EC2. Isto foi necessário para permitir que a instância EC2 tenha as permissões necessárias para acessar o ECR e puxar as imagens Docker durante o processo de deploy. Sem este IAM Role, a instância EC2 não teria as permissões adequadas para acessar o ECR, resultando em falhas no deploy.

``` hcl
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
```

---

Foi criado um security group para as instâncias EC2, permitindo acesso SSH (porta 22) apenas a partir do meu endereço IP público, e acesso HTTP (porta 80) e HTTPS (porta 443) de qualquer endereço IP, para permitir acesso público ao site. Também foi configurada uma regra de saída que permite todo o tráfego de saída, garantindo que as instâncias EC2 possam se comunicar com a internet.


``` hcl
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
  cidr_ipv4         = "ip/32" apenas a partir do seu IP
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.website_sg.id
  cidr_ipv4         = "0.0.0.0/0" 
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.website_sg.id
  cidr_ipv4         = "0.0.0.0/0" 
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.website_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1


}
```
Nota: O valor -1 para ip_protocol indica que todas as regras de protocolo são permitidas, ou seja, todo o tráfego de saída é permitido.

![alt text](<project_phase2/documentation/Captura de ecrã 2026-02-27 183940.png>)
**Figura 1:** Grupo de segurança criado via terraform.


---

Foi criado um recurso de instância EC2, associando o security group, o IAM instance profile e a chave SSH criados anteriormente. A instância EC2 é provisionada com uma imagem Amazon Linux 2, e é configurada para ser acessível via SSH usando a chave privada correspondente à chave pública provisionada.

``` hcl
resource "aws_instance" "website-server" {
  ami                    = "ami-0c5c1b3399d21cdc6" // Amazon Linux 2 AMI (HVM), SSD Volume Type - ami-0c5c1b3399d21cdc6
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.tf_key.key_name // associando a chave de acesso à instância, para permitir acesso via SSH
  vpc_security_group_ids = [aws_security_group.website_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.test_profile.name

  tags = {
    Name        = "website-server" 
    Provisioned = "Terraform"      
    Client      = "Tiago Miguel"   
  }
}
```
![alt text](<project_phase2/documentation/Captura de ecrã 2026-02-27 183455.png>)
**Figura 2:** Instância EC2 criada via terraform, associada ao security group e IAM Role criados anteriormente.


