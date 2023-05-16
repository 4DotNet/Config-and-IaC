using Microsoft.Extensions.Configuration;

namespace Shared.Configuration;

public static class ConfigurationExtensions{
     public static string GetRequiredValue(this IConfiguration config, string key)
    {
        var result = config.GetValue<string>(key);
        if (string.IsNullOrWhiteSpace(result))
        {
            throw new InvalidOperationException($"Missing required setting {key}");
        }

        return result;
    }
}
