# Set the minimum version required for 7-Zip
$MinimumVersion = '24.01.00.0'

# Initialize a version object to store the parsed minimum version
$minVersionObj = $null

# Validate the minimum version format
if (-not [Version]::TryParse($MinimumVersion, [ref]$minVersionObj)) {
    Write-Output "Invalid format for Minimum Version."
    exit 1
}

# Define the registry path where 7-Zip information is stored
$registryPath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'

# Initialize exit code variable
$exitCode = 0

# Query the registry for information about 7-Zip
$7Zip = Get-ItemProperty -Path $registryPath | Where-Object { $_.DisplayName -like '*7-Zip*' }

if ($7Zip) {
    $Version = $7Zip.DisplayVersion
    Write-Output "7-Zip detected. Version: $Version"
    
    $currentVersionObj = $null
    if (-not [Version]::TryParse($Version, [ref]$currentVersionObj)) {
        Write-Output "Invalid format for detected 7-Zip version."
        $exitCode = 1
    } elseif ($currentVersionObj -lt $minVersionObj) {
        Write-Output "Uninstalling 7-Zip version $Version..."
        
        $7ZipProductCode = $7Zip.ModifyPath -replace '^.*?(\{[A-F0-9\-]+\}).*$', '$1'
        
        # Use Start-Process with -PassThru to get the process object
        try {
            Write-Output "Executing uninstall command: msiexec.exe /x `"$7ZipProductCode`" /qn /norestart"
            $process = Start-Process "msiexec.exe" -ArgumentList "/x `"$7ZipProductCode`" /qn /norestart" -Wait -PassThru -NoNewWindow
            # Wait for the process to exit and then check the exit code
            $process.WaitForExit()
            if ($process.ExitCode -ne 0) {
                Write-Output "Failed to uninstall 7-Zip. Error: Exit code $($process.ExitCode)"
                $exitCode = 1
            } else {
                Write-Output "7-Zip version $Version has been successfully uninstalled."
            }
        } catch {
            Write-Output "An error occurred while attempting to uninstall 7-Zip: Error: $_"
            $exitCode = 1
        }
    } else {
        Write-Output "No action required. 7-Zip version meets or exceeds the minimum requirement."
    }
} else {
    Write-Output "7-Zip is not installed. This is considered successful for the purpose of this script."
}

exit $exitCode
