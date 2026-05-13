import groovy.json.JsonOutput

def runCommand(String command) {
  if (isUnix()) {
    sh command
  } else {
    bat command
  }
}

def csvList(String value) {
  if (!value?.trim()) {
    return []
  }

  return value
    .split(',')
    .collect { it.trim() }
    .findAll { it }
}

pipeline {
  agent any

  options {
    ansiColor('xterm')
    timestamps()
    disableConcurrentBuilds()
  }

  parameters {
    choice(name: 'TF_ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Terraform action to run.')
    string(name: 'CONFIRM_APPLY', defaultValue: '', description: 'Use APPLY_RDS for apply or DESTROY_RDS for destroy.')
    string(name: 'AWS_REGION', defaultValue: 'us-east-1', description: 'AWS region for the RDS instance.')
    string(name: 'AWS_CREDENTIALS_ID', defaultValue: 'aws-credentials', description: 'Jenkins AWS credentials ID.')
    string(name: 'DB_PASSWORD_CREDENTIALS_ID', defaultValue: 'rds-mysql-master-password', description: 'Jenkins secret text credential ID for the RDS master password.')
    string(name: 'DB_IDENTIFIER', defaultValue: 'jenkins-rds-mysql', description: 'RDS instance identifier.')
    string(name: 'DB_NAME', defaultValue: 'appdb', description: 'Initial database name.')
    string(name: 'DB_USERNAME', defaultValue: 'adminuser', description: 'RDS master username.')
    string(name: 'ENGINE_VERSION', defaultValue: '8.0', description: 'MySQL engine version.')
    string(name: 'INSTANCE_CLASS', defaultValue: 'db.t3.micro', description: 'RDS instance class.')
    string(name: 'ALLOCATED_STORAGE', defaultValue: '20', description: 'Initial storage in GB.')
    string(name: 'MAX_ALLOCATED_STORAGE', defaultValue: '100', description: 'Maximum autoscaled storage in GB.')
    string(name: 'VPC_ID', defaultValue: '', description: 'Target VPC ID.')
    text(name: 'SUBNET_IDS', defaultValue: '', description: 'Comma-separated subnet IDs for the RDS subnet group.')
    text(name: 'ALLOWED_CIDRS', defaultValue: '', description: 'Comma-separated CIDRs allowed to connect to MySQL.')
    booleanParam(name: 'PUBLICLY_ACCESSIBLE', defaultValue: false, description: 'Whether the RDS instance should be public.')
    booleanParam(name: 'SKIP_FINAL_SNAPSHOT', defaultValue: true, description: 'Skip final snapshot on destroy.')
  }

  environment {
    TF_IN_AUTOMATION = 'true'
    TF_INPUT = 'false'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Validate Parameters') {
      steps {
        script {
          if (!params.VPC_ID?.trim()) {
            error('VPC_ID is required.')
          }
          if (csvList(params.SUBNET_IDS).isEmpty()) {
            error('SUBNET_IDS must include at least one subnet ID.')
          }
          if (params.TF_ACTION == 'apply' && params.CONFIRM_APPLY != 'APPLY_RDS') {
            error('Set CONFIRM_APPLY to APPLY_RDS before provisioning the RDS instance.')
          }
          if (params.TF_ACTION == 'destroy' && params.CONFIRM_APPLY != 'DESTROY_RDS') {
            error('Set CONFIRM_APPLY to DESTROY_RDS before destroying the RDS instance.')
          }
        }
      }
    }

    stage('Write Terraform Variables') {
      steps {
        script {
          def tfvars = [
            aws_region           : params.AWS_REGION.trim(),
            db_identifier        : params.DB_IDENTIFIER.trim(),
            db_name              : params.DB_NAME.trim(),
            db_username          : params.DB_USERNAME.trim(),
            engine_version       : params.ENGINE_VERSION.trim(),
            instance_class       : params.INSTANCE_CLASS.trim(),
            allocated_storage    : params.ALLOCATED_STORAGE.toInteger(),
            max_allocated_storage: params.MAX_ALLOCATED_STORAGE.toInteger(),
            vpc_id               : params.VPC_ID.trim(),
            subnet_ids           : csvList(params.SUBNET_IDS),
            allowed_cidr_blocks  : csvList(params.ALLOWED_CIDRS),
            publicly_accessible  : params.PUBLICLY_ACCESSIBLE,
            skip_final_snapshot  : params.SKIP_FINAL_SNAPSHOT,
            tags                 : [
              ManagedBy : 'Jenkins',
              Project   : 'rds-mysql-provision',
              Repository: env.JOB_NAME
            ]
          ]

          dir('terraform') {
            writeFile file: 'jenkins.auto.tfvars.json', text: JsonOutput.prettyPrint(JsonOutput.toJson(tfvars))
          }
        }
      }
    }

    stage('Terraform Init') {
      steps {
        dir('terraform') {
          runCommand('terraform init -no-color')
        }
      }
    }

    stage('Terraform Validate') {
      steps {
        dir('terraform') {
          runCommand('terraform fmt -check -recursive -no-color')
          runCommand('terraform validate -no-color')
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: params.AWS_CREDENTIALS_ID],
          string(credentialsId: params.DB_PASSWORD_CREDENTIALS_ID, variable: 'DB_PASSWORD')
        ]) {
          withEnv(["TF_VAR_db_password=${DB_PASSWORD}"]) {
            dir('terraform') {
              script {
                if (params.TF_ACTION == 'destroy') {
                  runCommand('terraform plan -destroy -out=tfplan -no-color')
                } else {
                  runCommand('terraform plan -out=tfplan -no-color')
                }
              }
            }
          }
        }
      }
    }

    stage('Terraform Apply Or Destroy') {
      when {
        expression { params.TF_ACTION in ['apply', 'destroy'] }
      }
      steps {
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: params.AWS_CREDENTIALS_ID],
          string(credentialsId: params.DB_PASSWORD_CREDENTIALS_ID, variable: 'DB_PASSWORD')
        ]) {
          withEnv(["TF_VAR_db_password=${DB_PASSWORD}"]) {
            dir('terraform') {
              runCommand('terraform apply -auto-approve -no-color tfplan')
            }
          }
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'terraform/tfplan', allowEmptyArchive: true, fingerprint: true
    }
  }
}

