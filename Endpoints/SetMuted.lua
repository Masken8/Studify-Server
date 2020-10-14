local SpotifyAPI = require("./../SpotifyAPIServer.lua")
local json = require("json")

local SetMuted = {}

SetMuted.method = "POST"

SetMuted.path = "/SetMuted"

SetMuted.callback = function(req, res)
    local params = json.parse(req.body)

    if params then
        local mute = params["mute"]
        SpotifyAPI:SetMuted(mute)
        res.code = 204
    else
        res.code = 400
    end
end

return SetMuted