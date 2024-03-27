# Set the minimum version required for 7-Zip
$MinimumVersion = '23.01.00.0'

# Define the registry path where 7-Zip information is stored
$registryPath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'

# Query the registry for information about 7-Zip
$7Zip = Get-ItemProperty -Path $registryPath | Where-Object { $_.DisplayName -like '*7-Zip*' }

$exitCode = 0

# If 7-Zip is found
if ($7Zip) {
    # Retrieve the version of the installed 7-Zip
    $Version = $7Zip.DisplayVersion
    Write-Output "7-Zip detected. Version: $Version"
    
    # Extract the IdentifyingNumber from ModifyPath and set it to $7ZipProductCode
    $7ZipProductCode = $7Zip.ModifyPath -replace '^.*?(\{[A-F0-9\-]+\}).*$', '$1'
    
    # Compare the version with the minimum required version
    if ($Version -lt $MinimumVersion) {
        Write-Output "Uninstalling 7-Zip version $Version..."
        
        # Define the uninstallation command
        $UninstallCommand = "/x `"$($7ZipProductCode)`" /qn"
        
        # Attempt to uninstall 7-Zip
        $process = Start-Process "msiexec.exe" -ArgumentList $UninstallCommand -PassThru -Wait
        
        # Check if uninstallation was successful
        if ($process.ExitCode -eq 0) {
            Write-Output "7-Zip version $Version has been uninstalled."
        } else {
            Write-Output "Failed to uninstall 7-Zip. Exit code: $($process.ExitCode)"
            $exitCode = 1
        }
    } else {
        Write-Output "No action required. 7-Zip version meets minimum requirement."
    }
} else {
    # If 7-Zip is not found
    Write-Output "7-Zip is not installed."
    $exitCode = 1
}
exit $exitCode
