

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local cloneref = cloneref or function(serv) return serv end

print('[ZeroHub AltBot] Loading...')

local replicated = cloneref(game:GetService('ReplicatedStorage'))
local runservice = cloneref(game:GetService('RunService'))
local players = cloneref(game:GetService('Players'))
local teleport = cloneref(game:GetService('TeleportService'))
local manager = cloneref(game:GetService('VirtualInputManager'))
local virtual = cloneref(game:GetService('VirtualUser'))
local http = cloneref(game:GetService('HttpService'))
local startergui = cloneref(game:GetService('StarterGui'))

local lplr = players.LocalPlayer
local camera = workspace.CurrentCamera
local guns = {}

local utils = {}
local pguns, ammos = {}, {}
local shop = workspace:FindFirstChild('Ignored')
local getconnections = getconnections or function() return {} end

-- ══════════════════════════════════════════════════════════════════════════════
-- ENTITY REPLACEMENT (no require needed)
-- ══════════════════════════════════════════════════════════════════════════════
local entity = { Entities = {} }

-- LocalPlayer entity
entity.Entities.LocalPlayer = setmetatable({}, {
    __index = function(self, key)
        if key == 'Alive' then
            return lplr and lplr.Character and lplr.Character:FindFirstChild('Humanoid') and lplr.Character.Humanoid.Health > 0 and lplr.Character:FindFirstChild('HumanoidRootPart') ~= nil
        elseif key == 'Character' then
            return lplr and lplr.Character
        elseif key == 'RootPart' then
            return lplr and lplr.Character and lplr.Character:FindFirstChild('HumanoidRootPart')
        end
        return nil
    end
})

-- Player entities via metatable
setmetatable(entity.Entities, {
    __index = function(self, playerName)
        if playerName == 'LocalPlayer' then return rawget(self, 'LocalPlayer') end
        local plr = players:FindFirstChild(playerName)
        if not plr then return nil end
        return setmetatable({}, {
            __index = function(_, key)
                if key == 'Alive' then
                    return plr.Character and plr.Character:FindFirstChild('Humanoid') and plr.Character.Humanoid.Health > 0 and plr.Character:FindFirstChild('HumanoidRootPart') ~= nil
                elseif key == 'Character' then
                    return plr.Character
                elseif key == 'RootPart' then
                    return plr.Character and plr.Character:FindFirstChild('HumanoidRootPart')
                end
                return nil
            end
        })
    end
})

local localent = entity.Entities.LocalPlayer

-- ══════════════════════════════════════════════════════════════════════════════
-- POSITIONS
-- ══════════════════════════════════════════════════════════════════════════════
local pos = {
    military = Vector3.new(38.92, 50.73, -817.49),
    revolver = Vector3.new(-638.67, 21.72, -135.11),
    db = Vector3.new(-1043.89, 21.72, -271.67),
    bank = Vector3.new(-432.14, 38.96, -284.10),
    ufo = Vector3.new(80.11, 138.96, -660.76),
    downhill = Vector3.new(-557.68, 7.97, -734.80),
    uphill = Vector3.new(482.06, 47.98, -597.52),
    cage = Vector3.new(527.62, 47.97, -106.50),
    church = Vector3.new(205.29, 21.72, -87.12),
    jail = Vector3.new(-330.23, 21.72, -79.09),
    prison = Vector3.new(-330.23, 21.72, -79.09),
    school = Vector3.new(-596.09, 68.10, 322.42),
    higharmor = Vector3.new(-931.96, -28.53, 561.68),
    park = Vector3.new(-260.35, 22.12, -756.06),
    taco = Vector3.new(573.99, 51.03, -478.62),
    graveyard = Vector3.new(157.34, 21.72, 78.45),
    station = Vector3.new(-428.55, -21.28, 110.97),
}

-- ══════════════════════════════════════════════════════════════════════════════
-- ANTI-AFK / SETUP
-- ══════════════════════════════════════════════════════════════════════════════
if getconnections then
    for i, v in getconnections(lplr.Idled) do v:Disconnect() end
else
    warn('[ZeroHub AltBot] No getconnections. You may get AFK kicked.')
end

workspace.FallenPartsDestroyHeight = 0/0

if not fireclickdetector then
    getgenv().fireclickdetector = function(target)
        local cd = target:IsA('ClickDetector') and target or target:FindFirstChild('ClickDetector')
        if not cd then return end
        local originalParent = cd.Parent
        local holder = Instance.new('Part')
        holder.Transparency = 1
        holder.Size = Vector3.new(30, 30, 30)
        holder.Anchored = true
        holder.CanCollide = false
        holder.Parent = workspace
        cd.Parent = holder
        cd.MaxActivationDistance = 1e6
        local heart
        heart = runservice.Heartbeat:Connect(function()
            holder.CFrame = workspace.Camera.CFrame * CFrame.new(0, 0, -20)
            virtual:ClickButton1(Vector2.new(20, 20), workspace.CurrentCamera.CFrame)
        end)
        local restore = function()
            pcall(function() if heart then heart:Disconnect() end end)
            pcall(function() cd.Parent = originalParent end)
            pcall(function() holder:Destroy() end)
        end
        cd.MouseClick:Once(function() restore() end)
        task.delay(3, restore)
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- SHOP PARSE
-- ══════════════════════════════════════════════════════════════════════════════
if shop then
    shop = shop.Shop
    for _, v in next, shop:GetChildren() do
        local str = v.Name
        local ammoamount, ammolabel, ammoprice = str:match('(%d+)%s*%[([%w%s]+ Ammo)%]%s*%- %$(%d+)')
        if ammoamount and ammolabel and ammoprice then
            local key = ammolabel:lower():gsub('%s+ammo', '')
            ammos[key] = { name = str, amount = tonumber(ammoamount), label = ammolabel, price = tonumber(ammoprice) }
            continue
        end
        local gunlabel, gunprice = str:match('%[([%w%s]+)%]%s*%- %$(%d+)')
        if gunlabel and gunprice then
            pguns[gunlabel:lower()] = { name = str, label = gunlabel, price = tonumber(gunprice) }
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- UTILS
-- ══════════════════════════════════════════════════════════════════════════════
local seed = Random.new()
local x = function() return seed:NextNumber(-3000, 3000) end
local yy = function() return seed:NextNumber(2500, 3800) end

utils.shoot = function(args)
    replicated.MainEvent:FireServer('ShootGun', args.tool:FindFirstChild('Handle'), args.startposition, args.position, args.part, Vector3.zero)
end

utils.reload = function(weapon)
    replicated.MainEvent:FireServer('Reload', weapon)
end

utils.update = function(position)
    position = typeof(position) == 'Vector3' and CFrame.new(position) or position
    if lplr and lplr.Character and lplr.Character:FindFirstChild('HumanoidRootPart') and position then
        lplr.Character.HumanoidRootPart.CFrame = position
    end
end

utils.getposition = function(self, player)
    if player and typeof(player) == 'Instance' and player.Character and player.Character:FindFirstChild('HumanoidRootPart') then
        local hum = player.Character:FindFirstChild('Humanoid')
        if hum and hum.Health > 0 then
            return player.Character.HumanoidRootPart.CFrame
        end
    end
    return nil
end

utils.needarmor = function(player)
    player = player or lplr
    local ok, val = pcall(function() return tonumber(player.Character.BodyEffects.Armor.Value) end)
    return ok and val < 30
end

utils.hasarmor = function(player)
    player = player or lplr
    local ok, val = pcall(function() return tonumber(player.Character.BodyEffects.Armor.Value) end)
    return ok and val > 0
end

utils.getmoney = function(player)
    local plr = player or lplr
    if not plr then return 0 end
    local ok, val = pcall(function()
        return plr:FindFirstChild('DataFolder') and plr.DataFolder:FindFirstChild('Currency') and plr.DataFolder.Currency.Value or 0
    end)
    return ok and val or 0
end

utils.getitem = function(name)
    if lplr.Character then
        for _, v in lplr.Character:GetChildren() do
            if v.Name:lower():find(name) and v:IsA('Tool') then return v end
        end
    end
    for _, v in lplr.Backpack:GetChildren() do
        if v.Name:lower():find(name) and v:IsA('Tool') then return v end
    end
    return nil
end

utils.redeem = function(code)
    replicated.MainEvent:FireServer('EnterPromoCode', code)
end

