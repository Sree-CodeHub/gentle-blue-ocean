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

def optionalInteger(String value) {
  if (!value?.trim()) {
    return null
  }

  return value.trim().toInteger()
}

def runPortableScript(String unixScript, String windowsScript) {
  if (isUnix()) {
    sh unixScript
  } else {
    powershell windowsScript
  }
}

def withAwsAuthentication(String region, String profile, String credentialsId, Closure body) {
  def awsEnv = [
    "AWS_DEFAULT_REGION=${region.trim()}",
    "AWS_REGION=${region.trim()}"
  ]

  if (profile?.trim()) {
    awsEnv << "AWS_PROFILE=${profile.trim()}"
  }

  if (credentialsId?.trim()) {
    withCredentials([
      usernamePassword(credentialsId: credentialsId.trim(), usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')
    ]) {
      withEnv(awsEnv) {
        body()
      }
    }
  } else {
    withEnv(awsEnv) {
      body()
    }
  }
}

def withDatabasePassword(String resourceType, Boolean manageMasterUserPassword, String credentialsId, Closure body) {
  if (!['rds-mysql', 'aurora-mysql'].contains(resourceType)) {
    body()
    return
  }

  if (manageMasterUserPassword) {
    body()
    return
  }

  if (!credentialsId?.trim()) {
    error('DB_PASSWORD_CREDENTIALS_ID is required when MANAGE_MASTER_USER_PASSWORD is false.')
  }

  withCredentials([
    string(credentialsId: credentialsId.trim(), variable: 'DB_PASSWORD')
  ]) {
    withEnv(["TF_VAR_db_password=${env.DB_PASSWORD}"]) {
      body()
    }
  }
}

pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  parameters {
    choice(name: 'TF_ACTION', choices: ['validate', 'plan', 'apply', 'destroy', 'reboot'], description: 'Action to run.')
    string(name: 'CONFIRM_APPLY', defaultValue: '', description: 'Use APPLY_RESOURCE, DESTROY_RESOURCE, or REBOOT_RESOURCE for impact actions.')
    choice(name: 'RESOURCE_TYPE', choices: ['rds-mysql', 'aurora-mysql', 'elasticache-redis', 'elasticache-memcached'], description: 'AWS data service to manage.')
    string(name: 'RESOURCE_IDENTIFIER', defaultValue: 'jenkins-data-service', description: 'RDS identifier, Aurora cluster identifier, or ElastiCache identifier.')
    string(name: 'AWS_PROFILE', defaultValue: 'connect-london', description: 'AWS CLI profile available on the Jenkins agent. Leave blank to use the default AWS provider chain.')
    string(name: 'AWS_REGION', defaultValue: 'eu-west-2', description: 'AWS region for the RDS instance and STS check.')
    string(name: 'AWS_CREDENTIALS_ID', defaultValue: '', description: 'Optional Jenkins AWS key credential ID. Leave blank when using AWS_PROFILE.')
    booleanParam(name: 'MANAGE_MASTER_USER_PASSWORD', defaultValue: true, description: 'Use AWS Secrets Manager to manage the RDS master password.')
    string(name: 'DB_PASSWORD_CREDENTIALS_ID', defaultValue: '', description: 'Optional Jenkins secret text credential ID when MANAGE_MASTER_USER_PASSWORD is false.')
    string(name: 'DB_IDENTIFIER', defaultValue: 'jenkins-data-service', description: 'Backward-compatible RDS identifier. RESOURCE_IDENTIFIER is preferred.')
    string(name: 'DB_NAME', defaultValue: 'appdb', description: 'Initial database name.')
    string(name: 'DB_USERNAME', defaultValue: 'adminuser', description: 'RDS master username.')
    string(name: 'ENGINE_VERSION', defaultValue: '8.0', description: 'Engine version for RDS MySQL, Aurora MySQL, Redis/Valkey, or Memcached.')
    string(name: 'INSTANCE_CLASS', defaultValue: 'db.t3.micro', description: 'RDS instance class or Aurora instance class.')
    string(name: 'ALLOCATED_STORAGE', defaultValue: '20', description: 'Initial storage in GB.')
    string(name: 'MAX_ALLOCATED_STORAGE', defaultValue: '100', description: 'Maximum autoscaled storage in GB.')
    string(name: 'AURORA_INSTANCE_COUNT', defaultValue: '1', description: 'Aurora cluster instance count.')
    string(name: 'AURORA_ALLOCATED_STORAGE', defaultValue: '', description: 'Optional Aurora allocated storage when supported.')
    string(name: 'AURORA_STORAGE_TYPE', defaultValue: '', description: 'Optional Aurora storage type, for example aurora-iopt1.')
    string(name: 'CACHE_ENGINE', defaultValue: 'redis', description: 'ElastiCache engine for elasticache-redis, for example redis or valkey.')
    string(name: 'CACHE_NODE_TYPE', defaultValue: 'cache.t3.micro', description: 'ElastiCache node type.')
    string(name: 'CACHE_NUM_NODES', defaultValue: '1', description: 'Number of ElastiCache nodes.')
    string(name: 'CACHE_PORT', defaultValue: '', description: 'Optional ElastiCache port. Defaults to 6379 or 11211.')
    string(name: 'CACHE_PARAMETER_GROUP_NAME', defaultValue: '', description: 'Optional ElastiCache parameter group name.')
    booleanParam(name: 'CACHE_AUTOMATIC_FAILOVER', defaultValue: false, description: 'Enable ElastiCache automatic failover when using more than one Redis/Valkey node.')
    booleanParam(name: 'CACHE_MULTI_AZ', defaultValue: false, description: 'Enable ElastiCache Multi-AZ when using more than one Redis/Valkey node.')
    booleanParam(name: 'CACHE_AT_REST_ENCRYPTION', defaultValue: true, description: 'Enable ElastiCache at-rest encryption.')
    booleanParam(name: 'CACHE_TRANSIT_ENCRYPTION', defaultValue: false, description: 'Enable ElastiCache in-transit encryption.')
    string(name: 'CACHE_SNAPSHOT_RETENTION_LIMIT', defaultValue: '0', description: 'ElastiCache Redis/Valkey snapshot retention days.')
    string(name: 'REBOOT_TARGET_ID', defaultValue: '', description: 'Optional reboot target. Defaults to RESOURCE_IDENTIFIER.')
    string(name: 'REBOOT_CACHE_NODE_IDS', defaultValue: '0001', description: 'Comma-separated ElastiCache node IDs to reboot.')
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
          if (params.TF_ACTION in ['plan', 'apply', 'destroy']) {
            if (!params.VPC_ID?.trim()) {
              error('VPC_ID is required.')
            }
            if (csvList(params.SUBNET_IDS).size() < 2) {
              error('SUBNET_IDS must include at least two subnet IDs in different Availability Zones.')
            }
          }
          if (params.TF_ACTION == 'apply' && !(params.CONFIRM_APPLY in ['APPLY_RESOURCE', 'APPLY_RDS'])) {
            error('Set CONFIRM_APPLY to APPLY_RESOURCE before provisioning or modifying the AWS data service.')
          }
          if (params.TF_ACTION == 'destroy' && !(params.CONFIRM_APPLY in ['DESTROY_RESOURCE', 'DESTROY_RDS'])) {
            error('Set CONFIRM_APPLY to DESTROY_RESOURCE before destroying the AWS data service.')
          }
          if (params.TF_ACTION == 'reboot') {
            if (params.CONFIRM_APPLY != 'REBOOT_RESOURCE') {
              error('Set CONFIRM_APPLY to REBOOT_RESOURCE before rebooting.')
            }
            if (!(params.REBOOT_TARGET_ID?.trim() ?: params.RESOURCE_IDENTIFIER?.trim())) {
              error('REBOOT_TARGET_ID or RESOURCE_IDENTIFIER is required for reboot.')
            }
          }
        }
      }
    }

    stage('Write Terraform Variables') {
      when {
        expression { params.TF_ACTION in ['plan', 'apply', 'destroy'] }
      }
      steps {
        script {
          def tfvars = [
            resource_type              : params.RESOURCE_TYPE,
            resource_identifier        : params.RESOURCE_IDENTIFIER.trim(),
            aws_region                : params.AWS_REGION.trim(),
            db_identifier             : params.DB_IDENTIFIER.trim(),
            db_name                   : params.DB_NAME.trim(),
            db_username               : params.DB_USERNAME.trim(),
            manage_master_user_password: params.MANAGE_MASTER_USER_PASSWORD,
            engine_version            : params.ENGINE_VERSION.trim(),
            instance_class            : params.INSTANCE_CLASS.trim(),
            allocated_storage         : params.ALLOCATED_STORAGE.toInteger(),
            max_allocated_storage     : params.MAX_ALLOCATED_STORAGE.toInteger(),
            aurora_instance_count     : params.AURORA_INSTANCE_COUNT.toInteger(),
            aurora_allocated_storage  : optionalInteger(params.AURORA_ALLOCATED_STORAGE),
            aurora_storage_type       : params.AURORA_STORAGE_TYPE.trim(),
            cache_engine              : params.CACHE_ENGINE.trim(),
            cache_node_type           : params.CACHE_NODE_TYPE.trim(),
            cache_num_nodes           : params.CACHE_NUM_NODES.toInteger(),
            cache_port                : optionalInteger(params.CACHE_PORT),
            cache_parameter_group_name: params.CACHE_PARAMETER_GROUP_NAME.trim(),
            cache_automatic_failover_enabled: params.CACHE_AUTOMATIC_FAILOVER,
            cache_multi_az_enabled    : params.CACHE_MULTI_AZ,
            cache_at_rest_encryption_enabled: params.CACHE_AT_REST_ENCRYPTION,
            cache_transit_encryption_enabled: params.CACHE_TRANSIT_ENCRYPTION,
            cache_snapshot_retention_limit: params.CACHE_SNAPSHOT_RETENTION_LIMIT.toInteger(),
            vpc_id                    : params.VPC_ID.trim(),
            subnet_ids                : csvList(params.SUBNET_IDS),
            allowed_cidr_blocks       : csvList(params.ALLOWED_CIDRS),
            publicly_accessible       : params.PUBLICLY_ACCESSIBLE,
            skip_final_snapshot       : params.SKIP_FINAL_SNAPSHOT,
            tags                      : [
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
      when {
        expression { params.TF_ACTION != 'reboot' }
      }
      steps {
        dir('terraform') {
          runCommand('terraform init -no-color')
        }
      }
    }

    stage('Terraform Validate') {
      when {
        expression { params.TF_ACTION != 'reboot' }
      }
      steps {
        dir('terraform') {
          runCommand('terraform fmt -check -recursive -no-color')
          runCommand('terraform validate -no-color')
        }
      }
    }

    stage('AWS Caller Identity') {
      when {
        expression { params.TF_ACTION != 'validate' }
      }
      steps {
        script {
          withAwsAuthentication(params.AWS_REGION, params.AWS_PROFILE, params.AWS_CREDENTIALS_ID) {
            runCommand('aws sts get-caller-identity')
          }
        }
      }
    }

    stage('Reboot') {
      when {
        expression { params.TF_ACTION == 'reboot' }
      }
      steps {
        script {
          withAwsAuthentication(params.AWS_REGION, params.AWS_PROFILE, params.AWS_CREDENTIALS_ID) {
            def targetId = params.REBOOT_TARGET_ID?.trim() ?: params.RESOURCE_IDENTIFIER.trim()
            def nodeIds = params.REBOOT_CACHE_NODE_IDS?.trim() ?: '0001'

            if (params.RESOURCE_TYPE == 'rds-mysql') {
              runCommand("aws rds reboot-db-instance --db-instance-identifier \"${targetId}\"")
            } else if (params.RESOURCE_TYPE == 'aurora-mysql') {
              runPortableScript(
                '''set -e
instances=$(aws rds describe-db-instances --filters Name=db-cluster-id,Values="__RESOURCE_ID__" --query 'DBInstances[].DBInstanceIdentifier' --output text)
if [ -z "$instances" ] || [ "$instances" = "None" ]; then
  echo "No Aurora instances found for cluster __RESOURCE_ID__"
  exit 1
fi
for instance in $instances; do
  aws rds reboot-db-instance --db-instance-identifier "$instance"
done
'''.replace('__RESOURCE_ID__', targetId),
                '''
$instances = aws rds describe-db-instances --filters "Name=db-cluster-id,Values=__RESOURCE_ID__" --query "DBInstances[].DBInstanceIdentifier" --output text
if (-not $instances -or $instances.Trim() -eq "None") {
  throw "No Aurora instances found for cluster __RESOURCE_ID__"
}
$instances -split "\\s+" | Where-Object { $_ } | ForEach-Object {
  aws rds reboot-db-instance --db-instance-identifier $_
}
'''.replace('__RESOURCE_ID__', targetId)
              )
            } else if (params.RESOURCE_TYPE == 'elasticache-redis') {
              runPortableScript(
                '''set -e
clusters=$(aws elasticache describe-replication-groups --replication-group-id "__RESOURCE_ID__" --query 'ReplicationGroups[0].MemberClusters[]' --output text)
if [ -z "$clusters" ] || [ "$clusters" = "None" ]; then
  clusters="__RESOURCE_ID__"
fi
node_ids=$(echo "__NODE_IDS__" | tr ',' ' ')
for cluster in $clusters; do
  aws elasticache reboot-cache-cluster --cache-cluster-id "$cluster" --cache-node-ids-to-reboot $node_ids
done
'''.replace('__RESOURCE_ID__', targetId).replace('__NODE_IDS__', nodeIds),
                '''
$clusters = aws elasticache describe-replication-groups --replication-group-id "__RESOURCE_ID__" --query "ReplicationGroups[0].MemberClusters[]" --output text
if (-not $clusters -or $clusters.Trim() -eq "None") {
  $clusters = "__RESOURCE_ID__"
}
$nodeIds = "__NODE_IDS__" -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ }
$clusters -split "\\s+" | Where-Object { $_ } | ForEach-Object {
  aws elasticache reboot-cache-cluster --cache-cluster-id $_ --cache-node-ids-to-reboot $nodeIds
}
'''.replace('__RESOURCE_ID__', targetId).replace('__NODE_IDS__', nodeIds)
              )
            } else if (params.RESOURCE_TYPE == 'elasticache-memcached') {
              runPortableScript(
                '''set -e
node_ids=$(echo "__NODE_IDS__" | tr ',' ' ')
aws elasticache reboot-cache-cluster --cache-cluster-id "__RESOURCE_ID__" --cache-node-ids-to-reboot $node_ids
'''.replace('__RESOURCE_ID__', targetId).replace('__NODE_IDS__', nodeIds),
                '''
$nodeIds = "__NODE_IDS__" -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ }
aws elasticache reboot-cache-cluster --cache-cluster-id "__RESOURCE_ID__" --cache-node-ids-to-reboot $nodeIds
'''.replace('__RESOURCE_ID__', targetId).replace('__NODE_IDS__', nodeIds)
              )
            }
          }
        }
      }
    }

    stage('Terraform Plan') {
      when {
        expression { params.TF_ACTION in ['plan', 'apply', 'destroy'] }
      }
      steps {
        script {
          withAwsAuthentication(params.AWS_REGION, params.AWS_PROFILE, params.AWS_CREDENTIALS_ID) {
            withDatabasePassword(params.RESOURCE_TYPE, params.MANAGE_MASTER_USER_PASSWORD, params.DB_PASSWORD_CREDENTIALS_ID) {
              dir('terraform') {
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
        script {
          withAwsAuthentication(params.AWS_REGION, params.AWS_PROFILE, params.AWS_CREDENTIALS_ID) {
            withDatabasePassword(params.RESOURCE_TYPE, params.MANAGE_MASTER_USER_PASSWORD, params.DB_PASSWORD_CREDENTIALS_ID) {
              dir('terraform') {
                runCommand('terraform apply -auto-approve -no-color tfplan')
              }
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
