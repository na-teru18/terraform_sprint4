# EC2
# resource "aws_instance" "terraform_web_server" {
#   ami           = "ami-0d4aa492f133a3068"
#   instance_type = "t2.micro"
#   # key_name                    = aws_key_pair.terraform_my_key_pair.key_name
#   security_groups             = [aws_security_group.terraform_ec2_sg.id]
#   subnet_id                   = aws_subnet.terraform_public_subnet_1.id
#   associate_public_ip_address = true

#   user_data = <<-EOF
# #!/bin/bash
# dnf update -y
# dnf install -y nginx
# systemctl enable --now nginx
# cat <<HTML > /usr/share/nginx/html/index.html
#     <!DOCTYPE html>
# <html lang="en">
# <head>
# <meta charset="UTF-8">
# <title>API Test Example</title>
# <link rel="stylesheet" href="styles/styles.css">
# <style type="text/css">
# #result {
#   margin-top: 20px;
#   padding: 10px;
#   border: 1px solid #ccc;
#   margin-bottom: 20px;
# }
# .button {
#   background-color: #333;  /* 濃いグレー */
#   color: white;            /* テキストを白色に */
#   padding: 10px 20px;      /* 内側の余白 */
#   border: none;            /* 枠線なし */
#   border-radius: 5px;      /* 角の丸み */
#   font-size: 16px;         /* フォントサイズ */
#   cursor: pointer;         /* カーソルをポインタに */
#   transition: background-color 0.3s ease; /* 背景色の変化を滑らかに */
# }
# .button:hover {
#   background-color: #555;  /* ホバー時はやや明るいグレーに */
# }
# </style>
# </head>
# <body>
# <div id="result"></div>
# <button id="apiTestButton" class="button">API Test</button>
# <button id="databaseTestButton" class="button">Database Test</button>

# <script src="config.js"></script>
# <script src="scripts/scripts.js"></script>
# </body>
# </html>
# HTML
#   EOF

#   tags = {
#     Name = "web-server-01"
#   }
# }

# resource "aws_instance" "terraform_api_server_1" {
#   ami           = "ami-0d4aa492f133a3068"
#   instance_type = "t2.micro"
#   # key_name                    = aws_key_pair.terraform_my_key_pair.key_name
#   security_groups             = [aws_security_group.terraform_api_sg.id]
#   subnet_id                   = aws_subnet.terraform_private_subnet_3.id
#   associate_public_ip_address = false
#   tags = {
#     Name = "api-server-01"
#   }
# }

# resource "aws_instance" "terraform_api_server_2" {
#   ami           = "ami-0d4aa492f133a3068"
#   instance_type = "t2.micro"
#   # key_name                    = aws_key_pair.terraform_my_key_pair.key_name
#   security_groups             = [aws_security_group.terraform_api_sg.id]
#   subnet_id                   = aws_subnet.terraform_private_subnet_4.id
#   associate_public_ip_address = false
#   tags = {
#     Name = "api-server-02"
#   }
# }

# Elastic IP
# resource "aws_eip" "terraform_eip" {
#   instance = aws_instance.terraform_api_server.id
#   domain   = "vpc"
#   tags = {
#     Name = "public_gip"
#   }
# }
