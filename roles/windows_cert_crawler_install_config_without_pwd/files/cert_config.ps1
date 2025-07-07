Param(
    [Parameter(Mandatory = $true)]
    [string]$installPath,

    [Parameter(Mandatory = $true)]
    [string]$jsonB64,

    [string]$extRootCert,

    [string]$firstTimeInstallString
)

try {
    # Decode Base64 JSON string
    $jsonText = [System.Text.Encoding]::UTF8.GetString(
        [System.Convert]::FromBase64String($jsonB64)
    )

    Write-Host "DEBUG: Raw decoded JSON text:"
    Write-Host $jsonText

    # Parse top-level JSON object
    $parsedJson = $jsonText | ConvertFrom-Json

    # If $parsedJson.certs is a string, convert it properly
    if ($parsedJson.certs -is [string]) {
        Write-Host "DEBUG: certs was a string, cleaning..."
        $cleanCerts = $parsedJson.certs -replace "'", '"'
        $cleanCerts = $cleanCerts.Trim()
        Write-Host "DEBUG: Cleaned certs JSON string:"
        Write-Host $cleanCerts
        $certList = $cleanCerts | ConvertFrom-Json
    } else {
        $certList = $parsedJson.certs
    }

    Write-Host "DEBUG: Parsed cert list:"
    $certList | ConvertTo-Json -Depth 5
}
catch {
    Write-Error "Error decoding or parsing JSON input: $_"
    exit 1
}

if ($certList -isnot [System.Array]) {
    $certList = @($certList)
}

# Create a mapping for deterministic folder codes
$folderCodes = @{}

# If installPath is a directory, append default filename
if ((Test-Path -Path $installPath) -and (Get-Item -Path $installPath).PSIsContainer) {
    $installPath = Join-Path -Path $installPath -ChildPath "WinCert.config"
}

$outputDir = Split-Path -Path $installPath -Parent
New-Item -ItemType Directory -Path $outputDir -Force -ErrorAction SilentlyContinue | Out-Null

# Determine whether first install
$firstTimeInstall = $false
if ($firstTimeInstallString) {
    if ($firstTimeInstallString.ToLower() -eq "true") {
        $firstTimeInstall = $true
    } elseif ($firstTimeInstallString.ToLower() -eq "false") {
        $firstTimeInstall = $false
    } else {
        Write-Error "Invalid value for firstTimeInstallString: '$firstTimeInstallString'. Expected 'true' or 'false'."
        exit 1
    }
}

# Initialize XML
if ($firstTimeInstall -eq $true) {
    Write-Host "DEBUG: First time installation detected. Creating new XML."

    $xml = New-Object System.Xml.XmlDocument
    $declaration = $xml.CreateXmlDeclaration("1.0", "utf-8", $null)
    $xml.AppendChild($declaration) | Out-Null

    $configuration = $xml.CreateElement("configuration")
    $xml.AppendChild($configuration) | Out-Null

    $certificatesNode = $xml.CreateElement("Certificates")
    $configuration.AppendChild($certificatesNode) | Out-Null

    $appSettingsNode = $xml.CreateElement("appSettings")
    $configuration.AppendChild($appSettingsNode) | Out-Null
}
else {
    Write-Host "DEBUG: Not first time installation. Loading existing XML."
    if (-not (Test-Path $installPath)) {
        Write-Error "Existing config file not found: $installPath"
        exit 1
    }

    [xml]$xml = Get-Content -Path $installPath

    $configuration = $xml.SelectSingleNode("/configuration")
    if (-not $configuration) {
        Write-Error "Configuration node not found in existing XML."
        exit 1
    }

    $certificatesNode = $configuration.SelectSingleNode("Certificates")
    if (-not $certificatesNode) {
        $certificatesNode = $xml.CreateElement("Certificates")
        $configuration.AppendChild($certificatesNode) | Out-Null
    }

    $appSettingsNode = $configuration.SelectSingleNode("appSettings")
    if (-not $appSettingsNode) {
        $appSettingsNode = $xml.CreateElement("appSettings")
        $configuration.AppendChild($appSettingsNode) | Out-Null
    }
}

# Now, add cert entries in both cases
foreach ($cert in $certList) {
    # Check if a node with the same 'path' attribute already exists
    $existingNode = $certificatesNode.SelectSingleNode("add[@path='$($cert.path)']")
    if ($null -ne $existingNode) {
        Write-Host "DEBUG: Certificate path already exists, skipping: $($cert.path)"
        continue
    }

    $path = $cert.path
    $type = $cert.type

    if (-not $folderCodes.ContainsKey($path)) {
        $sha1 = [System.Security.Cryptography.SHA1]::Create()
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($path)
        $hashBytes = $sha1.ComputeHash($bytes)
        $hashString = ([BitConverter]::ToString($hashBytes)).Replace("-", "")
        $code = $hashString.ToUpper()
        $folderCodes[$path] = $code
    } else {
        $code = $folderCodes[$path]
    }

    $tag = "${code}_$($type.ToUpper())"
    $certNode = $xml.CreateElement("add")
    $certNode.SetAttribute("tag", $tag)
    $certNode.SetAttribute("type", $type.ToLower())
    $certNode.SetAttribute("path", $path)

    $certificatesNode.AppendChild($certNode) | Out-Null
}

# Add or update Storecert in appSettings
$storeNode = $appSettingsNode.SelectSingleNode("add[@key='Storecert']")
if ($storeNode -eq $null) {
    $storeNode = $xml.CreateElement("add")
    $storeNode.SetAttribute("key", "Storecert")
    $appSettingsNode.AppendChild($storeNode) | Out-Null
}

$certFlag = if ($extRootCert -eq "True") { "Y" } else { "N" }
$storeNode.SetAttribute("value", $certFlag)

# Save
$xml.Save($installPath)
Write-Host "DEBUG: XML configuration saved to $installPath"

# Cleanup script
$scriptPath = $MyInvocation.MyCommand.Path
if (Test-Path -Path $scriptPath) {
    Remove-Item -Path $scriptPath -Force -ErrorAction SilentlyContinue
    Write-Host "DEBUG: Removed script file $scriptPath"
    exit 0
}
