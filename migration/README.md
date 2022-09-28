# Start database migration

Now, it's time to perform a online migration of the Adventureworks2019 database from SQL Server on Azure VM to an Azure SQL Managed Instance by using Microsoft Azure CLI.

1. Run the following to login from your client using your default web browser

    `az login`

    If you have more than one subscription, you can select a particular subscription.

    `az account set --subscription <subscription-id>`

    The [Azure SQL migration extension for Azure Data Studio](https://learn.microsoft.com/en-us/sql/azure-data-studio/extensions/azure-sql-migration-extension?view=sql-server-ver16) enables you to assess, get Azure recommendations and migrate your SQL Server databases to Azure.

    In addition, the Azure CLI command [az datamigration](https://learn.microsoft.com/en-us/cli/azure/datamigration?view=azure-cli-latest) can be used to manage data migration at scale.

2. Backup database

    Backup must be taken before starting the migration:
    - [Create SAS tokens for your storage containers](https://learn.microsoft.com/en-us/azure/cognitive-services/translator/document-translation/create-sas-tokens?tabs=Containers)
    - [Create a SQL Server credential using a shared access signature](https://learn.microsoft.com/en-us/sql/relational-databases/tutorial-use-azure-blob-storage-service-with-sql-server-2016?view=sql-server-ver16#2---create-a-sql-server-credential-using-a-shared-access-signature)
    - [Database backup to URL](https://learn.microsoft.com/en-us/sql/relational-databases/tutorial-use-azure-blob-storage-service-with-sql-server-2016?view=sql-server-ver16#3---database-backup-to-url)

    The following T-SQL is an example that creates the credential to use a Shared Access Signature and creates a backup.

    ```sql
    USE master
    CREATE CREDENTIAL [https://storagemigration.blob.core.windows.net/backup] 
      -- this name must match the container path, start with https and must not contain a forward slash at the end
    WITH IDENTITY='SHARED ACCESS SIGNATURE' 
      -- this is a mandatory string and should not be changed   
     , SECRET = 'XXXXXXX' 
       -- this is the shared access signature key. Don't forget to remove the first character "?"   
    GO
    
    -- Back up the full AdventureWorks2019 database to the container
    BACKUP DATABASE AdventureWorks2019 TO URL = 'https://storagemigration.blob.core.windows.net/backup/AdventureWorks2019.bak'
    WITH CHECKSUM
    ```

3. In the Azure Portal, find the resource group you just created and navigate to the Azure SQL VM.
4. In the overview page, copy the Public IP Address
    ![sqlvm-ip](../media/sqlvm-ip.png)

    > [!CAUTION]
    > Now you have to connect to the Jumpbox VM.
    > Use the credentials provided in the deploy page.

## Azure Database Migration Service

Use the az datamigration sql-managed-instance create command to  create new instance of Azure Database Migration Service.

    az datamigration sql-service create --resource-group "1clickpoc" --sql-migration-service-name "MySqlMigrationService" --location "<location>"

## Migration

1. **Online migration**

    Use the **az datamigration sql-managed-instance create** command to create and start a database migration.

    ```dotnetcli
    az datamigration sql-managed-instance create `
    --source-location '{\"AzureBlob\":{\"storageAccountResourceId\":\"/subscriptions/<SubscriptionId>/resourceGroups/<ResourceGroupName>/providers/Microsoft.Storage/storageAccounts/<StorageAccountName>\",\"accountKey\":\"<StorageKey>\",\"blobContainerName\":\"AdventureWorksContainer\"}}' `
    --migration-service "/subscriptions/<SubscriptionId>/resourceGroups/<ResourceGroupName>/providers/Microsoft.DataMigration/SqlMigrationServices/MySqlMigrationService" `
    --scope "/subscriptions/<SubscriptionId>/resourceGroups/<ResourceGroupName>/providers/Microsoft.Sql/managedInstances/<ManagedInstanceName>" `
    --source-database-name "AdventureWorks2019" `
    --source-sql-connection authentication="SqlAuthentication" data-source="<AzureSQLVM_IPAddress>" password="My$upp3r$ecret" user-name="sqladmin" `
    --target-db-name "AdventureWorks2019" `
    --resource-group <ResourceGroupName> `
    --managed-instance-name <ManagedInstanceName>
    ```

2. **Offline Migration**

    To start an offline migration, you should add **--offline-configuration** parameter.

    ```dotnetcli
    az datamigration sql-managed-instance create `
    --source-location '{\"AzureBlob\":{\"storageAccountResourceId\":\"/subscriptions/<SubscriptionId>/resourceGroups/<ResourceGroupName>/providers/Microsoft.Storage/storageAccounts/<StorageAccountName>\",\"accountKey\":\"<StorageKey>\",\"blobContainerName\":\"AdventureWorksContainer\"}}' `
    --migration-service "/subscriptions/<SubscriptionId>/resourceGroups/<ResourceGroupName>/providers/Microsoft.DataMigration/SqlMigrationServices/MySqlMigrationService" `
    --scope "/subscriptions/<SubscriptionId>/resourceGroups/<ResourceGroupName>/providers/Microsoft.Sql/managedInstances/<ManagedInstanceName>" `
    --source-database-name "AdventureWorks2019" `
    --source-sql-connection authentication="SqlAuthentication" data-source="<AzureSQLVM_IPAddress>" password="My$upp3r$ecret" user-name="sqladmin" `
    --target-db-name "AdventureWorks2019" `
    --resource-group <ResourceGroupName> `
    --managed-instance-name <ManagedInstanceName>
    --offline-configuration last-backup-name="AdventureWorksTransactionLog2.trn" offline=true
    ```

    > [!TIP]
    > You should take all necessary backups.

    Learn more about using [CLI to migrate](https://github.com/Azure-Samples/data-migration-sql/blob/main/CLI/sql-server-to-sql-mi-blob.md#start-online-database-migration)

3. Monitoring

    To monitor the migration, check the status of task.
    1. Gets complete migration detail

        ```dotnetcli
        az datamigration sql-managed-instance show --managed-instance-name "<ManagedInstanceName>" --resource-group "<ResourceGroupName>" --target-db-name "AdventureWorks2019" --expand=MigrationStatusDetails
        ```

    2. *ProvisioningState* should be "**Creating**", "**Failed**" or "**Succeeded**"

        ```dotnetcli
        az datamigration sql-managed-instance show --managed-instance-name "<ManagedInstanceName>" --resource-group "<ResourceGroupName>" --target-db-name "AdventureWorks2019" --expand=MigrationStatusDetails --query "properties.provisioningState"
        ```

    3. *MigrationStatus* should be "**InProgress**", "**Canceling**", "**Failed**" or "**Succeeded**"

        ```dotnetcli
        az datamigration sql-managed-instance show --managed-instance-name "<ManagedInstanceName>" --resource-group "<ResourceGroupName>" --target-db-name "AdventureWorks2019" --expand=MigrationStatusDetails --query "properties.migrationStatus"
        ```

4. Cutover

    Use the **az datamigration sql-managed-instance cutover** command to perform cutover.

    1. Obtain the MigrationOperationId

        ```dotnetcli
        $migOpId = az datamigration sql-managed-instance show --managed-instance-name "<ManagedInstanceName>" --resource-group "<ResourceGroupName>" --target-db-name "AdventureWorks2019" --expand=MigrationStatusDetails --query "properties.migrationOperationId"
        ```

    2. Perform Cutover

        ```dotnetcli
        az datamigration sql-managed-instance cutover --managed-instance-name "<ManagedInstanceName>" --resource-group "<ResourceGroupName>" --target-db-name "AdventureWorks2019" --migration-operation-id $migOpId
        ```

## Migrating at scale

This script performs an [end to end migration of a multiple databases in multiple servers](https://github.com/Azure-Samples/data-migration-sql/tree/main/CLI/scripts/multiple%20databases)
