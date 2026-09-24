local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- Discord blokir request langsung dari Roblox, pakai proxy
local WEBHOOK_URL = "https://discord.com/api/webhooks/1425552550693961730/UnZoF2M5fwi2mdcyWYjvZdZS4Q7Ux8MtTJaMVZGqVensHGMY6wAEV27gedMKxIGocUV4"
local INTERVAL = 0.5
local MAX_STRIKES = 4
local SPEED_TOLERANCE = 1.6
local MAX_HOVER_TIME = 3

local data = {}

local function sendWebhook(player, reason)
	local payload = {
		username = "Anti-Cheat",
		embeds = {{
			title = "Player di-kick",
			color = 16711680,
			fields = {
				{name = "Username", value = player.Name, inline = true},
				{name = "UserId", value = tostring(player.UserId), inline = true},
				{name = "Alasan", value = reason},
				{name = "Server", value = game.JobId ~= "" and game.JobId or "Studio"},
			},
		}},
	}
	pcall(function()
		HttpService:PostAsync(WEBHOOK_URL, HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
	end)
end

local function flag(player, reason)
	local d = data[player]
	if not d then return end
	d.strikes = d.strikes + 1
	if d.strikes >= MAX_STRIKES then
		data[player] = nil
		task.spawn(sendWebhook, player, reason)
		player:Kick("Terdeteksi cheat: " .. reason)
	end
end

local function resetState(player, grace)
	data[player] = data[player] or {strikes = 0}
	local d = data[player]
	d.lastPos = nil
	d.hover = 0
	d.grace = os.clock() + (grace or 3)
end

local function checkPlayer(player)
	local d = data[player]
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (d and hum and root) then return end
	if hum.Health <= 0 then return end

	local ignore = player:GetAttribute("ACIgnoreUntil") or 0
	if os.clock() < d.grace or os.clock() < ignore or hum.SeatPart then
		d.lastPos = root.Position
		d.hover = 0
		return
	end

	-- 1) Speed hack
	if d.lastPos then
		local delta = (root.Position - d.lastPos) * Vector3.new(1, 0, 1)
		local speed = delta.Magnitude / INTERVAL
		if speed > hum.WalkSpeed * SPEED_TOLERANCE + 8 then
			flag(player, "Speed hack (" .. math.floor(speed) .. " studs/s)")
		end
	end
	d.lastPos = root.Position

	-- 2) Fly hack
	local airborne = hum.FloorMaterial == Enum.Material.Air
	local notFalling = root.AssemblyLinearVelocity.Y > -5
	local climbing = hum:GetState() == Enum.HumanoidStateType.Climbing
	if airborne and notFalling and not climbing then
		d.hover = d.hover + INTERVAL
		if d.hover >= MAX_HOVER_TIME then
			d.hover = 0
			flag(player, "Fly hack (melayang di udara)")
		end
	else
		d.hover = 0
	end
end

Players.PlayerAdded:Connect(function(player)
	resetState(player)
	player.CharacterAdded:Connect(function()
		resetState(player, 3)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	data[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			checkPlayer(player)
		end
	end
end)