utils.getname = function(search)
    search = tostring(search):lower()
    for _, player in players:GetPlayers() do
        if player ~= lplr and (player.Name:lower():find(search) or (player.DisplayName and player.DisplayName:lower():find(search))) then
            return player
        end
    end
    return nil
end

utils.purchase = function(type, itemname, last)
    if type == 'weapon' then
        local weapon = itemname:gsub('%s*%- %$%d+', '')
        if lplr.Character:FindFirstChild(weapon) or lplr.Backpack:FindFirstChild(weapon) then return 'owned' end
        local shopItem = workspace.Ignored.Shop:FindFirstChild(itemname)
        local click = shopItem and shopItem:FindFirstChildOfClass('ClickDetector')
        if not click then return 'nosuch' end
        local name = itemname:gsub('%[', ''):gsub('%]', ''):gsub('%s*%- %$%d+', '')
        local head = shopItem:FindFirstChildOfClass('Part') or shopItem:FindFirstChildOfClass('BasePart') or shopItem:FindFirstChild('Head')
        if not head then return 'nosuch' end
        local startingmoney = utils.getmoney()
        local saved = {}
        for i, v in lplr.Character:GetChildren() do
            if v:IsA('Tool') then table.insert(saved, v); v.Parent = lplr.Backpack end
        end
        local data = pguns[name:lower()]
        local part
        local check = false
        local timeout = tick()
        if data then
            for i, v in workspace.Ignored.Shop:GetChildren() do
                if data.name:lower() == v.Name:lower() then part = v; break end
            end
        end
        if not part then return 'nosuch' end
        task.spawn(function()
            repeat task.wait()
                check = startingmoney ~= utils.getmoney() or (lplr.Backpack:FindFirstChild(name) or (lplr.Character and lplr.Character:FindFirstChild(name)))
            until check or tick() - timeout > 0.9
        end)
        repeat task.wait()
            utils.update(head.CFrame + Vector3.new(0, 5, 0))
            if fireclickdetector then fireclickdetector(click) end
        until check or tick() - timeout > 0.90
        utils.update(CFrame.new(x(), yy(), x()))
        for i, v in saved do if v then v.Parent = lplr.Character end end
        local tool = lplr.Backpack:FindFirstChild(weapon) or lplr.Character:FindFirstChild(weapon)
        if tool then tool.Parent = lplr.Character; table.insert(guns, tool); return 'success' end
        return 'failed'
    elseif type == 'ammo' then
        local match = string.match(itemname, '%[([A-Za-z]+)%]')
        if not match then return 'nosuch' end
        local data = ammos[match:lower()]
        if not data then return 'nosuch' end
        local shopItem = workspace.Ignored.Shop:FindFirstChild(data.name)
        local clickdetector = shopItem and shopItem:FindFirstChildOfClass('ClickDetector')
        if not clickdetector then return 'nosuch' end
        local head = shopItem:FindFirstChildOfClass('Part') or shopItem:FindFirstChildOfClass('BasePart') or shopItem:FindFirstChild('Head')
        if not head then return 'nosuch' end
        local timeout = tick()
        local saved = {}
        for i, v in lplr.Character:GetChildren() do
            if v:IsA('Tool') then table.insert(saved, v); v.Parent = lplr.Backpack end
        end
        repeat task.wait()
            utils.update(head.CFrame + Vector3.new(0, 5, 0))
            if fireclickdetector then fireclickdetector(clickdetector) end
        until tick() - timeout > .75
        for i, v in saved do if v then v.Parent = lplr.Character end end
        if last then utils.update(CFrame.new(x(), yy(), x())) end
        return 'success'
    end
    return 'invalidtype'
end

utils.getfullammo = function(tool)
    if not tool then return 0 end
    local ok, val = pcall(function()
        return lplr.DataFolder.Inventory:FindFirstChild(tool.Name) and lplr.DataFolder.Inventory[tool.Name].Value or 0
    end)
    return ok and tonumber(val) or 0
end

-- ══════════════════════════════════════════════════════════════════════════════
-- BODY EFFECTS (direct check, no entity module)
-- ══════════════════════════════════════════════════════════════════════════════
local bodyeffects = {}
bodyeffects.get = function(player, beffect)
    local ok, val = pcall(function()
        if player and player.Character and player.Character:FindFirstChild('BodyEffects') then
            local be = player.Character.BodyEffects:FindFirstChild(beffect)
            if be then return be.Value end
        end
        return nil
    end)
    return ok and val or nil
end

-- ══════════════════════════════════════════════════════════════════════════════
-- STATE
-- ══════════════════════════════════════════════════════════════════════════════
local stomp_offset = 3
local stomping = false
local killing = false
local grabbing = false
local assist = false
local mode = 'kill'
local sentry = false
local stop = false
local target = nil
local autogun = false
local buyinammo = false
local void = true
local ka = false
local karange = 35
local whitelist = {}
local automask = false
local autoarmor = false
local badstrafe = false
local weld = false
local punch = false
local flamethrower = false
local auto = false
local farming = false
local multikilling = false
local noclip = false

local showtarget = altcontrol.owners[1] or nil
local show = showtarget ~= nil

local default = 'rbxassetid://5917459365'
local currentanim

local anims = {
    kickinglegs = 120370790028350, spongebobdance = 18443245017,
    teleport = 104767795538635, crossed = 128386160365167,
    imagination = 18443237526, yungblud = 15609995579,
    laugh = 3337966527, floss = 5917459365, sleep = 4686925579,
    hype = 3695333486, sad = 4841407203
}

if altcontrol and altcontrol.emotes then
    for i, v in altcontrol.emotes do anims[i] = v end
end

if altcontrol and altcontrol.whitelist then
    for i, v in altcontrol.whitelist do table.insert(whitelist, v) end
end

local loadanimation = function(animation, speed)
    if not lplr or not lplr.Character or not lplr.Character:FindFirstChildOfClass('Humanoid') or not lplr.Character.Humanoid:FindFirstChild('Animator') then return end
    if currentanim then currentanim:Stop() end
    currentanim = nil
    local anim = Instance.new('Animation')
    local id = tostring(animation)
    if not id:match('^rbxassetid://') then id = 'rbxassetid://' .. id end
    anim.AnimationId = id
    local track = lplr.Character.Humanoid.Animator:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action4
    track.Looped = true
    track:Play()
    track:AdjustSpeed(speed or 1)
    currentanim = track
    return track
end

-- ══════════════════════════════════════════════════════════════════════════════
-- GUI
-- ══════════════════════════════════════════════════════════════════════════════
local screen = Instance.new('ScreenGui')
screen.Parent = game:GetService('CoreGui')
screen.Name = 'zerohub_altbot'

local info = Instance.new('TextLabel')
info.Position = UDim2.new(0.5, 0, 0.55, 0)
info.AnchorPoint = Vector2.new(0.5, 0.5)
info.TextStrokeColor3 = Color3.new()
info.TextColor3 = Color3.new(1, 1, 1)
info.Size = UDim2.new(0.2, 0, 0.2, 0)
info.FontSize = Enum.FontSize.Size14
info.BackgroundTransparency = 1
info.TextStrokeTransparency = 0
info.Font = Enum.Font.Code
info.RichText = true
info.Parent = screen
info.Text = ''

for i, v in workspace:GetDescendants() do if v:IsA('Seat') then v.Disabled = true end end
workspace.DescendantAdded:Connect(function(inst) if inst:IsA('Seat') then inst.Disabled = true end end)

-- ══════════════════════════════════════════════════════════════════════════════
-- CORE LOOPS
-- ══════════════════════════════════════════════════════════════════════════════
local t = 0
-- ══════════════════════════════════════════════════════════════════════════════
-- CORE LOOPS (TP-on-top style)
-- ══════════════════════════════════════════════════════════════════════════════
local t = 0

