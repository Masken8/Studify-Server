local bundle = require("luvi").bundle
local uv = require("uv")
local p = require('pretty-print').prettyPrint
local QueryString = require("querystring")
local request = require("coro-http").request
local json = require("json")
local timer = require("timer")

local APIServer = {}

APIServer.clientId = nil
APIServer.currentApp = nil
APIServer.currentCode = nil
APIServer.currentToken = nil
APIServer.refreshToken = nil

APIServer.muted = false
APIServer.volumeBeforeMute = 100

function APIServer:Start(clientId, codeVerifier, redirectUri)
    self.clientId = clientId
    -- This returns a table that is the app instance.
    -- All it's functions return the same table for chaining calls.
    self.currentApp = require('weblit-app')

    .bind({
        host = "0.0.0.0",
        port = 8080
    })

    -- Include a few useful middlewares.  Weblit uses a layered approach.
    .use(require('weblit-logger'))
    .use(require('weblit-auto-headers'))
    .use(require('weblit-etag-cache'))

    -- This is a custom route handler
    .route({
        method = "GET",
        path = "/"
    }, function (req, res)
        p(req)

        local code = req.query["code"]
        local error = req.query["error"]

        if code then
            self.currentCode = code
            self:RequestAccessToken(codeVerifier, redirectUri)
        elseif error then
            error(error)
        end

        res.body = "Authentication successful"
        res.code = 200
    end)

    for _, endpoint in ipairs(bundle.readdir("./Endpoints/")) do
        local endpointModule = require("bundle:/Endpoints/"..endpoint)
        p(endpointModule)
        assert(endpointModule.path ~= "/", endpoint.." is attempting to use a protected endpoint")
        self.currentApp.route({
            method = endpointModule.method,
            path = endpointModule.path,
        }, endpointModule.callback)
    end

    self.currentApp.start()
    uv.run() -- keep program from exiting
end

function APIServer:Stop()
    self.currentApp.stop()
end

function APIServer:GetInfo(raw)
    do
        local Res, Body = request(
            "GET",
            "https://api.spotify.com/v1/me/player",
            {
                {"Content-Length", "0"},
                {"Authorization", "Bearer "..self.currentToken}
            }
        )

        if Res.code == 200 then
            if raw then
                return Body
            else
                return json.parse(Body)
            end
        else
            print("oof")
            p(Res)
            p(Body)
        end
    end
end

function constructForm(tbl)
    local first = true
    local str = ""
    for index,v in pairs(tbl) do
        if first then
            str = str..index.."="..QueryString.urlencode(v)
            first = false
        else
            str = str.."&"..index.."="..QueryString.urlencode(v)
        end
    end
    return str
end

function APIServer:SetMuted(muted)
    local info = self:GetInfo()

    if info then
        if muted then
            self.muted = true
            self.volumeBeforeMute = info["device"]["volume_percent"]
            self:SetVolume(0)
        else
            self.muted = false
            self:SetVolume(self.volumeBeforeMute)
            self.volumeBeforeMute = 100
        end
    end
end

function APIServer:Resume()
    do
        local Res, Body = request(
            "PUT",
            "https://api.spotify.com/v1/me/player/play",
            {
                {"Content-Length", "0"},
                {"Authorization", "Bearer "..self.currentToken}
            }
        )

        if not Res.code == 204 then
            p(Res)
            p(Body)
        end
    end
end

function APIServer:Pause()
    do
        local Res, Body = request(
            "PUT",
            "https://api.spotify.com/v1/me/player/pause",
            {
                {"Content-Length", "0"},
                {"Authorization", "Bearer "..self.currentToken}
            }
        )

        if Res.code == 204 then
            print("Yes")
        else
            p(Res)
            p(Body)
        end
    end
end

function APIServer:TogglePlaying()
    do
        local Res, Body = request(
            "GET",
            "https://api.spotify.com/v1/me/player",
            {
                {"Content-Length", "0"},
                {"Authorization", "Bearer "..self.currentToken}
            }
        )

        if Res.code == 200 then
            local BodyJSON = json.parse(Body)
            p(BodyJSON)
            if BodyJSON["is_playing"] then
                self:Pause()
            else
                self:Resume()
            end
        else
            print("oof")
            p(Res)
            p(Body)
        end
    end
end

function APIServer:SkipForward()
    do
        local Res, Body = request(
            "POST",
            "https://api.spotify.com/v1/me/player/next",
            {
                {"Content-Length", "0"},
                {"Authorization", "Bearer "..self.currentToken}
            }
        )

        if Res.code == 204 then
            print("Yes")
        else
            p(Res)
            p(Body)
        end
    end
end

function APIServer:SkipBackward()
    do
        local Res, Body = request(
            "POST",
            "https://api.spotify.com/v1/me/player/previous",
            {
                {"Content-Length", "0"},
                {"Authorization", "Bearer "..self.currentToken}
            }
        )

        if Res.code == 204 then
            print("Yes")
        else
            p(Res)
            p(Body)
        end
    end
end

function APIServer:SetVolume(volume)
    --[[
    local form = constructForm({
        volume_percent = tostring(volume)
    })
    ]]
    do
        local Res, Body = request(
            "PUT",
            "https://api.spotify.com/v1/me/player/volume?volume_percent="..tostring(volume),
            {
                {"Content-Length", "0"},
                {"Authorization", "Bearer "..self.currentToken}
            }
        )

        if Res.code == 204 then
            print("Volume set")
        else
            p(Res)
            p(Body)
        end
    end
end

local function TokenRefresher(expiresIn)
    print("Resuming refresh coroutine")

    timer.sleep((expiresIn-60)*1000) -- refresh 1 minute early to make sure token doesn't expire before refresh
    APIServer:RefreshAccessToken()
end

function APIServer:RequestAccessToken(codeVerifier, redirectUri)
    local form = constructForm({
        client_id = self.clientId,
        grant_type = "authorization_code",
        code = self.currentCode,
        redirect_uri = redirectUri,
        code_verifier = codeVerifier
    })
    do
        local AccessTokenResponse, Body = request(
            "POST",
            "https://accounts.spotify.com/api/token",
            {
                {"Content-Type", "application/x-www-form-urlencoded"},
                {"Accept", "application/json"}
            },
            form
        )
        print(form)
        if AccessTokenResponse.code == 200 then
            local BodyJSON = json.parse(Body)

            local RefreshCoroutine = coroutine.create(TokenRefresher)
            coroutine.resume(RefreshCoroutine, BodyJSON["expires_in"])

            p(BodyJSON)
            self.currentToken = BodyJSON["access_token"]
            self.refreshToken = BodyJSON["refresh_token"]
        else
            p(AccessTokenResponse)
            p(Body)
        end
    end
end

function APIServer:RefreshAccessToken()
    local form = constructForm({
        grant_type = "refresh_token",
        refresh_token = self.refreshToken,
        client_id = self.clientId,
    })
    do
        local AccessTokenResponse, Body = request(
            "POST",
            "https://accounts.spotify.com/api/token",
            {
                {"Content-Type", "application/x-www-form-urlencoded"},
                {"Accept", "application/json"}
            },
            form
        )
        print(form)
        if AccessTokenResponse.code == 200 then
            local BodyJSON = json.parse(Body)

            local RefreshCoroutine = coroutine.create(TokenRefresher)
            coroutine.resume(RefreshCoroutine, BodyJSON["expires_in"])

            p(BodyJSON)
            self.currentToken = BodyJSON["access_token"]
            self.refreshToken = BodyJSON["refresh_token"]
        else
            p(AccessTokenResponse)
            p(Body)
        end
    end
end

return APIServer