# stop on errors
$ErrorActionPreference = "Stop"

Write-Host -ForegroundColor Green "Publish the web app"
dotnet publish ./DemoApp/DemoApp.csproj -c Release -o ./DemoApp/bin/publish
Write-Host -ForegroundColor Green "Create a zip file of the web app"
Compress-Archive -Path ./DemoApp/bin/publish/* -DestinationPath ./output/DemoApp.zip -Force 

Write-Host -ForegroundColor Green "Deploying the web app to Azure:"
Write-Host

# Deploy DemoApp to previously created resources
$parameters = [PSCustomObject]@{
    prefix = (-not $Env:DeployPrefix ? "acme1" : $Env:DeployPrefix )
    environment = "development"
}

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

Write-Host -ForegroundColor Yellow "Please enter a resource prefix. This should be a short text starting with a letter (default $($parameters.prefix)): "
$prefix = Read-Host;

if( $prefix -ne '')
{
    $parameters.prefix=$prefix;
}
$Env:DeployPrefix=$parameters.prefix # Set the environment variable for the next script

$resourceGroup="$($parameters.prefix)-app-dev"

if($(az group exists --name $resourceGroup) -eq 'false')
{
    Write-Error "Please run deploy-shared.ps1 and deploy-hosting,ps1 first to create the required Azure resources"
}

Write-Host -ForegroundColor Green "Deploy the web app to Azure"
az webapp deploy --name "$($parameters.prefix)-app-dev-demo" --resource-group $resourceGroup --src-path ./output/DemoApp.zip --verbose

Write-Host -ForegroundColor Green "Web app deployed to https://$($parameters.prefix)-app-dev-demo.azurewebsites.net"