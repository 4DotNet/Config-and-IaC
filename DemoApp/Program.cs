using Microsoft.AspNetCore.Mvc;
using Microsoft.FeatureManagement; // Optional
using Shared.Configuration;

var builder = WebApplication.CreateBuilder(args);
Console.WriteLine("Application starting");

// Send logs and telemetry to application insights
builder.Services.AddApplicationInsightsTelemetry();

// Load settings from Azure AppConfiguration
builder.AddAzureAppConfiguration("DemoApp:*");

// Optional: user feature flags
builder.Services.AddFeatureManagement();

#if DEBUG // overrides for local testing
// force reload of user secrets to allow overriding settings from Azure AppConfiguration
builder.Configuration.AddUserSecrets<Program>(optional: true);
// Load overrides from shared settings file.
builder.Configuration.AddJsonFile("appsettings.overrides.json", optional: true);
#endif

var app = builder.Build();
app.UseAzureAppConfiguration(); // This is required to make settings and features refresh

app.MapGet("/", async(HttpContext context, [FromServices] IConfiguration config, [FromServices] IFeatureManager feature) =>
{
    // Key/Value from AppConfiguration
    var color = config.GetValue("DemoApp:Color", "Red");
    // KeyVault reference from AppConfiguration
    var secret = config.GetValue("DemoApp:MySecretValue", "Unknown");
    // Feature flag
    var isBeta = await feature.IsEnabledAsync("Beta");

    context.Response.ContentType = "text/html";
    await context.Response.WriteAsync($"<html><body><h1>Hello world!{(isBeta? "<div style=\"display:inline-block;color:red;font-size:0.5em;transform: rotate(-45deg);\">Beta</div>" : "")}</h1><p style=\"color:{color}\">The secret is {secret}</p></body></html>");
});

Console.WriteLine("Running...");

app.Run();

Console.WriteLine("Application stopped");