-- KO check + auto-void
task.spawn(function()
    repeat task.wait()
        if target and killing then
            if bodyeffects.get(target, 'K.O') or not players:FindFirstChild(target.Name) then
                local tname = target and target.Name or '?'
                local deadTarget = target
                killing = false
                pcall(function() camera.CameraSubject = lplr.Character.Humanoid end)

                -- Auto stomp if sentry or assist is on
                if (sentry or assist) and deadTarget and players:FindFirstChild(tname) and bodyeffects.get(deadTarget, 'K.O') then
                    info.Text = 'stomping ' .. tname
                    pcall(function() wsSend({type='log', msg='Auto-stomping ' .. tname}) end)
                    stomping = true; target = deadTarget
                else
                    utils.update(CFrame.new(x(), yy(), x()))
                    info.Text = 'killed ' .. tname .. ' - voiding'
                    pcall(function() wsSend({type='log', msg='Killed ' .. tname .. ' - back to void'}) end)
                    target = nil
                    task.delay(2, function() if not killing and not stomping then info.Text = '' end end)
                end
            end
        end
        if target and stomping then
            if not bodyeffects.get(target, 'K.O') or bodyeffects.get(target, 'SDeath') or not players:FindFirstChild(target.Name) then
                local tname = target and target.Name or '?'
                stomping = false
                pcall(function() camera.CameraSubject = lplr.Character.Humanoid end)
                utils.update(CFrame.new(x(), yy(), x()))
                info.Text = 'stomped ' .. tname .. ' - voiding'
                pcall(function() wsSend({type='log', msg='Stomped ' .. tname .. ' - back to void'}) end)
                target = nil
                task.delay(2, function() if not killing and not stomping then info.Text = '' end end)
            end
        end
    until not game
end)

-- Main combat loop — Heartbeat-based for maximum fire rate (~60Hz), kills in ~1 sec
local _combatConn
_combatConn = runservice.Heartbeat:Connect(function()
    pcall(function()
        -- ── KILL ──────────────────────────────────────────────────────────────
        if localent.Alive and target and killing then
            if bodyeffects.get(target, 'K.O') or not players:FindFirstChild(target.Name) then return end
            if not target.Character then return end

            -- Still reloading — stay ON TOP of target, don't void
            if bodyeffects.get(lplr, 'Reload') then
                local stayRoot = target.Character:FindFirstChild('HumanoidRootPart')
                if stayRoot then utils.update(CFrame.new(stayRoot.Position + Vector3.new(0, 5, 0))) end
                return
            end

            -- Buy guns if we have none
            if #guns == 0 then
                local dg = altcontrol.default_guns or {'rifle', 'flintlock'}
                for i, v in dg do
                    if pguns[v] then
                        local status = pguns[v]
                        if not status or not localent.Alive then continue end
                        local weapon = status.name:gsub('%s*%- %$%d+', '')
                        if lplr.Backpack and lplr.Character and not lplr.Backpack:FindFirstChild(weapon) and not lplr.Character:FindFirstChild(weapon) then
                            info.Text = 'buying ' .. v
                            utils.purchase('weapon', status.name)
                        end
                    end
                end
                return
            end

            -- Check forcefield
            if target.Character:FindFirstChildOfClass('ForceField') then
                info.Text = 'target has forcefield - waiting'
                utils.update(CFrame.new(x(), yy(), x()))
                return
            end

            -- Camera follow target
            if target.Character:FindFirstChild('Humanoid') then
                camera.CameraSubject = target.Character.Humanoid
            end

            -- Handle GRABBING_CONSTRAINT redirect
            if target.Character:FindFirstChild('GRABBING_CONSTRAINT') then
                local a = target.Character:FindFirstChild('GRABBING_CONSTRAINT')
                if a:GetAttribute('PLAYER_HOLD') then
                    local nt = utils.getname(a:GetAttribute('PLAYER_HOLD'))
                    if nt then target = nt end
                end
            end

            local hum = target.Character.Humanoid
            if not hum then return end

            local head = target.Character:FindFirstChild('Head')
            local root = target.Character:FindFirstChild('HumanoidRootPart')
            if not head or not root then return end

            info.Text = 'shooting (' .. target.Name .. ') | hp: ' .. math.floor((hum.Health / hum.MaxHealth) * 100) .. '%'

            -- Always read LIVE position every shot — never use cached tpos
            -- This tracks targets through server TPs, flings, movement hacks, etc.
            local livePos = root.Position

            -- Lock bot directly on top of target (re-TP every frame = no escape)
            utils.update(CFrame.new(livePos + Vector3.new(0, 5, 0)))

            -- Burst: fire ALL guns, 6 shots each per Heartbeat tick
            for _, v in guns do
                if not lplr or not lplr.Character or not target or not target.Character then break end
                v.Parent = lplr.Character
                if not v or not v:FindFirstChild('Ammo') or buyinammo then continue end

                if v.Ammo.Value == 0 then
                    if utils.getfullammo(v) ~= 0 then utils.reload(v) end
                    continue
                end

                -- Re-read live position PER SHOT so each bullet tracks current location
                for _ = 1, 6 do
                    local shotPos = root.Position  -- live read each iteration
                    utils.shoot({
                        startposition = shotPos + Vector3.new(0, seed:NextNumber(2, 5), 0),
                        position      = shotPos,
                        part          = head,
                        tool          = v,
                    })
                end
            end
            return
        end

        -- ── STOMP ─────────────────────────────────────────────────────────────
        if stomping and target and target.Character then
            if bodyeffects.get(lplr, 'Reload') then
                local stayRoot = target.Character:FindFirstChild('HumanoidRootPart')
                if stayRoot then utils.update(CFrame.new(stayRoot.Position + Vector3.new(0, 5, 0))) end
                return
            end
            for i, v in lplr.Character:GetChildren() do if v:IsA('Tool') then v.Parent = lplr.Backpack end end
            info.Text = 'stomping (' .. target.Name .. ')'
            local lt = target.Character:FindFirstChild('LowerTorso') or target.Character:FindFirstChild('HumanoidRootPart')
            if lt then
                utils.update(CFrame.new(lt.Position + Vector3.new(0, stomp_offset or 4, 0)))
            end
            lplr.Character.HumanoidRootPart.Velocity = Vector3.zero
            replicated.MainEvent:FireServer('Stomp')
            return
        end

        -- ── IDLE ──────────────────────────────────────────────────────────────
        if not (killing or stomping) then
            if showtarget then
                local showpos = show and utils:getposition(players:FindFirstChild(showtarget)) or nil
                utils.update(showpos and showpos + Vector3.new(0, 4, 4) or CFrame.new(x(), yy(), x()))
            elseif void then
                utils.update(CFrame.new(x(), yy(), x()))
            end
        end
    end)
end)

-- Gun tracking
task.spawn(function()
    repeat task.wait()
        pcall(function()
            if not startergui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack) then startergui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) end
            if lplr and lplr.Character then
                for i, gun in guns do
                    if not gun or not gun.Parent or not (gun.Parent == lplr.Character or gun.Parent == lplr.Backpack) then table.remove(guns, i) end
                end
                for i, v in lplr.Character:GetChildren() do
                    if v:IsA('Tool') and v:FindFirstChild('Ammo') and not table.find(guns, v) then table.insert(guns, v) end
                end
                for i, v in lplr.Backpack:GetChildren() do
                    if v:IsA('Tool') and v:FindFirstChild('Ammo') and not table.find(guns, v) then table.insert(guns, v) end
                end
            end
        end)
    until not game
end)

-- Ammo buy loop
task.spawn(function()
    repeat task.wait()
        pcall(function()
            for i, v in guns do
                if utils.getfullammo(v) == 0 and localent.Alive then
                    local purchase
                    for i2, a in ammos do
                        if v.Name:lower():gsub('[%[%]]', ''):find(tostring(i2):lower():gsub('[%[%]]', ''), 1, true) then purchase = '[' .. i2 .. ']'; break end
                    end
                    buyinammo = true
                    if not purchase then continue end
                    if v and v.Parent and utils.getfullammo(v) > 0 then
                        utils.reload(v)
                        repeat task.wait() until not bodyeffects.get(lplr, 'Reload') or not killing or stop
                    end
                    info.Text = ''; buyinammo = false
                end
            end
        end)
    until not game
end)

-- Auto reload idle
task.spawn(function()
    repeat task.wait()
        pcall(function()
            if localent.Alive and lplr.Character then
                local com = lplr.Character:FindFirstChild('COMPart')
                if com then com:Destroy() end
            end
            if not killing and lplr.Character then
                for i, v in lplr.Character:GetChildren() do
                    if v:IsA('Tool') and v:FindFirstChild('Ammo') and v.Ammo.Value <= 2 then utils.reload(v) end
                end
                for i, v in lplr.Backpack:GetChildren() do
                    if v:IsA('Tool') and v:FindFirstChild('Ammo') and v.Ammo.Value == 0 and utils.getfullammo(v) ~= 0 then
                        v.Parent = lplr.Character; utils.reload(v)
                        repeat task.wait() until not bodyeffects.get(lplr, 'Reload')
                        v.Parent = lplr.Backpack; task.wait(1)
                    end
                end
            end
        end)
    until not game
end)

