// Generated by CoffeeScript 1.10.0
(function() {
  var bytewise, csv, es, exec, fs, geoip, level, request, through;

  exec = require('child_process').exec;

  csv = require('csv-streamify');

  request = require('request');

  through = require('through2');

  bytewise = require("bytewise");

  es = require('event-stream');

  level = require('level');

  fs = require('fs');

  geoip = level("./data/geoip", {
    keyEncoding: bytewise
  });

  module.exports = {
    "import": function(file) {
      return geoip.close(function() {
        console.log("closed ");
        return exec("rm -r " + file, function(err, out) {
          var found, ips, places, tmp;
          console.log(" deleted geoip db");
          geoip = level(file, {
            keyEncoding: bytewise
          });
          tmp = level("./data/tmp", {
            valueEncoding: 'json'
          });
          places = {};
          found = 0;
          ips = 0;
          return fs.createReadStream("geoip.csv").pipe(csv({
            delimiter: ",",
            objectMode: true
          })).pipe(through.obj(function(d, enc, next) {
            return tmp.get("id:" + d[4], function(err, n) {
              ips += 1;
              if (n) {
                found += 1;
                places[n] = true;
                console.log("FOUND geoname id " + d[4] + " :: " + n + "   for IP range " + d[0] + "-" + d[1] + "  (" + d[2] + "-" + d[3] + ")");
                geoip.put(parseInt(d[2]), n);
                return geoip.put(parseInt(d[3] + 1), null, next);
              } else {
                return next();
              }
            });
          })).on("end", function() {
            return console.log("done.\n found " + (Object.keys(places).length) + " places for " + found + " places out of " + ips + " ip ranges");
          });
        });
      });
    },
    resolve: function(ip, cb) {
      var i, s;
      s = ip.split(".");
      i = 0;
      i += parseInt(s[0]) * 256 * 256 * 256;
      i += parseInt(s[1]) * 256 * 256;
      i += parseInt(s[2]) * 256;
      i += parseInt(s[3]);
      console.log("get " + ip + "   " + i);
      return geoip.createReadStream({
        lte: i,
        reverse: true,
        limit: 1
      }).pipe(through.obj(function(d, enc, next) {
        return cb(d != null ? d.value : void 0);
      }));
    }
  };

}).call(this);
