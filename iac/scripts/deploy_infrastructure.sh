#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

###################
# REQUIRED ENV VARIABLES:
#
# PROJECT
# DEPLOYMENT_ID
# ENV_NAME
# AZURE_LOCATION
# AZURE_SUBSCRIPTION_ID

#####################

#####################
# DEPLOY ARM TEMPLATE
sqlpwd=$(echo /dev/urandom | base64 | fold -w 10 | head -n 1)

# Set account to where ARM template will be deployed to
echo "Deploying to Subscription: $AZURE_SUBSCRIPTION_ID"
az account set --subscription "$AZURE_SUBSCRIPTION_ID"

# # Retrieve User Id
signed_in_user_object_id=$(az ad signed-in-user show --output json | jq -r '.objectId')


# Validate arm template
# Management Resources
echo "Validating deployment Management"
management_arm_output=$(az deployment sub validate \
    --name 'management' \
    --location $AZURE_LOCATION \
    --template-file ./management/infra/main.bicep \
    --parameters location=$AZURE_LOCATION project=$PROJECT env=$ENV_NAME deployment_id=$DEPLOYMENT_ID signed_in_user_object_id=$signed_in_user_object_id\
    --output json)

# Landing Core Resources

echo "Validating deployment Landing Core"
core_arm_output=$(az deployment sub validate \
    --name 'landing-core'\
    --location $AZURE_LOCATION \
    --template-file ./landing-core/infra/main.bicep \
    --parameters location=$AZURE_LOCATION project=$PROJECT env=$ENV_NAME deployment_id=$DEPLOYMENT_ID signed_in_user_object_id=$signed_in_user_object_id\
    sqlPassword=$sqlpwd \
    --output json)

# integration001 Resources

echo "Validating deployment integration001"
arm_output=$(az deployment sub validate \
    --name 'integration001' \
    --location $AZURE_LOCATION \
    --template-file ./integration001/infra/main.bicep \
    --parameters location=$AZURE_LOCATION project=$PROJECT env=$ENV_NAME deployment_id=$DEPLOYMENT_ID signed_in_user_object_id=$signed_in_user_object_id \
    --output json)

# # product001 Resources

# echo "Validating deployment product001"
# arm_output=$(az deployment sub validate \
#     --name 'product001' \
#     --location $AZURE_LOCATION \
#     --template-file ./product001/infra/main.bicep \
#     --parameters location=$AZURE_LOCATION project=$PROJECT env=$ENV_NAME deployment_id=$DEPLOYMENT_ID signed_in_user_object_id=$signed_in_user_object_id \
#     --output json)
# Management Resources

# # Deploy arm template
echo "Start deployment Management"
management_arm_output=$(az deployment sub create \
    --name 'management' \
    --location $AZURE_LOCATION \
    --template-file ./management/infra/main.bicep \
    --parameters location=$AZURE_LOCATION project=$PROJECT env=$ENV_NAME deployment_id=$DEPLOYMENT_ID signed_in_user_object_id=$signed_in_user_object_id\
    --output json)

echo "Finish deploying governance resources "

# Management Outputs

purviewId=$(echo "$management_arm_output" | jq -r '.properties.outputs.purviewId.value')

# Landing Core Resources


# # Deploy arm template
echo "Start deployment Landing Core"
core_arm_output=$(az deployment sub create \
    --name 'landing-core'\
    --location $AZURE_LOCATION \
    --template-file ./landing-core/infra/main.bicep \
    --parameters location=$AZURE_LOCATION project=$PROJECT env=$ENV_NAME deployment_id=$DEPLOYMENT_ID signed_in_user_object_id=$signed_in_user_object_id\
    purviewId=$purviewId sqlPassword=$sqlpwd \
    --output json)

