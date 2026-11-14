local stored = ac.storage({ pb = 0, name = "" })

local score = 0
local combo = 1.0
local comboTimer = 0
local maxComboTime = 5.0
local minSpeedKmh = 95
local nearMissDist = 3.5
local passedCars = {}
local statusText = ""
local statusTimer = 0
local leaderboard = {}
local lastSpline = nil
local wrongWay = false
local driftActive = false
local wrongWayMult = 1.5
local driftBonusRate = 0.20
local broadcastTimer = 0
local popupText = ""
local popupTimer = 0
local popupColor = rgbm(0.3, 1, 0.5, 1)

local function triggerStatus(msg)
  statusText = msg
  statusTimer = 2.5
end

local function triggerPopup(msg, col)
  popupText = msg
  popupTimer = 2.0
  popupColor = col or rgbm(0.3, 1, 0.5, 1)
end

local function getScreenSize()
  local ok, ui = pcall(ac.getUI)
  if ok and ui and ui.windowSize then return ui.windowSize end
  return vec2(1920, 1080)
end

local function speedMult(spd)
  if spd >= 180 then return 1.5
  elseif spd >= 150 then return 1.3
  elseif spd >= 120 then return 1.15
  else return 1.0 end
end

local function isDrifting(car)
  if not car or not car.wheels then return false end
  for i = 0, 3 do
    local w = car.wheels[i]
    if w then
      local slip = w.slip or w.sideSlip or w.slipAngle or w.lateralSlip or 0
      if type(slip) == "number" and math.abs(slip) > 0.35 then return true end
    end
  end
  return false
end

local function updateLeaderboard(name, sc)
  if not name or name == "" then return end
  local found = false
  for _, e in ipairs(leaderboard) do
    if e.name == name then
      if sc > e.score then e.score = sc end
      found = true
      break
    end
  end
  if not found then
    table.insert(leaderboard, { name = name, score = sc })
  end
  table.sort(leaderboard, function(a, b) return a.score > b.score end)
  while #leaderboard > 10 do table.remove(leaderboard) end
end

local function broadcastPB()
  local pb = math.floor(stored.pb or 0)
  local name = stored.name
  if name == "" then
    name = "Player"
    if ac.getDriverName then
      local ok, n = pcall(ac.getDriverName, 0)
      if ok and n and n ~= "" then name = n end
    end
    stored.name = name
  end
  updateLeaderboard(name, pb)
  pcall(function()
    if ac.onlineEvent then
      ac.onlineEvent("overtakePB", { name = name, score = pb })
    end
  end)
end

pcall(function()
  if ac.onOnlineEvent then
    ac.onOnlineEvent("overtakePB", function(sender, data)
      pcall(function()
        if data and data.name then
          updateLeaderboard(data.name, data.score or 0)
        end
      end)
    end)
  end
end)

function script.update(dt)
  local player = ac.getCar(0)
  local sim = ac.getSim()
  if not player or not sim then return end

  if player.collisionDepth > 0 then
    if score > 0 then
      if score > stored.pb then
        stored.pb = math.floor(score)
        broadcastPB()
        ac.sendChatMessage(string.format("New Personal Best: %d pts!", stored.pb))
        triggerPopup(string.format("NEW PB! %d PTS", stored.pb), rgbm(1, 0.85, 0.2, 1))
      end
      triggerStatus("CRASHED! RUN LOST")
    end
    score = 0
    combo = 1.0
    comboTimer = 0
    table.clear(passedCars)
    return
  end

  if comboTimer > 0 then
    comboTimer = comboTimer - dt
    if comboTimer <= 0 then
      if score > stored.pb then
        stored.pb = math.floor(score)
        broadcastPB()
        ac.sendChatMessage(string.format("New Personal Best: %d pts!", stored.pb))
        triggerPopup(string.format("NEW PB! %d PTS", stored.pb), rgbm(1, 0.85, 0.2, 1))
      end
      score = 0
      combo = 1.0
      table.clear(passedCars)
    end
  end

  if statusTimer > 0 then
    statusTimer = statusTimer - dt
  end

  if popupTimer > 0 then
    popupTimer = popupTimer - dt
  end

  driftActive = isDrifting(player)
  wrongWay = false
  local sp = player.splinePosition
  if sp then
    if lastSpline then
      local delta = sp - lastSpline
      if delta > 0.5 then delta = delta - 1 end
      if delta < -0.5 then delta = delta + 1 end
      if delta < -0.005 then wrongWay = true end
    end
    lastSpline = sp
  end

  if player.speedKmh >= minSpeedKmh and comboTimer > 0 then
    local rate = 0.15
    if driftActive then rate = rate + driftBonusRate end
    score = score + (player.speedKmh * rate * combo * speedMult(player.speedKmh) * dt)
  end

  if player.speedKmh >= minSpeedKmh then
    for i = 1, sim.carsCount - 1 do
      local target = ac.getCar(i)
      if target and target.isActive then
        local dist = math.distance(player.position, target.position)
        if dist < nearMissDist and not passedCars[i] then
          passedCars[i] = true
          local proximityBonus = math.max(1.0, (nearMissDist - dist) * 0.6)
          local pointsGained = math.floor((150 + player.speedKmh) * proximityBonus * combo * speedMult(player.speedKmh))
          if wrongWay then pointsGained = math.floor(pointsGained * wrongWayMult) end
          if driftActive then pointsGained = math.floor(pointsGained * 1.2) end
          score = score + pointsGained
          combo = math.min(10.0, combo + 0.2)
          comboTimer = maxComboTime
          triggerStatus(string.format("NEAR MISS +%d", pointsGained))
          triggerPopup(string.format("+%d PTS", pointsGained), rgbm(0.3, 1, 0.5, 1))
        elseif dist > 25 and passedCars[i] then
          passedCars[i] = nil
        end
      end
    end
  end

  broadcastTimer = broadcastTimer + dt
  if broadcastTimer >= 10.0 then
    broadcastTimer = 0
    if score > stored.pb then
      stored.pb = math.floor(score)
    end
    broadcastPB()
  end
