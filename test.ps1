# Target version of 7-Zip that should remain installed
$targetVersion = "19.00"  # Adjust this to the version you wish to keep

# Function to check if a specific version of 7-Zip is installed
function Is-7ZipInstalled {
    param (
        [Version]$versionToCheck
    )

    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $regPaths) {
        $installedSoftware = Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*7-Zip*" }
        
        foreach ($software in $installedSoftware) {
            if ([Version]$software.DisplayVersion -eq $versionToCheck) {
                return $true
            }
        }
    }

    return $false
}

# Function to uninstall non-target versions of 7-Zip and verify their removal
function Uninstall-NonTarget7ZipVersions {
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $regPaths) {
        $installedSoftware = Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*7-Zip*" }
        
        foreach ($software in $installedSoftware) {
            $installedVersion = [Version]$software.DisplayVersion

            if ($installedVersion -ne $targetVersion) {
                # Construct the uninstall string
                $uninstallString = $software.UninstallString -replace "msiexec.exe", "msiexec.exe /x" -replace "/I", "/x"

                # Execute the uninstall command silently
                Start-Process cmd.exe -ArgumentList "/c $uninstallString /quiet" -Wait -NoNewWindow

                # Wait a moment for the uninstall to complete
                Start-Sleep -Seconds 5

                # Verify if the version is still installed
                if (-not (Is-7ZipInstalled -versionToCheck $installedVersion)) {
                    Write-Output "Successfully uninstalled non-target 7-Zip version $installedVersion."
                } else {
                    Write-Output "Failed to uninstall 7-Zip version $installedVersion."
                }
            }
        }
    }
}

# Run the uninstall and verification function
Uninstall-NonTarget7ZipVersions

# Always exit with code 0 to indicate successful script execution
exit 0