-- Bot protection: track who kills the bot and auto revenge
local revengeQueue = {} -- list of player names to revenge kill

-- Track last person who shot the bot
local lastBotAttacker = nil
replicated.MainEvent.OnClientEvent:Connect(function(name, plr, handle, startPos, aimPos, hitPart, ...)
    if name ~= 'ClientBullet' then return end
    pcall(function()
        -- Check if bot got hit
        if typeof(hitPart) == 'Instance' then
            if hitPart:IsDescendantOf(lplr.Character) or (hitPart.Parent and hitPart.Parent == lplr.Character) then
                local shooter
                if typeof(plr) == 'Instance' then
                    if plr:IsA('Player') then shooter = plr
                    else shooter = players:GetPlayerFromCharacter(plr) or (plr.Parent and players:GetPlayerFromCharacter(plr.Parent)) end
                end
                if shooter and shooter ~= lplr and not table.find(altcontrol.owners, shooter.Name) and not table.find(whitelist, shooter.Name) then
                    lastBotAttacker = shooter.Name
                end
            end
        end
    end)
end)

-- Auto reset on KO + revenge
task.spawn(function()
    repeat task.wait()
        if bodyeffects.get(lplr, 'K.O') then
            -- Find who's near the bot (stomper) or use last attacker
            local killer = nil
            pcall(function()
                if lplr.Character and lplr.Character:FindFirstChild('HumanoidRootPart') then
                    local botPos = lplr.Character.HumanoidRootPart.Position
                    local closest, closestDist = nil, 15
                    for _, v in players:GetPlayers() do
                        if v == lplr or table.find(altcontrol.owners, v.Name) or table.find(whitelist, v.Name) then continue end
                        if not v.Character or not v.Character:FindFirstChild('HumanoidRootPart') then continue end
                        local dist = (botPos - v.Character.HumanoidRootPart.Position).Magnitude
                        if dist < closestDist then closest = v; closestDist = dist end
                    end
                    if closest then killer = closest.Name end
                end
            end)
            -- Use last attacker if no one nearby
            if not killer and lastBotAttacker then killer = lastBotAttacker end

            -- Add to revenge queue
            if killer and not table.find(revengeQueue, killer) then
                table.insert(revengeQueue, killer)
                pcall(function() wsSend({type='log', msg='[revenge] ' .. killer .. ' killed bot — added to kill queue'}) end)
            end

            lastBotAttacker = nil
            pcall(function() lplr.Character.Humanoid.Health = 0 end)
            repeat task.wait() until localent.Alive
            utils.update(CFrame.new(x(), yy(), x()))

            -- Process revenge queue after respawn
            task.spawn(function()
                task.wait(1) -- wait for respawn
                while #revengeQueue > 0 and not stop do
                    local targetName = table.remove(revengeQueue, 1)
                    local user = utils.getname(targetName)
                    if user and user.Character and not bodyeffects.get(user, 'K.O') and not bodyeffects.get(user, 'SDeath') then
                        pcall(function() wsSend({type='log', msg='[revenge] Killing ' .. user.Name}) end)
                        target = user; killing = true
                        repeat task.wait() until not killing or stop
                        -- Auto stomp
                        if user and players:FindFirstChild(user.Name) and bodyeffects.get(user, 'K.O') then
                            stomping = true; target = user
                            repeat task.wait() until not stomping or stop
                        end
                        target = nil
                        utils.update(CFrame.new(x(), yy(), x()))
                        task.wait(0.5)
                    end
                end
            end)
        end
    until not game
end)

-- Anti-vehicle: eject from seats/vehicles (only when not in combat)
task.spawn(function()
    repeat task.wait(0.5)
        pcall(function()
            if killing or stomping then return end
            if lplr.Character and lplr.Character:FindFirstChild('Humanoid') then
                local hum = lplr.Character.Humanoid
                if hum.Sit then
                    hum.Sit = false
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    task.wait(0.1)
                    for _, v in lplr.Character:GetDescendants() do
                        if v:IsA('Weld') and v.Name == 'SeatWeld' then v:Destroy() end
                    end
                    if not killing and not stomping then
                        utils.update(CFrame.new(x(), yy(), x()))
                    end
                end
            end
        end)
    until not game
end)