end

function script.drawUI()
  local pos = vec2(40, 40)
  local size = vec2(260, 115)

  ui.drawRectFilled(pos, pos + size, rgbm(0.06, 0.06, 0.08, 0.82), 8)
  ui.drawRect(pos, pos + size, rgbm(0.55, 0.25, 0.95, 0.7), 8, 1.5)

  ui.dwriteDrawText(string.format("%d PTS", math.floor(score)), 24, pos + vec2(14, 10), rgbm(1, 1, 1, 1))
  ui.dwriteDrawText(string.format("%.1fx", combo), 22, pos + vec2(195, 11), rgbm(0.75, 0.4, 1, 1))

  ui.dwriteDrawText(string.format("PB: %d PTS", stored.pb), 13, pos + vec2(14, 44), rgbm(0.7, 0.7, 0.75, 1))

  if statusTimer > 0 then
    local col = statusText:find("CRASH") and rgbm(1, 0.3, 0.3, 1) or rgbm(0.3, 1, 0.5, 1)
    ui.dwriteDrawText(statusText, 14, pos + vec2(14, 66), col)
  end

  if driftActive then
    ui.dwriteDrawText("DRIFT", 12, pos + vec2(195, 34), rgbm(1, 0.85, 0.2, 1))
  end
  if wrongWay then
    ui.dwriteDrawText("WRONG WAY", 12, pos + vec2(195, 50), rgbm(1, 0.3, 0.3, 1))
  end

  local barStart = pos + vec2(14, 94)
  local barWidth = 232
  ui.drawRectFilled(barStart, barStart + vec2(barWidth, 7), rgbm(0.2, 0.2, 0.25, 0.9), 3)
  if comboTimer > 0 then
    local fill = barWidth * (comboTimer / maxComboTime)
    ui.drawRectFilled(barStart, barStart + vec2(fill, 7), rgbm(0.65, 0.3, 1, 1), 3)
  end

  local lbPos = pos + vec2(270, 0)
  local lbSize = vec2(230, 115 + (#leaderboard * 14))
  if lbSize.y < 130 then lbSize.y = 130 end
  ui.drawRectFilled(lbPos, lbPos + lbSize, rgbm(0.06, 0.06, 0.08, 0.82), 8)
  ui.drawRect(lbPos, lbPos + lbSize, rgbm(0.55, 0.25, 0.95, 0.7), 8, 1.5)
  ui.dwriteDrawText("TOP 10", 14, lbPos + vec2(14, 8), rgbm(0.75, 0.4, 1, 1))
  for i = 1, math.min(10, #leaderboard) do
    local e = leaderboard[i]
    ui.dwriteDrawText(string.format("%d. %s  %d", i, e.name, math.floor(e.score)), 12, lbPos + vec2(14, 26 + (i - 1) * 14), rgbm(0.85, 0.85, 0.9, 1))
  end

  if popupTimer > 0 then
    local alpha = math.min(1.0, popupTimer / 0.5)
    local scr = getScreenSize()
    local fontSize = 40
    local charW = fontSize * 0.62
    local estWidth = #popupText * charW
    local x = (scr.x / 2) - (estWidth / 2)
    local y = 80
    local col = rgbm(popupColor.r, popupColor.g, popupColor.b, alpha)
    local bg = rgbm(0.0, 0.0, 0.0, alpha * 0.55)
    ui.drawRectFilled(vec2(x - 16, y - 8), vec2(x + estWidth + 16, y + fontSize + 8), bg, 6)
    ui.dwriteDrawText(popupText, fontSize, vec2(x, y), col)
  end
end
