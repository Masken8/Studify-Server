local SpotifyAPI = require("./../SpotifyAPIServer.lua")
local json = require("json")

local ToggleMute = {}

ToggleMute.method = "GET"

ToggleMute.path = "/ToggleMute"

ToggleMute.callback = function(req, res)
    local info = SpotifyAPI:GetInfo()

    if info then
        if not SpotifyAPI.muted then
            local infoJSON = json.parse(info)
            SpotifyAPI.muted = true
            SpotifyAPI.volumeBeforeMute = infoJSON["device"]["volume_percent"]
            SpotifyAPI:SetVolume(0)
        else
            SpotifyAPI.muted = false
            SpotifyAPI:SetVolume(SpotifyAPI.volumeBeforeMute)
            SpotifyAPI.volumeBeforeMute = 100
        end
    end

    res.code = 204
end

return ToggleMute