-- ══════════════════════════════════════════════════════════════════════════════
-- NOCLIP — ทำให้ลอดกำแพง/พื้น ได้ทุก part ใน character
-- ══════════════════════════════════════════════════════════════════════════════
runservice.Stepped:Connect(function()
    if not noclip then return end
    pcall(function()
        if lplr.Character then
            for _, part in lplr.Character:GetDescendants() do
                if part:IsA('BasePart') and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end)

-- Anti-stomp sentry: if owner gets KO'd, kill whoever is near them (stomping)
task.spawn(function()
    repeat task.wait(0.2)
        if not sentry or stop or killing or stomping then continue end
        pcall(function()
            for _, ownerName in altcontrol.owners do
                local owner = players:FindFirstChild(ownerName)
                if not owner or not owner.Character or not owner.Character:FindFirstChild('HumanoidRootPart') then continue end
                
                -- Owner is KO'd — someone might be stomping
                if bodyeffects.get(owner, 'K.O') and not bodyeffects.get(owner, 'SDeath') then
                    local ownerPos = owner.Character.HumanoidRootPart.Position
                    -- Find closest enemy standing on top of owner (stomping)
                    local closest, closestDist = nil, 12
                    for _, v in players:GetPlayers() do
                        if v == lplr or v.Name == ownerName or table.find(altcontrol.owners, v.Name) or table.find(whitelist, v.Name) then continue end
                        if not v.Character or not v.Character:FindFirstChild('HumanoidRootPart') then continue end
                        if bodyeffects.get(v, 'K.O') or bodyeffects.get(v, 'SDeath') then continue end
                        local dist = (ownerPos - v.Character.HumanoidRootPart.Position).Magnitude
                        if dist < closestDist then closest = v; closestDist = dist end
                    end
                    if closest and not killing then
                        pcall(function() wsSend({type='log', msg='[sentry] ' .. closest.Name .. ' stomping ' .. ownerName .. ' — killing'}) end)
                        target = closest; killing = true
                    end
                end
            end
        end)
    until not game
end)

-- ══════════════════════════════════════════════════════════════════════════════
-- INSTANT SENTRY + ASSIST  (Heartbeat HP delta — reacts in <1 frame, ~60Hz)
-- Replaces ClientBullet (misses bullets that don't hit) + 0.15s poll (too slow)
-- ══════════════════════════════════════════════════════════════════════════════
local _sentryHP = {}   -- [ownerName]  = last hp
local _assistHP = {}   -- [playerName] = last hp

local function fastEngage(plr, reason)
    if not plr or not plr.Character then return end
    if bodyeffects.get(plr, 'K.O') or bodyeffects.get(plr, 'SDeath') then return end
    if plr.Character:FindFirstChildOfClass('ForceField') then return end
    pcall(function() wsSend({type='log', msg='[' .. reason .. '] engaging ' .. plr.Name}) end)
    target  = plr
    killing = true
end

runservice.Heartbeat:Connect(function()
    if stop then return end
    pcall(function()

        -- SENTRY: owner HP dropped → find closest attacker and kill them NOW
        if sentry then
            for _, ownerName in altcontrol.owners do
                local owner = players:FindFirstChild(ownerName)
                if not owner or not owner.Character then _sentryHP[ownerName] = nil; continue end
                local hum  = owner.Character:FindFirstChild('Humanoid')
                local root = owner.Character:FindFirstChild('HumanoidRootPart')
                if not hum or not root then continue end

                local hp   = hum.Health
                local prev = _sentryHP[ownerName] or hp
                _sentryHP[ownerName] = hp

                if hp < prev and hp > 0 and not killing and not stomping then
                    local closest, closestDist = nil, 60
                    for _, v in players:GetPlayers() do
                        if v == lplr or table.find(altcontrol.owners, v.Name) or table.find(whitelist, v.Name) then continue end
                        if not v.Character or not v.Character:FindFirstChild('HumanoidRootPart') then continue end
                        if bodyeffects.get(v, 'K.O') or bodyeffects.get(v, 'SDeath') then continue end
                        local d = (root.Position - v.Character.HumanoidRootPart.Position).Magnitude
                        if d < closestDist then closest = v; closestDist = d end
                    end
                    if closest then fastEngage(closest, 'sentry') end
                end
            end
        end

        -- ASSIST: enemy HP dropped while owner is nearby → bot finishes them
        if assist and not killing and not stomping then
            for _, v in players:GetPlayers() do
                if v == lplr or table.find(altcontrol.owners, v.Name) or table.find(whitelist, v.Name) then continue end
                if not v.Character or not v.Character:FindFirstChild('Humanoid') or not v.Character:FindFirstChild('HumanoidRootPart') then
                    _assistHP[v.Name] = nil; continue
                end
                if v.Character:FindFirstChildOfClass('ForceField') or bodyeffects.get(v, 'K.O') or bodyeffects.get(v, 'SDeath') then
                    _assistHP[v.Name] = nil; continue
                end

                local hp   = v.Character.Humanoid.Health
                local prev = _assistHP[v.Name] or hp
                _assistHP[v.Name] = hp

                if hp < prev and hp > 0 then
                    for _, ownerName in altcontrol.owners do
                        local owner = players:FindFirstChild(ownerName)
                        if owner and owner.Character and owner.Character:FindFirstChild('HumanoidRootPart') then
                            local d = (owner.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
                            if d < 50 then
                                fastEngage(v, 'assist')
                                break
                            end
                        end
                    end
                end
            end
            for name in pairs(_assistHP) do
                if not players:FindFirstChild(name) then _assistHP[name] = nil end
            end
        end

    end)
end)

-- Kill aura
task.spawn(function()
    repeat task.wait(0.1)
        if not ka or stop or not localent.Alive or not altcontrol.owners then continue end
        for _, v in players:GetPlayers() do
            if not ka then break end
            if v == lplr or table.find(altcontrol.owners, v.Name) or table.find(whitelist, v.Name) then continue end
            if not v.Character or not v.Character:FindFirstChild('HumanoidRootPart') then continue end
            if v.Character:FindFirstChild('ForceField') or bodyeffects.get(v, 'SDeath') or bodyeffects.get(v, 'K.O') then continue end
            for _, ownerName in altcontrol.owners do
                local owner = players:FindFirstChild(ownerName)
                if owner and owner.Character and owner.Character:FindFirstChild('HumanoidRootPart') then
                    if (owner.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude <= karange then
                        if not killing and not target then
                            target = v; killing = true
                            repeat task.wait() until not killing or not ka or stop
                            if not void then void = true end
                        end
                        break
                    end
                end
            end
        end
    until not game
end)

local WS_URL = altcontrol.ws_url or 'ws://localhost:8000/ws'
local WS_TOKEN = altcontrol.ws_token or ''
local wsConnected = false
local wsSocket = nil

local function wsLog(msg) print('[ZeroHub AltBot] ' .. msg) end

local function wsSend(data)
    pcall(function() if wsSocket then wsSocket:Send(http:JSONEncode(data)) end end)
end

local function getStatus()
    local status = 'idle'
    if killing then status = 'killing' elseif stomping then status = 'stomping' elseif grabbing then status = 'grabbing' end
    local hp = 0
    pcall(function() hp = math.floor((lplr.Character.Humanoid.Health / lplr.Character.Humanoid.MaxHealth) * 100) end)
    return {
        username = lplr.Name, display_name = lplr.DisplayName,
        server_id = game.JobId, place_id = game.PlaceId,
        status = status, target = target and target.Name or nil,
        health = hp, money = utils.getmoney(), guns = #guns,
        alive = localent.Alive, sentry = sentry, assist = assist,
        killaura = ka, void = void, automask = automask,
        autoarmor = autoarmor, autogun = autogun, farming = farming,
    }
end

local function handleCommand(cmd, args)
    args = args or {}
    local targetName = args.target or ''
    wsLog('CMD: ' .. cmd .. ' | ' .. targetName)

    if cmd == 'kill' then
        local user = utils.getname(targetName)
        if not user then wsSend({type='log', msg='Target not found: ' .. targetName}); return end
        killing = true; target = user; wsSend({type='log', msg='Killing ' .. user.Name})
    elseif cmd == 'stomp' then
        local user = utils.getname(targetName)
        if not user then wsSend({type='log', msg='Target not found'}); return end
        killing = true; target = user; wsSend({type='log', msg='Kill+Stomp ' .. user.Name})
        task.spawn(function()
            repeat task.wait() until not killing
            stomping = true; target = user
            repeat task.wait() until not stomping or bodyeffects.get(user, 'SDeath') or not bodyeffects.get(user, 'K.O')
        end)
    elseif cmd == 'auto' then
        local user = utils.getname(targetName)
        if not user then wsSend({type='log', msg='Target not found'}); return end
        auto = not auto; wsSend({type='log', msg=(auto and 'ON' or 'OFF') .. ' auto on ' .. user.Name})
        if auto then task.spawn(function()
            repeat task.wait()
                if auto and not bodyeffects.get(user, 'SDeath') then
                    killing = true; target = user
                    repeat task.wait() until not killing or not auto
                    if not auto then break end; task.wait(0.1)
                    stomping = true; target = user
                    repeat task.wait() until not stomping or not auto or bodyeffects.get(user, 'SDeath')
                else utils.update(CFrame.new(x(), yy(), x())); task.wait(1) end
            until not auto
        end) end
    elseif cmd == 'stop' then
        killing = false; stop = true; stomping = false; auto = false; target = nil; info.Text = ''
        ka = false; showtarget = nil; show = false; assist = false; void = true; sentry = false
        farming = false; multikilling = false; noclip = false
        pcall(function() camera.CameraSubject = lplr.Character.Humanoid; utils.update(CFrame.new(x(), yy(), x())) end)
        stop = false; wsSend({type='log', msg='Stopped'})
    elseif cmd == 'guns' then
        for i, v in (altcontrol.default_guns or {'rifle', 'flintlock'}) do
            local s = pguns[v]; if not s then continue end
            local w = s.name:gsub('%s*%- %$%d+', '')
            if not lplr.Backpack:FindFirstChild(w) and not lplr.Character:FindFirstChild(w) then utils.purchase('weapon', s.name) end
        end
        wsSend({type='log', msg='Bought guns'})
    elseif cmd == 'sentry' then sentry = not sentry; wsSend({type='log', msg=(sentry and 'ON' or 'OFF') .. ' sentry'})
    elseif cmd == 'assist' then assist = not assist; wsSend({type='log', msg=(assist and 'ON' or 'OFF') .. ' assist'})
    elseif cmd == 'killaura' then ka = not ka; if not ka and not void then void = true end; wsSend({type='log', msg=(ka and 'ON' or 'OFF') .. ' killaura'})
    elseif cmd == 'show' then
        local user = utils.getname(targetName)
        if user then showtarget = user.Name; show = true; wsSend({type='log', msg='Following ' .. user.Name}) end
    elseif cmd == 'void' then showtarget = nil; show = false; void = true; wsSend({type='log', msg='Voided'})
    elseif cmd == 'bring' then
        local rr = utils.getname(targetName); if not rr then return end
        local to = args.target2 and utils.getname(args.target2) or nil
        killing = true; target = rr; repeat task.wait() until not killing or stop
        for i, v in lplr.Character:GetChildren() do if v:IsA('Tool') then v.Parent = lplr.Backpack end end
        void = false
        repeat
            utils.update(CFrame.new(rr.Character.LowerTorso.Position) + Vector3.new(0, stomp_offset, 0))
            replicated.MainEvent:FireServer('Grabbing', false); task.wait(0.37)
        until (rr.Character and rr.Character:FindFirstChild('GRABBING_CONSTRAINT')) or bodyeffects.get(rr, 'Grabbed') or not bodyeffects.get(rr, 'K.O') or bodyeffects.get(rr, 'SDeath')
        if to and to.Character then
            utils.update(CFrame.new(to.Character.LowerTorso.Position) + Vector3.new(3, 5, 0))
            task.wait(0.37); replicated.MainEvent:FireServer('Grabbing', false)
        end
        task.wait(0.2); void = true; utils.update(CFrame.new(x(), yy(), x())); wsSend({type='log', msg='Bring done'})
    elseif cmd == 'automask' then
        automask = not automask; wsSend({type='log', msg=(automask and 'ON' or 'OFF') .. ' automask'})
        if automask then task.spawn(function()
            repeat task.wait()
                if pguns['riot mask'] and localent.Alive and not lplr.Character:FindFirstChild('In-gameMask') and automask then
                    utils.purchase('weapon', pguns['riot mask'].name)
                    local mask; repeat task.wait(); mask = lplr.Backpack:FindFirstChild('[Mask]') until mask or stop
                    if mask then mask.Parent = lplr.Character; mask:Activate()
                        repeat task.wait() until lplr.Character:FindFirstChild('In-gameMask'); mask.Parent = lplr.Backpack end
                end
            until not automask or stop
        end) end
    elseif cmd == 'autoarmor' then
        autoarmor = not autoarmor; wsSend({type='log', msg=(autoarmor and 'ON' or 'OFF') .. ' autoarmor'})
        if autoarmor then task.spawn(function()
            repeat task.wait()
                if autoarmor and localent.Alive and utils.needarmor() and pguns['medium armor'] then utils.purchase('weapon', pguns['medium armor'].name) end
            until not autoarmor or stop
        end) end
    elseif cmd == 'aguns' then
        autogun = not autogun; wsSend({type='log', msg=(autogun and 'ON' or 'OFF') .. ' autoguns'})
        if autogun then task.spawn(function()
            repeat task.wait()
                if (#guns == 0 or bodyeffects.get(lplr, 'SDeath')) then
                    repeat task.wait() until localent.Alive
                    for i, v in (altcontrol.default_guns or {'rifle', 'flintlock'}) do
                        local s = pguns[v]; if not s then continue end
                        local w = s.name:gsub('%s*%- %$%d+', '')
                        if not lplr.Backpack:FindFirstChild(w) and not lplr.Character:FindFirstChild(w) then utils.purchase('weapon', s.name) end
                    end
                end
            until not autogun or stop
        end) end
    elseif cmd == 'rejoin' then wsSend({type='log', msg='Rejoining...'}); teleport:TeleportToPlaceInstance(game.PlaceId, game.JobId, lplr)
    elseif cmd == 'leave' then wsSend({type='log', msg='Leaving...'}); lplr:Kick('[ZeroHub AltBot] Kicked via panel')
    elseif cmd == 'reset' then pcall(function() lplr.Character.Humanoid.Health = 0 end); wsSend({type='log', msg='Reset'})
    elseif cmd == 'emote' then local e = targetName:lower(); if anims[e] then loadanimation(anims[e]); wsSend({type='log', msg='Emote: ' .. e}) end
    elseif cmd == 'noclip' then
        noclip = not noclip
        -- ถ้าปิด noclip ให้ restore CanCollide กลับ
        if not noclip and lplr.Character then
            pcall(function()
                for _, part in lplr.Character:GetDescendants() do
                    if part:IsA('BasePart') then part.CanCollide = true end
                end
            end)
        end
        wsSend({type='log', msg=(noclip and 'ON' or 'OFF') .. ' noclip'})
    elseif cmd == 'weld' then weld = not weld; wsSend({type='log', msg=(weld and 'ON' or 'OFF') .. ' weld'})
    elseif cmd == 'punch' then punch = not punch; wsSend({type='log', msg=(punch and 'ON' or 'OFF') .. ' punch'})
    elseif cmd == 'flame' then flamethrower = not flamethrower; wsSend({type='log', msg=(flamethrower and 'ON' or 'OFF') .. ' flame'})
    elseif cmd == 'whitelist' then
        local user = utils.getname(targetName); if not user then return end
        local idx = table.find(whitelist, user.Name)
        if idx then table.remove(whitelist, idx); wsSend({type='log', msg='Unwhitelisted ' .. user.Name})
        else table.insert(whitelist, user.Name); wsSend({type='log', msg='Whitelisted ' .. user.Name}) end
    elseif cmd == 'owner' then
        local user = utils.getname(targetName); if not user then return end
        local idx = table.find(altcontrol.owners, user.Name)
        if idx then table.remove(altcontrol.owners, idx); wsSend({type='log', msg='-owner ' .. user.Name})
        else table.insert(altcontrol.owners, user.Name); wsSend({type='log', msg='+owner ' .. user.Name}) end
    elseif cmd == 'range' then local v = tonumber(targetName); if v then karange = v; wsSend({type='log', msg='Range: ' .. v}) end
    elseif cmd == 'stomp_offset' then local v = tonumber(targetName); if v then stomp_offset = v; wsSend({type='log', msg='SO: ' .. v}) end
    elseif cmd == 'setfps' then local v = tonumber(targetName); if v and setfpscap then setfpscap(v); wsSend({type='log', msg='FPS: ' .. v}) end
    elseif cmd == 'fakepos' then
        pcall(function()
            local fake = true; lplr.Character.Humanoid.Health = 0; setfflag('NextGenReplicatorEnabledWrite4', 'true')
            repeat task.wait() until localent.Alive; utils.update(CFrame.new(x(), yy(), x())); wsSend({type='log', msg='Fakepos ON'})
        end)
    elseif cmd == 'faststrafe' then badstrafe = not badstrafe; wsSend({type='log', msg=(badstrafe and 'ON' or 'OFF') .. ' faststrafe'})
    elseif cmd == 'hidesc' then pcall(function() runservice:Set3dRenderingEnabled(not runservice:Is3dRenderingEnabled()) end); wsSend({type='log', msg='Screen toggled'})
    elseif cmd == 'redeem' then
        pcall(function()
            local codes = http:JSONDecode(game:HttpGet('https://raw.githubusercontent.com/ah2r/storage/refs/heads/main/sync/codes.sync'))
            for _, v in codes do utils.redeem(v); task.wait(0.6) end
        end); wsSend({type='log', msg='Redeemed codes'})

    elseif cmd == 'debug' then
        -- Log next 10 MainEvent fires to panel
        wsSend({type='log', msg='[debug] Listening for next 10 MainEvent fires...'})
        local debugCount = 0
        local debugConn
        debugConn = replicated.MainEvent.OnClientEvent:Connect(function(name, ...)
            debugCount += 1
            local args = {...}
            local argStr = ''
            for i, v in args do
                argStr = argStr .. tostring(i) .. '=' .. typeof(v) .. '(' .. tostring(v):sub(1, 30) .. ') '
            end
            pcall(function() wsSend({type='log', msg='[debug #' .. debugCount .. '] ' .. tostring(name) .. ' | ' .. argStr}) end)
            if debugCount >= 10 then debugConn:Disconnect(); wsSend({type='log', msg='[debug] Done'}) end
        end)
        task.delay(30, function() if debugConn.Connected then debugConn:Disconnect(); wsSend({type='log', msg='[debug] Timeout'}) end end)

    -- TP to location
    elseif cmd == 'tp' then
        local loc = targetName:lower()
        if pos[loc] then
            utils.update(CFrame.new(pos[loc]))
            wsSend({type='log', msg='TP to ' .. loc})
        else
            -- try as player name
            local user = utils.getname(targetName)
            if user then
                local p = utils:getposition(user)
                if p then utils.update(p + Vector3.new(0, 5, 0)); wsSend({type='log', msg='TP to ' .. user.Name}) end
            else
                local locs = {}
                for k, _ in pairs(pos) do table.insert(locs, k) end
                wsSend({type='log', msg='Unknown location. Available: ' .. table.concat(locs, ', ')})
            end
        end

    -- Farm money (auto rob/loot cash drops)
    elseif cmd == 'farm' then
        farming = not farming
        wsSend({type='log', msg=(farming and 'ON' or 'OFF') .. ' farming'})
        if farming then
            task.spawn(function()
                while farming and not stop do
                    pcall(function()
                        -- Collect cash drops on the ground
                        for _, v in workspace:GetDescendants() do
                            if not farming then break end
                            if v:IsA('ClickDetector') and v.Parent and v.Parent.Name:lower():find('cash') then
                                utils.update(v.Parent.CFrame or v.Parent.Position and CFrame.new(v.Parent.Position))
                                fireclickdetector(v)
                                task.wait(0.2)
                            end
                        end
                        -- Rob cash register if nearby
                        for _, v in workspace:GetDescendants() do
                            if not farming then break end
                            if v:IsA('ClickDetector') and v.Parent and (v.Parent.Name:lower():find('register') or v.Parent.Name:lower():find('rob') or v.Parent.Name:lower():find('atm')) then
                                local part = v.Parent:FindFirstChildOfClass('Part') or v.Parent:FindFirstChildOfClass('BasePart') or v.Parent
                                if part and part:IsA('BasePart') then
                                    utils.update(CFrame.new(part.Position + Vector3.new(0, 3, 0)))
                                    fireclickdetector(v)
                                    task.wait(0.5)
                                end
                            end
                        end
                    end)
                    task.wait(1)
                    if farming then
                        utils.update(CFrame.new(x(), yy(), x()))
                        task.wait(2)
                    end
                end
            end)
        end

    -- Multi-target kill queue
    elseif cmd == 'multikill' then
        local names = {}
        for name in targetName:gmatch('[^,]+') do
            local trimmed = name:match('^%s*(.-)%s*$')
            if trimmed and trimmed ~= '' then table.insert(names, trimmed) end
        end
        if #names == 0 then wsSend({type='log', msg='Usage: player1,player2,player3'}); return end
        multikilling = not multikilling
        if not multikilling then
            wsSend({type='log', msg='Multi kill STOPPED'})
            return
        end
        wsSend({type='log', msg='Multi kill LOOP: ' .. table.concat(names, ' > ') .. ' (send again to stop)'})
        task.spawn(function()
            local round = 0
            while multikilling and not stop do
                round = round + 1
                wsSend({type='log', msg='--- Round ' .. round .. ' ---'})
                for i, name in names do
                    if stop or not multikilling then break end
                    local user = utils.getname(name)
                    if not user then wsSend({type='log', msg='Skip: ' .. name .. ' (not found)'}); continue end
                    if bodyeffects.get(user, 'K.O') or bodyeffects.get(user, 'SDeath') then
                        wsSend({type='log', msg='Skip: ' .. name .. ' (dead)'}); continue
                    end
                    wsSend({type='log', msg='[' .. i .. '/' .. #names .. '] Killing ' .. user.Name})
                    killing = true; target = user
                    local timeout = tick()
                    repeat task.wait() until not killing or stop or not multikilling or (tick() - timeout > 30)
                    if stop or not multikilling then break end
                    if user and user.Character and bodyeffects.get(user, 'K.O') then
                        stomping = true; target = user
                        local t2 = tick()
                        repeat task.wait() until not stomping or stop or not multikilling or (tick() - t2 > 15)
                    end
                    wsSend({type='log', msg='[' .. i .. '/' .. #names .. '] Done: ' .. user.Name})
                    task.wait(0.5)
                end
                if stop or not multikilling then break end
                wsSend({type='log', msg='Round ' .. round .. ' done — waiting 3s...'})
                utils.update(CFrame.new(x(), yy(), x()))
                task.wait(3)
            end
            multikilling = false
            utils.update(CFrame.new(x(), yy(), x()))
            wsSend({type='log', msg='Multi kill loop ended'})
        end)

    -- Chat message from panel
    elseif cmd == 'chat' then
        pcall(function()
            local textChannel = game:GetService('TextChatService')
            local channel = textChannel and textChannel:FindFirstChild('TextChannels') and textChannel.TextChannels:FindFirstChild('RBXGeneral')
            if channel then
                channel:SendAsync(targetName)
                wsSend({type='log', msg='Chat: ' .. targetName})
            else
                -- fallback old chat
                replicated.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(targetName, 'All')
                wsSend({type='log', msg='Chat (legacy): ' .. targetName})
            end
        end)

    -- Player list
    elseif cmd == 'playerlist' then
        local list = {}
        for _, p in players:GetPlayers() do
            local hp = 0
            pcall(function() hp = math.floor((p.Character.Humanoid.Health / p.Character.Humanoid.MaxHealth) * 100) end)
            local isOwner = table.find(altcontrol.owners, p.Name) and true or false
            local isWl = table.find(whitelist, p.Name) and true or false
            table.insert(list, {
                name = p.Name,
                display = p.DisplayName,
                hp = hp,
                alive = p.Character and p.Character:FindFirstChild('Humanoid') and p.Character.Humanoid.Health > 0 or false,
                ko = bodyeffects.get(p, 'K.O') and true or false,
                owner = isOwner,
                whitelisted = isWl,
            })
        end
        wsSend({type='playerlist', players=list})

    -- Join owner's server
    elseif cmd == 'joinowner' then
        local ownerName = targetName ~= '' and targetName or (altcontrol.owners[1] or '')
        wsSend({type='log', msg='Looking for ' .. ownerName .. ' server...'})
        pcall(function()
            local pages = players:GetFriendsAsync(lplr.UserId)
            -- Try to find owner via API
            local userId
            local success, result = pcall(function()
                local url = 'https://users.roblox.com/v1/usernames/users'
                local body = http:JSONEncode({usernames = {ownerName}, excludeBannedUsers = false})
                local response = http:RequestAsync({Url = url, Method = 'POST', Headers = {['Content-Type'] = 'application/json'}, Body = body})
                local data = http:JSONDecode(response.Body)
                return data.data and data.data[1] and data.data[1].id
            end)
            if success and result then userId = result end
            if userId then
                local ok2, presence = pcall(function()
                    local url2 = 'https://presence.roblox.com/v1/presence/users'
                    local body2 = http:JSONEncode({userIds = {userId}})
                    local response2 = http:RequestAsync({Url = url2, Method = 'POST', Headers = {['Content-Type'] = 'application/json'}, Body = body2})
                    return http:JSONDecode(response2.Body)
                end)
                if ok2 and presence and presence.userPresences and presence.userPresences[1] then
                    local p = presence.userPresences[1]
                    if p.placeId and p.gameId then
                        wsSend({type='log', msg='Found! Joining ' .. ownerName .. ' server...'})
                        teleport:TeleportToPlaceInstance(p.placeId, p.gameId, lplr)
                        return
                    end
                end
            end
            wsSend({type='log', msg='Could not find ' .. ownerName .. ' server'})
        end)

    -- Server info/dashboard data
    elseif cmd == 'dashboard' then
        local playerCount = #players:GetPlayers()
        local money = utils.getmoney()
        local gunList = {}
        for _, g in guns do table.insert(gunList, g.Name) end
        wsSend({type='dashboard', data={
            username = lplr.Name,
            display = lplr.DisplayName,
            server = game.JobId,
            place = game.PlaceId,
            players = playerCount,
            money = money,
            guns = gunList,
            health = (function() local h = 0; pcall(function() h = math.floor((lplr.Character.Humanoid.Health / lplr.Character.Humanoid.MaxHealth) * 100) end); return h end)(),
            alive = localent.Alive,
            sentry = sentry, assist = assist, killaura = ka,
            void = void, automask = automask, autoarmor = autoarmor,
            autogun = autogun, farming = farming,
            karange = karange, stomp_offset = stomp_offset,
        }})
    end
end

-- WS Connection
local function connectWS()
    while true do
        local ok, socket = pcall(function()
            if WebSocket then return WebSocket.connect(WS_URL) end
            return nil
        end)
        if not ok or not socket then wsLog('WS failed. Retry 5s...'); task.wait(5); continue end
        wsSocket = socket; wsConnected = true; wsLog('Connected!')
        wsSend({ type = 'auth', token = WS_TOKEN, info = getStatus() })
        local statusThread = task.spawn(function()
            while wsConnected do pcall(function() wsSend({ type = 'status', data = getStatus() }) end); task.wait(2) end
        end)
        socket.OnMessage:Connect(function(raw)
            local ok2, msg = pcall(function() return http:JSONDecode(raw) end)
            if not ok2 then return end
            if msg.type == 'auth_ok' then wsLog('Auth OK!'); wsSend({type='log', msg='Bot: ' .. lplr.Name .. ' | ' .. game.JobId:sub(1,8)})
            elseif msg.type == 'auth_fail' then wsLog('Auth FAIL'); wsConnected = false
            elseif msg.type == 'command' then task.spawn(handleCommand, msg.cmd, msg.args) end
        end)
        socket.OnClose:Connect(function() wsLog('Disconnected'); wsConnected = false; wsSocket = nil end)
        repeat task.wait(1) until not wsConnected
        pcall(function() task.cancel(statusThread) end)
        wsLog('Reconnecting 5s...'); task.wait(5)
    end
end

loadanimation(default)
task.spawn(connectWS)
wsLog('Loaded! Player: ' .. lplr.Name)

-- ═══════════════════════════════════════════════════════════════════════════
-- OWNER CONTROL UI — only shows if current player is in owners list
-- ═══════════════════════════════════════════════════════════════════════════
if table.find(altcontrol.owners, lplr.Name) then
    task.spawn(function()
        local UIS = game:GetService("UserInputService")
        local spamTargets = {}

        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "CPOwner"
        ScreenGui.ResetOnSpawn = false
        if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
        if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game:GetService("CoreGui") end

        local Main = Instance.new("Frame", ScreenGui)
        Main.Size = UDim2.new(0, 300, 0, 400)
        Main.Position = UDim2.new(0, 100, 0.5, -200)
        Main.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
        Main.BorderSizePixel = 0
        Main.Visible = true
        Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
        local stroke = Instance.new("UIStroke", Main)
        stroke.Color = Color3.fromRGB(40, 40, 70)
        stroke.Thickness = 1

        -- Title
        local TBar = Instance.new("Frame", Main)
        TBar.Size = UDim2.new(1, 0, 0, 32)
        TBar.BackgroundColor3 = Color3.fromRGB(16, 16, 28)
        TBar.BorderSizePixel = 0
        Instance.new("UICorner", TBar).CornerRadius = UDim.new(0, 10)
        local TLabel = Instance.new("TextLabel", TBar)
        TLabel.Size = UDim2.new(1, -10, 1, 0)
        TLabel.Position = UDim2.new(0, 10, 0, 0)
        TLabel.BackgroundTransparency = 1
        TLabel.Text = "CatPrivate Control"
        TLabel.TextColor3 = Color3.fromRGB(124, 106, 255)
        TLabel.TextXAlignment = Enum.TextXAlignment.Left
        TLabel.Font = Enum.Font.GothamBold
        TLabel.TextSize = 13

        -- Player Scroll
        local Scroll = Instance.new("ScrollingFrame", Main)
        Scroll.Size = UDim2.new(1, -12, 1, -80)
        Scroll.Position = UDim2.new(0, 6, 0, 38)
        Scroll.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
        Scroll.BorderSizePixel = 0
        Scroll.ScrollBarThickness = 3
        Scroll.ScrollBarImageColor3 = Color3.fromRGB(124, 106, 255)
        Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 8)
        local Layout = Instance.new("UIListLayout", Scroll)
        Layout.Padding = UDim.new(0, 3)

        -- Bottom
        local Bot = Instance.new("Frame", Main)
        Bot.Size = UDim2.new(1, -12, 0, 28)
        Bot.Position = UDim2.new(0, 6, 1, -34)
        Bot.BackgroundTransparency = 1

        local function mkBtn(text, color, pos, size, cb)
            local b = Instance.new("TextButton", Bot)
            b.Size = size
            b.Position = pos
            b.BackgroundColor3 = color
            b.BorderSizePixel = 0
            b.Text = text
            b.TextColor3 = Color3.new(1,1,1)
            b.Font = Enum.Font.GothamBold
            b.TextSize = 10
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
            b.MouseButton1Click:Connect(cb)
            return b
        end

        mkBtn("Kill All", Color3.fromRGB(200, 40, 60), UDim2.new(0,0,0,0), UDim2.new(0.31,0,1,0), function()
            if wsSocket then wsSend({type='log', msg='[owner] Kill All'}) end
            for _, p in players:GetPlayers() do
                if p ~= lplr and not table.find(altcontrol.owners, p.Name) and not table.find(whitelist, p.Name) then
                    target = p; killing = true
                    repeat task.wait() until not killing or stop
                    target = nil
                end
            end
        end)

        local noclipBtn = mkBtn("Noclip", Color3.fromRGB(30, 100, 160), UDim2.new(0.34,0,0,0), UDim2.new(0.31,0,1,0), function() end)
        noclipBtn.MouseButton1Click:Connect(function()
            noclip = not noclip
            if not noclip and lplr.Character then
                pcall(function()
                    for _, part in lplr.Character:GetDescendants() do
                        if part:IsA('BasePart') then part.CanCollide = true end
                    end
                end)
            end
            noclipBtn.Text = noclip and "Noclip ON" or "Noclip"
            noclipBtn.BackgroundColor3 = noclip and Color3.fromRGB(20, 200, 100) or Color3.fromRGB(30, 100, 160)
        end)

        mkBtn("Stop", Color3.fromRGB(60, 60, 100), UDim2.new(0.68,0,0,0), UDim2.new(0.32,0,1,0), function()
            target = nil; killing = false; stomping = false; noclip = false
            noclipBtn.Text = "Noclip"; noclipBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 160)
            spamTargets = {}
        end)

        local function makeCard(plr)
            if plr == lplr or table.find(altcontrol.owners, plr.Name) then return end
            local card = Instance.new("Frame", Scroll)
            card.Name = "P_" .. plr.Name
            card.Size = UDim2.new(1, -6, 0, 48)
            card.BackgroundColor3 = Color3.fromRGB(16, 16, 30)
            card.BorderSizePixel = 0
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

            local nm = Instance.new("TextLabel", card)
            nm.Size = UDim2.new(1, 0, 0, 16)
            nm.Position = UDim2.new(0, 6, 0, 2)
            nm.BackgroundTransparency = 1
            nm.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"
            nm.TextColor3 = Color3.fromRGB(220, 218, 230)
            nm.Font = Enum.Font.GothamBold
            nm.TextSize = 10
            nm.TextXAlignment = Enum.TextXAlignment.Left

            local function btn(text, col, px, cb)
                local b = Instance.new("TextButton", card)
                b.Size = UDim2.new(0, 38, 0, 16)
                b.Position = UDim2.new(0, px, 0, 24)
                b.BackgroundColor3 = col
                b.BorderSizePixel = 0
                b.Text = text
                b.TextColor3 = Color3.new(1,1,1)
                b.Font = Enum.Font.GothamBold
                b.TextSize = 9
                Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
                b.MouseButton1Click:Connect(cb)
                return b
            end

            btn("Kill", Color3.fromRGB(180, 40, 60), 6, function()
                target = plr; killing = true
            end)
            btn("Stomp", Color3.fromRGB(140, 60, 30), 48, function()
                target = plr; stomping = true
            end)
            btn("TP", Color3.fromRGB(50, 70, 150), 90, function()
                pcall(function()
                    if lplr.Character and plr.Character then
                        lplr.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame
                    end
                end)
            end)
            btn("Bring", Color3.fromRGB(40, 120, 70), 132, function()
                pcall(function()
                    if lplr.Character and plr.Character then
                        plr.Character.HumanoidRootPart.CFrame = lplr.Character.HumanoidRootPart.CFrame + Vector3.new(3,0,0)
                    end
                end)
            end)
            local spamBtn = btn("Spam", Color3.fromRGB(140, 50, 140), 174, function() end)
            spamBtn.MouseButton1Click:Connect(function()
                if spamTargets[plr.Name] then
                    spamTargets[plr.Name] = nil
                    spamBtn.Text = "Spam"
                    spamBtn.BackgroundColor3 = Color3.fromRGB(140, 50, 140)
                else
                    spamTargets[plr.Name] = true
                    spamBtn.Text = "Stop"
                    spamBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
                end
            end)
        end

        local function refresh()
            for _, c in Scroll:GetChildren() do if c:IsA("Frame") then c:Destroy() end end
            for _, p in players:GetPlayers() do makeCard(p) end
            Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 6)
        end

        refresh()
        players.PlayerAdded:Connect(function() task.wait(1) refresh() end)
        players.PlayerRemoving:Connect(function(p) spamTargets[p.Name] = nil task.wait(0.5) refresh() end)

        -- Spam loop
        task.spawn(function()
            while true do
                task.wait(0.5)
                for name, _ in pairs(spamTargets) do
                    local p = players:FindFirstChild(name)
                    if p and p.Character then
                        target = p; killing = true
                    else
                        spamTargets[name] = nil
                    end
                end
            end
        end)

        -- Toggle
        UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.RightShift then
                Main.Visible = not Main.Visible
            end
        end)

        -- Drag
        local dragging, dragStart, startPos
        TBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; dragStart = input.Position; startPos = Main.Position
                input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local d = input.Position - dragStart
                Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)

        wsLog('Owner UI loaded — RightShift to toggle')
    end)
end
