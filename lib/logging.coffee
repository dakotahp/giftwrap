# You specified using cloud redis
if redistogo_url isnt ""
  rtg   = require("url").parse process.env.REDISTOGO_URL
  redis = require("redis").createClient rtg.port, rtg.hostname
  redis.auth rtg.auth.split(":")[1]

# You are using redis locally
else
  try
    redis  = require("redis").createClient()
  catch error
    console.error "Error: You have turned on web interface but have not installed redis or the required NPM module."
  finally
    # Stop entire process if redis is needed but not found
    process.exit(code=1)


class Log

  constructor: ->
    redis.on(
        "error"
        , (err) ->
          console.log "Error " + err
    )

  add: (message) ->
    redis.set "process_log", message, redis.print

  get: ->
    redis.get "process_log"