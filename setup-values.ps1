$ErrorActionPreference = "Stop"

$account=$(az account show --output json)| ConvertFrom-Json
if($LASTEXITCODE -ne 0){
    Write-Host -ForegroundColor Green 'Please login to Azure'
    az login
    $account=$(az account show --output json)| ConvertFrom-Json
}

# List available subscriptions
$subscriptions = az account list --query "[].{Name:name, Id:id}" --output json | ConvertFrom-Json

if ($subscriptions.Count -eq 0) {
    Write-Error "No subscriptions found in the current Azure account."
    exit 1
}

# Ensure correct subscription is used if there is more than 1 subscription
if($subscriptions.Count -gt 1){
    Write-Host -ForegroundColor Green "These are your Azure subscriptions:"
    $index=1
    $default=1
    $subscriptions | ForEach-Object {       
        if( $_.Id -eq $account.id){
            $default=$index
            Write-Host -ForegroundColor Yellow "[$index] $($_.Name) : $($_.Id)"
        }
        else {
            Write-Host "[$index] $($_.Name) : $($_.Id)"
        }
        $index += 1        
    }

    # Prompt the user to select a subscription
    Write-Host 
    Write-Host -ForegroundColor Yellow "Enter the index of the subscription you want to use (default is $default)" -NoNewline
    $subscriptionIndex = Read-Host

    if( $subscriptionIndex -lt 0 ){
        $subscriptionIndex=$default
    }

    # Get the selected subscription
    $selectedSubscription = $subscriptions[$subscriptionIndex-1]

    if (-not $selectedSubscription) {
        exit 1
    }

    if( $selectedSubscription.Id -ne $account.Id ){
        # Set the selected subscription as the current subscription
        az account set --subscription $selectedSubscription.Id
        Write-Host -ForegroundColor Green "Successfully selected subscription: $($selectedSubscription.Name)"
    }
    Write-Host ""
}

Write-Host -ForegroundColor Yellow "Please enter a resource prefix. This should be a short text starting with a letter (default $($Env:DeployPrefix)): "
$prefix = Read-Host;

if( $prefix -eq '')
{
    $prefix=$Env:DeployPrefix;
}
else {
    $Env:DeployPrefix=$prefix # Set the environment variable for the next script
}

Write-Host -ForegroundColor Green 'Please provide a secret value for the demo app'
$value=Read-Host

if( $value -eq '' ){
    # set the value to a guid
    $value="$(New-Guid)"
}

Write-Host -ForegroundColor Green "Updating secret to $value"
az keyvault secret set --name MySecretValue --vault-name "$prefix-keyvault-dev" --value "$value"

Write-Host -ForegroundColor Green 'Set app setting that refers to the kv secret'

$secretUri=$(az keyvault secret show --name MySecretValue --vault-name "$prefix-keyvault-dev" --query id --output tsv)
az appconfig kv set-keyvault --name "$prefix-appconfig-dev" --key "DemoApp:MySecretValue"  --secret-identifier $secretUri -y --auth-mode login

Write-Host -ForegroundColor Green "Please provide a color value for the demo app (default is Purple)"
$value=Read-Host

if( $value -eq '' ){
    $value='Purple'
}

Write-Host -ForegroundColor Green "Updating value to $value"
az appconfig kv set -n "$($Env:DeployPrefix)-appconfig-dev" --key "DemoApp:Color" --value "$value" -y --auth-mode login

Write-Host -ForegroundColor Green "Adding a feature flag 'Beta' for the demo app"
az appconfig feature set -n "$($Env:DeployPrefix)-appconfig-dev" --feature "Beta" --yes --auth-mode login


Write-Host -ForegroundColor Green "Updating sentinel key to trigger settings reload"
az appconfig kv set -n "$($Env:DeployPrefix)-appconfig-dev" --key "Settings:Refresh" --value "$(New-Guid)" -y --auth-mode login