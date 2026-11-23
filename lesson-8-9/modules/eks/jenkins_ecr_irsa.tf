data "aws_iam_policy_document" "jenkins_ecr_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:jenkins:jenkins"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "jenkins_ecr" {
  name               = "${var.cluster_name}-jenkins-ecr-role"
  assume_role_policy = data.aws_iam_policy_document.jenkins_ecr_assume_role.json
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  role       = aws_iam_role.jenkins_ecr.name
}

output "jenkins_ecr_role_arn" {
  value = aws_iam_role.jenkins_ecr.arn
}
