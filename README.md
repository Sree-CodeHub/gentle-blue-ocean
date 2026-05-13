# gentle-blue-ocean

Git repo for the Jenkins pipeline `testpipeline`.

## Jenkins Terraform AWS RDS MySQL

This repository contains Terraform code and a Jenkins pipeline to provision an AWS RDS MySQL instance.

## What Is Included

- `terraform/` provisions the RDS MySQL instance, subnet group, and optional security group.
- `Jenkinsfile` runs Terraform `plan`, `apply`, or `destroy`.
- `jenkins/rds-mysql-provision-job.xml` is a Jenkins multibranch Pipeline job template that points Jenkins at this repository.
- `scripts/update-jenkins-job.ps1` creates or updates the Jenkins job through the Jenkins API.

## Jenkins Credentials

Create these Jenkins credentials before running `apply`:

- `aws-credentials`: Jenkins username/password credential. Username is the AWS access key ID; password is the AWS secret access key.
- `rds-mysql-master-password`: Secret text containing the RDS master password.

The credential IDs are Jenkins parameters, so they can be changed at build time if your Jenkins uses different IDs.

## Required AWS Inputs

The pipeline requires these AWS network values:

- `VPC_ID`: VPC where the RDS security group will be created.
- `SUBNET_IDS`: comma-separated subnet IDs for the RDS subnet group. Use at least two subnets in different Availability Zones.
- `ALLOWED_CIDRS`: optional comma-separated CIDRs allowed to connect to MySQL on port `3306`.

## Local Terraform Validation

```powershell
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform fmt
terraform -chdir=terraform validate
```

## Jenkins Job Creation

After the code is pushed to GitHub, create or update the Jenkins multibranch job:

```powershell
.\scripts\update-jenkins-job.ps1 `
  -JenkinsUrl "http://localhost:8080" `
  -JobName "testpipeline" `
  -JenkinsUser "admin" `
  -JenkinsApiToken "admin" `
  -GitRepositoryUrl "https://github.com/Sree-CodeHub/gentle-blue-ocean.git" `
  -GitBranch "main" `
  -GitCredentialsId "GitHub-PAT"
```

The job defaults to `plan`. To actually provision the RDS instance, run the Jenkins build with:

- `TF_ACTION=apply`
- `CONFIRM_APPLY=APPLY_RDS`

For destroy, use:

- `TF_ACTION=destroy`
- `CONFIRM_APPLY=DESTROY_RDS`
