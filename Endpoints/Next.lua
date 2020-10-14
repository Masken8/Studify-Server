local SpotifyAPI = require("./../SpotifyAPIServer.lua")

local Next = {}

Next.method = "GET"

Next.path = "/Next"

Next.callback = function(req, res)
    SpotifyAPI:SkipForward()

    res.code = 204
end

return Next