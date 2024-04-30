# Define a list of software checks. Each check has a name, local path, installer path, and process name.

$centralPath = "C:\USEFUL_TOOLS\Software Updater\TEST\" # <<<<<< change to central repo for your softare updaters

# Defines the temp folder for copying the installers to
$tempPath = "C:\USEFUL_TOOLS\Software Updater\Temp\"

# Defines locations specifically for the script itself
$currentScriptPath = $MyInvocation.MyCommand.Path
$updatedScriptPath = "$centralPath\Software Updater.ps1"
$updatedScriptHashPath = "C:\USEFUL_TOOLS\Software Updater\Hashes\Script.txt"

# Defines the software to check for updates, add more as required
$softwareChecks = @(
    @{
        Name          = "X-Ways"; # Software name
        LocalPath     = "D:\XWays\"; # Path to the current install exe - Not needed for traditionally installed programs
        InstallerPath = "$centralPath\X-Ways\"; # Parent folder of the installer exe
        ProcessName   = "xwforensics64"; # Name of the process to check before updating
        InstallArgs   = "/sp /SILENT" # Installer arguments if applicable - not needed for Xways
    },
    @{
        Name          = "VLC"; 
        InstallerPath = "$centralPath\VLC\"; 
        ProcessName   = "vlc"; 
        InstallArgs   = "/L=1033 /S" 
    },
    @{
        Name          = "Notepad++"; 
        InstallerPath = "$centralPath\Notepad++\"; 
        ProcessName   = "notepad++"; 
        InstallArgs   = "/S" 
    },
    @{
        Name          = "7zip"; 
        InstallerPath = "$centralPath\7zip\"; 
        ProcessName   = "7zFM"; 
        InstallArgs   = "/S" 
    }
)


# Displays header when the script starts

Write-Host @("
╔═══════════════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                               ║
║                                     Software Updater                                          ║
║                                       Version 1.2                                             ║
║                                  Last Update: 08/02/2024                                      ║
╠═══════════════════════════════════════════════════════════════════════════════════════════════╣
║                                                                                               ║
║                                                                                               ║
║                                                                                               ║
║                              Update checks starting.......                                    ║
║                                                                                               ║
║                                                                                               ║
║                                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════════════════════╝
")

#---------------------------------------------------------------------------------------
# Handle updating Xways due to it being a zip not exe
#---------------------------------------------------------------------------------------
function CheckAndUpdateXWays {
    param (
        [string]$name,
        [string]$localPath,
        [string]$installerPath,
        [string]$processName
    )

    Write-Host "Checking for updates for X-Ways..."

    # Check if the specified process is running
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if ($process) {
        # Process is running, ask the user if they want to quit the process
        $userChoice = Read-Host "The process '$processName' is running for $name. Do you want to quit the process and proceed with the update? (Y/N)"
        if ($userChoice -eq 'Y' -or $userChoice -eq 'y') {
            # User chose to quit the process
            $process | Stop-Process -Force
        }
        else {
            # User chose not to quit the process, skip this software check
            Write-Host "Skipping update for $name due to a running process."
            return
        }
    }

    # Create a folder in the temp directory named after the software
    $softwareTempPath = Join-Path -Path $tempPath -ChildPath $name
    if (-not (Test-Path $softwareTempPath)) {
        New-Item -ItemType Directory -Path $softwareTempPath
    }

    Write-Host "Copying X-Ways installer contents to $softwareTempPath..."
    Copy-Item "$installerPath\*" -Destination $softwareTempPath -Recurse -Force

    # Check if a zip file exists in the temp folder
    $zipFilePath = Get-ChildItem $softwareTempPath -Filter "*.zip" | Select-Object -ExpandProperty FullName
    if ($zipFilePath) {
        # Calculate the hash of the downloaded zip file
        $currentZipHash = Get-FileHash -Algorithm MD5 -Path $zipFilePath | Select-Object -ExpandProperty Hash

        # Check if the hash file exists and contains a hash
        $hashFilePath = Join-Path -Path 'C:\USEFUL_TOOLS\Software Updater\Hashes\' -ChildPath "$($name).txt"
        $localZipHash = $null

        if (Test-Path $hashFilePath) {
            # Read the stored hash from the file
            $localZipHash = Get-Content -Path $hashFilePath
        }

        # Compare the hashes
        if ($localZipHash -ne $currentZipHash) {
            # Extract the contents of the zip file to the local installation path
            Expand-Archive -Path $zipFilePath -DestinationPath $localPath -Force
            Write-Host "X-Ways update extracted to $localPath."

            # Update the hash file with the new hash
            $currentZipHash | Set-Content -Path $hashFilePath
        }
        else {
            Write-Host "$name is already up to date."
        }
    }
    else {
        Write-Host "No zip file found in $softwareTempPath. Skipping update for $name."
    }
}
#---------------------------------------------------------------------------------------
# Handle updating other normal exe software updates
#---------------------------------------------------------------------------------------
function CheckAndUpdateSoftware {
    param (
        [string]$name,
        [string]$localPath,
        [string]$installerPath,
        [string]$processName,
        [string]$installArgs,
        [bool]$fileNameVersion
    )

    Write-Host "Checking for updates for $name..."

    # Define hash file path
    $hashFilePath = Join-Path -Path 'C:\USEFUL_TOOLS\Software Updater\hashes\' -ChildPath "$($name).txt"

    # Calculate the hash of the installer file on the server
    $serverExePath = Get-ChildItem $installerPath -Filter "*.exe" | Select-Object -First 1
    if ($null -eq $serverExePath) {
        Write-Host "No installer found for $name. Skipping update."
        return
    }
    $serverExeHash = Get-FileHash -Algorithm MD5 -Path $serverExePath.FullName | Select-Object -ExpandProperty Hash

    # Compare with local hash
    if (Test-Path $hashFilePath) {
        $localExeHash = Get-Content -Path $hashFilePath
        if ($serverExeHash -eq $localExeHash) {
            Write-Host "$name is already up to date."
            return
        }
    }

    # Create a folder in the temp directory named after the software
    $softwareTempPath = Join-Path -Path $tempPath -ChildPath $name
    if (-not (Test-Path $softwareTempPath)) {
        New-Item -ItemType Directory -Path $softwareTempPath | Out-Null
    }

    # Check if the specified process is running
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if ($process) {
        $userChoice = Read-Host "The process '$processName' is running for $name. Do you want to quit the process and proceed with the update? (Y/N)"
        if ($userChoice -eq 'Y' -or $userChoice -eq 'y') {
            $process | Stop-Process -Force
        }
        else {
            Write-Host "Skipping update for $name due to a running process."
            return
        }
    }

    Write-Host "Copying installer contents to $softwareTempPath..."
    Copy-Item "$installerPath\*" -Destination $softwareTempPath -Recurse -Force

    # Proceed with installation using the copied executable
    $tempExePath = Join-Path -Path $softwareTempPath -ChildPath $serverExePath.Name

    Write-Host "Update available for $name. Local version appears to differ."
    Write-Host "Launching installer for $name ..."
    Write-host "If no installer launches then it may be silent and no GUI presented. Script will continue when complete!"

    Start-Process $tempExePath -ArgumentList $installArgs -Wait
	

    # Wait for the installation to complete if necessary
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "Waiting for $name installation to complete..."
        Wait-Process -InputObject $process
    }

    Write-Host "$name installation has completed."

    # Update the hash file with the new hash
    $serverExeHash | Set-Content -Path $hashFilePath
}

