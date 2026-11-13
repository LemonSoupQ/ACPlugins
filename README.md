# ACPlugins - No Hesi-Style Traffic Points System

CSP online Lua script (client HUD) + optional AssettoServer C# plugin for global leaderboards.

## Files

- `overtake.lua` - CSP online Lua script (points & combo HUD, near-miss detection, personal bests, drift/wrong-way/speed-tier scoring, live top-10 leaderboard).
- `cfg/csp_extra_options.ini` - Server config snippet (script served from the server's own HTTP endpoint).
- `plugins/CustomOvertakePlugin/` - Optional .NET 8 server plugin scaffold.

## Script URL (served from the server's own HTTP endpoint)

http://{ServerIP}:{ServerHTTPPort}/static/overtake.lua

## Setup

1. Ensure `EnableClientMessages: true` in `cfg/extra_cfg.yml`.
2. Copy `cfg/csp_extra_options.ini` into your server's `cfg/` (merge if it exists).
3. Upload `overtake.lua` to the server's `wwwroot/` folder (create it if missing) so CSP fetches it over HTTP.
4. Restart the server. CSP downloads the script automatically when players join `main_layout`.

## Optional plugin build

```
cd plugins/CustomOvertakePlugin
dotnet build -c Release
```

Upload `bin/Release/net8.0/CustomOvertakePlugin.dll` to `plugins/CustomOvertakePlugin/` on the server and add `- CustomOvertakePlugin` under `EnablePlugins:` in `cfg/extra_cfg.yml`. Requires `AssettoServer.Shared.dll` from the server root (adjust HintPath in csproj).
