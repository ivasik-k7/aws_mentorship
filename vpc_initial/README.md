# AWS VPC (Virtual Private Cloud) - Mentorship Program Exercises

This project outlines a series of hands-on exercises to explore AWS Virtual Private Cloud (VPC) concepts using Terraform. It progresses from basic VPC creation to advanced networking setups, focusing on practical implementation, security, and inter-VPC connectivity. Each exercise builds on the previous one, offering a comprehensive learning path for cloud infrastructure management.

## Exercise Objectives

- Master VPC creation, configuration, and networking components.
- Understand subnet types (public vs. private) and their use cases.
- Implement connectivity solutions like VPC Peering and Transit Gateway.
- Configure secure access controls and Internet connectivity.
- Explore multi-VPC and multi-account architectures.

---

## Chapter 1: Basic VPC Setup with Private Subnets

### 1.1 Create and Configure a Custom VPC

- **Task**: Provision a VPC with a CIDR block (e.g., `10.0.0.0/16`) using Terraform.
- **Details**:
  - Enable DNS support and hostnames.
  - Create two private subnets (e.g., `10.0.1.0/24` and `10.0.2.0/24`) in different Availability Zones (AZs) for resilience.
- **Goal**: Establish a foundational private network isolated from the Internet.

### 1.2 Implement VPC Peering Between Subnets

- **Task**: Set up peering within the same VPC to ensure communication between the two private subnets.
- **Details**:
  - Configure route tables to allow traffic between subnets (e.g., `10.0.1.0/24` ↔ `10.0.2.0/24`).
  - Note: Peering is typically between VPCs, but this step simulates intra-VPC routing for learning purposes.
- **Goal**: Understand routing basics within a VPC.

### 1.3 Deploy EC2 Instances and Test Connectivity

- **Task**: Launch two EC2 instances, one in each private subnet.
- **Details**:
  - Use a basic AMI (e.g., Amazon Linux 2).
  - Test connectivity using `ping` (ICMP) between instances.
- **Goal**: Verify subnet-to-subnet communication within the VPC.

---

## Chapter 2: Expanding to Public Subnet and Internet Access

### 2.1 Create a Public Subnet

- **Task**: Add a third subnet (e.g., `10.0.3.0/24`) designated as public.
- **Details**:
  - Place it in a separate AZ for diversity.
  - Update route tables to connect all three subnets (public and two private).
- **Goal**: Learn the distinction between public and private subnets.

### 2.2 Set Up Internet Access with an Internet Gateway

- **Task**: Attach an Internet Gateway (IGW) to the VPC and configure routing.
- **Details**:
  - Add a route in the public subnet’s route table (e.g., `0.0.0.0/0` → IGW).
  - Deploy an EC2 instance in the public subnet and test external connectivity (e.g., `curl google.com`).
- **Goal**: Enable outbound and inbound Internet access for public resources.

### 2.3 Deploy a NAT Gateway for Private Subnets

- **Task**: Configure a NAT Gateway in the public subnet to allow private subnets outbound Internet access.
- **Details**:
  - Allocate an Elastic IP (EIP) for the NAT Gateway.
  - Update private subnet route tables (e.g., `0.0.0.0/0` → NAT Gateway).
  - Test outbound connectivity from private EC2 instances (e.g., `yum update`).
- **Goal**: Securely enable Internet access for private resources without exposing them.

### 2.4 Configure Security Controls

- **Task**: Set up Network ACLs (NACLs) and Security Groups for EC2 instances.
- **Details**:
  - **Security Groups**: Allow inbound traffic for FTP (ports 20-21), ICMP (ping), HTTP (port 80), SSH (port 22) only.
  - **NACLs**: Mirror the Security Group rules at the subnet level, denying all other traffic.
  - Test connectivity (e.g., SSH into public instance, ping between instances).
- **Goal**: Implement layered security for network traffic control.

### 2.5 Set Up a Transit Gateway

- **Task**: Replace intra-VPC routing with a Transit Gateway to connect all three subnets.
- **Details**:
  - Create a Transit Gateway and attach the VPC.
  - Update route tables to route subnet traffic through the Transit Gateway.
  - Validate connectivity across all subnets.
- **Goal**: Explore a scalable solution for multi-subnet or multi-VPC connectivity.

---

## Chapter 3: Multi-VPC Scenarios

### 3.1 Private Subnets in Two Different VPCs with VPC Peering

- **Task**: Repeat the setup with two VPCs (e.g., VPC1: `10.0.0.0/16`, VPC2: `10.1.0.0/16`), each with a private subnet.
- **Details**:
  - Configure VPC Peering between the two VPCs.
  - Deploy an EC2 instance in each subnet and update route tables for cross-VPC communication.
  - Test connectivity (e.g., `ping` between instances).
- **Goal**: Understand inter-VPC communication within the same AWS account.

### 3.2 Private Subnets in Two VPCs Across Different AWS Accounts

- **Task**: Extend the previous exercise to two separate AWS accounts.
- **Details**:
  - In Account A: Create VPC1 (`10.0.0.0/16`) with a private subnet.
  - In Account B: Create VPC2 (`10.1.0.0/16`) with a private subnet.
  - Set up VPC Peering (requires accepter/requester handshake across accounts).
  - Deploy EC2 instances and configure routing.
  - Test cross-account connectivity.
- **Goal**: Learn cross-account VPC peering and its real-world applications.

---

## Additional Enhancements

- **Automation**: Use Terraform modules to modularize VPC, subnet, and gateway configurations.
- **Validation**: Add scripts (e.g., Bash or Python) to automate connectivity tests.
- **Monitoring**: Integrate CloudWatch to log and monitor traffic or instance health.
- **Cost Management**: Tag all resources and estimate costs using AWS Cost Explorer.
- **Cleanup**: Ensure `terraform destroy` is documented to avoid lingering resources.

---

## Learning Outcomes

- Proficiency in VPC design, subnet segmentation, and routing.
- Hands-on experience with Terraform for IaC.
- Understanding of AWS networking components (IGW, NAT Gateway, Transit Gateway, VPC Peering).
- Practical knowledge of security configurations and multi-account architectures.
