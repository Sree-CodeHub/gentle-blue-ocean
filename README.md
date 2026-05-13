# gentle-blue-ocean

Git repo for the Jenkins pipeline `testpipeline`.

## Jenkins Terraform AWS RDS MySQL

This repository contains Terraform code and a Jenkins pipeline to provision an AWS RDS MySQL instance.

## What Is Included

- `terraform/` provisions the RDS MySQL instance, subnet group, and optional security group.
- `Jenkinsfile` runs Terraform `plan`, `apply`, or `destroy`.
- `jenkins/rds-mysql-provision-job.xml` is a Jenkins multibranch Pipeline job template that points Jenkins at this repository.
- `scripts/update-jenkins-job.ps1` creates or updates the Jenkins job through the Jenkins API.

## AWS Authentication

The Jenkins job can use an AWS CLI profile already configured on the Jenkins agent, so no AWS account password or AWS key credential is required in Jenkins.

Example profile setup on the Jenkins agent:

```powershell
aws configure --profile uk-pci-staging
```

Example build parameters:

```powershell
AWS_PROFILE=connect-london
AWS_REGION=eu-west-2
```

The pipeline exports `AWS_PROFILE`, `AWS_DEFAULT_REGION`, and `AWS_REGION`, then checks the active identity with:

```powershell
aws sts get-caller-identity
```

`AWS_CREDENTIALS_ID` is optional and should stay blank when using an AWS profile.

## RDS Password

By default, `MANAGE_MASTER_USER_PASSWORD=true`, so AWS Secrets Manager manages the RDS master password and no Jenkins database password credential is needed.

If you set `MANAGE_MASTER_USER_PASSWORD=false`, create a Jenkins secret text credential and pass its ID as `DB_PASSWORD_CREDENTIALS_ID`.

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

The job defaults to `validate` so automatic multibranch scans do not create AWS resources. To preview changes, run with `TF_ACTION=plan` and provide the required AWS inputs.

To actually provision the RDS instance, run the Jenkins build with:

- `TF_ACTION=apply`
- `CONFIRM_APPLY=APPLY_RDS`
- `AWS_PROFILE=<profile-configured-on-jenkins-agent>`
- `AWS_REGION=eu-west-2`

For destroy, use:

- `TF_ACTION=destroy`
- `CONFIRM_APPLY=DESTROY_RDS`
