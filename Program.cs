using Azure.Identity;
using System;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var builder = FunctionsApplication.CreateBuilder(args);

var credential = new DefaultAzureCredential();
// Initialize SecretClient. Ensure package Azure.Security.KeyVault.Secrets is referenced
// and replace <your-key-vault-name> with your Key Vault name.
//var client = new SecretClient(new Uri("https://<your-key-vault-name>.vault.azure.net/"), credential);

builder.ConfigureFunctionsWebApplication();

builder.Services
    .AddApplicationInsightsTelemetryWorkerService()
    .ConfigureFunctionsApplicationInsights();
  

builder.Build().Run();
