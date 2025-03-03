# Mentorship Program Task: AWS VPC Endpoints Implementation

## Overview

This task is designed to enhance your understanding and practical skills in working with AWS VPC Endpoints as part of the mentorship program. You will explore the purpose of VPC Endpoints, implement both Gateway and Interface Endpoints, test security configurations, and familiarize yourself with endpoint restrictions and supported services. The task is to be completed by **March 03, 2025**, aligning with the current date context.

## Task Details

The following subtasks must be completed to successfully wrap up this assignment:

### 1. Understand the Purpose of VPC Endpoints

- **Objective**: Learn the differences and use cases for **Interface Endpoints** and **Gateway Endpoints**.
- **Action**: Research and document the key purposes of VPC Endpoints, focusing on how they enable private connectivity to AWS services without requiring public internet access.

### 2. Implement Gateway Endpoints

- **Objective**: Set up a Gateway Endpoint for an AWS service.
- **Action**: Configure a Gateway Endpoint for either **Amazon S3** or **Amazon DynamoDB** within a VPC.
- **Steps**:
  1. Create a VPC (if not already available).
  2. Add a Gateway Endpoint to the VPC.
  3. Update the route table to direct traffic to the endpoint.
  4. Test connectivity to the chosen service (e.g., upload a file to S3 or query DynamoDB).

### 3. Deploy Interface Endpoints

- **Objective**: Establish a private connection to an AWS service using an Interface Endpoint.
- **Action**: Configure an Interface Endpoint for one of the following services: **SNS**, **SQS**, or **CloudWatch**.
- **Steps**:
  1. Identify the service’s endpoint in your AWS region.
  2. Deploy the Interface Endpoint in your VPC.
  3. Associate it with a subnet and security group.
  4. Verify private connectivity to the service (e.g., publish a message to SNS or write logs to CloudWatch).

### 4. Test Endpoint Security

- **Objective**: Ensure endpoint access is secure and restricted.
- **Action**: Apply and test an endpoint policy.
- **Steps**:
  1. Create a custom endpoint policy to restrict access (e.g., limit S3 bucket access to specific buckets or CloudWatch to specific log groups).
  2. Attach the policy to the Gateway or Interface Endpoint.
  3. Test the restrictions by attempting unauthorized actions and confirming they are blocked.

### 5. Learn About VPC Endpoint Restrictions

- **Objective**: Gain a comprehensive understanding of services compatible with VPC Endpoints.
- **Action**: Read AWS documentation and memorize the list of services that support Gateway and Interface Endpoints.
- **Deliverable**: Create a summary table of supported services, including whether they use Gateway or Interface Endpoints (e.g., S3 - Gateway, SNS - Interface).

## Tools and Resources

- **AWS Management Console**: For configuring VPCs and Endpoints.
- **AWS CLI**: Optional for scripted setup and testing.
- **Documentation**: AWS VPC Endpoints official documentation.
- **Grok 3 (xAI)**: Available for assistance with research, explanations, or clarifications (e.g., web searches, X post analysis). Contact Grok 3 with specific queries if needed.

## Deliverables

- A working VPC with at least one Gateway Endpoint and one Interface Endpoint.
- A tested endpoint policy restricting access.
- A documented summary of VPC Endpoint-supported services (in table format).

## Deadline

- **Completion Date**: March 07, 2025
- Submit deliverables to the mentorship program coordinator by the deadline.

## Getting Started

1. Review AWS VPC Endpoint documentation.
2. Set up your AWS environment (VPC, subnets, etc.).
3. Begin with the Gateway Endpoint implementation and progress to Interface Endpoints.

Happy learning and good luck!
