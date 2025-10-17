# IAMグループ
resource "aws_iam_group" "terraform_server_management_group" {
  name = "server-management-group"
  path = "/"
}

resource "aws_iam_group" "terraform_database_management_group" {
  name = "database-management-group"
  path = "/"
}

resource "aws_iam_group" "terraform_user_management_group" {
  name = "user-management-group"
  path = "/"
}

# IAMグループ・ポリシー
resource "aws_iam_group_policy" "terraform_server_management_policy" {
  name  = "server-management-policy"
  group = aws_iam_group.terraform_server_management_group.name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Action" : "ec2:*",
        "Effect" : "Allow",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "elasticloadbalancing:*",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "cloudwatch:*",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "autoscaling:*",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "iam:CreateServiceLinkedRole",
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "iam:AWSServiceName" : [
              "autoscaling.amazonaws.com",
              "ec2scheduled.amazonaws.com",
              "elasticloadbalancing.amazonaws.com",
              "spot.amazonaws.com",
              "spotfleet.amazonaws.com",
              "transitgateway.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_group_policy" "terraform_database_management_policy" {
  name  = "database-management-policy"
  group = aws_iam_group.terraform_database_management_group.name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "rds:*",
          "application-autoscaling:DeleteScalingPolicy",
          "application-autoscaling:DeregisterScalableTarget",
          "application-autoscaling:DescribeScalableTargets",
          "application-autoscaling:DescribeScalingActivities",
          "application-autoscaling:DescribeScalingPolicies",
          "application-autoscaling:PutScalingPolicy",
          "application-autoscaling:RegisterScalableTarget",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeCoipPools",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeLocalGatewayRouteTablePermissions",
          "ec2:DescribeLocalGatewayRouteTables",
          "ec2:DescribeLocalGatewayRouteTableVpcAssociations",
          "ec2:DescribeLocalGateways",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcAttribute",
          "ec2:DescribeVpcs",
          "ec2:GetCoipPoolUsage",
          "sns:ListSubscriptions",
          "sns:ListTopics",
          "sns:Publish",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "outposts:GetOutpostInstanceTypes",
          "devops-guru:GetResourceCollection"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "pi:*",
        "Resource" : [
          "arn:aws:pi:*:*:metrics/rds/*",
          "arn:aws:pi:*:*:perf-reports/rds/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : "iam:CreateServiceLinkedRole",
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "iam:AWSServiceName" : [
              "rds.amazonaws.com",
              "rds.application-autoscaling.amazonaws.com"
            ]
          }
        }
      },
      {
        "Action" : [
          "devops-guru:SearchInsights",
          "devops-guru:ListAnomaliesForInsight"
        ],
        "Effect" : "Allow",
        "Resource" : "*",
        "Condition" : {
          "ForAllValues:StringEquals" : {
            "devops-guru:ServiceNames" : [
              "RDS"
            ]
          },
          "Null" : {
            "devops-guru:ServiceNames" : "false"
          }
        }
      }
    ]
  })
}

resource "aws_iam_group_policy" "terraform_user_management_policy" {
  name  = "user-management-policy"
  group = aws_iam_group.terraform_user_management_group.name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:*",
          "organizations:DescribeAccount",
          "organizations:DescribeOrganization",
          "organizations:DescribeOrganizationalUnit",
          "organizations:DescribePolicy",
          "organizations:ListChildren",
          "organizations:ListParents",
          "organizations:ListPoliciesForTarget",
          "organizations:ListRoots",
          "organizations:ListPolicies",
          "organizations:ListTargetsForPolicy"
        ],
        "Resource" : "*"
      }
    ]
  })
}

# IAMユーザー
resource "aws_iam_user" "terraform_manager" {
  name = "test-taro"
  path = "/"
}

resource "aws_iam_user" "terraform_application" {
  name = "test-jiro"
  path = "/"
}

resource "aws_iam_user" "terraform_db" {
  name = "test-saburo"
  path = "/"
}

resource "aws_iam_user" "terraform_tech_read" {
  name = "test-shiro"
  path = "/"
}

# IAMユーザーをIAMグループに追加する
resource "aws_iam_user_group_membership" "terraform_membership_taro" {
  user = aws_iam_user.terraform_manager.name

  groups = [
    aws_iam_group.terraform_user_management_group.name,
  ]
}


resource "aws_iam_user_group_membership" "terraform_membership_jiro" {
  user = aws_iam_user.terraform_application.name

  groups = [
    aws_iam_group.terraform_server_management_group.name,
  ]
}

resource "aws_iam_user_group_membership" "terraform_membership_saburo" {
  user = aws_iam_user.terraform_db.name

  groups = [
    aws_iam_group.terraform_database_management_group.name,
  ]
}

resource "aws_iam_user_group_membership" "terraform_membership_shiro" {
  user = aws_iam_user.terraform_tech_read.name

  groups = [
    aws_iam_group.terraform_server_management_group.name,
    aws_iam_group.terraform_database_management_group.name,
  ]
}
