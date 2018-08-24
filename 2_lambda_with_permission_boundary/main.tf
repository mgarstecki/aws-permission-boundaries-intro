provider "aws" {
  version = "~> 1.32.0"
}

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

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "delegated_vm_role" {
  name                 = "delegated-demo_vm_role"
  permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/permission_boundary_for_demo_delegated_user"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "delegated_vm_role_policy" {
  name = "delegated-demo_vm_role_policy"
  role = "${aws_iam_role.delegated_vm_role.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:*",
        "s3:*"
      ],

      "Resource": "${aws_dynamodb_table.app1_dynamodb_table.arn}",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "delegated_vm_instance_profile" {
  name = "delegated-demo_vm_instance_profile"
  role = "${aws_iam_role.delegated_vm_role.name}"
}

data "aws_ami" "ubuntu_16-04" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }
}

resource "aws_security_group" "demo_vm_sg" {
  name = "demo_vm_sg"
}

resource "aws_security_group_rule" "allow_outbound" {
  type = "egress"

  from_port = 0
  to_port   = 65535
  protocol  = "all"

  security_group_id = "${aws_security_group.demo_vm_sg.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_ssh" {
  type = "ingress"

  from_port = 22
  to_port   = 22
  protocol  = "tcp"

  security_group_id = "${aws_security_group.demo_vm_sg.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_instance" "demo_vm" {
  instance_type = "t2.micro"
  ami           = "${data.aws_ami.ubuntu_16-04.id}"

  key_name = "mat-laptop"

  iam_instance_profile = "${aws_iam_instance_profile.delegated_vm_instance_profile.name}"

  tags {
    Name      = "permissions_boundary_demo_vm"
    Trigramme = "MAT"
  }

  vpc_security_group_ids = ["${aws_security_group.demo_vm_sg.id}"]
}

output "vm_ip" {
  value = "${aws_instance.demo_vm.public_ip}"
}
