namespace Shared.Configuration;

public class AppConfigSettings
{
    
    public const string ConfigSection = "AppConfig";
    public const string DefaultSentinelKey = "Settings:Refresh";
    public static readonly TimeSpan DefaultSettingsCacheExpiration = TimeSpan.FromMinutes(15);
    public static readonly TimeSpan DefaultFeatureCacheExpiration = TimeSpan.FromMinutes(1);

    public bool Enable { get; set; } = true;
    public string? Uri { get; set; } = null;
    public TimeSpan FeatureCacheExpiration { get; set; } = DefaultFeatureCacheExpiration;
    public TimeSpan SettingsCacheExpiration { get; set; } = DefaultSettingsCacheExpiration;
    public string? SentinelKey { get; set; }
}