local SpotifyAPI = require("./../SpotifyAPIServer.lua")

local Pause = {}

Pause.method = "GET"

Pause.path = "/Pause"

Pause.callback = function(req, res)
    SpotifyAPI:Pause()

    res.code = 204
end

return Pause