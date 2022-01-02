#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

####################################
# Variables
# HIVEKEYVAULTRESOURCEID
# HIVEKEYVAULTDNSNAME
# DATABRICKSHOSTURL
# DATABRICKSWORKSPACESUBSCRIPTIONID
# DATABRICKSWORKSPACERESOURCEGROUPNAME
# DATABRICKSWORKSPACENAME
# LOGKEYVAULTRESOURCEID
# LOGKEYVAULTDNSNAME
# JOBPOLICY
####################################


# HIVEKEYVAULTRESOURCEID='/subscriptions/d8e5e9d7-9314-492c-8734-1728139a350d/resourceGroups/rg-adbconfig-0182-verify/providers/Microsoft.KeyVault/vaults/mkvadbconfig0182verify'
# HIVEKEYVAULTDNSNAME='https://mkvadbconfig0182verify.vault.azure.net/'
# DATABRICKSHOSTURL='https://adb-6041374376217211.11.azuredatabricks.net/'
# DATABRICKSWORKSPACESUBSCRIPTIONID='d8e5e9d7-9314-492c-8734-1728139a350d'
# DATABRICKSWORKSPACERESOURCEGROUPNAME='rg-adbconfig-0182-verify'
# DATABRICKSWORKSPACENAME='adb002-adbconfig-0182-verify'
# LOGKEYVAULTRESOURCEID='/subscriptions/d8e5e9d7-9314-492c-8734-1728139a350d/resourceGroups/rg-adbconfig-0182-verify/providers/Microsoft.KeyVault/vaults/lkvadbconfig0182verify'
# LOGKEYVAULTDNSNAME='https://lkvadbconfig0182verify.vault.azure.net/'

databricksHostUrl=$DATABRICKSHOSTURL
databricksWorkspaceSubscriptionId=$DATABRICKSWORKSPACESUBSCRIPTIONID
databricksWorkspaceResourceGroupName=$DATABRICKSWORKSPACERESOURCEGROUPNAME
databricksWorkspaceName=$DATABRICKSWORKSPACENAME

hiveKeyVaultResourceId=$HIVEKEYVAULTRESOURCEID
hiveKeyVaultDnsName=$HIVEKEYVAULTDNSNAME
hiveScopeName='hiveSecretScope'

logKeyVaultResourceId=$LOGKEYVAULTRESOURCEID
logKeyVaultDnsName=$LOGKEYVAULTDNSNAME
logScopeName='logAnalyticsSecretScope'

jobPolicy=$JOBPOLICY

echo "Start deploying databricks "$databricksWorkspaceName

export DATABRICKS_AAD_TOKEN=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d | jq .accessToken --raw-output)
databricks configure --aad-token --host "${databricksHostUrl}"

adbTmpDir=.tmp/databricks
mkdir -p $adbTmpDir && cp -a ./landing-core/code/databricks .tmp/
tmpfile=.tmpfile
################################################################
# Log Analytics configure
# upload spark-monitoring.sh

sed -i -e "s/AZ_SUBSCRIPTION_ID=/AZ_SUBSCRIPTION_ID=${databricksWorkspaceSubscriptionId}/" "${adbTmpDir}"/applicationLogging/spark-monitoring.sh
sed -i -e "s/AZ_RSRC_GRP_NAME=/AZ_RSRC_GRP_NAME=${databricksWorkspaceResourceGroupName}/" "${adbTmpDir}"/applicationLogging/spark-monitoring.sh
sed -i -e "s/AZ_RSRC_NAME=/AZ_RSRC_NAME=${databricksWorkspaceName}/" "${adbTmpDir}"/applicationLogging/spark-monitoring.sh

dbfs cp ${adbTmpDir}/applicationLogging/spark-monitoring.sh 'dbfs:/databricks/spark-monitoring/spark-monitoring.sh' --overwrite 

# execute configration Notebook
databricks workspace import --language SCALA ./landing-core/code/databricks/ConfigureDatabricksWorkspace.scala /ConfigureDatabricksWorkspace 

runs=$(databricks runs submit --json-file ./landing-core/code/databricks/submit-run.json)
runId=$(echo $runs | jq -r '.run_id')

echo "execute configration Notebook"
runResult=$(databricks runs get --run-id $runId)
runPageUrl=$(echo $runResult | jq -r '.run_page_url')
echo 'run_page_url is' $runPageUrl
# runStatus=$(echo $runResult | jq -r '.state.result_state')

# sleep 600
# # reset token
# export DATABRICKS_AAD_TOKEN=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d | jq .accessToken --raw-output)
# databricks configure --aad-token --host "${databricksHostUrl}"

# while true
# do
#     runResult=$(databricks runs get --run-id $runId)
#     runStatus=$(echo $runResult | jq -r '.state.result_state')
#     lifeCycleState=$(echo $runResult | jq -r '.state.life_cycle_state')
#     if  [ $runStatus == 'SUCCESS' ]; then
#         echo "Job Complete"
#         break
#     fi
#     # echo $runStatus
#     echo 'Status:'"$lifeCycleState"'...'
#     sleep 30
# done

# databricks workspace delete  "/ConfigureDatabricksWorkspace"
################################################################
# Create Scope 
# Hive metastore setting
# Create hive secret scope
echo "Create Scope"

databricks secrets create-scope --scope "${hiveScopeName}" --scope-backend-type 'AZURE_KEYVAULT' \
--resource-id "${hiveKeyVaultResourceId}" --dns-name "${hiveKeyVaultDnsName}"

# put acl
databricks secrets put-acl --scope "${hiveScopeName}"  --permission READ --principal "users" 

# loganalytics setting
# Create logAnalytics secret scope
databricks secrets create-scope --scope "${logScopeName}" --scope-backend-type 'AZURE_KEYVAULT' \
--resource-id "${logKeyVaultResourceId}" --dns-name "${logKeyVaultDnsName}" 
# put acl
databricks secrets put-acl --scope "${logScopeName}" --permission READ --principal "users" 

################################################################
# create Policy

echo "Create Policy "

sleep 10

if  [ $jobPolicy == false ]; then
    # create allPurpose policy
    allPurposeDefinition=$(jq -c '.' ./landing-core/code/databricks/policies/allPurposePolicy.json) 
    jq --arg definition "$allPurposeDefinition" '.definition = $definition' ./landing-core/code/databricks/policies/allPurposePolicyBase.json \
    > "${adbTmpDir}"/policies/allPurposePolicy_updated.json
    databricks cluster-policies create --json-file "${adbTmpDir}"/policies/allPurposePolicy_updated.json 

else

    # create allPurpose policy
    jobDefinition=$(jq -c '.' ./landing-core/code/databricks/policies/jobPolicy.json) 
    jq --arg definition "$jobDefinition" '.definition = $definition' ./landing-core/code/databricks/policies/jobPolicyBase.json \
    > "${adbTmpDir}"/policies/jobPolicy_updated.json
    databricks cluster-policies create --json-file "${adbTmpDir}"/policies/jobPolicy_updated.json 

fi



echo "Finish deploying databricks "$databricksWorkspaceName

