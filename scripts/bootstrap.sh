#!/bin/bash
set -e

LOCATION=$1
SA_NAME="stlfcslab${LOCATION//[-]/}"

echo "Creating bootstrap infrastructure in location: $LOCATION"

az group create \
  --name "rg-tfstate-${LOCATION}" \
  --location "${LOCATION}"

az storage account create \
  --name "${SA_NAME}" \
  --resource-group "rg-tfstate-${LOCATION}" \
  --location "${LOCATION}" \
  --sku Standard_LRS \
  --allow-blob-public-access false

az storage container create \
  --name tfstate \
  --account-name "${SA_NAME}"

echo "Bootstrap complete for location: ${LOCATION}"
echo "Storage account: ${SA_NAME}"
echo "Resource group:  rg-tfstate-${LOCATION}"