#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

##############


# # REQUIRED ENV VARIABLES:
# APV_NAME
# AKV_NAME
# SP_OBJECTID
# SYNAPSE_OBJECTID
# SYNAPSE_STORAGENAME
##############

apv_name=$APV_NAME
akv_name=$AKV_NAME
resource_group_name=$RESOURCE_GROUP_NAME
sp_objectId=$SP_OBJECTID
addMemberPID=$SYNAPSE_OBJECTID
synapsestorageName=$SYNAPSE_STORAGENAME

##############
# variable

endpoint="https://${apv_name}.purview.azure.com"

##############
# functions

CreateCollection () {
    declare collectionName=$1
    declare parentFrendryName=$2
    getCollectionURL=${endpoint}/collections/${parentFrendryName}?api-version=2019-11-01-preview
    parentCollectionName=$(az rest --method get --resource "https://purview.azure.net" --url $getCollectionURL | jq -r '.name')
    createColleciontURL=${endpoint}/collections/${collectionName}?api-version=2019-11-01-preview
    collectionBody=$(printf '
        {
            "parentCollection": {
                "referenceName":"%s"
            }
        }
    ' "${parentCollectionName}")
    az rest --method put --resource "https://purview.azure.net" --url $createColleciontURL --body "$collectionBody"
    echo "Created Collection: $collectionName"
}

CreateKeyVault () {
    declare keyVaultName=$1
    createKeyVaultURL=${endpoint}/scan/azureKeyVaults/${keyVaultName}?api-version=2018-12-01-preview
    KeyVaultBody=$(printf '
        {
            "properties": {
                "baseUrl": "https://%s.vault.azure.net/",
                "description": "Governance KeyVault"
            }
        }
    ' "${keyVaultName}")
    az rest --method put --resource "https://purview.azure.net" --url $createKeyVaultURL --body "$KeyVaultBody"
    echo "Created KeyVault Connection: $keyVaultName"
}

##############
echo "Deploying Purview"

# Create Collection
CreateCollection 'localdev' "$apv_name"
CreateCollection 'adventureworks' 'localdev'

# Create KeyVault

CreateKeyVault "$akv_name"


echo "Purview Deployment Complete"