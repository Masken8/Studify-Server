local SpotifyAPI = require("./../SpotifyAPIServer.lua")

local GetInfo = {}

GetInfo.method = "GET"

GetInfo.path = "/GetInfo"

GetInfo.callback = function(req, res)
    local inforaw = SpotifyAPI:GetInfo(true)

    if inforaw then
        res.body = inforaw
        res.code = 200
    else
        res.code = 500
    end
end

return GetInfo