# Setting up a Secure Environment with AWS WAF
![architecture.png](images%2Farchitecture.png)
This project provides a hands-on proof of concept (POC) for setting up and testing the AWS Web Application Firewall (WAF). AWS WAF is a security service that protects your web applications from common web exploits. This POC demonstrates how to create a secure AWS environment with AWS WAF and test it with simulated attacks.

## Prerequisites
Before you start, ensure you have the following:
* An AWS account with necessary permissions to create and manage the required resources. If you don't have one, you can [create a new AWS account here](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/).
* [AWS CLI installed and configured](https://aws.amazon.com/cli/)
* [Terraform installed](https://learn.hashicorp.com/tutorials/terraform/install-cli)

## Architecture Overview
* VPC and VPC Endpoints
* ECR Repository
* ECS Fargate cluster and deployment
* Application load balancer
* Route53 record
* ACM certificate
* WAF

## Configuration
Before you run the Terraform commands, you need to update a few configuration values. Open the variables.tf file (assuming it exists) and set the following:
* public_domain: This is the domain where your application will be hosted. Replace it with your domain.

## How to setup
1. Initialize Terraform
```bash
cd terraform
terraform init
```
2. Run and save a plan
```bash
terraform plan -out=plan.out
```
3. And then apply it
```bash
terraform apply plan.out
```
4. Login to ECR

Replace <AWS_CLI_PROFILE> and <AWS_REGION> with your AWS CLI profile name and AWS region, respectively.
```bash
 aws ecr get-login-password --profile <AWS_CLI_PROFILE> --region <AWS_REGION> | docker login --username AWS --password-stdin <AWS_ACCOUNT_NUMBER>.dkr.ecr.<AWS_REGION>.amazonaws.com
```
5. Build your docker container
```bash
cd docker
docker build --platform=linux/amd64 -t <AWS_ACCOUNT_NUMBER>.dkr.ecr.<AWS_REGION>.amazonaws.com/aws_waf_poc:latest .
```
6. Push your docker container
```bash
docker push <AWS_ACCOUNT_NUMBER>.dkr.ecr.<AWS_REGION>.amazonaws.com/aws_waf_poc:latest
```
## Your website is up
https://waf.<YOUR_DOMAIN>
![website.png](images%2Fwebsite.png)
## Testing
### Install Testing Tools
To simulate attacks, you need to have sqlmap and httpd installed. If you have brew installed, you can install them using the following commands:
```bash
brew install httpd sqlmap 
```
### Run Simulated Attacks
Run the bad_actor.sh script to simulate attacks:
Run bad_actor.sh
```bash
cd scripts
./bad_actor.sh
```
## Monitoring
### Check the script output
![script_output.png](images%2Fscript_output.png)
### Check WAF Logs
We can see ALLOWs from when we viewed our website.
![allow.png](images%2Fallow.png)
We can also see our DENYs after running our bash bad_actor script
![deny.png](images%2Fdeny.png)
## Cleanup
```bash
terraform destroy
```
## Resources
To learn more about the concepts and tools used in this POC, visit the following links:
* [AWS Web Application Firewall (WAF)](https://aws.amazon.com/waf/)
* [AWS CLI](https://aws.amazon.com/cli/)
* [Terraform](https://www.terraform.io/)
* [Docker](https://www.docker.com/)
* [sqlmap](http://sqlmap.org/)
* [Apache HTTP Server (httpd)](https://httpd.apache.org/)

## Feedback and Contributions
Your feedback is welcome! If you have any suggestions or find any issues, please create an issue in the GitHub repository. If you want to contribute, feel free to create a pull request.