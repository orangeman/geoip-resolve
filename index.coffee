exec = require('child_process').exec
csv = require('csv-streamify')
request = require('request')
through = require('through2')
bytewise = require("bytewise")
es = require('event-stream')
level = require('level')
fs = require('fs')

geoip = level "./data/geoip", keyEncoding: bytewise

module.exports =

  import: (file) ->
    geoip.close () ->
      console.log "closed "
      exec "rm -r #{file}", (err, out) ->
        console.log " deleted geoip db"
        geoip = level file, keyEncoding: bytewise
        tmp = level "./data/tmp", valueEncoding: 'json'
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
    geoip.createReadStream lte: i, reverse: true, limit: 1
    .pipe through.obj (d, enc, next) -> cb d?.value


#get "95.91.246.12" #home
#get "95.91.245.73" #büro
#get "217.251.193.0" # Frankfurt
