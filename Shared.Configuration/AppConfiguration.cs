using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Configuration.AzureAppConfiguration;

namespace Shared.Configuration;

public static class AppConfiguration
{
    /// <summary>
    /// Enable Azure App Configuration for the application.
    /// <para>Setting <c>AppConfig:Uri</c> must be set to the uri of the Azure AppConfiguration service.</para>
    /// <para>Set <c>AppConfig:Enable</c> to false to disable the service, for example for unit tests.</para>
    /// </summary>
    /// <param name="builder">The web host builder.</param>
    /// <param name="filters">Filters for the configuration keys to pull in. For example: <c>"Codex:*"</c> to pull in settings to access the Codex API.</param>
    /// <returns>The builder.</returns>
    public static WebApplicationBuilder AddAzureAppConfiguration(this WebApplicationBuilder builder, params string[] filters)
    {
        builder.Configuration.AddAzureAppConfiguration(builder.Configuration, options =>
        {
            foreach (var filter in filters)
            {
                options.Select(filter);
            }
        });
        builder.Services.AddAzureAppConfiguration();
        return builder;
    }


    /// <summary>
    /// Enable Azure App Configuration for the application.
    /// <para>Setting <c>AppConfig:Uri</c> must be set to <c>https://arXcfgshared.azconfig.io</c> in your app configuration.</para>
    /// <para>Set <c>AppConfig:Enable</c> to false to disable the service, for example for unit tests.</para>
    /// </summary>
    /// <param name="configBuilder">The configuration builder.</param>
    /// <param name="configuration">The current configuration. This should contain the <c>AppConfig</c> section.</param>. You'll need to construct it from the <paramref name="configBuilder"/> if you're adding App COnfiguration to a Functions project.
    /// <param name="action">An action to configure the options for the Azure App Config service. Use this if you want to use feature flags or other extended configuration.</param>
    /// <param name="optional">If true, this method will not throw an exception if the configuration store cannot be accessed.</param>
    /// <returns>The builder.</returns>
    public static IConfigurationBuilder AddAzureAppConfiguration(this IConfigurationBuilder configBuilder, IConfiguration configuration, Action<AzureAppConfigurationOptions> action, bool optional = false)
    {
        var settings = configuration.GetSection(AppConfigSettings.ConfigSection).Get<AppConfigSettings>() ?? new AppConfigSettings();

        var appConfigEnabled = !string.IsNullOrWhiteSpace(settings.Uri) && settings.Enable;
        if (appConfigEnabled)
        {
            if (!Uri.TryCreate(settings.Uri, UriKind.Absolute, out var appConfigUri))
            {
                throw new InvalidOperationException(
                    $"Setting {AppConfigSettings.ConfigSection}:{nameof(AppConfigSettings.Uri)} is missing or invalid. Expected the full URL of the App Config instance in the format 'https://myappconfig.azconfig.io'");
            }

            configBuilder.AddAzureAppConfiguration(options =>
                {
                    ConfigureOptions(options, appConfigUri, settings);
                    action?.Invoke(options);
                },
                optional);
        }
        else
        {
            Console.WriteLine("WARNING: AppConfiguration is disabled");
        }

        return configBuilder;
    }

    private static void ConfigureOptions(AzureAppConfigurationOptions options, Uri appConfigEndpoint, AppConfigSettings settings)
    {
        var credentials = ManagedIdentityHelpers.GetAzureCredentials();
        options.Connect(appConfigEndpoint, credentials);

        // Add KeyVault integration
        options.ConfigureKeyVault(kv => kv.SetCredential(credentials));

        if (!string.IsNullOrEmpty(settings.SentinelKey))
        {
            // Enable dynamic configuration updates
            // https://docs.microsoft.com/en-us/azure/azure-app-configuration/enable-dynamic-configuration-aspnet-core
            options.ConfigureRefresh(refresh =>
            {
                if (settings.SettingsCacheExpiration < TimeSpan.FromSeconds(1))
                {
                    throw new InvalidOperationException(
                        $"Setting {AppConfigSettings.ConfigSection}:{nameof(AppConfigSettings.SettingsCacheExpiration)} must be at least 1 second. The default is {AppConfigSettings.DefaultSettingsCacheExpiration}");
                }

                refresh.Register(settings.SentinelKey, refreshAll: true)
                    .SetCacheExpiration(settings.SettingsCacheExpiration);
            });
        }

        // Enable feature flags
        if (settings.FeatureCacheExpiration < TimeSpan.FromSeconds(10))
        {
            throw new InvalidOperationException($"Setting {AppConfigSettings.ConfigSection}:{nameof(AppConfigSettings.FeatureCacheExpiration)} must be at least 1 second. The default is {AppConfigSettings.DefaultFeatureCacheExpiration}");
        }
        options.UseFeatureFlags(opt => opt.CacheExpirationInterval = settings.FeatureCacheExpiration);
    }
}