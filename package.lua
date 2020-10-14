  return {
    name = "studio-spotify-server",
    version = "0.1.0",
    description = "The intermediary server between Roblox and the Spotify API",
    tags = { "luvit", "roblox-studio", "spotify-api", "server" },
    license = "GNU GPLv3",
    author = { name = "Filip", email = "filip@masken8.com" },
    homepage = "https://github.com/studio-spotify-server",
    dependencies = {
      "james2doyle/base64-url",
      "creationix/coro-http",
      "creationix/weblit",
      "luvit/secure-socket"
    },
    files = {
      "**.lua",
      "!test*"
    }
  }
  