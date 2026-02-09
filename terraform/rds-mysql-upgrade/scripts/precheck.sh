#!/usr/bin/env bash
set -euo pipefail

DB_IDENTIFIER="${1:?db identifier required}"
REGION="${2:?aws region required}"
SOURCE_VERSION="${3:?source engine version required}"
TARGET_VERSION="${4:?target engine version required}"

echo "[INFO] Checking current instance engine version"
CURRENT_VERSION="$(aws rds describe-db-instances \
  --db-instance-identifier "$DB_IDENTIFIER" \
  --region "$REGION" \
  --query 'DBInstances[0].EngineVersion' \
  --output text)"

if [[ "$CURRENT_VERSION" != "$SOURCE_VERSION" ]]; then
  echo "[ERROR] DB instance $DB_IDENTIFIER is on $CURRENT_VERSION, expected $SOURCE_VERSION"
  exit 1
fi

echo "[INFO] Checking if target engine version is orderable"
ORDERABLE="$(aws rds describe-db-engine-versions \
  --engine mysql \
  --engine-version "$TARGET_VERSION" \
  --region "$REGION" \
  --query 'length(DBEngineVersions)' \
  --output text)"

if [[ "$ORDERABLE" == "0" ]]; then
  echo "[ERROR] Target version $TARGET_VERSION is not available in $REGION"
  exit 1
fi

echo "[INFO] Precheck passed: $DB_IDENTIFIER $SOURCE_VERSION -> $TARGET_VERSION"
