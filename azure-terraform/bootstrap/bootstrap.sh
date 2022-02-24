#!/bin/bash

### Usage ./bootstrap.sh dev 123-456-789 westeurope
### Bootstrapping script that creates Service Principal and Storage for Terraform
### Use once on first project setup
### This assumes you have performed az login and have sufficient permissions

ENV=$1
SUBSCRIPTION_ID=$2
REGION=${3:-"westeurope"}

echo "Creating service principal"
SERVICE_PRINCIPAL=$(az ad sp create-for-rbac --name "Terraform${RANDOM}" --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}")

ARM_SUBSCRIPTION_ID=${SUBSCRIPTION_ID}
echo "ARM_SUBSCRIPTION_ID=${ARM_SUBSCRIPTION_ID}" > .${ENV}.env

ARM_TENANT_ID=$(echo ${SERVICE_PRINCIPAL} | jq .tenant)
echo "ARM_TENANT_ID=${ARM_TENANT_ID}" >> .${ENV}.env

ARM_CLIENT_ID=$(echo ${SERVICE_PRINCIPAL} | jq .appId)
echo "ARM_CLIENT_ID=${ARM_CLIENT_ID}" >> .${ENV}.env

ARM_CLIENT_SECRET=$(echo ${SERVICE_PRINCIPAL} | jq .password)
echo "ARM_CLIENT_SECRET=${ARM_CLIENT_SECRET}" >> .${ENV}.env

RESOURCE_GROUP_NAME=tfstate
STORAGE_ACCOUNT_NAME=tfstate$RANDOM
CONTAINER_NAME=tfstate

echo "Creating remote state storage account"
az group create --name $RESOURCE_GROUP_NAME --location ${REGION}
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob --https-only true --allow-blob-public-access false

ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)

echo "Creating remote state container"
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY
 
echo -e "resource_group_name = \"${RESOURCE_GROUP_NAME}\"\n" > ../backend/${ENV}.conf
echo -e "storage_account_name = \"${STORAGE_ACCOUNT_NAME}\"\n" >> ../backend/${ENV}.conf
echo -e "container_name = \"${CONTAINER_NAME}\"\n" >> ../backend/${ENV}.conf
echo -e "key = \"terraform.${ENV}.tfstate\"\n" >> ../backend/${ENV}.conf

echo "ARM_ACCESS_KEY=${ACCOUNT_KEY}" >> .${ENV}.env

echo "Saving secrets to keyvault"
KEYVAULT_NAME="${ENV}-${RANDOM}-terraform"
az keyvault create --name ${KEYVAULT_NAME} --resource-group "${RESOURCE_GROUP_NAME}" --location "${REGION}"
az keyvault secret set --vault-name ${KEYVAULT_NAME} --name "ARM-SUBSCRIPTION-ID" --value "${SUBSCRIPTION_ID}"
az keyvault secret set --vault-name ${KEYVAULT_NAME} --name "ARM-TENANT-ID" --value "${ARM_TENANT_ID}"
az keyvault secret set --vault-name ${KEYVAULT_NAME} --name "ARM-CLIENT-ID" --value "${ARM_CLIENT_ID}"
az keyvault secret set --vault-name ${KEYVAULT_NAME} --name "ARM-CLIENT-SECRET" --value "${ARM_CLIENT_SECRET}"
az keyvault secret set --vault-name ${KEYVAULT_NAME} --name "ARM-ACCESS-KEY" --value ${ACCOUNT_KEY}