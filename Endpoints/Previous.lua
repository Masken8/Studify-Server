local SpotifyAPI = require("./../SpotifyAPIServer.lua")

local Previous = {}

Previous.method = "GET"

Previous.path = "/Previous"

Previous.callback = function(req, res)
    SpotifyAPI:SkipBackward()

    res.code = 204
end

return Previous