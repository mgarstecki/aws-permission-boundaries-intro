provider "aws" {
  version = "~> 1.32.0"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "permission_boundary_for_delegated_user" {
  name = "permission_boundary_for_demo_delegated_user"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_user" "delegated_user" {
  name = "demo_delegated_user"
}

resource "aws_iam_user_policy" "permissions_for_delegated_user" {
  name = "permissions_for_delegated_user"

  user = "${aws_iam_user.delegated_user.name}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "dynamodb:*",
          "ec2:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
            "iam:CreateRole",
            "iam:DeleteRole",
            "iam:PassRole",
            "iam:PutRolePolicy",
            "iam:DeleteRolePolicy"
        ],
        "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/delegated-*",

        "Condition": {
          "StringEquals": {
              "iam:PermissionsBoundary": "${aws_iam_policy.permission_boundary_for_delegated_user.arn}"
          }
        }
      }
    ]
  }
EOF
}
