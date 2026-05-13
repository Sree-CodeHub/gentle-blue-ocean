# gentle-blue-ocean

Git repo for the Jenkins pipeline `testpipeline`.

## Jenkins Terraform AWS Data Services

This repository contains Terraform code and a Jenkins pipeline to provision and operate AWS data services.

## What Is Included

- `terraform/` provisions RDS MySQL, Aurora MySQL, ElastiCache Redis/Valkey, or ElastiCache Memcached.
- `Jenkinsfile` runs `validate`, `plan`, `apply`, `destroy`, or `reboot`.
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

For `plan`, `apply`, or `destroy`, the pipeline requires these AWS network values:

- `VPC_ID`: VPC where the RDS security group will be created.
- `SUBNET_IDS`: comma-separated subnet IDs. Use at least two subnets in different Availability Zones.
- `ALLOWED_CIDRS`: optional comma-separated CIDRs allowed to connect to the service port.

## Supported Resources

Set `RESOURCE_TYPE` to one of:

- `rds-mysql`
- `aurora-mysql`
- `elasticache-redis`
- `elasticache-memcached`

Set `RESOURCE_IDENTIFIER` to the RDS instance identifier, Aurora cluster identifier, ElastiCache replication group ID, or ElastiCache cluster ID.

Use `ENGINE_VERSION` to choose the engine version. Examples:

- RDS MySQL: `8.0`
- Aurora MySQL: `8.0.mysql_aurora.3.08.0`
- ElastiCache Redis: `7.1`
- ElastiCache Memcached: `1.6.22`

## Modify Or Resize

Use `TF_ACTION=plan` to preview changes and `TF_ACTION=apply` with `CONFIRM_APPLY=APPLY_RESOURCE` to apply them.

Common resize parameters:

- `INSTANCE_CLASS`: RDS or Aurora instance class.
- `ALLOCATED_STORAGE`: RDS MySQL storage in GB.
- `MAX_ALLOCATED_STORAGE`: RDS MySQL autoscaling storage limit in GB.
- `AURORA_INSTANCE_COUNT`: number of Aurora instances.
- `AURORA_STORAGE_TYPE`: optional Aurora storage type, such as `aurora-iopt1`.
- `CACHE_NODE_TYPE`: ElastiCache node type.
- `CACHE_NUM_NODES`: number of ElastiCache nodes.

## Reboot

Use `TF_ACTION=reboot` and `CONFIRM_APPLY=REBOOT_RESOURCE`.

`REBOOT_TARGET_ID` is optional and defaults to `RESOURCE_IDENTIFIER`.

For ElastiCache, set `REBOOT_CACHE_NODE_IDS`, for example `0001` or `0001,0002`.

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

To provision or modify the selected service, run the Jenkins build with:

- `TF_ACTION=apply`
- `CONFIRM_APPLY=APPLY_RESOURCE`
- `RESOURCE_TYPE=<resource-type>`
- `RESOURCE_IDENTIFIER=<resource-identifier>`
- `ENGINE_VERSION=<engine-version>`
- `AWS_PROFILE=<profile-configured-on-jenkins-agent>`
- `AWS_REGION=eu-west-2`

For destroy, use:

- `TF_ACTION=destroy`
- `CONFIRM_APPLY=DESTROY_RESOURCE`
