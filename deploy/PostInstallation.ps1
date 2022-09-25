Set-ExecutionPolicy Unrestricted -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Function to create folders
function CreateFolder {
    param (
        [Parameter()] [String] $FolderName
    )

    if (Test-Path $FolderName) {
   
        Write-Host "Folder Exists"
    }
    else {
      
        #PowerShell Create directory if not exists
        New-Item $FolderName -ItemType Directory
        Write-Host "Folder Created successfully"
    }
    
}

#Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201
if (-not(Get-InstalledModule Az.Storage -ErrorAction silentlycontinue)) {
    Write-Host "Module does not exist"
    Write-Host "Installing NuGet"
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Write-Host "NuGet Installed"
    Write-Host "Installing Az.Storage"
    Install-Module Az.Storage -Force
    Write-Host "Module installed successfully"
}
else {
    Write-Host "Module exists"
}

# Storage account name and Container name
# $StorageAccountName = "1clickpocmigrationsqlmi"
$ContainerName = "databases"

# Give the connection string.
$ConnectionString = "BlobEndpoint=https://1clickpocmigrationsqlmi.blob.core.windows.net/;SharedAccessSignature=sv=2021-06-08&ss=bfqt&srt=co&sp=rwdlacupiytfx&se=2050-09-04T18:00:08Z&st=2022-09-04T10:00:08Z&spr=https&sig=8OSfBUeMjicbBbpq9LGqR9ZRkYoI1%2F8ZbsXz3SWT9O8%3D"
$Ctx = New-AzStorageContext -ConnectionString $ConnectionString
## ?sv=2021-06-08&ss=bfqt&srt=co&sp=rwdlacupiytfx&se=2050-09-04T18:00:08Z&st=2022-09-04T10:00:08Z&spr=https&sig=8OSfBUeMjicbBbpq9LGqR9ZRkYoI1%2F8ZbsXz3SWT9O8%3D
## https://1clickpocmigrationsqlmi.blob.core.windows.net/?sv=2021-06-08&ss=bfqt&srt=co&sp=rwdlacupiytfx&se=2050-09-04T18:00:08Z&st=2022-09-04T10:00:08Z&spr=https&sig=8OSfBUeMjicbBbpq9LGqR9ZRkYoI1%2F8ZbsXz3SWT9O8%3D

#Download File
$FileName1 = "AdventureWorks2019.bak"
$FileName2 = "AW_with_issues.bak"

#Destination Path
$localTargetDirectory = "C:\temp\1clickPoC"

#Create Folders
CreateFolder $localTargetDirectory

#Download Blob to the Destination Path
Write-Host "Downloading files"
Get-AzStorageBlobContent -Blob $FileName1 -Container $ContainerName -Destination $localTargetDirectory -Context $ctx -Force
Get-AzStorageBlobContent -Blob $FileName2 -Container $ContainerName -Destination $localTargetDirectory -Context $ctx -Force
Write-Host "Files downloaded successfully"

#Install Software
Write-Host "Installing Azure Data Studio"
choco install azure-data-studio -y
choco install azure-cli -y

# Define clear text string for username and password
[string]$userName = 'sqladmin'
[string]$userPassword = 'My$upp3r$ecret'

# Enable FILESTREAM
Write-Host "Enabling Filestream"
$instance = "MSSQLSERVER"
$wmi = Get-WmiObject -Namespace "ROOT\Microsoft\SqlServer\ComputerManagement15" -Class FilestreamSettings | Where-Object { $_.InstanceName -eq $instance }
$wmi.EnableFilestream(3, $instance)
Get-Service -Name $instance | Restart-Service
Write-Host "SQL Server was restarted"
Write-Host "Configuring Filestream"
Import-Module "sqlps" -DisableNameChecking
Invoke-Sqlcmd "EXEC sp_configure filestream_access_level, 2" -Username $userName -Password $userPassword
Invoke-Sqlcmd "RECONFIGURE" -Username $userName -Password $userPassword
Write-Host "Filestream configured"

Write-Host "Restoring database"
Invoke-Sqlcmd "RESTORE DATABASE [AdventureWorks2019] FROM DISK = N'C:\temp\1clickPoC\AdventureWorks2019.bak' WITH FILE = 1 , MOVE N'AdventureWorks2017'  TO N'F:\SQLData\AdventureWorks2019.mdf', MOVE N'AdventureWorks2017_log' TO N'G:\SQLLog\AdventureWorks2019_log.ldf', NOUNLOAD, STATS = 5;" -Username $userName -Password $userPassword
Invoke-Sqlcmd "RESTORE DATABASE [AdventureWorks_with_issues] FROM DISK = N'C:\temp\1clickPoC\AW_with_issues.bak'WITH FILE = 1, MOVE N'AdventureWorksLT2012_Data' TO N'F:\SQLData\AdventureWorksLT2012.mdf', MOVE N'AdventureWorksLT2012_Log' TO N'G:\SQLLog\AdventureWorksLT2012_log.ldf', MOVE N'AdventureWorksLT2012_Log2' TO N'G:\SQLLog\AdventureWorksLT2012_log2.ldf', MOVE N'Photos1' TO N'F:\SQLData\Photos1.ndf', NOUNLOAD;" -Username $userName -Password $userPassword
Write-Host "Restore completed"
