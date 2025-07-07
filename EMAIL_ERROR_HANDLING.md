# Email Sending Error Handling Guide

## Overview
This document describes the enhanced error handling implemented for the email notification system in the Windows Certificate Crawler project.

## Error Handling Features

### 1. PowerShell Script Improvements (`send_mail.ps1`)

#### Enhanced Error Handling
- **Try-Catch Block**: All email operations wrapped in try-catch for proper error handling
- **File Validation**: Checks if body file and attachments exist before processing
- **Attachment Processing**: Handles multiple attachments separated by semicolons
- **Detailed Error Messages**: Provides specific error information for debugging

#### Attachment Handling
- **Multiple Attachments**: Supports multiple files separated by semicolons
- **File Validation**: Only includes attachments that actually exist
- **Warning Messages**: Logs warnings for missing attachment files
- **Path Normalization**: Properly handles Windows file paths

### 2. Ansible Task Improvements (`send_mail.yml`)

#### Failure Resilience
- **Non-Blocking Failures**: `failed_when: false` prevents playbook failure on email issues
- **Conditional Success/Failure Handling**: Different actions based on mail sending results
- **Comprehensive Logging**: All mail attempts are logged regardless of outcome

#### Result Processing
- **Success Detection**: Checks both return code and output message for success
- **Failure Detection**: Identifies failures through return code or error messages
- **Detailed Debugging**: Provides return code, stdout, and stderr information

### 3. Attachment Preparation (`prepare_mail.yml`)

#### File Existence Validation
- **Pre-Check Files**: Validates attachment files exist before sending
- **Dynamic Attachment List**: Only includes files that are actually present
- **Debug Information**: Shows which attachments will be included

## Common Error Scenarios

### 1. **Drive Path Errors**
**Error**: `Cannot find drive. A drive with the name '['C' does not exist.`
**Cause**: Malformed attachment path or array serialization issue
**Solution**: Enhanced attachment argument preparation and PowerShell parsing

### 2. **Missing Attachment Files**
**Error**: Attachment files don't exist
**Solution**: File existence validation before sending

### 3. **SMTP Connection Issues**
**Error**: Cannot connect to SMTP server
**Solution**: Detailed error logging and non-blocking failure handling

### 4. **Authentication Failures**
**Error**: SMTP authentication failed
**Solution**: Comprehensive error messages and continued playbook execution

## Log Messages

### Success Messages
```
Email sent successfully at 2025-07-05T14:30:45Z
Mail sending attempt - Result: 0 - Output: Email sent successfully
```

### Failure Messages
```
Email sending failed at 2025-07-05T14:30:45Z - Error: Failed to send email. Error: Cannot connect to SMTP server
Mail sending attempt - Result: 1 - Output: Failed to send email. Error: Authentication failed
```

### Warning Messages
```
Warning: Attachment not found or empty: C:\path\to\missing\file.txt
Warning: Body file not found: C:\path\to\missing\body.txt
```

## Testing Recommendations

### 1. **Test Email Configuration**
- Verify SMTP server settings
- Test authentication credentials
- Check network connectivity

### 2. **Test Attachment Handling**
- Test with existing files
- Test with missing files
- Test with multiple attachments

### 3. **Test Error Scenarios**
- Invalid SMTP settings
- Wrong credentials
- Network connectivity issues
- Missing attachment files

## Troubleshooting

### 1. **Check Log Files**
Look in `{{ cc_path }}playbook_runtime.log` for:
- Mail sending attempts
- Success/failure messages
- Attachment validation results

### 2. **Debug Output**
Enable debug mode to see:
- Return codes
- stdout/stderr from PowerShell
- Attachment file paths

### 3. **Manual Testing**
Test the PowerShell script manually:
```powershell
powershell.exe -ExecutionPolicy Bypass -File "send_mail.ps1" -From "test@example.com" -To "recipient@example.com" -Subject "Test" -BodyFile "body.txt" -Username "user" -Password "pass" -SmtpServer "smtp.gmail.com" -Port 587
```

## Configuration Variables

Ensure these variables are properly set:
- `notify_from`: Sender email address
- `notify_to`: Recipient email address (usually `{{ fid }}`)
- `notify_username`: SMTP authentication username
- `notify_password`: SMTP authentication password
- `notify_smtp_server`: SMTP server address
- `notify_port`: SMTP server port (usually 587 for TLS)

## Benefits

1. **Robust Error Handling**: Playbook continues even if email fails
2. **Detailed Logging**: All email attempts are logged with results
3. **Attachment Validation**: Only sends existing files as attachments
4. **Clear Error Messages**: Easy to identify and fix email issues
5. **Non-Blocking Operation**: Email failures don't stop the entire process
6. **Comprehensive Debugging**: Full visibility into email sending process
