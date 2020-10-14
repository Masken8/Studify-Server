local SpotifyAPI = require("./../SpotifyAPIServer.lua")
local json = require("json")

local GetMuted = {}

GetMuted.method = "GET"

GetMuted.path = "/GetMuted"

GetMuted.callback = function(req, res)
    local isMutedRes = json.stringify({
        muted = SpotifyAPI.muted
    })

    if isMutedRes then
        res.body = isMutedRes
        res.code = 200
    else
        res.code = 500
    end
end

return GetMuted