using AssettoServer.Server;
using AssettoServer.Server.Plugin;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;

namespace CustomOvertakePlugin;

public class OvertakeModule : AssettoServerModule<OvertakeConfiguration>
{
    protected override void ConfigureServices(IServiceCollection services)
    {
        services.AddSingleton<OvertakeService>();
        services.AddHostedService(sp => sp.GetRequiredService<OvertakeService>());
    }
}

public class OvertakeConfiguration : IValidateConfiguration
{
    public int MinChatAnnounceScore { get; set; } = 10000;
    public void Validate() { }
}

public class OvertakeService : BackgroundService
{
    private readonly EntryCarManager _entryCarManager;
    private readonly OvertakeConfiguration _config;

    public OvertakeService(EntryCarManager entryCarManager, OvertakeConfiguration config)
    {
        _entryCarManager = entryCarManager;
        _config = config;
    }

    protected override Task ExecuteAsync(CancellationToken stoppingToken)
    {
        Log.Information("Custom Overtake Plugin loaded (Chat announce threshold: {Score})", _config.MinChatAnnounceScore);
        return Task.CompletedTask;
    }
}
