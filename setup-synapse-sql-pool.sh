#!/bin/bash

# Setup a Synapse SQL Pool in Azure.
#
# Prerequisites:
# - An up-to-date Azure CLI, see https://docs.microsoft.com/de-de/cli/azure/install-azure-cli-apt
#   This script was written and tested with Azure CLI version 2.11.1.
#
# Notes: - This script is provided "as is". Feel free to use it but don't blame me if things go wrong.
#          Especially, this script has NOT been developed or tested for production use. Use at your
#          own risk.
#        - Be aware that the script below deletes resources in Azure. Ensure that the configuration
#          settings match your intention before running the script. Otherwise you may unintentionally
#          delete the wrong resources. You have been warned.
#        - To remove the entire resource group once you are done, run:
#          az group delete --name <resource group name>

# stop on first error
set -e

# configuration
# either set an env variable named AZURE_SUBSCRIPTION_ID or provide a hard-coded value.
subscriptionId=$AZURE_SUBSCRIPTION_ID
randomNumber=$((1 + RANDOM % 1000))
resourceGroupName="SynapsePoC"
location="westeurope"
synapseStorageAccount="synapsestorageaccount$randomNumber"
synapseFileSystem="synapsefilesystem$randomNumber"
synapseWorkspaceName="synapseworkspace$randomNumber"
synapseSqlPoolName="sqlpool$randomNumber"
synapsePerformanceLevel="DW100c"

# login to Azure
echo "Signing in to Azure..."
az login
az account set --subscription "$subscriptionId"

# ask for new SQL admin name and password
echo "Please enter the credentials of the new SQL admin user to create."
echo "---"
echo "IMPORTANT: Your password has to meet Synapse's password policy. This script does NOT check if your password complies with it."
echo "           The script below will fail if the password does not comply."
echo "For more infos, see https://docs.microsoft.com/en-us/sql/relational-databases/security/password-policy."
echo "---"
read -r -p "New Synapse SQL admin user name: " synapseAdminName
read -r -s -p "Password: " synapseAdminPW
echo
read -r -s -p "Retype password: " synapseAdminPWRetype
while [ "$synapseAdminPW" != "$synapseAdminPWRetype" ]; do
    echo
    echo "Passwords did not match. Please try again."
    read -r -s -p "Password: " synapseAdminPW
    echo
    read -r -s -p "Password (again): " synapseAdminPWRetype
done
echo

# enable Synapse extension
# note: might be part of Azure CLI meanwhile, try installing the extension if it does not work out-of-the-box.
echo "Enabling Synapse extension..."
az extension add --name synapse

# delete resource group if pre-exists
echo "Checking if resource group exists already..."
if [ "$(az group exists --name $resourceGroupName)" = "true" ]; then
    echo "Resource group '$resourceGroupName' exists already. Use a different resource group or delete the resource group before running this script."
    exit
fi

# create resource group
echo "Creating resource group..."
az group create --name $resourceGroupName --location $location

# create storage account
echo "Creating storage account..."
az storage account create --name $synapseStorageAccount \
    --resource-group $resourceGroupName \
    --access-tier Hot \
    --enable-hierarchical-namespace true \
    --kind StorageV2 \
    --location $location \
    --sku Standard_RAGRS

# create file system
echo "Creating file system..."
connectString=$(az storage account show-connection-string -g $resourceGroupName -n $synapseStorageAccount -o tsv)

az storage container create --name $synapseFileSystem \
    --account-name $synapseStorageAccount \
    --connection-string "$connectString"

# create Synapse workspace
echo "Creating Synapse workspace..."
az synapse workspace create --name $synapseWorkspaceName \
    --resource-group $resourceGroupName \
    --storage-account $synapseStorageAccount \
    --file-system $synapseFileSystem \
    --sql-admin-login-user "$synapseAdminName" \
    --sql-admin-login-password "$synapseAdminPW" \
    --location $location

# create Synapse SQL pool
echo "Creating Synapse SQL pool..."
az synapse sql pool create --resource-group $resourceGroupName \
    --workspace-name $synapseWorkspaceName \
    --name $synapseSqlPoolName \
    --performance-level $synapsePerformanceLevel

# set permissions
echo "Setting permissions..."
identity=$(az synapse workspace show --name $synapseWorkspaceName --resource-group $resourceGroupName --query "identity.principalId" -o tsv)
az role assignment create --role "Storage Blob Data Contributor" \
    --assignee-object-id "$identity" \
    --scope "$(az storage account show -g $resourceGroupName -n $synapseStorageAccount --query 'id' -o tsv)"

# configure firewall
echo "Configuring firewall..."
echo "Beware: This allows access from ANY IP address. This should be adjusted for production environments."
az synapse workspace firewall-rule create --resource-group $resourceGroupName \
    --workspace-name $synapseWorkspaceName \
    --name allowAll \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 255.255.255.255
#ipaddress=$(curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//')

# pause SQL pool
echo "Pause SQL pool..."
az synapse sql pool pause --name $synapseSqlPoolName \
    --resource-group $resourceGroupName \
    --workspace-name $synapseWorkspaceName

# tell we're done
echo "Done."
echo "Synapse SQL Pool name = '$synapseSqlPoolName'"