# Task: Deploy an AWS Application Load Balancer (ALB)

## Objective

Your task is to deploy an AWS Application Load Balancer (ALB) to distribute incoming traffic across multiple EC2 instances. You will configure the ALB with multiple target groups and verify that traffic routing works as expected.

## Requirements

- Set up an ALB within an existing VPC.
- Create at least two target groups, each associated with a different EC2 instance running a web server.
- Configure the ALB to route traffic to a default target group.
- Ensure the ALB is internet-facing and accessible via its DNS name.
- Validate traffic distribution by testing access to the ALB.

## Deliverables

1. A deployed ALB with the following:
   - Name: `my-alb` (or a name of your choice).
   - Scheme: Internet-facing.
   - Listener: HTTP on port 80.
   - At least two target groups (e.g., `web-servers-tg1` and `web-servers-tg2`) with registered EC2 instances.
2. A brief report (text or markdown) including:
   - The ALB DNS name.
   - Confirmation that traffic successfully routes to the default target group.
   - Screenshots or logs showing the ALB and target group status (e.g., "Healthy" instances).

## Optional Challenge

- Add a listener rule to route traffic to the second target group based on a specific path (e.g., `/app2`).
- Test and document the behavior when one target becomes unavailable (e.g., stopping an EC2 instance).

## Constraints

- Use an existing VPC with at least two subnets in different Availability Zones.
- EC2 instances must be pre-configured with a web server (e.g., Nginx or Apache) listening on port 80.
- Do not configure HTTPS for this task (SSL/TLS will be covered in a later section).

## Success Criteria

- The ALB is active and publicly accessible via its DNS name.
- Traffic is correctly routed to the default target group when accessing the ALB.
- Target groups show "Healthy" status for registered instances.
- (Optional) Path-based routing works if implemented.

## Resources

- AWS Management Console (EC2 section).
- [AWS ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html).
- Your existing EC2 instances and VPC setup.
