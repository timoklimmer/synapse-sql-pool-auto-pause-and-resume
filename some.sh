#!/usr/bin/env bash

export RESOURCE_GROUP=SynapsePoC
export SYNAPSE_WORKSPACE_NAME=synapseworkspace655
export SQL_POOL_NAME=sqlpool655
export SQL_SERVER_ENDPOINT=synapseworkspace655.sql.azuresynapse.net
export SQL_DATABASE=sqlpool655
export SQL_USER=fidge
export SQL_PASSWORD=myP@sswordIsG00d


# if SQL Pool is online
if [ "$(az synapse sql pool show --name "$SQL_POOL_NAME" --workspace-name "$SYNAPSE_WORKSPACE_NAME" \
        --resource-group "$RESOURCE_GROUP" --query "status" -o tsv)" = "Online" ]; then
    echo "SQL Pool is online."

    # ...and can be paused:
    sudo curl https://packages.microsoft.com/keys/microsoft.asc -o gpg.keys
    sudo apt-key add gpg.keys
    sudo curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list -o /etc/apt/sources.list.d/msprod.list
    sudo apt-get update
    sudo apt-get -y install mssql-tools unixodbc-dev
    export PATH="$PATH:/opt/mssql-tools/bin"
    if [ "$(sqlcmd -S "$SQL_SERVER_ENDPOINT" -d "$SQL_DATABASE" -U "$SQL_USER" -P "$SQL_PASSWORD" -I \
            -i "$GITHUB_WORKSPACE/can_pause.sql" -h -1 -W)" = "1" ]; then
        echo "SQL Pool can be paused."
        
        # pause it
        echo "Pausing SQL Pool..."
        az synapse sql pool pause --name "$SQL_POOL_NAME" --workspace-name "$SYNAPSE_WORKSPACE_NAME" \
            --resource-group "$RESOURCE_GROUP"
    fi
fi