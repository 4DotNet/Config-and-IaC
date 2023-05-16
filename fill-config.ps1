# Helper script to fill in some app settings and a key vault secret for the demo application

# Setup
$secretName='MySecretValue'
$settingPrefix="DemoApp"
$settingName="TopSecret"

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

# List Key Vaults
$keyVaults = az keyvault list --query "[].{Name:name}" --output json | ConvertFrom-Json

# Check if any Key Vaults are available
if (-not $keyVaults) {
    Write-Host "No Key Vaults found in the current subscription."
    exit 1
}

# Select the KeyVault to use
$index=1;
Write-Host "Available Key Vaults:"
Write-Host "---------------------"
$keyVaults| ForEach-Object {
    Write-Host "[$index] $($keyVaults[$index-1].Name)"
}
Write-Host ""

# Prompt the user to select a Key Vault
Write-Host -ForegroundColor Yellow "Please enter the index of the keyvault you want to use (default: 1)"
$keyVaultIndex = Read-Host

if( $keyVaultIndex -lt 0 ){ $keyVaultIndex = 1}

# Get the selected Key Vault details
$keyVault = $keyVaults[$keyVaultIndex-1].Name

# Check if a valid Key Vault was selected
if (-not $keyVault) {
    Write-Error "Invalid selection."
    exit 1
}

# Ensure access
Write-Host -ForegroundColor Green "Ensuring you have rights to read and write to KeyVault ${keyvault}"
# Add policy to allow access
$currentUserId=$(az ad signed-in-user show --output tsv --query id)
az keyvault set-policy -n $keyvault --secret-permissions get list set --object-id $currentUserId

# Add network rule to allow access from your ip
Write-Host -ForegroundColor Green "Ensuring you have network access to the KeyVault ${keyvault} (may take a minute a bit of time)"
$ipAddress = Invoke-RestMethod -Uri 'https://api.ipify.org?format=json' | Select-Object -ExpandProperty ip
$ipRules=az keyvault network-rule list --name $keyvault --query ipRules[?value==``$ipAddress/32``].value | ConvertFrom-Json
if(-not $ipRules)
{
    az keyvault network-rule add --name $keyvault --ip-address $ipAddress
}

# Set the secret
Write-Host -ForegroundColor Yellow "Enter a value for the secret: " -NoNewline
$secretValue = Read-Host
Write-Host -ForegroundColor Green "Writing secret value"
az keyvault secret set --name $secretName --vault-name $keyvault --value $secretValue

# Get app config services
$appConfigs = $(az appconfig list --output json)|ConvertFrom-Json
$appconfig=$appConfigs[0]

Write-Host -ForegroundColor Green "Ensuring you have rights to modify data in the appconfiguration service"
az role assignment create --assignee-object-id $currentUserId --role "App Configuration Data Owner" --scope $appConfig.id --assignee-principal-type user

Write-Host -ForegroundColor Green "Writing settings to AppConfig $appconfig"
# Add a keyvault reference to app config
az appconfig kv set-keyvault --name $appconfig.name --auth-mode login -y --key "$($settingPrefix):$($settingName)" --secret-identifier "https://$keyvault.vault.azure.net/secrets/$secretName"
# Add a setting to app config
az appconfig kv set --name $appconfig.name --auth-mode login -y --key "$($settingPrefix):Color" --value "Green"
# Add a feature flag and enable it
az appconfig feature set --name $appconfig.name --auth-mode login -y --feature Beta --description "This enables beta features"

Write-Host -ForegroundColor Green Done!
Write-Host "The following settings are now available:"
Write-Host "$($settingPrefix):Color contains a color name."
Write-Host "$($settingPrefix):$($settingName) is a reference to secret $secretName in the keyvault."
Write-Host "Beta is a feature flag that is currently off."