# Landing Core Outputs
storageRawId=$(echo "$core_arm_output" | jq -r '.properties.outputs.storageRawId.value')
storageRawFileSystemId=$(echo "$core_arm_output" | jq -r '.properties.outputs.storageRawFileSystemId.value')
storageRawFileSystemId_di001=$(echo "$core_arm_output" | jq -r '.properties.outputs.storageRawFileSystemId_di001.value')
storageEnrichedCuratedId=$(echo "$core_arm_output" | jq -r '.properties.outputs.storageEnrichedCuratedId.value')
storageEnrichedCuratedFileSystemId=$(echo "$core_arm_output" | jq -r '.properties.outputs.storageEnrichedCuratedFileSystemId.value')
storageEnrichedCuratedFileSystemId_di001=$(echo "$core_arm_output" | jq -r '.properties.outputs.storageEnrichedCuratedFileSystemId_di001.value')
storageEnrichedCuratedFileSystemId_dp001=$(echo "$core_arm_output" | jq -r '.properties.outputs.storageEnrichedCuratedFileSystemId_dp001.value')
storageWorkspaceId=$(echo "$core_arm_output" | jq -r '.properties.outputs.storageWorkspaceId.value')
storageWorkspaceFileSystemId=$(echo "$core_arm_output" | jq -r '.properties.outputs.storageWorkspaceFileSystemId.value')
storageWorkspaceFileSystemId_dp001=$(echo "$core_arm_output" | jq -r '.properties.outputs.storageWorkspaceFileSystemId_dp001.value')
databricksIntegration001ApiUrl=$(echo "$core_arm_output" | jq -r '.properties.outputs.databricksIntegration001ApiUrl.value')
databricksIntegration001Id=$(echo "$core_arm_output" | jq -r '.properties.outputs.databricksIntegration001Id.value')
databricksWorkspaceUrl=$(echo "$core_arm_output" | jq -r '.properties.outputs.databricksWorkspaceUrl.value')

echo "Finish deploying Landing Core resources "

# integration001 Resources


# # Deploy arm template
echo "Start deployment integration001"
arm_output=$(az deployment sub create \
    --name 'integration001' \
    --location $AZURE_LOCATION \
    --template-file ./integration001/infra/main.bicep \
    --parameters location=$AZURE_LOCATION project=$PROJECT env=$ENV_NAME deployment_id=$DEPLOYMENT_ID signed_in_user_object_id=$signed_in_user_object_id \
    purviewId=$purviewId \
    storageRawFileSystemId_di001=$storageRawFileSystemId_di001 \
    storageEnrichedCuratedFileSystemId_di001=$storageEnrichedCuratedFileSystemId_di001 \
    storageRawId=$storageRawId \
    storageEnrichedCuratedId=$storageEnrichedCuratedId \
    databricks001Id=$databricksIntegration001Id \
    databricks001WorkspaceUrl=$databricksWorkspaceUrl \
    --output json)



echo "Finish deploying integration001 resources "


# # product001 Resources



# # Deploy arm template
echo "Start deployment product001"
arm_output=$(az deployment sub create \
    --name 'product001' \
    --location $AZURE_LOCATION \
    --template-file ./product001/infra/main.bicep \
    --parameters location=$AZURE_LOCATION project=$PROJECT env=$ENV_NAME deployment_id=$DEPLOYMENT_ID signed_in_user_object_id=$signed_in_user_object_id \
    purviewId=$purviewId \
    synapseDefaultStorageAccountFileSystemId=$storageWorkspaceFileSystemId_dp001 \
    storageCuratedFileSystemId=$storageEnrichedCuratedFileSystemId_dp001 \
    storageEnrichedFileSystemId=$storageEnrichedCuratedFileSystemId_di001 \
    --output json)

echo "Finish deploying product001 resources "

coreSubscriptionId=$(echo "$core_arm_output" | jq -r '.properties.outputs.coreSubscriptionId.value')

# metastore
metastoreResourceGroupName=$(echo "$core_arm_output" | jq -r '.properties.outputs.metastoreResourceGroupName.value')
metastoreSqlServerName=$(echo "$core_arm_output" | jq -r '.properties.outputs.metastoreSqlServerName.value')

