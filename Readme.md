# Azure Demo app

This application shows how to apply Infrastructure as Code (IaC) with Bicep and zero-knowledge security in Azure applications ánd local development.

## What you need

Make sure you have the following tools installed:

* [Visual Studio 2022](https://visualstudio.microsoft.com/downloads/)
* [Visual Studio Code](https://code.visualstudio.com/download) - Infrastructure as Code with Bicep
  * Bicep extensions
* [PowerShell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.3)
* [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) - to be able to authenticate for resources
* An Azure subscription and rights to deploy resources (Contributor or Owner) and assign roles on resources (Owner or User Access Administrator).

## Deploying resources from VS Code

Make sure you have the Bicep extensions for VS Code installed. These are really helpful when developing and testing Bicep files.

* Open the project folder in VS Code and navigate to the [Resources](Resources) folder.
* Right-click on the `shared-infra.bicep` file and pick _Deploy Bicep file..._
  You'll be asked to login to Azure, next 

### Deploy resources from Visual Studio Code

## Running the application in Azure

🚧 TODO


## Running the application for local development

The demo application is setup to use the same configuration as the Development environment. The idea is that running the application for local development should be as close as possible to running it in Azure.
To do this, you need to configure the url for the AppConfiguration service in [DemoApp/appsettings.Development.json](DemoApp/appsettings.Development.json) by setting the `AppConfig:Uri` setting.