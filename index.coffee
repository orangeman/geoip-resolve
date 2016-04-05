exec = require('child_process').exec
csv = require('csv-streamify')
request = require('request')
through = require('through2')
es = require('event-stream')
level = require('level')
fs = require('fs')
alt = level "./data/alt"
tmp = level "./data/tmp", valueEncoding: 'json'

module.exports =

  import: () ->
    exec "rm -r data/geoip", (err, out) ->
      geoip = level "./data/geoip", keyEncoding: require "bytewise"
      console.log " deleted geoip db"
      fs.createReadStream "geoip.csv"
      .pipe csv delimiter: ",", objectMode: true
      .pipe through.obj (d, enc, next) ->
        tmp.get "id:" + d[4], (err, n) ->
          if n
            console.log "FOUND geoname id #{d[4]} :: #{n}   for IP range #{d[0]}-#{d[1]}  (#{d[2]}-#{d[3]})"
            geoip.put parseInt(d[2]), n
            geoip.put parseInt(d[3] + 1), null, next
          else next()

  resolve: (ip, cb) ->
    s = ip.split "."
    i = 0
    i += parseInt(s[0]) * 256 * 256 * 256
    i += parseInt(s[1]) * 256 * 256
    i += parseInt(s[2]) * 256
    i += parseInt(s[3])
    console.log "get #{ip}   #{i}"
    geoip = level "./data/geoip", keyEncoding: require "bytewise"
    geoip.createReadStream lte: i, reverse: true, limit: 1
    .pipe through.obj (d, enc, next) -> cb d?.value

#get "95.91.246.12" #home
#get "95.91.245.73" #büro
#get "217.251.193.0" # Frankfurt
