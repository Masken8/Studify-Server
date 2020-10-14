local openssl = require("openssl")
local digest = openssl.digest
local CryptoMath = require("bundle:/CryptoMath.lua")
local Base64URL = require("base64-url")
local QueryString = require("querystring")

local function StringToSHA256(str)
    return digest.digest("sha256", str, true)
end

local function StringToBase64URL(str)
    local url = openssl.base64(str)
    return Base64URL.escape(url)
end

local function Base64URLToString(str)
    local url = Base64URL.unescape(str)
    return openssl.base64(url, false)
end

local urlTemplate = "%s?client_id=%s^&response_type=%s^&redirect_uri=%s^&code_challenge_method=%s^&code_challenge=%s^&scope=%s"

local function CreateAuthURI(host, clientId, responseType, redirectUri, codeChallengeMethod, codeChallenge, scope)
    return string.format(urlTemplate, host, clientId, responseType, redirectUri, codeChallengeMethod, codeChallenge, scope)
end

local str = CryptoMath.RandomString(128)

print("Random: "..str)
local hashedStr = StringToSHA256(str)
print("SHA256: "..hashedStr)

print("Base64: "..openssl.base64(hashedStr))

local base64HashedStr = StringToBase64URL(hashedStr)
print("Base64URL: "..base64HashedStr)

local clientId = "95565900c1c84bdd813b4a4d48a68c08"

local authURL = CreateAuthURI(
    "https://accounts.spotify.com/authorize",
    clientId,
    "code",
    QueryString.urlencode("http://localhost:8080/"),
    "S256",
    base64HashedStr,
    QueryString.urlencode("user-modify-playback-state user-read-currently-playing user-read-playback-state")
)

os.execute("start "..authURL)

local APIServer = require("bundle:/SpotifyAPIServer.lua")
APIServer:Start(clientId, str, "http://localhost:8080/")