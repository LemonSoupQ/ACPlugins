-- No Hesi-Style Traffic Overtake & Near-Miss Script for CSP
local stored = ac.storage({ pb = 0 })

local score = 0
local combo = 1.0
local comboTimer = 0
local maxComboTime = 5.0
local minSpeedKmh = 95
local nearMissDist = 7.5
local passedCars = {}
local statusText = ""
local statusTimer = 0

local function triggerStatus(msg)
  statusText = msg
  statusTimer = 2.5
end

function script.update(dt)
  local player = ac.getCar(0)
  local sim = ac.getSim()
  if not player or not sim then return end

  -- Reset active run on crash
  if player.collisionDepth > 0 then
    if score > 0 then
      if score > stored.pb then
        stored.pb = math.floor(score)
        ac.sendChatMessage(string.format("New Personal Best: %d pts!", stored.pb))
      end
      triggerStatus("CRASHED! RUN LOST")
    end
    score = 0
    combo = 1.0
    comboTimer = 0
    table.clear(passedCars)
    return
  end

  -- Tick down combo bar
  if comboTimer > 0 then
    comboTimer = comboTimer - dt
    if comboTimer <= 0 then
      if score > stored.pb then
        stored.pb = math.floor(score)
        ac.sendChatMessage(string.format("New Personal Best: %d pts!", stored.pb))
      end
      score = 0
      combo = 1.0
      table.clear(passedCars)
    end
  end

  if statusTimer > 0 then
    statusTimer = statusTimer - dt
  end

  -- Continuous high-speed cruise points while combo is active
  if player.speedKmh >= minSpeedKmh and comboTimer > 0 then
    score = score + (player.speedKmh * 0.15 * combo * dt)
  end

  -- Detect close near-misses against traffic / other cars
  if player.speedKmh >= minSpeedKmh then
    for i = 1, sim.carsCount - 1 do
      local target = ac.getCar(i)
      if target and target.isActive then
        local dist = math.distance(player.position, target.position)
        if dist < nearMissDist and not passedCars[i] then
          passedCars[i] = true
          local proximityBonus = math.max(1.0, (nearMissDist - dist) * 0.6)
          local pointsGained = math.floor((150 + player.speedKmh) * proximityBonus * combo)
          score = score + pointsGained
          combo = math.min(10.0, combo + 0.2)
          comboTimer = maxComboTime
          triggerStatus(string.format("NEAR MISS +%d", pointsGained))
        elseif dist > 25 and passedCars[i] then
          passedCars[i] = nil
        end
      end
    end
  end
end

function script.drawUI()
  local uiState = ac.getUI()
  local pos = vec2(40, 40)
  local size = vec2(260, 115)

  -- Dark translucent HUD card
  ui.drawRectFilled(pos, pos + size, rgbm(0.06, 0.06, 0.08, 0.82), 8)
  ui.drawRect(pos, pos + size, rgbm(0.55, 0.25, 0.95, 0.7), 8, 1.5)

  -- Score & Multiplier
  ui.dwriteDrawText(string.format("%d PTS", math.floor(score)), 24, pos + vec2(14, 10), rgbm(1, 1, 1, 1))
  ui.dwriteDrawText(string.format("%.1fx", combo), 22, pos + vec2(195, 11), rgbm(0.75, 0.4, 1, 1))

  -- Personal Best
  ui.dwriteDrawText(string.format("PB: %d PTS", stored.pb), 13, pos + vec2(14, 44), rgbm(0.7, 0.7, 0.75, 1))

  -- Status pop-up (Near Miss / Crash)
  if statusTimer > 0 then
    local col = statusText:find("CRASH") and rgbm(1, 0.3, 0.3, 1) or rgbm(0.3, 1, 0.5, 1)
    ui.dwriteDrawText(statusText, 14, pos + vec2(14, 66), col)
  end

  -- Combo timer progress bar
  local barStart = pos + vec2(14, 94)
  local barWidth = 232
  ui.drawRectFilled(barStart, barStart + vec2(barWidth, 7), rgbm(0.2, 0.2, 0.25, 0.9), 3)
  if comboTimer > 0 then
    local fill = barWidth * (comboTimer / maxComboTime)
    ui.drawRectFilled(barStart, barStart + vec2(fill, 7), rgbm(0.65, 0.3, 1, 1), 3)
  end
end
