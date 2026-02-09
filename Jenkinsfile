pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
    ansiColor('xterm')
  }

  parameters {
    choice(name: 'ACTION', choices: ['plan', 'apply'], description: 'Terraform action to run')
    string(name: 'AWS_REGION', defaultValue: 'us-east-1', description: 'AWS region for RDS instance')
    string(name: 'TF_WORKSPACE', defaultValue: 'prod', description: 'Terraform workspace/environment')
    string(name: 'RDS_IDENTIFIER', defaultValue: 'mysql-prod-01', description: 'RDS DB instance identifier')
    string(name: 'SOURCE_ENGINE_VERSION', defaultValue: '8.0.40', description: 'Current MySQL engine version')
    string(name: 'TARGET_ENGINE_VERSION', defaultValue: '8.4.7', description: 'Target MySQL engine version')
    booleanParam(name: 'ALLOW_MAJOR_UPGRADE', defaultValue: true, description: 'Must be true for major version upgrades')
    booleanParam(name: 'APPLY_IMMEDIATELY', defaultValue: false, description: 'Apply immediately or in next maintenance window')
    booleanParam(name: 'AUTO_APPROVE_APPLY', defaultValue: false, description: 'Skip manual approval when ACTION=apply')
  }

  environment {
    TF_DIR = 'terraform/rds-mysql-upgrade'
    TF_IN_AUTOMATION = 'true'
    AWS_DEFAULT_REGION = "${params.AWS_REGION}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Tooling checks') {
      steps {
        sh '''
          set -euo pipefail
          terraform -version
          aws --version
        '''
      }
    }

    stage('Terraform fmt + validate') {
      steps {
        dir("${TF_DIR}") {
          sh '''
            set -euo pipefail
            terraform fmt -check -recursive
            terraform init -backend=false
            terraform validate
          '''
        }
      }
    }

    stage('RDS prechecks') {
      steps {
        dir("${TF_DIR}") {
          sh '''
            set -euo pipefail
            chmod +x scripts/precheck.sh
            scripts/precheck.sh \
              "$RDS_IDENTIFIER" \
              "$AWS_REGION" \
              "$SOURCE_ENGINE_VERSION" \
              "$TARGET_ENGINE_VERSION"
          '''
        }
      }
    }

    stage('Terraform init') {
      steps {
        dir("${TF_DIR}") {
          sh '''
            set -euo pipefail
            terraform init
            terraform workspace select "$TF_WORKSPACE" || terraform workspace new "$TF_WORKSPACE"
          '''
        }
      }
    }

    stage('Terraform plan') {
      steps {
        dir("${TF_DIR}") {
          sh '''
            set -euo pipefail
            terraform plan -out=tfplan.binary \
              -var="aws_region=$AWS_REGION" \
              -var="db_instance_identifier=$RDS_IDENTIFIER" \
              -var="source_engine_version=$SOURCE_ENGINE_VERSION" \
              -var="target_engine_version=$TARGET_ENGINE_VERSION" \
              -var="allow_major_version_upgrade=$ALLOW_MAJOR_UPGRADE" \
              -var="apply_immediately=$APPLY_IMMEDIATELY"
            terraform show -no-color tfplan.binary > tfplan.txt
          '''
        }
      }
      post {
        always {
          archiveArtifacts artifacts: 'terraform/rds-mysql-upgrade/tfplan.txt', fingerprint: true
        }
      }
    }

    stage('Manual approval') {
      when {
        allOf {
          expression { params.ACTION == 'apply' }
          expression { params.AUTO_APPROVE_APPLY == false }
        }
      }
      steps {
        timeout(time: 30, unit: 'MINUTES') {
          input message: "Approve MySQL major upgrade ${params.SOURCE_ENGINE_VERSION} -> ${params.TARGET_ENGINE_VERSION} for ${params.RDS_IDENTIFIER}?", ok: 'Approve Apply'
        }
      }
    }

    stage('Terraform apply') {
      when {
        expression { params.ACTION == 'apply' }
      }
      steps {
        dir("${TF_DIR}") {
          sh '''
            set -euo pipefail
            terraform apply -auto-approve tfplan.binary
          '''
        }
      }
    }

    stage('Post-upgrade verification') {
      when {
        expression { params.ACTION == 'apply' }
      }
      steps {
        sh '''
          set -euo pipefail
          aws rds describe-db-instances \
            --db-instance-identifier "$RDS_IDENTIFIER" \
            --region "$AWS_REGION" \
            --query 'DBInstances[0].{Status:DBInstanceStatus,EngineVersion:EngineVersion,Pending:PendingModifiedValues}' \
            --output table
        '''
      }
    }
  }
}
