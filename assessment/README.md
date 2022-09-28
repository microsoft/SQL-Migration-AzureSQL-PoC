# Assessment

Assess your SQL Server databases for Azure SQL MI readiness or to identify any migration blockers before migrating them to Azure SQL MI.

The [Azure SQL migration extension for Azure Data Studio](https://learn.microsoft.com/en-us/sql/azure-data-studio/extensions/azure-sql-migration-extension?view=sql-server-ver16) enables you to assess, get Azure recommendations and migrate your SQL Server databases to Azure.

In addition, the Azure CLI command [az datamigration](https://learn.microsoft.com/en-us/cli/azure/datamigration?view=azure-cli-latest) can be used to manage data migration at scale.

## Prerequisites

- SQL Server with Windows authentication or SQL authentication access.
- .Net Core 3.1 (Already installed in the Jumpbox VM)
- Azure CLI (Already installed in the Jumpbox VM)  

## Getting Started

1. In the Azure Portal, find the resource group you just created and navigate to the Azure SQL VM.
2. In the overview page, copy the Public IP Address
    ![sqlvm-ip](../media/sqlvm-ip.png)

    > [!CAUTION]
    > Now you have to connect to the Jumpbox VM.
    > Use the credentials provided in the deploy page.

3. Install az datamigration extension. Open either a command shell or PowerShell as administrator.

    `az extension add --name datamigration`

4. Run the following to login from your client using your default web browser

    `az login`

    If you have more than one subscription, you can select a particular subscription.

    `az account set --subscription <subscription-id>`

## Run the assessment

1. We can run a SQL server assessment using the ***az datamigration get-assessment*** command.

    > [!IMPORTANT]
    > Change the IP Address

    `az datamigration get-assessment --connection-string "Data Source=20.2.100.5,1433;Initial Catalog=master;User Id=sqladmin;Password=My$upp3r$ecret" --output-folder "C:\Output" --overwrite`

2. Assessment at scale using config file

    We can also create a config file to use as a parameter to run assessment on SQL servers.The config file has the following structure:

    ```json
    {
        "action": "Assess",
        "outputFolder": "C:\\Output",
        "overwrite":  "True",
        "sqlConnectionStrings": [
            "Data Source=Server1.database.net;Initial Catalog=master;Integrated Security=True;",
            "Data Source=Server2.database.net;Initial Catalog=master;Integrated Security=True;"
        ]
    }
    ```

    The config file can be passed to the cmdlet in the following way

    `az datamigration get-assessment --config-file-path "C:\Users\user\document\config.json"`

    > [!TIP]
    > To view the report, go to **C:\Output** folder and check the json file.

    Learn more about using [CLI to assess sql server](https://github.com/Azure-Samples/data-migration-sql/blob/main/CLI/sql-server-assessment.md)

## Performance data collection

This step is optional. We already have a Azure SQL MI provisioned.

1. We can run a SQL server performance data collection using the ***az datamigration performance-data-collection*** command.

    `az datamigration performance-data-collection --connection-string "Data Source=20.2.100.5,1433;Initial Catalog=master;User Id=sqladmin;Password=My$upp3r$ecret" --output-folder "C:\Output" --perf-query-interval 10 --number-of-iteration 5 --static-query-interval 120`

    > [!TIP]
    > Collect as much data as you want, then stop the process.
    > To view the report, go to **C:\Output** folder and check the report file.

2. Running performance data collection at scale using config file

    We can also create a config file to use as a parameter to run performance data collection on SQL servers.
    The config file has the following structure:

    ```json
    {
        "action": "PerfDataCollection",
        "outputFolder": "C:\\Output",
        "perfQueryIntervalInSec": 20,
        "staticQueryIntervalInSec": 120,
        "numberOfIterations": 7,
        "sqlConnectionStrings": [
            "Data Source=Server1.database.net;Initial Catalog=master;Integrated Security=True;",
            "Data Source=Server2.database.net;Initial Catalog=master;Integrated Security=True;"
        ]
    }
    ```

    The config file can be passed to the cmdlet in the following way.

    `az datamigration performance-data-collection --config-file-path "C:\Users\user\document\config.json"`

    > [!TIP]
    > You can look into the output folder to find a CSV file which also gives the details of performance data collected.

    Learn more about using [CLI to perform data collection](https://github.com/Azure-Samples/data-migration-sql/blob/main/CLI/sql-server-sku-recommendation.md#performance-data-collection-using-connection-string)

## SKU Recommendation

This step is optional. We already have a Azure SQL MI provisioned.

1. We can get SKU recommendation using the **az datamigration get-sku-recommendation** command.

    `az datamigration get-sku-recommendation --output-folder "C:\Output" --display-result --overwrite`

2. Getting SKU recommendation at scale using config file.

    We can also create a config file to use as a parameter to get SKU recommendation on SQL servers.The config file has the following structure:

    ```json
    {
        "action": "GetSKURecommendation",
        "outputFolder": "C:\\Output",
        "overwrite":  "True",
        "displayResult": "True",
        "targetPlatform": "any",
        "scalingFactor": 1000
    }
    ```

    > [!TIP]
    > You can look into the output folder to find a HTML file which also gives the details of SKU being recommended.

    Learn more about using [CLI to get SKU recommendation](https://github.com/Azure-Samples/data-migration-sql/blob/main/CLI/sql-server-sku-recommendation.md#performance-data-collection-using-connection-string)

## Page Navigator

[Index: Table of Contents]()

[Prev: 1 Click Deploy](../deploy/README.md)

[Next: Migration](../migration/README.md)
