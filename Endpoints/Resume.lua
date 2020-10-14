local SpotifyAPI = require("./../SpotifyAPIServer.lua")

local Resume = {}

Resume.method = "GET"

Resume.path = "/Resume"

Resume.callback = function(req, res)
    SpotifyAPI:Resume()

    res.code = 204
end

return Resume