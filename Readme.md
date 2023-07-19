# Azure Demo app

This application shows how to apply Infrastructure as Code (IaC) with Bicep and zero-knowledge security in Azure applications ánd local development.

## What's in this repository

The repository contains two dotnet 7 projects, the required Bicep files that describe the required Azure resources and some PowerShell scripts to deploy the resources to Azure.

* [DemoApp](DemoApp) - Contains the demo application.
* [SharedConfiguration](SharedConfiguration) - Contains a shared library that can be reused across multiple applications to simplify .
* [Resources](Resources) - Contains the Bicep files to deploy the required Azure resources.
* [deploy-shared.ps1](deploy-shared.ps1) - PowerShell script to deploy the shared resources.  
  This simulates a pipeline that deploys resources shared by multiple applications.
* [setup-values.ps1](setup-values.ps1) - PowerShell script to setup the required settings for the demo application.  
* [deploy-hosting.ps1](deploy-hosting.ps1) - PowerShell script to deploy the hosting resources
  needed to run the demo app in Azure.  
  This simulates a pipeline that deploys application specific resources.
* [deploy-app.ps1](deploy-app.ps1) - PowerShell script to deploy the demo application.  
  This simulates a pipeline that deploys the application. Usually resources and the application are deployed together.
* [remove-all.ps1](remove-all.ps1) - PowerShell script to remove all resources from Azure.

This setup is similar to how many organisations manage their Azure applications. 

This repository doesn not cover CI/CD pipelines, though all the Bicep and C# code here can be deployed with a pipeline. The scripts are used to simulate pipelines that deploy the resources and application.

## What you'll learn

This repo is a demo application that shows how to apply Infrastructure as Code (IaC) with Bicep and zero-knowledge security in Azure applications ánd local development. It is based on actual production code and is used to demonstrate the following topics:

* Use Bicep to deploy Azure resources.
* Use Azure App Configuration to store application settings.
* Use Azure Managed Identities to access Azure resources, both in Azure and locally.
* Use Azure Key Vault to store secrets.
* How Azure App Configuration and Azure Key Vault work together with dotnet Configuration to provide a flexible yet simple way to configure apps.
* Refreshing settings without restarting the application.
* Using feature flags to enable/disable features in the application at runtime.

## What you need

* An Azure subscription. If you don't have one, you can create a free account [here](https://azure.microsoft.com/en-us/free/).
* Sufficient ights to deploy resources (*Contributor* or *Owner*) and assign roles on resources (*Owner* or *User Access Administrator*).

> ⚠️ Having these permissions is not usually recommended for developers. It's better to let CI/CD pipelines handle deployments and use Just-in-time access or a seperate administrative account for manual access. This is not covered in this demo.

Make sure you have the following tools installed:

* [Visual Studio 2022](https://visualstudio.microsoft.com/downloads/) (or at least the .NET 7 SDK)
* [Visual Studio Code](https://code.visualstudio.com/download) - Infrastructure as Code with Bicep
  * Bicep extension for VS Code
* [PowerShell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.3)
* [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) - to be able to authenticate for resources


## Running the app locally

The application uses Azure resources so you'll need to deploy these first. You can do this by running the `deploy-shared.ps1` script in the root of the repository or by deploying the resources from VS Code.

The script will propmpt you to login to Azure and select a subscription. It will also ask you to provide a prefix that is used to make the resource names unique. This is required because some resources require globally unique names.

> ℹ️ Make sure you use the same prefix for all deployment scripts. They build upon each other.

Next, setup the settings using the `setup-values.ps1` script. This will ask you to provide a secret value and a color. Use common HTTP color names because it will be used to style a bit of text on a web page.
This script will also create a feature flag called `Beta` and touch the sentinal key that controls the refresh of settings from Azure AppConfiguration.

Now configure the url for the AppConfiguration service in [DemoApp/appsettings.Development.json](DemoApp/appsettings.Development.json) by setting the `AppConfig:Uri` setting.

With all this in place, you can run the application. Use Visual Studio to run the application locally. You can debug and play around with it. Open the application in the browser to see the output.

### Refreshing settings

With the application running, run `setup-values.ps1` again and provide different values. You'll see that the application will pick up the new values without restarting within about a minute. The sentinel key and refresh interval is configured in [DemoApp/appsettings.json](DemoApp/appsettings.Development.json).

Refresh the page a couple of times and you'll see that the text color and secret value change. 

### Using the feature flag

Leave the application running and head over to the Azure Portal. Locate the AppConfiguration service and open the Feature manager. Enable the `Beta` feature flag and refresh the page. You'll see that the text `Beta` appear within 10 seconds. The text will disappear.

## Running the app in Azure

Open up a powershell core terminal. 
* Run `deploy-shared.ps1` to deploy shared resources, if you haven't done so already
* Run `setup-values.ps1` to setup the secret, settings and feature flag for the demo application.
* Run `deploy-hosting.ps1` to deploy the hosting resources for the demo application. 
* Run `deploy-app.ps1` to build and deploy the demo application.

The last script will output the application url. Open it in a browser to see the application running in Azure.	

You can now run the *Refresh settings* and *Using the feature flag* steps from the previous section and see that everything works in Azure as it does for local development.
