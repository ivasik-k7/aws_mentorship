resource "aws_ecr_repository" "nginx" {
  name                 = local.image_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.default_tags, {
    Name = "${local.app_name}-ecr-repo"
  })
}


resource "null_resource" "build_and_push_nginx" {
  provisioner "local-exec" {
    command = <<EOT
      aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com

      docker build -t ${local.image_name}:${local.image_tag} ./docker
      docker tag ${local.image_name}:${local.image_tag} ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.image_name}:${local.image_tag}
      docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.image_name}:${local.image_tag}
    EOT
  }

  depends_on = [aws_ecr_repository.nginx]
}
