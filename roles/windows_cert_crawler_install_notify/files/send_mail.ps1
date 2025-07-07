param(
    [string]$From,
    [string]$To,
    [string]$Subject,
    [string]$BodyFile = "",
    [string]$Username,
    [string]$Password,
    [string]$SmtpServer = "smtp.gmail.com",
    [int]$Port = 587,
    [string]$AttachmentPath = ""
)

try {
    # Read body text from file if provided
    if ($BodyFile -ne "") {
        if (Test-Path $BodyFile) {
            $Body = Get-Content -Path $BodyFile -Raw
        } else {
            Write-Host "Warning: Body file not found: $BodyFile"
            $Body = "Email body file not found."
        }
    } else {
        $Body = ""
    }

    # Convert password
    $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $credentials = New-Object System.Management.Automation.PSCredential ($Username, $securePassword)

    # Prepare parameters
    $sendParams = @{
        From       = $From
        To         = $To
        Subject    = $Subject
        Body       = $Body
        SmtpServer = $SmtpServer
        Port       = $Port
        UseSsl     = $true
        Credential = $credentials
        BodyAsHtml = $true
    }

    # Handle attachments properly
    if ($AttachmentPath -ne "") {
        # Split multiple attachments by semicolon
        $attachments = $AttachmentPath -split ';'
        $validAttachments = @()
        
        foreach ($attachment in $attachments) {
            $attachment = $attachment.Trim()
            if ($attachment -ne "" -and (Test-Path $attachment)) {
                $validAttachments += $attachment
                Write-Host "Adding attachment: $attachment"
            } else {
                Write-Host "Warning: Attachment not found or empty: $attachment"
            }
        }
        
        if ($validAttachments.Count -gt 0) {
            $sendParams.Add("Attachments", $validAttachments)
        }
    }

    # Send the email
    Send-MailMessage @sendParams
    Write-Host "Email sent successfully."
    
} catch {
    Write-Host "Failed to send email."
    Write-Host "Error: $($_.Exception.Message)"
    Write-Host "Full Error: $($_.Exception.ToString())"
    exit 1
}

# Clean up BodyFile if exists
if ($BodyFile -ne "" -and (Test-Path $BodyFile)) {
    Remove-Item -Force -ErrorAction SilentlyContinue $BodyFile
}

# Remove this script itself
$scriptPath = $MyInvocation.MyCommand.Definition
if (Test-Path $scriptPath) {
    Remove-Item -Force -ErrorAction SilentlyContinue $scriptPath
}