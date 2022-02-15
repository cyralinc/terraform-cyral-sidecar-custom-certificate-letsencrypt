
data "aws_iam_policy_document" "lambda_execution" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_execution_policy" {
  # Cloudwatch permissions
  statement {
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:${local.partition}:logs:${local.region}:${local.account_id}:*"
    ]
  }
  statement {
    actions = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }

  # Route53 permissions
  statement {
    actions = [
      "route53:GetChange",
      "route53:ChangeResourceRecordSets"
    ]
    resources = [
      "arn:${local.partition}:route53:::change/*",
      "arn:${local.partition}:route53:::hostedzone/*"
    ]
  }
  statement {
    actions = ["route53:ListHostedZones"]
    resources = ["*"]
  }

  # Secrets Manager permissions
  # TODO: refactor -aholmquist 2022-02-14
  statement {
    actions = (var.sidecar_secrets_manager_role_arn == "") ? ([
      "secretsmanager:CreateSecret",
      "secretsmanager:DeleteSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:UpdateSecret"
      ]) : ([
      "sts:AssumeRole"
    ])

    resources = (var.sidecar_secrets_manager_role_arn == "") ? ([
      "arn:${local.partition}:secretsmanager:${local.region}:${local.account_id}:secret:/cyral/sidecar-certificate/*"
      ]) : ([
      var.sidecar_secrets_manager_role_arn
    ])
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda_execution_role"
  path               = "/" # TODO: Test -aholmquist 2022-02-14
  assume_role_policy = data.aws_iam_policy_document.lambda_execution.json
}

resource "aws_iam_policy" "lambda_execution_policy" {
  name   = "lambda_execution_policy"
  path   = "/" # TODO: Test -aholmquist 2022-02-14
  policy = data.aws_iam_policy_document.lambda_execution_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}