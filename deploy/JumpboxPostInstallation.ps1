Set-ExecutionPolicy Unrestricted -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
#Install Software
Write-Host "Installing Azure Data Studio"
choco install azure-data-studio -y
choco install azure-cli -y
choco install dotnetcore -y

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

#Destination Path
$localTargetDirectory = "C:\Output"

#Create Folders
CreateFolder $localTargetDirectory
