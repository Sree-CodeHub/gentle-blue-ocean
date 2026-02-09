# gentle-blue-ocean

Jenkins + Terraform pipeline for controlled AWS RDS MySQL major version upgrades (example: `8.0.40 -> 8.4.7`).

## What this repository now contains

- `Jenkinsfile`: production-ready CI/CD pipeline for plan/apply workflow.
- `terraform/rds-mysql-upgrade`: Terraform configuration to manage and upgrade an existing RDS MySQL instance.
- `terraform/rds-mysql-upgrade/scripts/precheck.sh`: AWS CLI precheck for current and target versions.

## End-to-end process

### 1) Prerequisites

- Jenkins agent with:
  - Terraform `>= 1.5`
  - AWS CLI v2
  - IAM credentials (via role or credentials binding)
- Existing RDS MySQL instance (already running on `8.0.40` in this use case).
- Existing Terraform backend (S3 + DynamoDB lock) configured for your environment.

### 2) One-time bootstrap for existing RDS

Terraform must manage the existing DB instance in state before upgrades:

```bash
cd terraform/rds-mysql-upgrade
terraform init
terraform workspace new prod || terraform workspace select prod
terraform import aws_db_instance.mysql mysql-prod-01
```

> Replace `mysql-prod-01` with your actual DB instance identifier.

### 3) Jenkins job configuration

Create a **Pipeline** job pointing to this repository and `Jenkinsfile`.

Pipeline parameters:

- `ACTION`: `plan` or `apply`
- `AWS_REGION`: e.g., `us-east-1`
- `TF_WORKSPACE`: e.g., `prod`
- `RDS_IDENTIFIER`: target DB identifier
- `SOURCE_ENGINE_VERSION`: `8.0.40`
- `TARGET_ENGINE_VERSION`: `8.4.7`
- `ALLOW_MAJOR_UPGRADE`: `true`
- `APPLY_IMMEDIATELY`: `false` (recommended for production)
- `AUTO_APPROVE_APPLY`: `false` (keeps manual gate)

### 4) Execution flow in Jenkins

1. Checkout code.
2. Verify Terraform/AWS CLI tools.
3. Run Terraform format + validation.
4. Run RDS precheck script:
   - Validates current engine version equals source version.
   - Validates target engine version is available in region.
5. Terraform init + workspace selection.
6. Terraform plan and artifact upload (`tfplan.txt`).
7. Manual approval gate (unless auto-approved).
8. Terraform apply (only when `ACTION=apply`).
9. Post-upgrade verification through AWS CLI.

### 5) Recommended production safeguards

- Keep `APPLY_IMMEDIATELY=false` so change occurs in maintenance window.
- Ensure DB parameter group and option group compatibility for `8.4` before applying.
- Take/manual-verify backups and snapshot retention before major upgrades.
- Use read replica / blue-green strategy for very low downtime requirements.

## Local dry-run example

```bash
cd terraform/rds-mysql-upgrade
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

## Notes

- This pipeline is designed to fail early if source version mismatches.
- `prevent_destroy = true` is enabled for safety against accidental deletion.
