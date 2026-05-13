# Jenkins Terraform AWS RDS MySQL

This repository contains Terraform code and a Jenkins pipeline to provision an AWS RDS MySQL instance.

## What Is Included

- `terraform/` provisions the RDS MySQL instance, subnet group, and optional security group.
- `Jenkinsfile` runs Terraform `plan`, `apply`, or `destroy`.
- `jenkins/rds-mysql-provision-job.xml` is a Jenkins Pipeline job template that points Jenkins at this repository.
- `scripts/update-jenkins-job.ps1` creates or updates the Jenkins job through the Jenkins API.

## Jenkins Credentials

Create these Jenkins credentials before running `apply`:

- `aws-credentials`: AWS credentials usable by the Jenkins AWS Credentials plugin.
- `rds-mysql-master-password`: Secret text containing the RDS master password.

The credential IDs are Jenkins parameters, so they can be changed at build time if your Jenkins uses different IDs.

## Required AWS Inputs

The pipeline requires these AWS network values:

- `VPC_ID`: VPC where the RDS security group will be created.
- `SUBNET_IDS`: comma-separated subnet IDs for the RDS subnet group. Use at least two subnets in different Availability Zones for normal RDS deployments.
- `ALLOWED_CIDRS`: optional comma-separated CIDRs allowed to connect to MySQL on port `3306`.

## Local Terraform Validation

```powershell
terraform -chdir=terraform fmt
terraform -chdir=terraform validate
```

`terraform validate` needs provider plugins, so run `terraform -chdir=terraform init` first when network access is available.

## Jenkins Job Creation

After the code is pushed to GitHub, create or update the Jenkins job:

```powershell
.\scripts\update-jenkins-job.ps1 `
  -JenkinsUrl "http://localhost:8080" `
  -JobName "testpipeline" `
  -JenkinsUser "<jenkins-user>" `
  -JenkinsApiToken "<jenkins-api-token>" `
  -GitRepositoryUrl "https://github.com/<owner>/<repo>.git" `
  -GitBranch "main" `
  -GitCredentialsId ""
```

The job defaults to `plan`. To actually provision the RDS instance, run the Jenkins build with:

- `TF_ACTION=apply`
- `CONFIRM_APPLY=APPLY_RDS`

For destroy, use:

- `TF_ACTION=destroy`
- `CONFIRM_APPLY=DESTROY_RDS`

