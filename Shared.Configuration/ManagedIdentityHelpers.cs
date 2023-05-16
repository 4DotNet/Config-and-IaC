using Azure.Core;
using Azure.Identity;

namespace Shared.Configuration;

internal static class ManagedIdentityHelpers
{
    /// <summary>
    /// Get the an Azure Credentials provider that is optimized for the environment it runs in.
    /// This helps deployed instances fail faster by limiting timeouts and ensuring only managed identities are tried, if available. 
    /// </summary>
    /// <param name="tenantId">Set this ensure authentication is attempted against the correct Azure AD instance.</param>
    /// <returns>An Azure Token Credential provider.</returns>
    public static TokenCredential GetAzureCredentials(string? tenantId=null)
    {
        var isDeployed =
            !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("WEBSITE_SITE_NAME")) && // Azure Web Apps
            !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("KUBERNETES_SERVICE_HOST")); // AKS

        if (string.IsNullOrEmpty(tenantId))
        {
            tenantId = Environment.GetEnvironmentVariable("AZURE_TENANT_ID");
        }

        // Note: when using managed identity exclusively, it may be more efficient to use ManagedIdentityCredential() instead of DefaultAzureCredential

        var options = new DefaultAzureCredentialOptions
        {
            // Prevent deployed instances from trying things that don't work and generally take too long
            ExcludeInteractiveBrowserCredential = isDeployed,
            ExcludeVisualStudioCodeCredential = isDeployed,
            ExcludeVisualStudioCredential = isDeployed,
            ExcludeSharedTokenCacheCredential = isDeployed,
            ExcludeAzureCliCredential = isDeployed,
            ExcludeAzurePowerShellCredential = isDeployed,
            ExcludeManagedIdentityCredential = false,
            Retry =
            {
                // Reduce retries and timeouts to get faster failures
                MaxRetries = 2,
                NetworkTimeout = TimeSpan.FromSeconds(5),
                MaxDelay = TimeSpan.FromSeconds(5)
            }
        };

        if (!string.IsNullOrEmpty(tenantId))
        {
            // this helps devs use the right tenant
            options.InteractiveBrowserTenantId = tenantId;
            options.SharedTokenCacheTenantId = tenantId;
            options.VisualStudioCodeTenantId = tenantId;
            options.VisualStudioTenantId = tenantId;
        }

        var userManagedId = Environment.GetEnvironmentVariable("MANAGED_CLIENT_ID") ?? Environment.GetEnvironmentVariable("AZURE_CLIENT_ID");
        if (!string.IsNullOrWhiteSpace(userManagedId))
        {
            options.ManagedIdentityClientId = userManagedId;
        }

        return new DefaultAzureCredential(options);
    }
}