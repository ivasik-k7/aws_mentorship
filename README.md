# DataArt Mentorship Program - Infrastructure Playground

This repository serves as a hands-on playground for the DataArt mentorship program, focusing on Infrastructure as Code (IaC) and cloud technologies. It contains a collection of projects and examples, organized into chapters, to demonstrate various concepts, tools, and best practices in infrastructure management. The initial chapter focuses on setting up a basic AWS VPC using Terraform, with more chapters to be added as the program progresses.

## Repository Overview

The goal of this repository is to:

- Provide practical examples of cloud infrastructure deployment.
- Explore tools like Terraform, AWS, and potentially others (e.g., Ansible, Docker).
- Build a foundation for learning and experimentation throughout the mentorship program.

Each chapter is housed in its own directory with self-contained code and documentation.

## Prerequisites

To work with the projects in this repository, you’ll need:

- [Terraform](https://www.terraform.io/downloads.html) (version 1.5+ recommended)
- [AWS CLI](https://aws.amazon.com/cli/) configured with valid credentials
- An AWS account with appropriate permissions for each chapter’s resources
- Git for cloning and managing the repository

## Getting Started

1. **Clone the Repository**:

   ```bash
   git clone <repository-url>
   cd <repository-name>
   ```

2. **Navigate to a Chapter**:
   Each chapter has its own directory. For example, to explore the VPC setup:

   ```bash
   cd vpc_initial
   ```

3. **Follow Chapter-Specific Instructions**:
   Refer to the sections below for setup and deployment instructions specific to each chapter.

## Chapters

### Chapter 1: Basic VPC Setup (`vpc_initial`)

This chapter demonstrates the creation of a basic AWS Virtual Private Cloud (VPC) with an Internet Gateway using Terraform.

#### Objectives

- Understand VPC fundamentals and Terraform basics.
- Deploy a reusable network foundation in AWS.

#### Setup Instructions

1. **Initialize Terraform**:
   ```bash
   cd vpc_initial
   terraform init
   ```
2. **Configure Variables**:
   Create a `terraform.tfvars` file or pass variables inline:
   ```hcl
   vpc_cidr = "10.0.0.0/16"
   default_tags = {
     Project = "DataArt Mentorship"
     Chapter = "VPC Initial"
   }
   ```
3. **Deploy**:
   ```bash
   terraform apply
   ```
   Confirm with `yes`.
4. **Clean Up**:
   ```bash
   terraform destroy
   ```

#### Outputs

- `vpc_id`: The ID of the created VPC (see `outputs.tf`).

#### Next Steps

- Add subnets and route tables (potential Chapter 2).

---

_More chapters will be documented here as they are developed._

## General Guidelines

- **Modularity**: Each chapter is self-contained to focus on specific learning objectives.
- **Best Practices**: Code follows IaC principles, including variable usage, tagging, and separation of concerns.
- **Safety**: Sensitive data (e.g., `.tfstate`, `.tfvars`) is excluded via `.gitignore`.

## Extending the Repository

As the mentorship program progresses, new chapters can be added by:

1. Creating a new directory (e.g., `chapter_2_subnet_config`).
2. Adding Terraform files and documentation specific to the topic.
3. Updating this `README.md` with a new section under "Chapters".

Suggestions for future chapters:

- Subnets and Route Tables
- EC2 Instance Deployment
- Security Groups and Network ACLs
- Load Balancers and Auto Scaling

## Troubleshooting

- **AWS Errors**: Verify your credentials in `~/.aws/credentials` and permissions in your AWS account.
- **Terraform Issues**: Ensure the correct version with `terraform version`.
- **Resource Conflicts**: Check the AWS console for existing resources with the same names or CIDR blocks.

## Contributions

This repository is a work in progress. Feedback and suggestions from mentors and peers are encouraged to improve the content and structure.
