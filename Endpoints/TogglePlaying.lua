local SpotifyAPI = require("./../SpotifyAPIServer.lua")

local TogglePlaying = {}

TogglePlaying.method = "GET"

TogglePlaying.path = "/TogglePlaying"

TogglePlaying.callback = function(req, res)
    SpotifyAPI:TogglePlaying()

    res.code = 204
end

return TogglePlaying