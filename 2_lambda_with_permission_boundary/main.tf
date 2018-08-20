provider "aws" {
  version = "~> 1.32.0"
}

data "aws_caller_identity" "current" {}

resource "aws_dynamodb_table" "app1_dynamodb_table" {
  name           = "app1_storage"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "Id"

  attribute {
    name = "Id"
    type = "N"
  }
}

resource "aws_dynamodb_table_item" "sample_data" {
  table_name = "${aws_dynamodb_table.app1_dynamodb_table.name}"
  hash_key   = "${aws_dynamodb_table.app1_dynamodb_table.hash_key}"

  item = <<EOF
{
  "Id": { "N": "1" },
  "Description": { "S": "A sample item" }
}
EOF
}

resource "aws_iam_role" "delegated_lambda_role" {
  name = "delegated-demo_lambda_role"
  permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/permission_boundary_for_delegated_user"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "delegated_lambda_role_policy" {
  name = "delegated-demo_lambda_role_policy"
  role = "${aws_iam_role.delegated_lambda_role.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:*"
      ],

      "Resource": "${aws_dynamodb_table.app1_dynamodb_table.arn}",
      "Effect": "Allow"
    }
  ]
}
EOF
}