# product
databricksProduct001WorkspaceUrl=$(echo "$core_arm_output" | jq -r '.properties.outputs.databricksProduct001WorkspaceUrl.value')
databrikcsProduct001Name=$(echo "$core_arm_output" | jq -r '.properties.outputs.databrikcsProduct001Name.value')
sharedProductResourceGroupName=$(echo "$core_arm_output" | jq -r '.properties.outputs.sharedProductResourceGroupName.value')

# integration
databricksIntegration001WorkspaceUrl=$(echo "$core_arm_output" | jq -r '.properties.outputs.databricksIntegration001WorkspaceUrl.value')
databricksIntegration001Name=$(echo "$core_arm_output" | jq -r '.properties.outputs.databricksIntegration001Name.value')
sharedIntegrationResourceGroupName=$(echo "$core_arm_output" | jq -r '.properties.outputs.sharedIntegrationResourceGroupName.value')

hiveKeyVaultResourceId=$(echo "$core_arm_output" | jq -r '.properties.outputs.hiveKeyVaultResourceId.value')
hiveKeyVaultDnsName=$(echo "$core_arm_output" | jq -r '.properties.outputs.hiveKeyVaultDnsName.value')
logAnalytics001WorkspaceKeyVaultId=$(echo "$core_arm_output" | jq -r '.properties.outputs.logAnalytics001WorkspaceKeyVaultId.value')
logAnalytics001WorkspaceKeyVaultDns=$(echo "$core_arm_output" | jq -r '.properties.outputs.logAnalytics001WorkspaceKeyVaultDns.value')

# shared Product Databricks deploy

# HIVEKEYVAULTRESOURCEID=$hiveKeyVaultResourceId \
# HIVEKEYVAULTDNSNAME=$hiveKeyVaultDnsName \
# DATABRICKSHOSTURL=$databricksProduct001WorkspaceUrl \
# DATABRICKSWORKSPACESUBSCRIPTIONID=$coreSubscriptionId \
# DATABRICKSWORKSPACERESOURCEGROUPNAME=$sharedProductResourceGroupName \
# DATABRICKSWORKSPACENAME=$databrikcsProduct001Name \
# LOGKEYVAULTRESOURCEID=$logAnalytics001WorkspaceKeyVaultId \
# LOGKEYVAULTDNSNAME=$logAnalytics001WorkspaceKeyVaultDns \
# JOBPOLICY=false \
#     bash -c "./landing-core/scripts/deploy_databricks.sh"

# # shared integration Databricks deploy

# HIVEKEYVAULTRESOURCEID=$hiveKeyVaultResourceId \
# HIVEKEYVAULTDNSNAME=$hiveKeyVaultDnsName \
# DATABRICKSHOSTURL=$databricksIntegration001WorkspaceUrl \
# DATABRICKSWORKSPACESUBSCRIPTIONID=$coreSubscriptionId \
# DATABRICKSWORKSPACERESOURCEGROUPNAME=$sharedIntegrationResourceGroupName \
# DATABRICKSWORKSPACENAME=$databricksIntegration001Name \
# LOGKEYVAULTRESOURCEID=$logAnalytics001WorkspaceKeyVaultId \
# LOGKEYVAULTDNSNAME=$logAnalytics001WorkspaceKeyVaultDns \
# JOBPOLICY=true \
#     bash -c "./landing-core/scripts/deploy_databricks.sh"

# # Deploy SQL DB

RESOURCE_GROUP_NAME=$metastoreResourceGroupName \
SQL_SERVER_NAME=$metastoreSqlServerName \
    bash -c "./landing-core/scripts/deploy_sqldatabase.sh"

################


# RESOURCE_GROUP_NAME=$resource_group_name \
# SQL_SERVER_NAME=$sqlsvName \
#     bash -c "./Deployment/scripts/deploy_sqldatabase.sh"

# #####################
# # Create a Service Principal for Purview Rest API access

# echo "Creating Service principal for Purview Rest API access"

