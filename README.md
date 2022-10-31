# CyberHive Project

## Introduction

This project forms part of a job application to CyberHive and takes the form of a simple Terraform and Ansible project to complete the following tasks:

- Create an AWS account
- Build a VPC with 3 subnets in 3 different availability zones
- Ensure internet access is available from the VPC
- Create a small Ubuntu based web server
- Allow SSH, HTTP and HTTPS access to the web server
- Configure the system hostname
- Set the timezone to Europe/London
- Configure iptables
  - Allow TCP 22
  - Allow TCP 80
  - Allow TCP 443
  - Allow established and related connections
  - Allow ICMP
  - Standard DROP policy
- Install Apache2
- Ensure Apache2 is running
- Ensure Apache2 is enabled on boot

Potentials improvements I would consider are listed in the [Improvements](#improvements) section.

## Terraform

This project has made some asssumptions based on lack of practical experience with Terraform. Preference has been given to getting a working environment up and running as quickly as possible, rather than creating a perfect solution.

Hard coded values have been used throughout; given more time/experience I would have used variables to allow for more flexibility for the solution.

### Terraform Output

The terraform generates 2 output values:

- The public IP address for the web server
- The private SSH key saved as a sensitive variable

To extract the private SSH key, run the following command:

```bash
terraform output -raw cyberhive_ssh_private_key > ~/.ssh/cyberhive
```

## Ansible

The ansible project include a single playbook `website.yml` which is used to configure the web server.

The play assumes that the Linux base OS is Ubuntu and therefore uses the `apt` module to install the required packages.  This could be improved by using the `package` module or by including branching logic for different base distros.

The ansible play replies on the above [terraform output of the SSH key](#terraform-output) to have been completed and then the ssh added to the SSH agent.

### Running the play

The play can be run with the following command:

```bash
ansible-playbook -i inventory-aws/dev webserver.yml
```

## Improvements

1. Use of variables in the terraform deployment to allow for more flexibility in the solution.
1. Loop the creation of the subnets to allow for more flexibility in the solution.
1. Improve handling of SSH Keys to allow for a key to be provide and fallback to a default solution of creating a new key as the current deployment does.
