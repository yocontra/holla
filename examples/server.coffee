{join} = require 'path'
express = require "express"
http = require 'http'
holla = require "../"
redis  = require 'socket.io/node_modules/redis'

port = process.argv[2] or 8080

###
pub = redis.createClient()
sub = redis.createClient()
norm = redis.createClient()

pub.on 'error', (e) -> throw e
sub.on 'error', (e) -> throw e
norm.on 'error', (e) -> throw e

opt =
  debug: true
  redis:
    pub: pub
    sub: sub
    store: norm
###

transform = (socket, name, cb) ->
  name = "test" if name is "test2"
  cb null, name

opt =
  debug: true
  identityProvider: transform

app = express()
app.use express.static __dirname
server = http.createServer(app).listen port
rtc = holla.createServer server, opt


console.log "Server running on port #{port}"