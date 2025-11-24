locals {
  sub_domain = "api.cloud-tech-teruya-hands-on.com" # 使用するサブ・ドメイン
}

# ACM（AWS Certificate Manager）で事前に発行したSSL/TLS証明書の情報
data "aws_acm_certificate" "terraform_sub_domain" {
  region   = "us-east-1"
  domain   = local.sub_domain
  statuses = ["ISSUED"]
}

# ALB
resource "aws_lb" "terraform_alb" {
  name               = "api-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.terraform_alb_sg.id]
  subnets            = [aws_subnet.terraform_public_subnet_2.id, aws_subnet.terraform_public_subnet_3.id]
  ip_address_type    = "ipv4"

  tags = {
    Environment = "api-alb"
  }
}

# # ターゲット・グループのバックエンドサーバ
# locals {
#   api_server_ids = {
#     "api-ser-1" = aws_instance.terraform_api_server_1.id, "api-ser-2" = aws_instance.terraform_api_server_2.id
#   }
# }

# ターゲット・グループ
resource "aws_lb_target_group" "terraform_alb_target_group" {
  name     = "api-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform_vpc.id
  health_check {
    interval            = 10
    path                = "/"
    port                = 80
    protocol            = "HTTP"
    timeout             = 6
    unhealthy_threshold = 3
    matcher             = "200"
  }
}

# # バックエンド・サーバをターゲット・グループとして登録する
# resource "aws_lb_target_group_attachment" "terraform_target_group_attachment" {
#   for_each         = local.api_server_ids
#   target_group_arn = aws_lb_target_group.terraform_alb_target_group.arn
#   target_id        = each.value
#   port             = 80
# }

# リスナー
resource "aws_lb_listener" "terraform_alb_listener" {
  load_balancer_arn = aws_lb.terraform_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
  certificate_arn   = data.aws_acm_certificate.terraform_sub_domain.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform_alb_target_group.arn
  }
}

# リスナー・ルール
resource "aws_lb_listener_rule" "myapp_listener_rule" {
  listener_arn = aws_lb_listener.terraform_alb_listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform_alb_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

# 起動テンプレートの作成
resource "aws_launch_template" "terraform_launch_template" {
  name          = "api-server-template"
  image_id      = "ami-080887fe54897f457" # AMIのIDを指定
  instance_type = "t2.micro"
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.terraform_api_sg.id]
  }

  depends_on = [aws_db_instance.terraform_rds]

