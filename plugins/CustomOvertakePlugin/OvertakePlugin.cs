using AssettoServer.Server;
using AssettoServer.Server.Configuration;
using AssettoServer.Server.Plugin;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;
using System.IO;
using System.Threading;
using System.Threading.Tasks;

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
    public string ScriptFileName { get; set; } = "overtake.lua";
    public void Validate() { }
}

public class OvertakeService : BackgroundService
{
    private readonly ACServerConfiguration _config;
    private readonly CSPServerScriptProvider _scriptProvider;
    private readonly OvertakeConfiguration _cfg;

    public OvertakeService(ACServerConfiguration config, CSPServerScriptProvider scriptProvider, OvertakeConfiguration cfg)
    {
        _config = config;
        _scriptProvider = scriptProvider;
        _cfg = cfg;
    }

    protected override Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var path = Path.Combine(_config.BaseFolder, _cfg.ScriptFileName);
        if (!File.Exists(path))
        {
            Log.Warning("Overtake script not found at {Path}; place overtake.lua in cfg/", path);
            return Task.CompletedTask;
        }
        var script = File.ReadAllText(path);
        _scriptProvider.AddScript(script, "overtake.lua");
        Log.Information("Loaded overtake script from {Path} ({Length} bytes)", path, script.Length);
        return Task.CompletedTask;
    }
}