#---------------------------------------------------------------------------------------
# Handle updating the script so new software can be added to each user
#---------------------------------------------------------------------------------------
function Update-ScriptSelf {
    param (
        [string]$currentScriptPath,
        [string]$updatedScriptPath,
        [string]$updatedScriptHashPath
    )

    # Calculate the hash of the current script
    $currentScriptHash = Get-FileHash -Algorithm MD5 -Path $currentScriptPath | Select-Object -ExpandProperty Hash

    # Check if the hash file exists
    if (-not (Test-Path $updatedScriptHashPath)) {
        # Hash file doesn't exist, create it with the current script's hash
        Write-Host "Hash file not found. Creating hash file..."
        $currentScriptHash | Set-Content -Path $updatedScriptHashPath
    }

    # Read the hash of the updated script from the specified path
    $updatedScriptHash = Get-Content -Path $updatedScriptHashPath

    # Compare the hashes to determine if the script needs updating
    if ($currentScriptHash -ne $updatedScriptHash) {
        Write-Host "An update is available for this script. Updating now..."

        # Ensure the updated script is accessible before attempting to copy
        if (Test-Path $updatedScriptPath) {
            # Replace the current script with the updated script
            Copy-Item -Path $updatedScriptPath -Destination $currentScriptPath -Force

            # Update the hash file with the new script's hash
            $currentScriptHash | Set-Content -Path $updatedScriptHashPath

            Write-Host "The script has been updated. The next run will include any new changes or software additions."
            exit
        }
        else {
            Write-Host "The updated script was not found at the specified location: $updatedScriptPath"
        }
    }
    else {
        Write-Host "This script is already up to date."
    }
}

#---------------------------------------------------------------------------------------
# Script starts here and calls required functions
#---------------------------------------------------------------------------------------
# Iterate over each software check and perform update checks
foreach ($check in $softwareChecks) {
    # Ensure fileNameVersion is a valid boolean, default to $false if not specified
    if (-not $check.ContainsKey('FileNameVersion')) {
        $check['FileNameVersion'] = $false
    }

    if ($check.Name -eq "X-Ways") {
        CheckAndUpdateXWays -name $check.Name -localPath $check.LocalPath -installerPath $check.InstallerPath -processName $check.ProcessName
    }
    else {
        CheckAndUpdateSoftware -name $check.Name -localPath $check.LocalPath -installerPath $check.InstallerPath -processName $check.ProcessName -installArgs $check.InstallArgs -fileNameVersion $check.FileNameVersion
    }
    Write-Host "`n---------------------------------------------------------`n"
}

Write-Host "Checking for new version of updater script..."
# Call the update function
Update-ScriptSelf -currentScriptPath $currentScriptPath -updatedScriptPath $updatedScriptPath -updatedScriptHashPath $updatedScriptHashPath

# Cleans the temp folder
Get-ChildItem -Path $tempPath -File -Recurse | Remove-Item -Force


Write-Host "`nUpdate checks complete."
Write-Host "Temp folder cleaned."
Read-Host "`nPress enter to exit!"

