# Cost Breakdown:
# 1. AWS Launch Template: Free (only charges for launched resources).
# 2. AWS Auto Scaling Group: Free (charges apply to managed EC2 instances).
# 3. AWS EC2 Instance:
#    - t2.micro/t3.micro: Free Tier 750 hrs/month (1st 12 months), else ~$0.0116/hr (us-east-1).
#    - EBS: Free Tier 30 GB SSD, else ~$0.10/GB-month (gp2, us-east-1).
# 4. AWS IAM Instance Profile: Free (charges only for associated role actions).

resource "aws_launch_template" "ec2" {
  name_prefix   = "${var.project_name}-${var.environment}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  key_name = var.key_name

  vpc_security_group_ids = var.security_group_ids

  user_data = var.user_data != "" ? base64encode(var.user_data) : null

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.ebs_volume_size
      volume_type           = var.ebs_volume_type
      delete_on_termination = true
      encrypted             = true
    }
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip
    subnet_id                   = var.subnet_ids[0]
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.default_tags, var.instance_tags, {
      Name = "${var.project_name}-${var.environment}-instance"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ec2" {
  count = var.enable_autoscaling ? 1 : 0

  name                = "${var.project_name}-${var.environment}-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.target_group_arns
  health_check_type   = var.health_check_type
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

  launch_template {
    id      = aws_launch_template.ec2.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(var.default_tags, var.instance_tags)
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

resource "aws_instance" "ec2" {
  count = var.enable_autoscaling ? 0 : var.instance_count

  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = var.security_group_ids
  subnet_id                   = var.subnet_ids[count.index % length(var.subnet_ids)]
  associate_public_ip_address = var.associate_public_ip
  user_data                   = var.user_data

  ebs_block_device {
    device_name           = "/dev/xvda"
    volume_size           = var.ebs_volume_size
    volume_type           = var.ebs_volume_type
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(var.default_tags, var.instance_tags, {
    Name = "${var.project_name}-${var.environment}-instance-${count.index + 1}"
  })
}

resource "aws_iam_instance_profile" "ec2" {
  count = var.iam_role_name != "" ? 1 : 0
  name  = "${var.project_name}-${var.environment}-instance-profile"
  role  = var.iam_role_name
}

resource "aws_launch_template" "ec2_with_iam" {
  count = var.iam_role_name != "" ? 1 : 0

  name_prefix   = "${var.project_name}-${var.environment}-lt-iam-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  key_name = var.key_name

  vpc_security_group_ids = var.security_group_ids

  user_data = var.user_data != "" ? base64encode(var.user_data) : null

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2[0].name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.ebs_volume_size
      volume_type           = var.ebs_volume_type
      delete_on_termination = true
      encrypted             = true
    }
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip
    subnet_id                   = var.subnet_ids[0]
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.default_tags, var.instance_tags, {
      Name = "${var.project_name}-${var.environment}-instance"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}