# sp_stor_name="${PROJECT}-apv-${ENV_NAME}-${DEPLOYMENT_ID}-sp"
# rg_id=$(az group show \
#     --name "$resource_group_name" \
#     --output json |
#     jq -r '.id')

# sp_stor_out=$(az ad sp create-for-rbac \
#     --role "Reader" \
#     --scopes "$rg_id" \
#     --name "$sp_stor_name" \
#     --output json)

# echo "Created Service principal : ${sp_stor_name}"

# sp_appId=$(echo $sp_stor_out | jq -r .appId)
# sp_tenantId=$(echo $sp_stor_out | jq -r .tenant)
# sp_secret=$(echo $sp_stor_out | jq -r .password)
# sleep 30
# sp_objectId=$(az ad sp show --id ${sp_appId} | jq -r .objectId)

# # Deploy Purview
# apv_name=$(echo "$arm_output" | jq -r '.properties.outputs.apv_name_output.value')
# syn_objectId=$(echo "$arm_output" | jq -r '.properties.outputs.synapsePId.value')
# synapsestorageName=$(echo "$arm_output" | jq -r '.properties.outputs.synapsestorageName.value')

# RESOURCE_GROUP_NAME=$resource_group_name \
# APV_NAME=$apv_name \
# SP_OBJECTID=$sp_objectId \
# SYNAPSE_OBJECTID=$syn_objectId \
# SYNAPSE_STORAGENAME=$synapsestorageName \
# SQL_SERVER_NAME=$sqlsvName \
#     bash -c "./Deployment/scripts/deploy_purview.sh"


# #####################


# # upload data

# synapsestorageName=$(echo "$arm_output" | jq -r '.properties.outputs.synapsestorageName.value')
# synContainer=$(echo "$arm_output" | jq -r '.properties.outputs.synContainer.value')

# echo "Uploading data to ${synapsestorageName}"

# az storage blob upload-batch  \
# --auth-mode login \
# -d "$synContainer" \
# --account-name "$synapsestorageName" \
# -s ./Data

# echo "Finish uploading data"



# #####################

# # Deploy Synapse
# # リソース固有値変更


# synapseSrcDir=./Deployment/template/synapse/
# # synLsDir=$synTmpDir/linkedService

# synWorkspaceName=$(echo "$arm_output" | jq -r '.properties.outputs.synWorkspaceName.value')
# synSparkName=$(echo "$arm_output" | jq -r '.properties.outputs.synSparkName.value')

# RESOURCE_GROUP_NAME=$resource_group_name \
# SYN_WORKSPACENAME=$synWorkspaceName \
# SYN_SPARKNAME=$synSparkName \
# SYN_SRCDIR=$synapseSrcDir \
# SYNAPSE_STORAGENAME=$synapsestorageName \
# SQL_SERVER_NAME=$sqlsvName \
#     bash -c "./Deployment/scripts/deploy_synapse_artifacts.sh"

# #####################
# # variables file

# azuremlName=$(echo "$arm_output" | jq -r '.properties.outputs.azuremlName.value')
# json=$(printf '
# {
#     "01_Authenticate_to_Purview_AML":{
#     "TENANT_ID": "%s",
#     "CLIENT_ID": "%s",
#     "CLIENT_SECRET":"%s",
#     "PURVIEW_NAME": "%s",
#     "SUBSCRIPTION_ID": "%s",
#     "RESOURCE_GROUP":"%s",
#     "WORKSPACE_NAME": "%s",
#     "WORKSPACE_REGION": "%s"},
#     "04_Create_CreditRisk_Experiment":{
#         "Synapse_Storage_Account_Name":"%s"
#     }   
# }' "${sp_tenantId}" "${sp_appId}" ${sp_secret} ${apv_name} ${AZURE_SUBSCRIPTION_ID} ${resource_group_name} ${azuremlName} ${AZURE_LOCATION} ${synapsestorageName})

# echo "$json" | jq '.' > variable.json

# finish
echo "Completed deploying Azure resources" 