# aws_launch_template内でuser_dataを指定する場合、User DataがBase64でエンコードされた文字列である必要がある→Terraformの組み込み関数である base64encode を使ってエンコード
  user_data = base64encode(<<-EOF
#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
echo "=== UserData開始 ==="

# MySQLクライアントのインストール 
sudo yum update -y
sudo yum install -y https://dev.mysql.com/get/mysql84-community-release-el9-1.noarch.rpm
sudo yum install mysql-community-server -y
sudo systemctl enable mysqld
sudo systemctl start mysqld

# =======================================================
# RDS接続情報
RDS_HOST="${aws_db_instance.terraform_rds.address}"
DB_USER="${aws_db_instance.terraform_rds.username}"
DB_PASSWORD="${aws_db_instance.terraform_rds.password}"
DB_NAME="${aws_db_instance.terraform_rds.db_name}"

# echo "=== RDSの接続待機を開始... ==="
# MAX_RETRIES=30
# SLEEP_TIME=5
# RETRY=0

# nc (netcat) コマンドでポート3306への接続を試みる
# ループ処理を行うwhile 現在の試行回数(RETRY)が最大試行回数(MAX_RETRIES)よりも小さい場合、doからdoneまでのコードを実行し続ける
# -lt: 左辺が右辺よりも小さい ※比較演算子
# while [ $${RETRY} -lt $${MAX_RETRIES} ]; do
#   nc -z -w 5 $${RDS_HOST} 3306

#   if [ $? -eq 0 ]; then
#     echo "RDS接続ポート (3306) の開放を確認しました。"
#     break
#   fi
#   echo "RDSポート3306が利用不可です。$${SLEEP_TIME}秒待機します (試行回数: $((RETRY + 1)))"
#   sleep $${SLEEP_TIME}
  # $((...))	算術式展開（Arithmetic Expansion）です。括弧内の計算を実行し、その結果を文字列として返します。
#   RETRY=$((RETRY + 1))
# done

# -eq: 等しい ※比較演算子
# >&2: echoのメッセージを標準エラー出力に送る
# exit: スクリプトを終了 終了コード1: スクリプトが失敗
# if [ $${RETRY} -eq $${MAX_RETRIES} ]; then
#   echo "エラー: RDSへの接続がタイムアウトしました。スクリプトを終了します。" >&2
#   exit 1
# fi

# =======================================================
# スキーマとテーブルの作成
SQL_COMMANDS=$(cat <<EOF
CREATE DATABASE IF NOT EXISTS $${DB_NAME};
CREATE TABLE IF NOT EXISTS $${DB_NAME}.Reservations (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    reservation_date DATE NOT NULL,
    number_of_people INT NOT NULL
);
INSERT INTO $${DB_NAME}.Reservations (company_name, reservation_date, number_of_people)
VALUES ('株式会社テスト', '2024-04-21', 5);
SELECT * FROM reservation_db.Reservations;
EOF)

# =======================================================
# RDSに接続
export MYSQL_PWD=$${DB_PASSWORD}
echo "$${SQL_COMMANDS}"  |  mysql -h $${RDS_HOST} -P 3306 -u $${DB_USER}

# SQL実行コマンドの終了ステータスを確認(RDS接続を切断)
SQL_EXIT_CODE=$?

# 実行結果の確認
if [ $${SQL_EXIT_CODE} -eq 0 ]; then
    echo "RDSへの接続とテーブル作成に成功しました。"
else
    echo "RDSへの接続またはテーブル作成に失敗しました。" >&2
fi

# =======================================================
# 設定ファイルの作成
mkdir -p cloudtech-reservation-api

cat <<EOF_ENV > cloudtech-reservation-api/.env
DB_USERNAME=$${DB_USER}
DB_PASSWORD=$${DB_PASSWORD}
DB_SERVERNAME=$${RDS_HOST}
DB_PORT=3306
DB_NAME=$${DB_NAME}
EOF_ENV

# .envファイルの設定を反映させるためにプロセスの再起動を実行 ※-t オプションはPIDのみを取得する
PID=$(sudo lsof -i :8080 -t)

if [ ! -z "$${PID}" ]; then
    sudo kill -9 $${PID}
fi

# =======================================================
# データベースURL
TARGET_URL="http://localhost:8080/test"

# データベースへの接続確認
curl -s -f -o /dev/null $${TARGET_URL}

# curlコマンドの終了ステータスを確認
CURL_EXIT_CODE=$?

# 実行結果の確認
if [ $${CURL_EXIT_CODE} -eq 0 ]; then
    echo "データベース接続テストに成功しました。"
else
    echo "データベース接続テストに失敗しました。" >&2
fi

# exit: スクリプトを終了 終了コード0: スクリプトが正常終了(成功)
exit 0
EOF
  )
}

# Auto Scaling Group
resource "aws_autoscaling_group" "terraform_auto_scaling_group" {
  name                      = "api-autoscaling"
  max_size                  = 4 # 最大キャパシティ
  min_size                  = 2 # 最小キャパシティ
  desired_capacity          = 2 # 希望するキャパシティ
  health_check_grace_period = 300
  health_check_type         = "EC2"
  launch_template {
    id      = aws_launch_template.terraform_launch_template.id
    version = "$Latest"
  }
  vpc_zone_identifier = [aws_subnet.terraform_private_subnet_3.id, aws_subnet.terraform_private_subnet_4.id]
  target_group_arns   = [aws_lb_target_group.terraform_alb_target_group.arn]
}

# Autoscaling Policy
resource "aws_autoscaling_policy" "terraform_asg_policy" {
  name                   = "api-asg-policy"
  autoscaling_group_name = aws_autoscaling_group.terraform_auto_scaling_group.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
