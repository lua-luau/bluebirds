local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local username = player.Name
local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local gameLink = "https://www.roblox.com/games/" .. game.PlaceId

local webhookUrl = "https://discord.com/api/webhooks/1379840667076923524/u8CyESQXykF52nMlp_eK-WXcB0aDSdxzSEfvD4KObqTylhr1GGy_QnLL0hdFvPaKWpXf"

local data = {
    ["embeds"] = {{
        ["title"] = "🚀 Script Executed!",
        ["description"] = "**Yippee!** 🎉 Someone just used my script.",
        ["color"] = 65280, 
        ["fields"] = {
            {
                ["name"] = "👤 Username",
                ["value"] = username,
                ["inline"] = true
            },
            {
                ["name"] = "🎮 Game",
                ["value"] = "[" .. gameName .. "](" .. gameLink .. ")",
                ["inline"] = true
            }
        },
        ["footer"] = {
            ["text"] = "Logger",
        },
        ["timestamp"] = DateTime.now():ToIsoDate()
    }}
}

local headers = {
    ["Content-Type"] = "application/json"
}

local body = HttpService:JSONEncode(data)

local requestFunc = (syn and syn.request) or (http and http.request) or (request) or (fluxus and fluxus.request)

if requestFunc then
    requestFunc({
        Url = webhookUrl,
        Method = "POST",
        Headers = headers,
        Body = body
    })
else
    warn("Your exploit does not support HTTP requests.")
end