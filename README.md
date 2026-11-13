# ACPlugins - No Hesi-Style Traffic Points System

CSP online Lua script (client HUD) + optional AssettoServer C# plugin for global leaderboards.

## Files

- `overtake.lua` - CSP online Lua script (points & combo HUD, near-miss detection, personal bests, drift/wrong-way/speed-tier scoring, live top-10 leaderboard).
- `cfg/csp_extra_options.ini` - Server config snippet (script served from the server's own HTTP endpoint).
- `plugins/CustomOvertakePlugin/` - Optional .NET 8 server plugin scaffold.

## Setup (plugin-based, serves the script over the server's own HTTP endpoint)

1. Ensure `EnableClientMessages: true` in `cfg/extra_cfg.yml`.
2. Copy `cfg/csp_extra_options.ini` into your server's `cfg/` (merge if it exists).
3. Upload `overtake.lua` to the server's `cfg/` folder (so the plugin can read it).
4. Build the plugin on the server:
   ```
   cd plugins/CustomOvertakePlugin
   dotnet build -c Release
   ```
5. Upload `bin/Release/net8.0/CustomOvertakePlugin.dll` to `plugins/CustomOvertakePlugin/` on the server.
6. Add `- CustomOvertakePlugin` under `EnablePlugins:` in `cfg/extra_cfg.yml`.
7. Restart the server. The plugin embeds the script into the welcome message; CSP runs it on join.

## Optional plugin build

```
cd plugins/CustomOvertakePlugin
dotnet build -c Release
```

Upload `bin/Release/net8.0/CustomOvertakePlugin.dll` to `plugins/CustomOvertakePlugin/` on the server and add `- CustomOvertakePlugin` under `EnablePlugins:` in `cfg/extra_cfg.yml`. Requires `AssettoServer.Shared.dll` from the server root (adjust HintPath in csproj).
